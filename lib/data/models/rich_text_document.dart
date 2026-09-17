import '../../core/utils/json_map.dart';

class RichTextDocument {
  const RichTextDocument({
    required this.version,
    required this.blocks,
  });

  final int version;
  final List<RichTextBlock> blocks;

  factory RichTextDocument.fromJson(Map<String, dynamic> json) {
    final Object? blocksRaw = json['blocks'];
    final List<RichTextBlock> blocks = <RichTextBlock>[];
    if (blocksRaw is List) {
      for (final Object? item in blocksRaw) {
        if (item is Map) {
          blocks.add(RichTextBlock.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return RichTextDocument(
      version: asInt(json['version'], 1),
      blocks: blocks,
    );
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
  });

  final String id;
  final String type;
  final String text;
  final int? level;
  final List<RichTextMark> marks;
  final List<RichTextListItem> items;

  bool get isParagraph => type == 'paragraph';
  bool get isHeading => type == 'heading';
  bool get isBulletList => type == 'bullet_list';
  bool get isOrderedList => type == 'ordered_list';
  bool get isQuote => type == 'quote';

  factory RichTextBlock.fromJson(Map<String, dynamic> json) {
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
    return RichTextBlock(
      id: asString(json['id']),
      type: asString(json['type']),
      text: asString(json['text']),
      level: json['level'] == null ? null : asInt(json['level']),
      marks: marks,
      items: items,
    );
  }
}
