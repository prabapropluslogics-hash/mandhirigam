import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:maanthirigam/core/network/api_client.dart';
import 'package:maanthirigam/data/models/rich_text_document.dart';
import 'package:maanthirigam/data/services/chapter_media_loader.dart';
import 'package:maanthirigam/debug/reflowable_ebook/fixture_loader.dart';
import 'package:maanthirigam/debug/reflowable_ebook/ocr_review_banner.dart';
import 'package:maanthirigam/debug/reflowable_ebook/phase03_demo_screen.dart';
import 'package:maanthirigam/features/reader/data/rich_text_progress_store.dart';
import 'package:maanthirigam/features/reader/presentation/widgets/reader_image_viewer.dart';
import 'package:maanthirigam/features/reader/presentation/widgets/reader_inline_image.dart';
import 'package:maanthirigam/features/reader/presentation/widgets/reader_paper.dart';
import 'package:maanthirigam/features/reader/presentation/widgets/rich_text_document_view.dart';

Directory get _fixtures => resolveReflowableFixturesDir();

Directory get _screenshotDir {
  final Directory dir = Directory('docs/phase03-screenshots');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}

/// MemoryImage decode is async; pump frames without pumpAndSettle
/// (loading indicators never "settle").
Future<void> _pumpDemo(WidgetTester tester) async {
  await tester.pump();
  for (int i = 0; i < 30; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    });
    await tester.pump();
    final Finder loading = find.descendant(
      of: find.byType(ReaderInlineImage),
      matching: find.byType(CircularProgressIndicator),
    );
    if (loading.evaluate().isEmpty &&
        find.byType(ReaderInlineImage).evaluate().isNotEmpty) {
      // Extra frames so Image paints after status flips to loaded.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      return;
    }
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  await _pumpDemo(tester);
  final RenderRepaintBoundary boundary = tester.renderObject(
    find.byKey(const ValueKey<String>('phase03-screenshot-root')),
  );
  // toImage / toByteData must run via runAsync or the test binding hangs.
  final Uint8List pngBytes = (await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) {
      throw StateError('Screenshot toByteData returned null');
    }
    return data.buffer.asUint8List();
  }))!;
  final File out = File('${_screenshotDir.path}/$name.png');
  out.writeAsBytesSync(pngBytes);
  expect(out.existsSync(), isTrue);
  expect(out.lengthSync(), greaterThan(1000));
}

