import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/network/byte_range_response.dart';
import '../models/chapter.dart';

/// Progressive PDF byte reader backed by authenticated HTTP Range requests.
///
/// Designed for `pdfrx` `PdfDocument.openCustom` / `PdfDocumentRefCustom`.
///
/// Important PDFium contract (see `FPDF_FILEACCESS.m_GetBlock`):
/// - Return **non-zero** only when the **entire** requested window was filled.
/// - Return **0** on failure.
/// - Never throw across the pdfrx `FileAccess` bridge: pdfrx 1.0.84 maps
///   Dart exceptions to `-1`, which PDFium treats as success and then parses
///   an uninitialized buffer.
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

  /// Upper bound per HTTP Range call. Keeps proxies happy and matches the
  /// volume of small GetBlock requests PDFium issues for large files.
  static const int rangeChunkBytes = 256 * 1024;

  final ApiClient _client;
  final ChapterDocument document;
  final String bookId;
  final String chapterId;
  final int fileSize;
  final String sourceName;

  bool _disposed = false;
  int _bytesDownloaded = 0;
  int _rangeRequestCount = 0;
  Object? _lastError;

  int get bytesDownloaded => _bytesDownloaded;
  int get rangeRequestCount => _rangeRequestCount;
  Object? get lastError => _lastError;

  String get apiPath => document.apiRelativePath;

  void dispose() {
    _disposed = true;
  }

  bool get isDisposed => _disposed;

  /// pdfrx custom read callback: fill [buffer] from [position] for exactly
  /// [size] bytes (PDFium never requests past EOF).
  ///
  /// Returns [size] on success, or `0` on failure / dispose. Does not throw.
  Future<int> read(Uint8List buffer, int position, int size) async {
    if (_disposed) {
      _lastError = const ApiException(
        statusCode: 0,
        code: 'CANCELLED',
        message: 'Document closed.',
      );
      return 0;
    }
    if (size <= 0) return 0;
    if (position < 0 || position >= fileSize) return 0;
    if (position + size > fileSize) {
      // PDFium must not ask past EOF; treat as hard failure rather than a
      // short success (short success leaves garbage in the remainder).
      _lastError = ApiException(
        statusCode: 416,
        code: 'INVALID_RANGE',
        message:
            'PDF reader requested bytes past document end ($position+$size > $fileSize).',
      );
      debugPrint(
        '[pdf-range] FAIL book=$bookId chapter=$chapterId '
        'pastEOF pos=$position size=$size fileSize=$fileSize',
      );
      return 0;
    }
    if (size > buffer.length) {
      _lastError = const ApiException(
        statusCode: 0,
        code: 'MALFORMED_RESPONSE',
        message: 'Range response exceeds buffer.',
      );
      return 0;
    }

    try {
      int offset = 0;
      while (offset < size) {
        if (_disposed) {
          _lastError = const ApiException(
            statusCode: 0,
            code: 'CANCELLED',
            message: 'Document closed.',
          );
          return 0;
        }
        final int chunkStart = position + offset;
        final int chunkLen = (size - offset) > rangeChunkBytes
            ? rangeChunkBytes
            : (size - offset);
        final int chunkEnd = chunkStart + chunkLen - 1;
        final int requestIndex = ++_rangeRequestCount;

        debugPrint(
          '[pdf-range] #$requestIndex GET $apiPath '
          'bytes=$chunkStart-$chunkEnd book=$bookId chapter=$chapterId',
        );

        final ByteRangeResponse response = await _client.getByteRange(
          apiPath,
          start: chunkStart,
          endInclusive: chunkEnd,
          expectedTotalSize: fileSize,
          auth: AuthMode.required,
        );

        if (_disposed) {
          _lastError = const ApiException(
            statusCode: 0,
            code: 'CANCELLED',
            message: 'Document closed.',
          );
          return 0;
        }

        if (response.start != chunkStart) {
          throw const ApiException(
            statusCode: 0,
            code: 'MALFORMED_RESPONSE',
            message: 'Range response offset mismatch.',
          );
        }
        if (response.bytes.length != chunkLen) {
          throw ApiException(
            statusCode: response.statusCode,
            code: 'MALFORMED_RESPONSE',
            message:
                'Range response length mismatch: got ${response.bytes.length}, expected $chunkLen.',
          );
        }
        if (response.totalSize > 0 && response.totalSize != fileSize) {
          throw const ApiException(
            statusCode: 416,
            code: 'DOCUMENT_SIZE_MISMATCH',
            message: 'Document size changed. Please reopen the chapter.',
          );
        }
        if (chunkStart == 0 &&
            offset == 0 &&
            response.bytes.length >= 5 &&
            !(response.bytes[0] == 0x25 &&
                response.bytes[1] == 0x50 &&
                response.bytes[2] == 0x44 &&
                response.bytes[3] == 0x46)) {
          // %PDF
          throw const ApiException(
            statusCode: 0,
            code: 'MALFORMED_RESPONSE',
            message: 'Document does not start with a PDF header.',
          );
        }

        buffer.setRange(offset, offset + chunkLen, response.bytes);
        offset += chunkLen;
        _bytesDownloaded += chunkLen;

        debugPrint(
          '[pdf-range] #$requestIndex OK status=${response.statusCode} '
          'len=${response.bytes.length} total=${response.totalSize}',
        );
      }
      _lastError = null;
      return size;
    } catch (error, stack) {
      _lastError = error;
      debugPrint(
        '[pdf-range] FAIL book=$bookId chapter=$chapterId '
        'pos=$position size=$size error=$error\n$stack',
      );
      // Never throw into pdfrx FileAccess (maps to -1 == false "success").
      return 0;
    }
  }
}
