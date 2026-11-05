import 'dart:typed_data';

import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/network/byte_range_response.dart';
import '../models/chapter.dart';

/// Progressive PDF byte reader backed by authenticated HTTP Range requests.
///
/// Designed for `pdfrx` `PdfDocument.openCustom` / `PdfDocumentRefCustom`.
/// Each read obtains a fresh usable access token through [ApiClient] (Bearer
/// header only; never query). Concurrent reads are safe; disposed sources
/// reject further reads.
class AuthenticatedPdfRangeSource {
  AuthenticatedPdfRangeSource({
    required ApiClient client,
    required this.document,
    required this.bookId,
    required this.chapterId,
  })  : _client = client,
        fileSize = document.size,
        sourceName =
            'chapter-pdf:$bookId:$chapterId:${document.sha256}:${document.size}';

  final ApiClient _client;
  final ChapterDocument document;
  final String bookId;
  final String chapterId;
  final int fileSize;
  final String sourceName;

  bool _disposed = false;
  int _bytesDownloaded = 0;

  int get bytesDownloaded => _bytesDownloaded;

  String get apiPath => document.apiRelativePath;

  void dispose() {
    _disposed = true;
  }

  bool get isDisposed => _disposed;

  /// pdfrx custom read callback: fill [buffer] from [position] for up to [size].
  Future<int> read(Uint8List buffer, int position, int size) async {
    if (_disposed) {
      throw const ApiException(
        statusCode: 0,
        code: 'CANCELLED',
        message: 'Document closed.',
      );
    }
    if (size <= 0) return 0;
    if (position < 0 || position >= fileSize) return 0;

    final int end = (position + size - 1).clamp(position, fileSize - 1);
    final ByteRangeResponse response = await _client.getByteRange(
      apiPath,
      start: position,
      endInclusive: end,
      expectedTotalSize: fileSize,
      auth: AuthMode.required,
    );

    if (_disposed) {
      throw const ApiException(
        statusCode: 0,
        code: 'CANCELLED',
        message: 'Document closed.',
      );
    }

    if (response.start != position) {
      throw const ApiException(
        statusCode: 0,
        code: 'MALFORMED_RESPONSE',
        message: 'Range response offset mismatch.',
      );
    }
    if (response.totalSize > 0 && response.totalSize != fileSize) {
      throw const ApiException(
        statusCode: 416,
        code: 'DOCUMENT_SIZE_MISMATCH',
        message: 'Document size changed. Please reopen the chapter.',
      );
    }

    final int copyLength = response.bytes.length.clamp(0, size);
    if (copyLength > buffer.length) {
      throw const ApiException(
        statusCode: 0,
        code: 'MALFORMED_RESPONSE',
        message: 'Range response exceeds buffer.',
      );
    }
    buffer.setRange(0, copyLength, response.bytes);
    _bytesDownloaded += copyLength;
    return copyLength;
  }
}
