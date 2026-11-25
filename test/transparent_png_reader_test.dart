import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:maanthirigam/core/errors/api_exception.dart';
import 'package:maanthirigam/core/network/api_client.dart';
import 'package:maanthirigam/data/models/chapter.dart';
import 'package:maanthirigam/data/models/rich_text_document.dart';
import 'package:maanthirigam/data/models/transparent_pages.dart';
import 'package:maanthirigam/features/reader/data/pdf_progress_store.dart';
import 'package:maanthirigam/features/reader/data/transparent_page_bytes.dart';
import 'package:maanthirigam/features/reader/data/transparent_page_client.dart';
import 'package:maanthirigam/features/reader/data/transparent_page_image.dart';
import 'package:maanthirigam/features/reader/data/transparent_page_session.dart';
import 'package:maanthirigam/features/reader/presentation/reader_palette.dart';
import 'package:maanthirigam/features/reader/presentation/widgets/transparent_png_reader.dart';
import 'package:maanthirigam/features/reader/state/reader_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String pdfSha =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  test('parses an active package and keeps older chapters compatible', () {
    final ChapterContent chapter = ChapterContent.fromJson(<String, dynamic>{
      'id': 'chapter-1',
      'bookId': 'book-1',
      'chapterNumber': 1,
      'title': 'Yantra',
      'readerMode': 'ORIGINAL_PDF',
      'document': _document(pdfSha),
      'transparentPages': _packageJson(
        source: pdfSha,
        pages: <Map<String, dynamic>>[
          _pageJson(1, 12, 'b' * 64),
        ],
      ),
    });

    expect(chapter.document?.sha256, pdfSha);
    expect(chapter.transparentPages?.pageCount, 1);
    expect(
      chapter.transparentPages?.pages.single.apiRelativePath,
      '/books/book-1/chapters/chapter-1/transparent-pages/1',
    );
    expect(decideTransparentReader(chapter).usePackage, isTrue);

    final ChapterContent older = ChapterContent.fromJson(<String, dynamic>{
      'id': 'chapter-1',
      'bookId': 'book-1',
      'chapterNumber': 1,
      'title': 'Yantra',
      'readerMode': 'ORIGINAL_PDF',
      'document': _document(pdfSha),
    });
    final TransparentReaderDecision missing = decideTransparentReader(older);
    expect(older.transparentPages, isNull);
    expect(missing.usePackage, isFalse);
    expect(missing.rejection, isNull);
    expect(older.pdfOpenError(), isNull);
  });

  test('rejects a source checksum that does not match the PDF', () {
    final ChapterContent chapter = _pdfChapter(
      pdfSha: pdfSha,
      packageSource: 'b' * 64,
      pages: <Map<String, dynamic>>[_pageJson(1, 12, 'c' * 64)],
    );
    final TransparentReaderDecision decision = decideTransparentReader(chapter);
    expect(decision.usePackage, isFalse);
    expect(decision.rejection, contains('does not match'));
    expect(chapter.document?.sha256, pdfSha);
  });

  test('rejects pages that are out of order or the wrong size', () {
    final TransparentPagesDocument disordered =
        TransparentPagesDocument.fromJson(
      _packageJson(
        source: pdfSha,
        pageCount: 2,
        pages: <Map<String, dynamic>>[
          _pageJson(2, 10, 'd' * 64),
          _pageJson(1, 10, 'e' * 64),
        ],
      ),
    );
    expect(
      disordered.validationError(
        bookId: 'book-1',
        chapterId: 'chapter-1',
        documentSha256: pdfSha,
        documentPageCount: 2,
      ),
      'Transparent pages are not in order.',
    );

    final TransparentPagesDocument dimensions =
        TransparentPagesDocument.fromJson(
      _packageJson(
        source: pdfSha,
        width: 0,
        height: 1754,
        pages: <Map<String, dynamic>>[_pageJson(1, 10, 'd' * 64)],
      ),
    );
    expect(
      dimensions.validationError(
        bookId: 'book-1',
        chapterId: 'chapter-1',
        documentSha256: pdfSha,
        documentPageCount: 1,
      ),
      'Transparent page dimensions are invalid.',
    );
  });

  test('rejects a downloaded page whose length or checksum differs', () {
    final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
    final TransparentPage page = TransparentPage(
      pageNumber: 1,
      size: bytes.length,
      sha256: 'f' * 64,
      downloadPath: '/books/book-1/chapters/chapter-1/transparent-pages/1',
    );
    expect(
      () => verifyTransparentPageBytes(
        page: page,
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        contentType: 'image/png',
        contentLengthHeader: 3,
        statusCode: 200,
      ),
      throwsA(
        isA<ApiException>().having(
          (ApiException error) => error.code,
          'code',
          'PAGE_SIZE_MISMATCH',
        ),
      ),
    );

    final Uint8List png = _onePixelPng();
    final TransparentPage checksum = TransparentPage(
      pageNumber: 4,
      size: png.length,
      sha256: 'a' * 64,
      downloadPath: '/books/book-1/chapters/chapter-1/transparent-pages/4',
    );
    expect(
      () => verifyTransparentPageBytes(
        page: checksum,
        bytes: png,
        contentType: 'image/png',
        contentLengthHeader: png.length,
        statusCode: 200,
      ),
      throwsA(
        isA<ApiException>().having(
          (ApiException error) => error.code,
          'code',
          'PAGE_CHECKSUM_MISMATCH',
        ),
      ),
    );
  });

  test('downloads a page with bearer auth and retries once after 401',
      () async {
    final Uint8List png = _onePixelPng();
    var responses = 0;
    final _ScriptedClient httpClient =
        _ScriptedClient((http.BaseRequest request) async {
      responses += 1;
      if (responses == 1) {
        return _jsonResponse(
          401,
          '{"success":false,"error":{"code":"UNAUTHENTICATED","message":"expired"}}',
        );
      }
      return _bytesResponse(200, png, 'image/png');
    });
    var refreshes = 0;
    final ApiClient api = ApiClient(
      httpClient: httpClient,
      readAccessToken: () async => 'token-a',
      refreshAccessToken: () async {
        refreshes += 1;
        return 'token-b';
      },
    );
    final Uint8List body = await TransparentPageClient(api).fetch(
      scope: 'user-1|book-1|chapter-1|pkg-1',
      page: _livePage(png, 1),
    );

    expect(body, png);
    expect(refreshes, 1);
    expect(httpClient.requests, hasLength(2));
    expect(
      httpClient.requests.first.headers['Authorization'],
      'Bearer token-a',
    );
    expect(
      httpClient.requests.last.headers['Authorization'],
      'Bearer token-b',
    );
    for (final http.BaseRequest request in httpClient.requests) {
      expect(request.url.query, isEmpty);
      expect(request.url.toString().contains('token-a'), isFalse);
      expect(request.url.toString().contains('token-b'), isFalse);
      expect(request.url.path, contains('/transparent-pages/1'));
    }
  });

  test('a 403 entitlement error is not sent to another download route',
      () async {
    final _ScriptedClient httpClient =
        _ScriptedClient((http.BaseRequest request) async {
      return _jsonResponse(
        403,
        '{"success":false,"error":{"code":"PURCHASE_REQUIRED","message":"Purchase this book"}}',
      );
    });
    var refreshes = 0;
    final ApiClient api = ApiClient(
      httpClient: httpClient,
      readAccessToken: () async => 'token-a',
      refreshAccessToken: () async {
        refreshes += 1;
        return 'token-b';
      },
    );
    await expectLater(
      TransparentPageClient(api).fetch(
        scope: 'user|book-1|chapter-1|pkg',
        page: TransparentPage(
          pageNumber: 1,
          size: 4,
          sha256: 'a' * 64,
          downloadPath:
              '/api/v1/books/book-1/chapters/chapter-1/transparent-pages/1',
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (ApiException error) => error.isPurchaseRequired,
          'purchase',
          isTrue,
        ),
      ),
    );
    expect(refreshes, 0);
    expect(httpClient.requests, hasLength(1));
    expect(
      httpClient.requests.single.url.path,
      contains('transparent-pages/1'),
    );
    expect(
      transparentFailureOffersPdf(
        const ApiException(
          statusCode: 403,
          code: 'PURCHASE_REQUIRED',
          message: 'Purchase this book to continue reading.',
        ),
      ),
      isFalse,
    );
  });

  test('concurrent downloads of one page share a single request', () async {
    final Uint8List png = _onePixelPng();
    final Completer<void> gate = Completer<void>();
    final _ScriptedClient httpClient =
        _ScriptedClient((http.BaseRequest request) async {
      await gate.future;
      return _bytesResponse(200, png, 'image/png');
    });
    final TransparentPageClient client = TransparentPageClient(
      ApiClient(
        httpClient: httpClient,
        readAccessToken: () async => 'token-a',
      ),
    );
    final TransparentPage page = _livePage(png, 2);
    final Future<Uint8List> first = client.fetch(scope: 'same', page: page);
    final Future<Uint8List> second = client.fetch(scope: 'same', page: page);
    await Future<void>.delayed(Duration.zero);
    expect(httpClient.requests, hasLength(1));
    gate.complete();
    final List<Uint8List> bodies =
        await Future.wait(<Future<Uint8List>>[first, second]);
    expect(bodies.first, png);
    expect(bodies.last, png);
    expect(httpClient.requests, hasLength(1));
  });

  test('cache keeps five images, drops stale results, and evicts far pages',
      () async {
    final List<String> released = <String>[];
    final Map<int, Completer<String>> gates = <int, Completer<String>>{};
    final PageImageCoordinator<String> store = PageImageCoordinator<String>(
      maxReady: 5,
      decode: (int page) {
        final Completer<String> gate = Completer<String>();
        gates[page] = gate;
        return gate.future;
      },
      release: released.add,
    );

    store.pin(20);
    store.pin(20);
    expect(gates, hasLength(1));
    store.close();
    gates[20]!.complete('page-20');
    await Future<void>.delayed(Duration.zero);
    expect(store.readyFor(20), isNull);
    expect(store.readyFor(28), isNull);
    expect(released, <String>['page-20']);

    final List<String> evicted = <String>[];
    final PageImageCoordinator<String> live = PageImageCoordinator<String>(
      maxReady: 5,
      decode: (int page) async => 'page-$page',
      release: evicted.add,
    );
    for (var page = 1; page <= 6; page++) {
      live.pin(page);
    }
    await Future<void>.delayed(Duration.zero);
    expect(live.decodedCount, 6);
    live.setVisible(6);
    live.unpin(1);
    expect(live.readyFor(1), isNull);
    expect(live.readyFor(6), 'page-6');
    expect(evicted, <String>['page-1']);
    expect(live.decodedCount, 5);
    live.close();
    expect(live.decodedCount, 0);
    expect(evicted.length, 6);
  });

  test('account switch and logout clear the page session', () {
    final TransparentPageSession session = TransparentPageSession();
    final List<int> seen = <int>[];
    session.addListener(() => seen.add(session.generation));
    session.bindUser('account-a');
    final PageImageCoordinator<String> store = PageImageCoordinator<String>(
      decode: (int page) async => 'page-$page',
      release: (_) {},
    );
    session.addListener(store.close);
    session.bindUser('account-b');
    expect(session.userId, 'account-b');
    expect(store.isClosed, isTrue);
    session.bindUser(null);
    expect(session.userId, isNull);
    expect(session.generation, 3);
    expect(seen, <int>[1, 2, 3]);
  });

  test('progress keys stay on the account and package fingerprint', () {
    expect(
      pdfProgressKey(userId: 'a', bookId: 'b', chapterId: 'c'),
      'pdf.progress.a:b:c',
    );
    expect(
      pdfProgressKey(
        userId: 'a',
        bookId: 'b',
        chapterId: 'c',
        packageFingerprint: 'finger',
      ),
      'pdf.progress.a:b:c:png:finger',
    );
    expect(
      pdfProgressKey(
        userId: 'other',
        bookId: 'b',
        chapterId: 'c',
        packageFingerprint: 'finger',
      ),
      isNot(
        pdfProgressKey(
          userId: 'a',
          bookId: 'b',
          chapterId: 'c',
          packageFingerprint: 'finger',
        ),
      ),
    );
    expect(pdfProgressPage('$pdfSha|4', pdfSha), 4);
    expect(pdfProgressPage('${'b' * 64}|4', pdfSha), isNull);
  });

  test('rich text v1 and v2 chapters ignore transparent packages', () {
    final ChapterContent v1 = ChapterContent.fromJson(<String, dynamic>{
      'id': 'c',
      'bookId': 'b',
      'chapterNumber': 2,
      'title': 'Notes',
      'content': <String, dynamic>{
        'version': 1,
        'blocks': <Map<String, dynamic>>[
          <String, dynamic>{'type': 'paragraph', 'text': 'v1 line'},
        ],
      },
    });
    final ChapterContent v2 = ChapterContent.fromJson(<String, dynamic>{
      'id': 'c',
      'bookId': 'b',
      'chapterNumber': 2,
      'title': 'Notes',
      'contentFormat': 'RICH_TEXT',
      'readerMode': 'RICH_TEXT',
      'content': <String, dynamic>{
        'version': 2,
        'blocks': <Map<String, dynamic>>[
          <String, dynamic>{'type': 'paragraph', 'text': 'v2 line'},
        ],
      },
    });
    expect(v1.readerMode, ChapterReaderMode.richText);
    expect(v1.transparentPages, isNull);
    expect(v1.content?.version, 1);
    expect(v1.content?.blocks.single.text, 'v1 line');
    expect(v2.content?.version, 2);
    expect(v2.content?.blocks.single.text, 'v2 line');
    expect(decideTransparentReader(v1).usePackage, isFalse);
    expect(decideTransparentReader(v2).usePackage, isFalse);
    expect(v1.content, isA<RichTextDocument>());
  });

  test('production sources do not bundle the research PNG assets', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('assets/debug/phase2_png'), isFalse);
    expect(pubspec.contains('phase1_1-five-pages-transparent.pdf'), isFalse);
    expect(pubspec.contains('phase2-all-33-transparent.pdf'), isFalse);

    for (final FileSystemEntity entity
        in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains(
        '${Platform.pathSeparator}debug${Platform.pathSeparator}',
      )) {
        continue;
      }
      final String source = entity.readAsStringSync();
      expect(source.contains('phase23_png'), isFalse, reason: entity.path);
      expect(source.contains('assets/debug'), isFalse, reason: entity.path);
    }
  });

  testWidgets('pages keep their own identity while scrolling',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final Uint8List png = _onePixelPng();
    final TransparentPagesDocument package = TransparentPagesDocument.fromJson(
      _packageJson(
        source: pdfSha,
        pageCount: 3,
        width: 1,
        height: 1,
        pages: <Map<String, dynamic>>[
          _livePageJson(png, 1),
          _livePageJson(png, 2),
          _livePageJson(png, 3),
        ],
      ),
    );
    final ChapterContent chapter = ChapterContent.fromJson(<String, dynamic>{
      'id': 'chapter-1',
      'bookId': 'book-1',
      'chapterNumber': 1,
      'title': 'Yantra',
      'readerMode': 'ORIGINAL_PDF',
      'document': <String, dynamic>{
        ..._document(pdfSha),
        'pageCount': 3,
      },
      'transparentPages': _packageJson(
        source: pdfSha,
        pageCount: 3,
        width: 1,
        height: 1,
        pages: <Map<String, dynamic>>[
          _livePageJson(png, 1),
          _livePageJson(png, 2),
          _livePageJson(png, 3),
        ],
      ),
    });
    final TransparentPageClient client = TransparentPageClient(
      ApiClient(
        httpClient: _ScriptedClient((http.BaseRequest request) async {
          return _bytesResponse(200, png, 'image/png');
        }),
        readAccessToken: () async => 'token-a',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransparentPngReader(
            chapter: chapter,
            package: package,
            palette: ReaderPalette.of(ReaderThemeMode.olaichuvadi),
            session: TransparentPageSession()..bindUser('account-a'),
            client: client,
            readResume: () async => null,
            writeResume: (_) async {},
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    expect(find.byType(RawImage), findsWidgets);

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('account-a|book-1|chapter-1|pkg-1-1'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('account-a|book-1|chapter-1|pkg-1-2'),
      ),
      findsOneWidget,
    );

    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();
    // Max scroll must report the last one-based page, not extent-1.
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('Page 3'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('account-a|book-1|chapter-1|pkg-1-3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('page indicator stays one-based across jumps and partial pages',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final Uint8List png = _onePixelPng();
    const int pageCount = 33;
    final List<Map<String, dynamic>> pages = <Map<String, dynamic>>[
      for (int page = 1; page <= pageCount; page++) _livePageJson(png, page),
    ];
    final TransparentPagesDocument package = TransparentPagesDocument.fromJson(
      _packageJson(
        source: pdfSha,
        pageCount: pageCount,
        width: 1,
        height: 1,
        pages: pages,
      ),
    );
    final ChapterContent chapter = ChapterContent.fromJson(<String, dynamic>{
      'id': 'chapter-1',
      'bookId': 'book-1',
      'chapterNumber': 1,
      'title': 'Yantra',
      'readerMode': 'ORIGINAL_PDF',
      'document': <String, dynamic>{
        ..._document(pdfSha),
        'pageCount': pageCount,
      },
      'transparentPages': _packageJson(
        source: pdfSha,
        pageCount: pageCount,
        width: 1,
        height: 1,
        pages: pages,
      ),
    });
    final TransparentPageClient client = TransparentPageClient(
      ApiClient(
        httpClient: _ScriptedClient((http.BaseRequest request) async {
          return _bytesResponse(200, png, 'image/png');
        }),
        readAccessToken: () async => 'token-a',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransparentPngReader(
            chapter: chapter,
            package: package,
            palette: ReaderPalette.of(ReaderThemeMode.olaichuvadi),
            session: TransparentPageSession()..bindUser('account-a'),
            client: client,
            readResume: () async => null,
            writeResume: (_) async {},
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    expect(find.text('1 / 33'), findsOneWidget);

    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    const double pageWidth = 400 - 24;
    const double pageHeight = pageWidth;
    const double itemExtent = 18 + 4 + pageHeight + 12;

    Future<void> jumpAndExpect(int page) async {
      final double target =
          ((page - 1) * itemExtent).clamp(0, scrollable.position.maxScrollExtent);
      scrollable.position.jumpTo(target);
      await tester.pump();
      expect(find.text('$page / 33'), findsOneWidget);
    }

    await jumpAndExpect(2);
    await jumpAndExpect(7);
    await jumpAndExpect(16);
    await jumpAndExpect(33);
    await jumpAndExpect(16);
    await jumpAndExpect(1);

    // Partial visibility: halfway into page 7's item still reports page 7.
    final double partial =
        ((7 - 1) * itemExtent + itemExtent * 0.4)
            .clamp(0, scrollable.position.maxScrollExtent);
    scrollable.position.jumpTo(partial);
    await tester.pump();
    expect(find.text('7 / 33'), findsOneWidget);

    // Fast skip across several pages lands on the correct one-based label.
    scrollable.position.jumpTo(
      (32 * itemExtent).clamp(0, scrollable.position.maxScrollExtent),
    );
    await tester.pump();
    expect(find.text('33 / 33'), findsOneWidget);
  });

  test('decoded png dimensions must match the package metadata', () async {
    final Uint8List png = _onePixelPng();
    final ui.Image image =
        await decodeTransparentPageImage(png, width: 1, height: 1);
    expect(image.width, 1);
    expect(image.height, 1);
    image.dispose();
    await expectLater(
      decodeTransparentPageImage(png, width: 1241, height: 1754),
      throwsA(
        isA<ApiException>().having(
          (ApiException error) => error.code,
          'code',
          'PAGE_DIMENSION_MISMATCH',
        ),
      ),
    );
  });
}

Uint8List _onePixelPng() {
  return base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );
}

Map<String, dynamic> _document(String sha) {
  return <String, dynamic>{
    'mediaId': 'media-1',
    'fileName': 'original.pdf',
    'mimeType': 'application/pdf',
    'size': 1200,
    'pageCount': 1,
    'sha256': sha,
    'downloadPath': '/api/v1/books/book-1/chapters/chapter-1/document',
  };
}

Map<String, dynamic> _packageJson({
  required String source,
  required List<Map<String, dynamic>> pages,
  int? pageCount,
  int width = 1241,
  int height = 1754,
}) {
  return <String, dynamic>{
    'packageId': 'pkg-1',
    'sourcePdfSha256': source,
    'catalogFingerprint': 'catalog-fingerprint',
    'pageCount': pageCount ?? pages.length,
    'width': width,
    'height': height,
    'processorVersion': 'phase2-png',
    'pages': pages,
  };
}

Map<String, dynamic> _pageJson(int page, int size, String sha) {
  return <String, dynamic>{
    'pageNumber': page,
    'size': size,
    'sha256': sha,
    'downloadPath':
        '/api/v1/books/book-1/chapters/chapter-1/transparent-pages/$page',
  };
}

ChapterContent _pdfChapter({
  required String pdfSha,
  required String packageSource,
  required List<Map<String, dynamic>> pages,
}) {
  return ChapterContent.fromJson(<String, dynamic>{
    'id': 'chapter-1',
    'bookId': 'book-1',
    'chapterNumber': 1,
    'title': 'Yantra',
    'readerMode': 'ORIGINAL_PDF',
    'document': <String, dynamic>{
      ..._document(pdfSha),
      'pageCount': pages.length,
    },
    'transparentPages': _packageJson(source: packageSource, pages: pages),
  });
}

TransparentPage _livePage(Uint8List png, int page) {
  return TransparentPage(
    pageNumber: page,
    size: png.length,
    sha256: sha256.convert(png).toString(),
    downloadPath:
        '/api/v1/books/book-1/chapters/chapter-1/transparent-pages/$page',
  );
}

Map<String, dynamic> _livePageJson(Uint8List png, int page) {
  final TransparentPage live = _livePage(png, page);
  return <String, dynamic>{
    'pageNumber': live.pageNumber,
    'size': live.size,
    'sha256': live.sha256,
    'downloadPath': live.downloadPath,
  };
}

http.StreamedResponse _bytesResponse(
  int status,
  Uint8List bytes,
  String type,
) {
  return http.StreamedResponse(
    Stream<List<int>>.value(bytes),
    status,
    headers: <String, String>{
      'content-type': type,
      'content-length': '${bytes.length}',
    },
    contentLength: bytes.length,
  );
}

http.StreamedResponse _jsonResponse(int status, String body) {
  final List<int> bytes = utf8.encode(body);
  return http.StreamedResponse(
    Stream<List<int>>.value(bytes),
    status,
    headers: <String, String>{
      'content-type': 'application/json',
      'content-length': '${bytes.length}',
    },
    contentLength: bytes.length,
  );
}

class _ScriptedClient extends http.BaseClient {
  _ScriptedClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
      _handler;
  final List<http.BaseRequest> requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    return _handler(request);
  }
}
