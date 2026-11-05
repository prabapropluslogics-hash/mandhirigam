import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maanthirigam/core/config/reader_content_features.dart';
import 'package:maanthirigam/data/models/chapter.dart';
import 'package:maanthirigam/data/models/rich_text_document.dart';
import 'package:maanthirigam/features/reader/presentation/widgets/reader_image_viewer.dart';
import 'package:maanthirigam/features/reader/presentation/widgets/reader_inline_image.dart';
import 'package:maanthirigam/features/reader/presentation/widgets/rich_text_document_view.dart';

import 'support/test_images.dart';

const String _mediaId = '507f1f77bcf86cd799439011';
const String _mediaUrl =
    'https://api.maandhrigam.demosvr.in/api/v1/media/$_mediaId';
const String _mediaId2 = '507f1f77bcf86cd799439012';
const String _mediaUrl2 =
    'https://api.maandhrigam.demosvr.in/api/v1/media/$_mediaId2';

RichTextDocument _parse(String blocks, {int version = 1}) =>
    RichTextDocument.fromJson(
      jsonDecode('{"version":$version,"blocks":[$blocks]}')
          as Map<String, dynamic>,
    );

const String _v2MixedBlocks = '''
{"id":"blk_t1","type":"paragraph","text":"First words"},
{"id":"blk_h","type":"heading","level":2,"text":"செய்முறை",
 "presentation":"instruction","source":{"page":3,"order":1}},
{"id":"blk_img","type":"image","mediaId":"$_mediaId","url":"$_mediaUrl",
 "caption":"Temple wall","alt":"Carved stone","width":1200,"height":800,
 "fit":"contain","source":{"page":3,"order":2}},
{"id":"blk_t2","type":"paragraph","text":"Middle words"},
{"id":"blk_audio","type":"audio","url":"https://cdn.example.com/a.mp3",
 "title":"Chant","durationSeconds":95,"mimeType":"audio/mpeg"},
{"id":"blk_t3","type":"paragraph","text":"Later words"},
{"id":"blk_video","type":"video","url":"https://cdn.example.com/v.mp4",
 "thumbnailUrl":"https://cdn.example.com/v.jpg","title":"Ritual",
 "durationSeconds":42,"width":1920,"height":1080},
{"id":"blk_t4","type":"paragraph","text":"Last words"}
''';

