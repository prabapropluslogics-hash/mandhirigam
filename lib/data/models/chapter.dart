import '../../core/utils/json_map.dart';
import 'rich_text_document.dart';

/// How a published chapter should be presented in the mobile reader.
enum ChapterReaderMode {
  richText,
  originalPdf;

  static ChapterReaderMode parse(Object? raw) {
    final String value = asString(raw).trim().toUpperCase();
    if (value == 'ORIGINAL_PDF') return ChapterReaderMode.originalPdf;
    // Missing / unknown / RICH_TEXT → existing rich-text reader.
    return ChapterReaderMode.richText;
  }

  String get wireName =>
      this == ChapterReaderMode.originalPdf ? 'ORIGINAL_PDF' : 'RICH_TEXT';
}

/// Authenticated original-PDF metadata from the chapter API.
///
/// Do not invent fields beyond the backend contract.
class ChapterDocument {
  const ChapterDocument({
    required this.mediaId,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.pageCount,
    required this.sha256,
    required this.downloadPath,
  });

  final String mediaId;
  final String fileName;
  final String mimeType;
  final int size;
  final int pageCount;
  final String sha256;
  final String downloadPath;

  factory ChapterDocument.fromJson(Map<String, dynamic> json) {
    return ChapterDocument(
      mediaId: asString(json['mediaId']),
      fileName: asString(json['fileName']),
      mimeType: asString(json['mimeType']),
      size: asInt(json['size']),
      pageCount: asInt(json['pageCount']),
      sha256: asString(json['sha256']).trim(),
      downloadPath: asString(json['downloadPath']),
    );
  }

  /// Backend upload ceiling (`DOCUMENT_MAX_UPLOAD_MB`, default 25).
  static const int maxAcceptedBytes = 25 * 1024 * 1024;

  /// Returns a user-facing reason when metadata is unsafe to open, else null.
  String? validationError({
    required String expectedBookId,
    required String expectedChapterId,
  }) {
    if (mediaId.isEmpty) return 'This document is missing a media id.';
    if (mimeType.toLowerCase() != 'application/pdf') {
      return 'This chapter is not a PDF document.';
    }
    if (size <= 0) return 'This document has an invalid size.';
    if (size > maxAcceptedBytes) {
      return 'This document is larger than the supported limit.';
    }
    if (pageCount <= 0) return 'This document has an invalid page count.';
    if (sha256.isEmpty) {
      return 'This document is missing an integrity checksum.';
    }
    if (downloadPath.isEmpty) {
      return 'This document has no download path.';
    }
    if (downloadPath.contains('://') ||
        downloadPath.toLowerCase().startsWith('http')) {
      return 'This document path is not allowed.';
    }
    final String normalized =
        downloadPath.startsWith('/') ? downloadPath : '/$downloadPath';
    // Accept with or without a leading /api/v1 (AppEnv.resolve handles base).
    final String path = normalized.replaceFirst(RegExp(r'^/api/v1'), '');
    final RegExp expected = RegExp(
      r'^/books/' +
          RegExp.escape(expectedBookId) +
          r'/chapters/' +
          RegExp.escape(expectedChapterId) +
          r'/document/?$',
    );
    if (!expected.hasMatch(path)) {
      return 'This document path does not match the chapter.';
    }
    return null;
  }

  /// Path relative to `API_BASE_URL` (no duplicated `/api/v1`).
  String get apiRelativePath {
    String path = downloadPath.trim();
    if (!path.startsWith('/')) path = '/$path';
    if (path.startsWith('/api/v1/')) {
      path = path.substring('/api/v1'.length);
    }
    return path;
  }
}

class ChapterSummary {
  const ChapterSummary({
    required this.id,
    required this.bookId,
    required this.chapterNumber,
    required this.title,
    required this.contentFormat,
    required this.status,
    this.readerMode = ChapterReaderMode.richText,
  });

  final String id;
  final String bookId;
  final int chapterNumber;
  final String title;
  final String contentFormat;
  final String status;
  final ChapterReaderMode readerMode;

  factory ChapterSummary.fromJson(Map<String, dynamic> json) {
    return ChapterSummary(
      id: asString(json['id']),
      bookId: asString(json['bookId']),
      chapterNumber: asInt(json['chapterNumber']),
      title: asString(json['title']),
      contentFormat: asString(json['contentFormat'], 'RICH_TEXT'),
      status: asString(json['status'], 'PUBLISHED'),
      readerMode: ChapterReaderMode.parse(json['readerMode']),
    );
  }
}

class ChapterContent extends ChapterSummary {
  const ChapterContent({
    required super.id,
    required super.bookId,
    required super.chapterNumber,
    required super.title,
    required super.contentFormat,
    required super.status,
    required super.readerMode,
    this.content,
    this.document,
  });

  /// Rich Text body. Null when [readerMode] is [ChapterReaderMode.originalPdf].
  final RichTextDocument? content;

  /// Present when [readerMode] is [ChapterReaderMode.originalPdf].
  final ChapterDocument? document;

  bool get isOriginalPdf => readerMode == ChapterReaderMode.originalPdf;

  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    final ChapterReaderMode mode = ChapterReaderMode.parse(json['readerMode']);
    final Object? rawDocument = json['document'];
    final ChapterDocument? document = rawDocument is Map
        ? ChapterDocument.fromJson(asJsonMap(rawDocument))
        : null;

    RichTextDocument? content;
    if (mode == ChapterReaderMode.richText) {
      content = RichTextDocument.fromJson(asJsonMap(json['content']));
    } else if (json['content'] is Map) {
      // Optional leftover; PDF mode must not require blocks.
      try {
        content = RichTextDocument.fromJson(asJsonMap(json['content']));
      } catch (_) {
        content = null;
      }
    }

    return ChapterContent(
      id: asString(json['id']),
      bookId: asString(json['bookId']),
      chapterNumber: asInt(json['chapterNumber']),
      title: asString(json['title']),
      contentFormat: asString(json['contentFormat'], 'RICH_TEXT'),
      status: asString(json['status'], 'PUBLISHED'),
      readerMode: mode,
      content: content,
      document: document,
    );
  }

  /// Validates ORIGINAL_PDF metadata for the active book/chapter route.
  String? pdfOpenError() {
    if (readerMode != ChapterReaderMode.originalPdf) return null;
    final ChapterDocument? doc = document;
    if (doc == null) {
      return 'This PDF chapter is missing document metadata.';
    }
    return doc.validationError(
      expectedBookId: bookId,
      expectedChapterId: id,
    );
  }
}
