import '../../core/utils/json_map.dart';
import 'rich_text_document.dart';

class ChapterSummary {
  const ChapterSummary({
    required this.id,
    required this.bookId,
    required this.chapterNumber,
    required this.title,
    required this.contentFormat,
    required this.status,
  });

  final String id;
  final String bookId;
  final int chapterNumber;
  final String title;
  final String contentFormat;
  final String status;

  factory ChapterSummary.fromJson(Map<String, dynamic> json) {
    return ChapterSummary(
      id: asString(json['id']),
      bookId: asString(json['bookId']),
      chapterNumber: asInt(json['chapterNumber']),
      title: asString(json['title']),
      contentFormat: asString(json['contentFormat'], 'RICH_TEXT'),
      status: asString(json['status'], 'PUBLISHED'),
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
    required this.content,
  });

  final RichTextDocument content;

  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    return ChapterContent(
      id: asString(json['id']),
      bookId: asString(json['bookId']),
      chapterNumber: asInt(json['chapterNumber']),
      title: asString(json['title']),
      contentFormat: asString(json['contentFormat'], 'RICH_TEXT'),
      status: asString(json['status'], 'PUBLISHED'),
      content: RichTextDocument.fromJson(asJsonMap(json['content'])),
    );
  }
}
