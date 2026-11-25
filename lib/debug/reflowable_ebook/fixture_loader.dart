import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../data/models/chapter.dart';
import '../../data/models/rich_text_document.dart';
import '../../features/reader/presentation/widgets/reader_inline_image.dart';

/// Backend handoff fixture for Phase 03 local demonstration.
///
/// Lives under `test/fixtures/reflowable-ebook/` and must **not** be listed
/// in production `pubspec.yaml` assets.
class ReflowableEbookFixture {
  const ReflowableEbookFixture({
    required this.chapter,
    required this.reviewNotes,
    required this.yantraFile,
    required this.yantraMediaId,
    required this.localAssetByMediaId,
  });

  final ChapterContent chapter;
  final ChapterReviewNotes reviewNotes;
  final File yantraFile;
  final String yantraMediaId;
  final Map<String, File> localAssetByMediaId;

  /// Checksum of the checked-in Yantra PNG from the Admin handoff sample.
  static const String expectedYantraSha256 =
      'bb0a41aa823deb5f197e2f831fcdb29af70377521a37b921a6b9fb10b57687bd';

  static const String expectedYantraWidth = '1271';
  static const String expectedYantraHeight = '848';
}

/// OCR / Admin review metadata from the sample chapter envelope.
///
/// Production mobile payloads may omit this; when present, Flutter must show
/// that Tamil OCR still needs human verification — never silently "fix" text.
class ChapterReviewNotes {
  const ChapterReviewNotes({
    required this.humanVerificationRequired,
    required this.notes,
    this.ocrMode,
    this.diagramCount,
    this.ambiguousCount,
  });

  final bool humanVerificationRequired;
  final List<String> notes;
  final String? ocrMode;
  final int? diagramCount;
  final int? ambiguousCount;

  factory ChapterReviewNotes.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ChapterReviewNotes(
        humanVerificationRequired: false,
        notes: <String>[],
      );
    }
    final Object? rawNotes = json['notes'];
    final List<String> notes = <String>[];
    if (rawNotes is List) {
      for (final Object? item in rawNotes) {
        if (item is String && item.trim().isNotEmpty) {
          notes.add(item.trim());
        }
      }
    }
    return ChapterReviewNotes(
      humanVerificationRequired: json['humanVerificationRequired'] == true,
      notes: notes,
      ocrMode: json['ocrMode'] is String ? json['ocrMode'] as String : null,
      diagramCount: json['diagramCount'] is int ? json['diagramCount'] as int : null,
      ambiguousCount:
          json['ambiguousCount'] is int ? json['ambiguousCount'] as int : null,
    );
  }
}

