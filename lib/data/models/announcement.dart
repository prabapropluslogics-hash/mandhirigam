import '../../core/utils/json_map.dart';

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    this.actionLabel,
    this.actionUrl,
    this.displayOrder = 0,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final String? actionLabel;
  final String? actionUrl;
  final int displayOrder;
  final String? publishedAt;

  bool get hasAction {
    final String? label = actionLabel;
    return label != null &&
        label.trim().isNotEmpty &&
        actionUrl != null &&
        actionUrl!.trim().isNotEmpty;
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: asString(json['id']),
      title: asString(json['title']),
      message: asString(json['message']),
      imageUrl: asStringOrNull(json['imageUrl']),
      actionLabel: asStringOrNull(json['actionLabel']),
      actionUrl: asStringOrNull(json['actionUrl']),
      displayOrder: asInt(json['displayOrder']),
      publishedAt: asStringOrNull(json['publishedAt']),
    );
  }
}
