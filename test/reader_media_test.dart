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

RichTextDocument _parse(String blocks) => RichTextDocument.fromJson(
      jsonDecode('{"version":1,"blocks":[$blocks]}') as Map<String, dynamic>,
    );

const String _mixedBlocks = '''
{"id":"blk_t1","type":"paragraph","text":"First words"},
{"id":"blk_img","type":"image","url":"https://cdn.example.com/a.jpg",
 "caption":"Temple wall","alt":"Carved stone","width":1200,"height":800,
 "mediaId":"m1","mimeType":"image/jpeg","futureField":{"x":1}},
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
  group('parsing', () {
    test('Rich Text V1 documents parse exactly as before', () {
      final RichTextDocument document = _parse('''
{"id":"p","type":"paragraph","text":"Hello world",
 "marks":[{"start":0,"end":5,"type":"bold"}]},
{"id":"h","type":"heading","level":2,"text":"Title"},
{"id":"b","type":"bullet_list","items":[{"text":"One"},{"text":"Two"}]},
{"id":"o","type":"ordered_list","items":[{"text":"First"}]},
{"id":"q","type":"quote","text":"Quoted"}
''');
      expect(
        document.blocks.map((RichTextBlock b) => b.type),
        <String>[
          'paragraph',
          'heading',
          'bullet_list',
          'ordered_list',
          'quote'
        ],
      );
      expect(
          document.blocks.every((RichTextBlock b) => b.media == null), isTrue);
      expect(document.blocks[0].marks.single.isBold, isTrue);
      expect(document.blocks[1].level, 2);
      expect(document.blocks[2].items.map((RichTextListItem i) => i.text),
          <String>['One', 'Two']);
      expect(visibleBlocks(document), hasLength(5));
    });

    test('image blocks keep their position and metadata', () {
      final RichTextDocument document = _parse(_mixedBlocks);
      expect(
        document.blocks.map((RichTextBlock b) => b.id),
        <String>[
          'blk_t1',
          'blk_img',
          'blk_t2',
          'blk_audio',
          'blk_t3',
          'blk_video',
          'blk_t4',
        ],
      );
      final RichTextImage image = document.blocks[1].image!;
      expect(image.url, 'https://cdn.example.com/a.jpg');
      expect(image.caption, 'Temple wall');
      expect(image.alt, 'Carved stone');
      expect(image.width, 1200);
      expect(image.height, 800);
      expect(image.aspectRatio, 1.5);
      expect(image.mediaId, 'm1');
      expect(image.mimeType, 'image/jpeg');
    });

    test('an image without optional metadata still parses', () {
      final RichTextImage image = _parse(
        '{"id":"i","type":"image","url":"https://cdn.example.com/b.png",'
        '"caption":"  ","width":0,"height":null}',
      ).blocks.single.image!;
      expect(image.caption, isNull);
      expect(image.alt, isNull);
      expect(image.width, isNull);
      expect(image.height, isNull);
      expect(image.aspectRatio, isNull);
    });

    test('audio blocks are recognised with their metadata', () {
      final RichTextBlock block = _parse(_mixedBlocks).blocks[3];
      expect(block.isAudio, isTrue);
      final RichTextAudio audio = block.audio!;
      expect(audio.url, 'https://cdn.example.com/a.mp3');
      expect(audio.title, 'Chant');
      expect(audio.duration, const Duration(seconds: 95));
      expect(audio.mimeType, 'audio/mpeg');
    });

    test('video blocks are recognised with their metadata', () {
      final RichTextBlock block = _parse(_mixedBlocks).blocks[5];
      expect(block.isVideo, isTrue);
      final RichTextVideo video = block.video!;
      expect(video.url, 'https://cdn.example.com/v.mp4');
      expect(video.thumbnailUrl, 'https://cdn.example.com/v.jpg');
      expect(video.title, 'Ritual');
      expect(video.duration, const Duration(seconds: 42));
      expect(video.width, 1920);
      expect(video.height, 1080);
    });

    test('unknown and malformed blocks are skipped, the rest is kept', () {
      final RichTextDocument document = _parse('''
{"id":"a","type":"paragraph","text":"Kept"},
{"id":"u","type":"carousel","items":[]},
{"id":"n","type":"image","url":null},
{"id":"r","type":"image","url":"/media/x.jpg"},
{"id":"j","type":"image","url":"javascript:alert(1)"},
{"id":"x","type":"video","url":42},
{"id":"m","type":"audio"},
"not a block",
7,
{"id":"t","text":"No type"},
{"id":"z","type":"quote","text":"Also kept","extra":true}
''');
      expect(document.blocks.map((RichTextBlock b) => b.id),
          <String>['a', 't', 'z']);
      expect(document.blocks[1].isParagraph, isTrue);
    });

    test('chapter content with media parses through ChapterContent', () {
      final ChapterContent chapter = ChapterContent.fromJson(
        jsonDecode('{"id":"c1","bookId":"b1","chapterNumber":1,'
                '"title":"One","content":{"version":1,"blocks":[$_mixedBlocks]}}')
            as Map<String, dynamic>,
      );
      expect(chapter.content.blocks, hasLength(7));
    });

    test('only text and images are visible in this release', () {
      final RichTextDocument document = _parse(_mixedBlocks);
      expect(
        visibleBlocks(document).map((RichTextBlock b) => b.id),
        <String>['blk_t1', 'blk_img', 'blk_t2', 'blk_t3', 'blk_t4'],
      );
      expect(ReaderContentFeatures.current.readerImageSupport, isTrue);
      expect(ReaderContentFeatures.current.readerAudioSupport, isFalse);
      expect(ReaderContentFeatures.current.readerVideoSupport, isFalse);
      expect(
        visibleBlocks(
          document,
          features: const ReaderContentFeatures(readerImageSupport: false),
        ).any((RichTextBlock b) => b.isMedia),
        isFalse,
      );
    });
  });

  group('rendering', () {
    late ui.Image picture;

    setUp(() => debugReaderImageProvider = null);
    tearDown(() => debugReaderImageProvider = null);

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

    testWidgets('text and images render in order; audio and video stay hidden',
        (WidgetTester tester) async {
      picture = (await tester.runAsync(
        () => createTestImage(width: 60, height: 40),
      ))!;
      debugReaderImageProvider = (_) => TestImageProvider(picture);

      await pumpDocument(tester, _parse(_mixedBlocks));

      expect(find.byType(ReaderInlineImage), findsOneWidget);
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
      debugReaderImageProvider = (_) => provider;

      await pumpDocument(
        tester,
        _parse('{"id":"a","type":"paragraph","text":"Before"},'
            '{"id":"i","type":"image","url":"https://cdn.example.com/f.jpg",'
            '"caption":"Lost plate"},'
            '{"id":"b","type":"paragraph","text":"After"}'),
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
      debugReaderImageProvider = (_) => TestImageProvider(picture);

      await pumpDocument(
        tester,
        _parse(
            '{"id":"i1","type":"image","url":"https://cdn.example.com/1.jpg","alt":"One"},'
            '{"id":"p","type":"paragraph","text":"Between"},'
            '{"id":"i2","type":"image","url":"https://cdn.example.com/2.jpg","alt":"Two"}'),
      );

      expect(find.byType(ReaderInlineImage), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.bySemanticsLabel('One')).dy,
        lessThan(tester.getTopLeft(find.bySemanticsLabel('Two')).dy),
      );
    });

    testWidgets('the viewer shows the image and caption and closes',
        (WidgetTester tester) async {
      picture = (await tester.runAsync(
        () => createTestImage(width: 80, height: 40),
      ))!;
      debugReaderImageProvider = (_) => TestImageProvider(picture);

      await pumpDocument(tester, _parse(_mixedBlocks));
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
