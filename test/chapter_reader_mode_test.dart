import 'package:flutter_test/flutter_test.dart';
import 'package:maanthirigam/data/models/chapter.dart';

void main() {
  group('ChapterReaderMode', () {
    test('missing readerMode defaults to RICH_TEXT', () {
      final ChapterContent chapter = ChapterContent.fromJson(<String, dynamic>{
        'id': 'ch1',
        'bookId': 'b1',
        'chapterNumber': 1,
        'title': 'Opening',
        'contentFormat': 'RICH_TEXT',
        'status': 'PUBLISHED',
        'content': <String, dynamic>{
          'version': 1,
          'blocks': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'p1',
              'type': 'paragraph',
              'text': 'Hello',
            },
          ],
        },
      });
      expect(chapter.readerMode, ChapterReaderMode.richText);
      expect(chapter.isOriginalPdf, isFalse);
      expect(chapter.content, isNotNull);
      expect(chapter.document, isNull);
    });

    test('RICH_TEXT keeps content and ignores PDF routing', () {
      final ChapterContent chapter = ChapterContent.fromJson(<String, dynamic>{
        'id': 'ch1',
        'bookId': 'b1',
        'chapterNumber': 1,
        'title': 'Opening',
        'readerMode': 'RICH_TEXT',
        'contentFormat': 'RICH_TEXT',
        'status': 'PUBLISHED',
        'content': <String, dynamic>{
          'version': 1,
          'blocks': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'p1',
              'type': 'paragraph',
              'text': 'Body',
            },
          ],
        },
      });
      expect(chapter.readerMode, ChapterReaderMode.richText);
      expect(chapter.pdfOpenError(), isNull);
    });

    test('ORIGINAL_PDF parses document and does not require rich text', () {
      final ChapterContent chapter = ChapterContent.fromJson(<String, dynamic>{
        'id': 'ch9',
        'bookId': 'book9',
        'chapterNumber': 9,
        'title': 'Yantra',
        'readerMode': 'ORIGINAL_PDF',
        'contentFormat': 'ORIGINAL_PDF',
        'status': 'PUBLISHED',
        'document': <String, dynamic>{
          'mediaId': 'm1',
          'fileName': 'original-book.pdf',
          'mimeType': 'application/pdf',
          'size': 5380261,
          'pageCount': 33,
          'sha256': 'abc123',
          'downloadPath': '/api/v1/books/book9/chapters/ch9/document',
        },
      });
      expect(chapter.readerMode, ChapterReaderMode.originalPdf);
      expect(chapter.isOriginalPdf, isTrue);
      expect(chapter.content, isNull);
      expect(chapter.document, isNotNull);
      expect(chapter.pdfOpenError(), isNull);
      expect(chapter.document!.apiRelativePath,
          '/books/book9/chapters/ch9/document');
    });

    test('ORIGINAL_PDF missing document is a safe error', () {
      final ChapterContent chapter = ChapterContent.fromJson(<String, dynamic>{
        'id': 'ch9',
        'bookId': 'book9',
        'chapterNumber': 9,
        'title': 'Yantra',
        'readerMode': 'ORIGINAL_PDF',
        'status': 'PUBLISHED',
      });
      expect(chapter.pdfOpenError(), isNotNull);
    });

    test(
        'production mobile document without sha256 is reported as API/data issue',
        () {
      // Exact document projection observed from production:
      // GET /api/v1/books/6aead7cd76bf708b45cc60ab/chapters
      // (sha256 key absent; Admin UI still shows a stored checksum).
      final ChapterContent chapter = ChapterContent.fromJson(<String, dynamic>{
        'id': '6aead7f676bf708b45cc60de',
        'bookId': '6aead7cd76bf708b45cc60ab',
        'chapterNumber': 1,
        'title': 'தாந்தீரிகம் புத்தகம்',
        'contentFormat': 'RICH_TEXT',
        'readerMode': 'ORIGINAL_PDF',
        'status': 'PUBLISHED',
        'document': <String, dynamic>{
          'mediaId': '6aead7f976bf708b45cc60f4',
          'fileName': '_ _ __260823_184815 (2).pdf',
          'mimeType': 'application/pdf',
          'size': 5380261,
          'pageCount': 33,
          'downloadPath':
              '/api/v1/books/6aead7cd76bf708b45cc60ab/chapters/6aead7f676bf708b45cc60de/document',
        },
      });
      expect(chapter.document, isNotNull);
      expect(chapter.document!.sha256, isEmpty);
      expect(
        chapter.pdfOpenError(),
        'This document is missing an integrity checksum.',
      );
    });

    test('document.sha256 is preserved exactly from chapter JSON', () {
      const String checksum =
          'd9d6ebfaea32e221e9a4465980e4cd7feaee8a45dd186d3e8001eb1199d95231';
      final ChapterContent chapter = ChapterContent.fromJson(<String, dynamic>{
        'id': '6aead7f676bf708b45cc60de',
        'bookId': '6aead7cd76bf708b45cc60ab',
        'chapterNumber': 1,
        'title': 'தாந்தீரிகம் புத்தகம்',
        'readerMode': 'ORIGINAL_PDF',
        'status': 'PUBLISHED',
        'document': <String, dynamic>{
          'mediaId': '6aead7f976bf708b45cc60f4',
          'fileName': '_ _ __260823_184815 (2).pdf',
          'mimeType': 'application/pdf',
          'size': 5380261,
          'pageCount': 33,
          'sha256': checksum,
          'downloadPath':
              '/api/v1/books/6aead7cd76bf708b45cc60ab/chapters/6aead7f676bf708b45cc60de/document',
        },
      });
      expect(chapter.document!.sha256, checksum);
      expect(chapter.pdfOpenError(), isNull);
    });

    test('empty sha256 string is rejected the same as a missing key', () {
      final ChapterContent chapter = ChapterContent.fromJson(<String, dynamic>{
        'id': 'ch1',
        'bookId': 'b1',
        'chapterNumber': 1,
        'title': 'PDF',
        'readerMode': 'ORIGINAL_PDF',
        'status': 'PUBLISHED',
        'document': <String, dynamic>{
          'mediaId': 'm1',
          'fileName': 'a.pdf',
          'mimeType': 'application/pdf',
          'size': 100,
          'pageCount': 1,
          'sha256': '   ',
          'downloadPath': '/books/b1/chapters/ch1/document',
        },
      });
      expect(
        chapter.pdfOpenError(),
        'This document is missing an integrity checksum.',
      );
    });

    test('readerMode is authoritative even when document metadata is present',
        () {
      final ChapterContent chapter = ChapterContent.fromJson(<String, dynamic>{
        'id': 'ch1',
        'bookId': 'b1',
        'chapterNumber': 1,
        'title': 'Opening',
        'readerMode': 'RICH_TEXT',
        'contentFormat': 'RICH_TEXT',
        'status': 'PUBLISHED',
        'content': <String, dynamic>{
          'version': 1,
          'blocks': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'p1',
              'type': 'paragraph',
              'text': 'Body',
            },
          ],
        },
        'document': <String, dynamic>{
          'mediaId': 'm1',
          'fileName': 'ignored.pdf',
          'mimeType': 'application/pdf',
          'size': 100,
          'pageCount': 1,
          'sha256': 'sha',
          'downloadPath': '/books/b1/chapters/ch1/document',
        },
      });
      expect(chapter.readerMode, ChapterReaderMode.richText);
      expect(chapter.isOriginalPdf, isFalse);
      expect(chapter.pdfOpenError(), isNull);
    });

    test('documented ORIGINAL_PDF chapter fixture parses all document fields',
        () {
      // Fixture mirrors Docs/MOBILE_APP_INTEGRATION Original PDF chapter shape.
      final ChapterContent chapter = ChapterContent.fromJson(<String, dynamic>{
        'id': 'aaaaaaaaaaaaaaaaaaaaaaaa',
        'bookId': 'bbbbbbbbbbbbbbbbbbbbbbbb',
        'chapterNumber': 1,
        'title': 'Mantirigam PDF',
        'contentFormat': 'ORIGINAL_PDF',
        'status': 'PUBLISHED',
        'readerMode': 'ORIGINAL_PDF',
        'document': <String, dynamic>{
          'mediaId': 'cccccccccccccccccccccccc',
          'fileName': 'original-book.pdf',
          'mimeType': 'application/pdf',
          'size': 5380261,
          'pageCount': 33,
          'sha256': 'deadbeefcafebabe',
          'downloadPath':
              '/api/v1/books/bbbbbbbbbbbbbbbbbbbbbbbb/chapters/aaaaaaaaaaaaaaaaaaaaaaaa/document',
        },
      });
      expect(chapter.isOriginalPdf, isTrue);
      expect(chapter.document!.mediaId, 'cccccccccccccccccccccccc');
      expect(chapter.document!.fileName, 'original-book.pdf');
      expect(chapter.document!.mimeType, 'application/pdf');
      expect(chapter.document!.size, 5380261);
      expect(chapter.document!.pageCount, 33);
      expect(chapter.document!.sha256, 'deadbeefcafebabe');
      expect(chapter.pdfOpenError(), isNull);
    });

    test('rejects external downloadPath and wrong chapter ids', () {
      const ChapterDocument doc = ChapterDocument(
        mediaId: 'm1',
        fileName: 'x.pdf',
        mimeType: 'application/pdf',
        size: 100,
        pageCount: 2,
        sha256: 'sha',
        downloadPath: 'https://evil.example/file.pdf',
      );
      expect(
        doc.validationError(expectedBookId: 'b1', expectedChapterId: 'c1'),
        isNotNull,
      );

      const ChapterDocument wrong = ChapterDocument(
        mediaId: 'm1',
        fileName: 'x.pdf',
        mimeType: 'application/pdf',
        size: 100,
        pageCount: 2,
        sha256: 'sha',
        downloadPath: '/books/other/chapters/c1/document',
      );
      expect(
        wrong.validationError(expectedBookId: 'b1', expectedChapterId: 'c1'),
        isNotNull,
      );
    });

    test('rejects non-pdf mime and oversized files', () {
      const ChapterDocument badMime = ChapterDocument(
        mediaId: 'm1',
        fileName: 'x.bin',
        mimeType: 'application/octet-stream',
        size: 100,
        pageCount: 1,
        sha256: 'sha',
        downloadPath: '/books/b1/chapters/c1/document',
      );
      expect(
        badMime.validationError(expectedBookId: 'b1', expectedChapterId: 'c1'),
        contains('PDF'),
      );

      const ChapterDocument huge = ChapterDocument(
        mediaId: 'm1',
        fileName: 'x.pdf',
        mimeType: 'application/pdf',
        size: ChapterDocument.maxAcceptedBytes + 1,
        pageCount: 1,
        sha256: 'sha',
        downloadPath: '/books/b1/chapters/c1/document',
      );
      expect(
        huge.validationError(expectedBookId: 'b1', expectedChapterId: 'c1'),
        isNotNull,
      );
    });
  });
}