Widget _demoApp({double fontSize = 16}) {
  return MaterialApp(
    // InkSparkle (M3 default) throws during RepaintBoundary.toImage in tests.
    theme: ThemeData(
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
    ),
    home: RepaintBoundary(
      key: const ValueKey<String>('phase03-screenshot-root'),
      child: Phase03ReflowableDemoScreen(
        fixturesDir: _fixtures,
        initialFontSize: fontSize,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    clearLocalFixtureImageProvider();
    debugChapterMediaLoader = null;
  });

  test('fixture checksum and production parser keep the Yantra image block',
      () {
    final ReflowableEbookFixture fixture =
        loadReflowableEbookFixture(fixturesDir: _fixtures);
    final Digest digest = sha256.convert(fixture.yantraFile.readAsBytesSync());
    expect(digest.toString(), ReflowableEbookFixture.expectedYantraSha256);

    final RichTextDocument document = fixture.chapter.content!;
    expect(document.isV2, isTrue);
    expect(document.blocks.where((RichTextBlock b) => b.isImage), hasLength(1));
    final RichTextImage image =
        document.blocks.firstWhere((RichTextBlock b) => b.isImage).image!;
    expect(image.width, 1271);
    expect(image.height, 848);
    expect(image.fit, 'contain');
    expect(image.aspectRatio, closeTo(1271 / 848, 0.0001));
    expect(fixture.reviewNotes.humanVerificationRequired, isTrue);
    expect(
      fixture.reviewNotes.notes,
      contains(
        'Title OCR still imperfect — verify against source PDF.',
      ),
    );
  });

  test('relative media URLs are rejected by production parser until rewritten',
      () {
    expect(
      RichTextImage.tryParse(
        <String, dynamic>{
          'mediaId': '000000000000000000000001',
          'url': '/api/v1/media/000000000000000000000001',
          'width': 1271,
          'height': 848,
          'fit': 'contain',
        },
        documentVersion: 2,
      ),
      isNull,
    );
    expect(
      fixtureImageBlockSurvivesProductionParser(<String, dynamic>{
        'mediaId': '000000000000000000000001',
        'url': 'https://api.example.com/api/v1/media/000000000000000000000001',
        'width': 1271,
        'height': 848,
        'fit': 'contain',
      }),
      isTrue,
    );
  });

  test('rich text progress keys are account-scoped', () {
    expect(
      richTextProgressKey(
        userId: 'user-a',
        bookId: 'sample-book',
        chapterId: 'sample-tantrik-p7',
      ),
      'richtext.progress.user-a:sample-book:sample-tantrik-p7',
    );
    expect(
      richTextProgressKey(
        userId: null,
        bookId: 'sample-book',
        chapterId: 'sample-tantrik-p7',
      ),
      'richtext.progress.guest:sample-book:sample-tantrik-p7',
    );
  });

  testWidgets(
      'production renderer shows Tamil, instruction label, and OCR banner',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_demoApp());
    await _pumpDemo(tester);

    expect(find.byType(OcrReviewBanner), findsOneWidget);
    expect(find.textContaining('OCR / source verification required'),
        findsOneWidget);
    expect(find.textContaining('செய்முறை:'), findsOneWidget);
    expect(find.textContaining('அஸ்தர தோஷம்'), findsOneWidget);
    expect(find.byType(ReaderSurface), findsOneWidget);
    expect(find.byType(RichTextDocumentView), findsOneWidget);
    expect(find.byType(ReaderInlineImage), findsOneWidget);
    expect(find.byType(InstructionPresentation), findsOneWidget);

    // Unreviewed OCR title must remain as-is (no silent correction).
    expect(
      find.textContaining('அஜிகாரிவளியம்'),
      findsOneWidget,
    );
  });

  testWidgets('font sizes 16/22/28 reflow text while Yantra aspect stays fixed',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_demoApp(fontSize: 16));
    await _pumpDemo(tester);

    Size aspectOfImage() {
      final Size size = tester.getSize(find.byType(ReaderInlineImage));
      return size;
    }

    final Size at16 = aspectOfImage();
    await _capture(tester, 'font_16_olaichuvadi');

    await tester.tap(find.byKey(const ValueKey<String>('font-22')));
    await _pumpDemo(tester);
    final Size at22 = aspectOfImage();
    await _capture(tester, 'font_22_olaichuvadi');

    await tester.tap(find.byKey(const ValueKey<String>('font-28')));
    await _pumpDemo(tester);
    final Size at28 = aspectOfImage();
    await _capture(tester, 'font_28_olaichuvadi');

    // Width fills the column; height follows fixed 1271×848 aspect.
    expect(at16.width, closeTo(at22.width, 1));
    expect(at22.width, closeTo(at28.width, 1));
    expect(at16.height / at16.width, closeTo(848 / 1271, 0.02));
    expect(at22.height / at22.width, closeTo(848 / 1271, 0.02));
    expect(at28.height / at28.width, closeTo(848 / 1271, 0.02));
    // Text reflow changes vertical document length (scroll extent).
    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('theme and line-height switching keep Yantra geometry',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_demoApp(fontSize: 22));
    await _pumpDemo(tester);
    final Size before = tester.getSize(find.byType(ReaderInlineImage));

    await tester.tap(find.byKey(const ValueKey<String>('theme-dark')));
    await _pumpDemo(tester);
    expect(tester.getSize(find.byType(ReaderInlineImage)).width,
        closeTo(before.width, 1));

    await tester.tap(find.byKey(const ValueKey<String>('lh-spacious')));
    await _pumpDemo(tester);
    expect(tester.getSize(find.byType(ReaderInlineImage)).height / before.width,
        closeTo(848 / 1271, 0.02));
  });

  testWidgets('reading position can be restored after scroll',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_demoApp(fontSize: 22));
    await _pumpDemo(tester);

    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    final double max = scrollable.position.maxScrollExtent;
    expect(max, greaterThan(50));
    scrollable.position.jumpTo(max * 0.55);
    await _pumpDemo(tester);

    final State state = tester.state(find.byType(Phase03ReflowableDemoScreen));
    final dynamic demo = state as dynamic;
    final double saved = demo.scrollFraction as double;
    expect(saved, closeTo(0.55, 0.05));

    demo.restoreScrollFraction(0.0);
    await _pumpDemo(tester);
    expect(demo.scrollFraction as double, closeTo(0.0, 0.02));

    demo.restoreScrollFraction(saved);
    await _pumpDemo(tester);
    expect(demo.scrollFraction as double, closeTo(saved, 0.05));
  });

  testWidgets('diagram opens independent zoom viewer',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_demoApp(fontSize: 16));
    await _pumpDemo(tester);
    await tester.tap(find.byType(ReaderInlineImage));
    await _pumpDemo(tester);
    expect(find.byType(ReaderImageViewer), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsWidgets);
  });

  test('protected network media path uses Bearer media loader separately',
      () async {
    final _RecordingClient client = _RecordingClient();
    final ChapterMediaLoader loader = ChapterMediaLoader(
      ApiClient(
        httpClient: client,
        readAccessToken: () async => 'fixture-token',
      ),
    );
    final Uint8List bytes = await loader.load('000000000000000000000001');
    expect(bytes, isNotEmpty);
    expect(client.paths.single, contains('/media/000000000000000000000001'));
    expect(client.authHeaders.single, contains('Bearer fixture-token'));
  });
}

class _RecordingClient extends http.BaseClient {
  final List<String> paths = <String>[];
  final List<String?> authHeaders = <String?>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    paths.add(request.url.path);
    authHeaders.add(request.headers['authorization']);
    final Uint8List png =
        File('${_fixtures.path}/yantra_page07.png').readAsBytesSync();
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[png]),
      200,
      headers: <String, String>{'content-type': 'image/png'},
      contentLength: png.length,
    );
  }
}