void main() {
  group('Rich Text V1 regression', () {
    test('V1 documents parse exactly as before', () {
      final RichTextDocument document = _parse('''
{"id":"p","type":"paragraph","text":"Hello world",
 "marks":[{"start":0,"end":5,"type":"bold"}]},
{"id":"h","type":"heading","level":2,"text":"Title"},
{"id":"b","type":"bullet_list","items":[{"text":"One"},{"text":"Two"}]},
{"id":"o","type":"ordered_list","items":[{"text":"First"}]},
{"id":"q","type":"quote","text":"Quoted"}
''');
      expect(document.version, 1);
      expect(document.isV1, isTrue);
      expect(
        document.blocks.map((RichTextBlock b) => b.type),
        <String>[
          'paragraph',
          'heading',
          'bullet_list',
          'ordered_list',
          'quote',
        ],
      );
      expect(
        document.blocks.every((RichTextBlock b) => b.media == null),
        isTrue,
      );
      expect(document.blocks[0].marks.single.isBold, isTrue);
      expect(document.blocks[1].level, 2);
      expect(
        document.blocks[2].items.map((RichTextListItem i) => i.text),
        <String>['One', 'Two'],
      );
      expect(visibleBlocks(document), hasLength(5));
    });

    test('image blocks are ignored in V1 documents', () {
      final RichTextDocument document = _parse('''
{"id":"p","type":"paragraph","text":"Only text"},
{"id":"i","type":"image","mediaId":"$_mediaId","url":"$_mediaUrl",
 "alt":"Should not appear"}
''');
      expect(document.blocks.map((RichTextBlock b) => b.id), <String>['p']);
    });
  });

  group('Rich Text V2 parsing', () {
    test('image blocks keep position and metadata', () {
      final RichTextDocument document = _parse(_v2MixedBlocks, version: 2);
      expect(document.isV2, isTrue);
      expect(
        document.blocks.map((RichTextBlock b) => b.id),
        <String>[
          'blk_t1',
          'blk_h',
          'blk_img',
          'blk_t2',
          'blk_audio',
          'blk_t3',
          'blk_video',
          'blk_t4',
        ],
      );
      final RichTextImage image = document.blocks[2].image!;
      expect(image.url, _mediaUrl);
      expect(image.mediaId, _mediaId);
      expect(image.caption, 'Temple wall');
      expect(image.alt, 'Carved stone');
      expect(image.width, 1200);
      expect(image.height, 800);
      expect(image.fit, 'contain');
      expect(image.aspectRatio, 1.5);
      expect(image.source?.page, 3);
      expect(document.blocks[1].isInstruction, isTrue);
      expect(document.blocks[1].source?.order, 1);
    });

    test('an image without optional metadata still parses', () {
      final RichTextImage image = _parse(
        '{"id":"i","type":"image","mediaId":"$_mediaId","url":"$_mediaUrl",'
        '"caption":"  ","width":0,"height":null}',
        version: 2,
      ).blocks.single.image!;
      expect(image.caption, isNull);
      expect(image.alt, isNull);
      expect(image.width, isNull);
      expect(image.height, isNull);
      expect(image.aspectRatio, isNull);
    });

    test('rejects CDN URLs, admin routes and invalid media ids', () {
      final RichTextDocument document = _parse('''
{"id":"cdn","type":"image","mediaId":"$_mediaId",
 "url":"https://cdn.example.com/$_mediaId.jpg"},
{"id":"admin","type":"image","mediaId":"$_mediaId",
 "url":"https://api.example.com/api/v1/admin/media/$_mediaId"},
{"id":"covers","type":"image","mediaId":"$_mediaId",
 "url":"https://api.example.com/api/v1/media/covers/$_mediaId"},
{"id":"badid","type":"image","mediaId":"not-an-object-id",
 "url":"https://api.example.com/api/v1/media/not-an-object-id"},
{"id":"ok","type":"paragraph","text":"Kept"}
''', version: 2);
      expect(document.blocks.map((RichTextBlock b) => b.id), <String>['ok']);
    });

    test('audio and video are recognised but not visible', () {
      final RichTextDocument document = _parse(_v2MixedBlocks, version: 2);
      expect(document.blocks[4].isAudio, isTrue);
      expect(document.blocks[4].audio!.title, 'Chant');
      expect(document.blocks[6].isVideo, isTrue);
      expect(document.blocks[6].video!.title, 'Ritual');
      expect(
        visibleBlocks(document).map((RichTextBlock b) => b.id),
        <String>['blk_t1', 'blk_h', 'blk_img', 'blk_t2', 'blk_t3', 'blk_t4'],
      );
      expect(ReaderContentFeatures.current.readerImageSupport, isTrue);
      expect(ReaderContentFeatures.current.readerAudioSupport, isFalse);
      expect(ReaderContentFeatures.current.readerVideoSupport, isFalse);
    });

    test('unknown and malformed blocks are skipped', () {
      final RichTextDocument document = _parse('''
{"id":"a","type":"paragraph","text":"Kept"},
{"id":"u","type":"carousel","items":[]},
{"id":"n","type":"image","url":null},
"not a block",
7,
{"id":"z","type":"quote","text":"Also kept","extra":true}
''', version: 2);
      expect(
        document.blocks.map((RichTextBlock b) => b.id),
        <String>['a', 'z'],
      );
    });

    test('chapter content with V2 media parses through ChapterContent', () {
      final ChapterContent chapter = ChapterContent.fromJson(
        jsonDecode(
          '{"id":"c1","bookId":"b1","chapterNumber":1,'
          '"title":"One","content":{"version":2,"blocks":[$_v2MixedBlocks]}}',
        ) as Map<String, dynamic>,
      );
      expect(chapter.content!.version, 2);
      expect(chapter.content!.blocks, hasLength(8));
    });
  });

  group('rendering', () {
    late ui.Image picture;

    setUp(() {
      debugReaderImageProvider = null;
      debugChapterMediaLoader = null;
    });
    tearDown(() {
      debugReaderImageProvider = null;
      debugChapterMediaLoader = null;
    });

    Future<void> pumpDocument(
      WidgetTester tester,
      RichTextDocument document,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RichTextDocumentView(document: document),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
        'V2 text and images render in order; audio and video stay hidden',
        (WidgetTester tester) async {
      picture = (await tester.runAsync(
        () => createTestImage(width: 60, height: 40),
      ))!;
      debugReaderImageProvider =
          (RichTextImage _) => TestImageProvider(picture);

      await pumpDocument(tester, _parse(_v2MixedBlocks, version: 2));

      expect(find.byType(ReaderInlineImage), findsOneWidget);
      expect(find.byType(InstructionPresentation), findsOneWidget);
      expect(find.text('செய்முறை'), findsOneWidget);
      expect(find.bySemanticsLabel('Carved stone'), findsOneWidget);
      expect(find.text('Temple wall'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('blk_audio')), findsNothing);
      expect(find.byKey(const ValueKey<String>('blk_video')), findsNothing);
      expect(find.text('Chant'), findsNothing);
      expect(find.text('Ritual'), findsNothing);

      final double first = tester.getTopLeft(find.text('First words')).dy;
      final double image = tester.getTopLeft(find.byType(ReaderInlineImage)).dy;
      final double middle = tester.getTopLeft(find.text('Middle words')).dy;
      expect(first, lessThan(image));
      expect(image, lessThan(middle));
      expect(find.text('Last words'), findsOneWidget);
    });

    testWidgets('a failed image shows a retry and keeps the chapter readable',
        (WidgetTester tester) async {
      picture = (await tester.runAsync(
        () => createTestImage(width: 50, height: 50),
      ))!;
      final TestImageProvider provider =
          TestImageProvider(picture, failures: 1);
      debugReaderImageProvider = (RichTextImage _) => provider;

      await pumpDocument(
        tester,
        _parse(
          '{"id":"a","type":"paragraph","text":"Before"},'
          '{"id":"i","type":"image","mediaId":"$_mediaId","url":"$_mediaUrl",'
          '"caption":"Lost plate"},'
          '{"id":"b","type":"paragraph","text":"After"}',
          version: 2,
        ),
      );

      expect(find.text('Image unavailable'), findsOneWidget);
      expect(find.text('Before'), findsOneWidget);
      expect(find.text('After'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Image unavailable'), findsNothing);
      expect(find.text('Lost plate'), findsOneWidget);
      expect(provider.loads, 2);
    });

    testWidgets('multiple images render in order', (WidgetTester tester) async {
      picture = (await tester.runAsync(
        () => createTestImage(width: 30, height: 30),
      ))!;
      debugReaderImageProvider =
          (RichTextImage _) => TestImageProvider(picture);

      await pumpDocument(
        tester,
        _parse(
          '{"id":"i1","type":"image","mediaId":"$_mediaId","url":"$_mediaUrl","alt":"One"},'
          '{"id":"p","type":"paragraph","text":"Between"},'
          '{"id":"i2","type":"image","mediaId":"$_mediaId2","url":"$_mediaUrl2","alt":"Two"}',
          version: 2,
        ),
      );

      expect(find.byType(ReaderInlineImage), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.bySemanticsLabel('One')).dy,
        lessThan(tester.getTopLeft(find.bySemanticsLabel('Two')).dy),
      );
    });

    testWidgets('narrow layout does not overflow with images',
        (WidgetTester tester) async {
      picture = (await tester.runAsync(
        () => createTestImage(width: 80, height: 40),
      ))!;
      debugReaderImageProvider =
          (RichTextImage _) => TestImageProvider(picture);
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpDocument(
        tester,
        _parse(
          '{"id":"p","type":"paragraph","text":"'
          'இது ஒரு நீண்ட தமிழ் பத்தி. செய்முறை விளக்கம் இங்கே உள்ளது. '
          'இன்னும் சில வார்த்தைகள் சேர்க்கப்பட்டுள்ளன."},'
          '{"id":"i","type":"image","mediaId":"$_mediaId","url":"$_mediaUrl",'
          '"width":1600,"height":900,"alt":"Wide"}',
          version: 2,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ReaderInlineImage), findsOneWidget);
    });

    testWidgets('the viewer shows the image and caption and closes',
        (WidgetTester tester) async {
      picture = (await tester.runAsync(
        () => createTestImage(width: 80, height: 40),
      ))!;
      debugReaderImageProvider =
          (RichTextImage _) => TestImageProvider(picture);

      await pumpDocument(tester, _parse(_v2MixedBlocks, version: 2));
      await tester.tap(find.bySemanticsLabel('Carved stone'));
      await tester.pumpAndSettle();

      expect(find.byType(ReaderImageViewer), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(ReaderImageViewer), findsNothing);
      expect(find.text('First words'), findsOneWidget);
    });
  });
}
