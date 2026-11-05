import 'package:flutter/foundation.dart';

import '../../core/utils/json_map.dart';
import 'rich_text_media.dart';

export 'rich_text_media.dart';

class RichTextDocument {
  const RichTextDocument({
    required this.version,
    required this.blocks,
  });

  /// 1 = frozen Rich Text V1; 2 = V2 (includes image blocks).
  final int version;

  /// Blocks in reading order. Unknown / invalid blocks are omitted so one
  /// bad entry never breaks a chapter.
  final List<RichTextBlock> blocks;

  bool get isV1 => version <= 1;
  bool get isV2 => version >= 2;

  factory RichTextDocument.fromJson(Map<String, dynamic> json) {
    final int version = asInt(json['version'], 1);
    final Object? blocksRaw = json['blocks'];
    final List<RichTextBlock> blocks = <RichTextBlock>[];
    if (blocksRaw is List) {
      for (final Object? item in blocksRaw) {
        if (item is! Map) continue;
        final RichTextBlock block;
        try {
          block = RichTextBlock.fromJson(
            Map<String, dynamic>.from(item),
            documentVersion: version,
          );
        } catch (_) {
          _skipped('malformed block');
          continue;
        }
        if (!_keep(block, version)) {
          if (!block.isKnownType) {
            _skipped('unsupported block type');
          } else if (block.isImage && version < 2) {
            _skipped('image block in V1 document');
          } else if (block.isMedia && block.media == null) {
            _skipped('${block.type} block without usable media');
          } else {
            _skipped('${block.type} block');
          }
          continue;
        }
        blocks.add(block);
      }
    }
    return RichTextDocument(version: version, blocks: blocks);
  }

  static bool _keep(RichTextBlock block, int version) {
    if (!block.isKnownType) return false;
    if (block.isImage) {
      return version >= 2 && block.media != null;
    }
    if (block.isAudio || block.isVideo) {
      return block.media != null;
    }
    return block.isText;
  }

  static void _skipped(String reason) {
    if (kDebugMode) debugPrint('Rich text: skipped $reason');
  }
}

class RichTextMark {
  const RichTextMark({
    required this.start,
    required this.end,
    required this.type,
  });

  final int start;
  final int end;
  final String type;

  bool get isBold => type == 'bold';
  bool get isItalic => type == 'italic';

  factory RichTextMark.fromJson(Map<String, dynamic> json) {
    return RichTextMark(
      start: asInt(json['start']),
      end: asInt(json['end']),
      type: asString(json['type']),
    );
  }
}

class RichTextListItem {
  const RichTextListItem({required this.text});

  final String text;

  factory RichTextListItem.fromJson(Map<String, dynamic> json) {
    return RichTextListItem(text: asString(json['text']));
  }
}

class RichTextBlock {
  const RichTextBlock({
    required this.id,
    required this.type,
    this.text = '',
    this.level,
    this.marks = const <RichTextMark>[],
    this.items = const <RichTextListItem>[],
    this.media,
    this.presentation,
    this.source,
  });

  final String id;
  final String type;
  final String text;
  final int? level;
  final List<RichTextMark> marks;
  final List<RichTextListItem> items;

  /// Set for `image` / prepared audio / video with usable media.
  final RichTextMedia? media;

  /// Optional V1/V2 presentation, e.g. `instruction` for labels like செய்முறை.
  final String? presentation;

  /// Optional import source metadata (page/order). Not shown in the UI.
  final RichTextSource? source;

  bool get isParagraph => type == RichTextBlockType.paragraph;
  bool get isHeading => type == RichTextBlockType.heading;
  bool get isBulletList => type == RichTextBlockType.bulletList;
  bool get isOrderedList => type == RichTextBlockType.orderedList;
  bool get isQuote => type == RichTextBlockType.quote;
  bool get isImage => type == RichTextBlockType.image;
  bool get isAudio => type == RichTextBlockType.audio;
  bool get isVideo => type == RichTextBlockType.video;

  bool get isText => RichTextBlockType.text.contains(type);
  bool get isMedia => RichTextBlockType.media.contains(type);
  bool get isKnownType => isText || isMedia;

  bool get isInstruction =>
      presentation == RichTextBlockType.presentationInstruction;

  RichTextImage? get image {
    final RichTextMedia? media = this.media;
    return media is RichTextImage ? media : null;
  }

  RichTextAudio? get audio {
    final RichTextMedia? media = this.media;
    return media is RichTextAudio ? media : null;
  }

  RichTextVideo? get video {
    final RichTextMedia? media = this.media;
    return media is RichTextVideo ? media : null;
  }

  factory RichTextBlock.fromJson(
    Map<String, dynamic> json, {
    int documentVersion = 1,
  }) {
    final Object? marksRaw = json['marks'];
    final List<RichTextMark> marks = <RichTextMark>[];
    if (marksRaw is List) {
      for (final Object? item in marksRaw) {
        if (item is Map) {
          marks.add(RichTextMark.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final Object? itemsRaw = json['items'];
    final List<RichTextListItem> items = <RichTextListItem>[];
    if (itemsRaw is List) {
      for (final Object? item in itemsRaw) {
        if (item is Map) {
          items.add(RichTextListItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final String type = asString(json['type'], RichTextBlockType.paragraph);
    final String? presentation = asStringOrNull(json['presentation']);
    return RichTextBlock(
      id: asString(json['id']),
      type: type,
      text: asString(json['text']),
      level: json['level'] == null ? null : asInt(json['level']),
      marks: marks,
      items: items,
      media: RichTextMedia.fromBlock(
        type,
        json,
        documentVersion: documentVersion,
      ),
      presentation: presentation,
      source: RichTextSource.tryParse(json['source']),
    );
  }
}