/// Loads the Admin-provided sample into production [ChapterContent] models.
///
/// Rewrites relative `/api/v1/media/:id` URLs to absolute HTTPS URLs so the
/// unchanged production [RichTextImage] validator accepts them. Diagram bytes
/// still come from [localAsset] via [installLocalFixtureImageProvider].
ReflowableEbookFixture loadReflowableEbookFixture({
  required Directory fixturesDir,
  String apiHost = 'https://api.example.com',
}) {
  final File chapterFile = File('${fixturesDir.path}/chapter_response.json');
  final File yantraFile = File('${fixturesDir.path}/yantra_page07.png');
  if (!chapterFile.existsSync()) {
    throw StateError('Missing fixture: ${chapterFile.path}');
  }
  if (!yantraFile.existsSync()) {
    throw StateError('Missing fixture: ${yantraFile.path}');
  }

  final Map<String, dynamic> envelope =
      jsonDecode(chapterFile.readAsStringSync()) as Map<String, dynamic>;
  final Map<String, dynamic> data =
      Map<String, dynamic>.from(envelope['data'] as Map);

  final Map<String, File> localAssets = <String, File>{};
  String yantraMediaId = '';
  final Map<String, dynamic> content =
      Map<String, dynamic>.from(data['content'] as Map);
  final List<dynamic> blocks = List<dynamic>.from(content['blocks'] as List);
  for (int i = 0; i < blocks.length; i++) {
    final Map<String, dynamic> block =
        Map<String, dynamic>.from(blocks[i] as Map);
    if (block['type'] != 'image') continue;
    final String mediaId = '${block['mediaId']}'.trim();
    final String? local = block['localAsset'] is String
        ? (block['localAsset'] as String).trim()
        : null;
    if (mediaId.isNotEmpty && local != null && local.isNotEmpty) {
      final File asset = File('${fixturesDir.path}/$local');
      if (!asset.existsSync()) {
        throw StateError('Missing localAsset file: ${asset.path}');
      }
      localAssets[mediaId] = asset;
      yantraMediaId = mediaId;
    }
    // Production parser requires absolute http(s) media URLs.
    final String rawUrl = '${block['url'] ?? ''}'.trim();
    if (rawUrl.startsWith('/')) {
      block['url'] = '$apiHost$rawUrl';
    } else if (!rawUrl.contains('://')) {
      block['url'] = '$apiHost/api/v1/media/$mediaId';
    }
    blocks[i] = block;
  }
  content['blocks'] = blocks;
  data['content'] = content;

  final ChapterContent chapter = ChapterContent.fromJson(data);
  final ChapterReviewNotes review = ChapterReviewNotes.fromJson(
    data['reviewNotes'] is Map
        ? Map<String, dynamic>.from(data['reviewNotes'] as Map)
        : null,
  );

  final RichTextDocument? document = chapter.content;
  if (document == null || document.blocks.isEmpty) {
    throw StateError('Fixture produced an empty Rich Text document.');
  }
  final bool hasImage = document.blocks.any((RichTextBlock b) => b.isImage);
  if (!hasImage) {
    throw StateError(
      'Fixture image block was dropped — check media URL rewriting.',
    );
  }

  return ReflowableEbookFixture(
    chapter: chapter,
    reviewNotes: review,
    yantraFile: yantraFile,
    yantraMediaId: yantraMediaId,
    localAssetByMediaId: localAssets,
  );
}

/// Points [debugReaderImageProvider] at local fixture bytes for the demo/tests.
///
/// Uses [MemoryImage] so widget tests do not depend on async FileImage codecs.
/// Call [clearLocalFixtureImageProvider] in tearDown / dispose.
void installLocalFixtureImageProvider(Map<String, File> localAssetByMediaId) {
  final Map<String, Uint8List> bytesByMediaId = <String, Uint8List>{
    for (final MapEntry<String, File> entry in localAssetByMediaId.entries)
      entry.key: entry.value.readAsBytesSync(),
  };
  debugReaderImageProvider = (RichTextImage image) {
    final Uint8List? bytes = bytesByMediaId[image.mediaId];
    if (bytes == null) {
      throw StateError(
        'No local fixture for mediaId=${image.mediaId}. '
        'Protected network loading must be tested separately.',
      );
    }
    return MemoryImage(bytes);
  };
}

void clearLocalFixtureImageProvider() {
  debugReaderImageProvider = null;
}

/// Resolves the checked-in fixture directory for tests and debug entrypoints.
Directory resolveReflowableFixturesDir({String? override}) {
  if (override != null && override.isNotEmpty) {
    return Directory(override);
  }
  final List<String> candidates = <String>[
    'test/fixtures/reflowable-ebook',
    '../test/fixtures/reflowable-ebook',
    'fixtures/reflowable-ebook',
  ];
  for (final String relative in candidates) {
    final Directory dir = Directory(relative);
    if (dir.existsSync() &&
        File('${dir.path}/chapter_response.json').existsSync()) {
      return dir.absolute;
    }
  }
  // Walk up from the script / CWD looking for the Flutter package root.
  Directory cursor = Directory.current.absolute;
  for (int i = 0; i < 6; i++) {
    final Directory candidate =
        Directory('${cursor.path}/test/fixtures/reflowable-ebook');
    if (candidate.existsSync() &&
        File('${candidate.path}/chapter_response.json').existsSync()) {
      return candidate;
    }
    final Directory parent = cursor.parent;
    if (parent.path == cursor.path) break;
    cursor = parent;
  }
  throw StateError(
    'Could not locate test/fixtures/reflowable-ebook. '
    'Copy Admin docs/samples/reflowable-ebook/* into that folder.',
  );
}

@visibleForTesting
bool fixtureImageBlockSurvivesProductionParser(Map<String, dynamic> block) {
  final RichTextImage? image = RichTextImage.tryParse(
    block,
    documentVersion: 2,
  );
  return image != null;
}
