import '../../core/utils/json_map.dart';

/// Optional import/source metadata. Not shown in the Reader UI.
class RichTextSource {
  const RichTextSource({this.page, this.order});

  final int? page;
  final int? order;

  static RichTextSource? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final Map<String, dynamic> json = Map<String, dynamic>.from(raw);
    final int? page = _positive(json['page']);
    final int? order = _positive(json['order']);
    if (page == null && order == null) return null;
    return RichTextSource(page: page, order: order);
  }

  static int? _positive(Object? value) {
    final int number = asInt(value);
    return number > 0 ? number : null;
  }
}

/// Media carried by an `image` block (Rich Text V2), or prepared audio/video.
sealed class RichTextMedia {
  const RichTextMedia({
    required this.url,
    this.mediaId,
    this.mimeType,
    this.caption,
  });

  /// Absolute http(s) media URL from the API (never put a token in it).
  final String url;
  final String? mediaId;
  final String? mimeType;
  final String? caption;

  /// Parses media for [type], or null when the block is unusable.
  static RichTextMedia? fromBlock(
    String type,
    Map<String, dynamic> json, {
    required int documentVersion,
  }) {
    switch (type) {
      case RichTextBlockType.image:
        return RichTextImage.tryParse(json, documentVersion: documentVersion);
      case RichTextBlockType.audio:
        return RichTextAudio.tryParse(json);
      case RichTextBlockType.video:
        return RichTextVideo.tryParse(json);
    }
    return null;
  }

  static String? mediaUrl(Object? value) {
    if (value is! String) return null;
    final String text = value.trim();
    final Uri? uri = Uri.tryParse(text);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    return text;
  }

  static String? text(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? dimension(Object? value) {
    final int number = asInt(value);
    return number > 0 ? number : null;
  }
}

class RichTextImage extends RichTextMedia {
  const RichTextImage({
    required super.url,
    required String mediaId,
    super.mimeType,
    super.caption,
    this.alt,
    this.width,
    this.height,
    this.fit = 'contain',
    this.source,
  }) : super(mediaId: mediaId);

  @override
  String get mediaId => super.mediaId!;

  /// Accessibility text from the backend.
  final String? alt;
  final int? width;
  final int? height;

  /// Backend fit hint; only `contain` is used today.
  final String fit;
  final RichTextSource? source;

  double? get aspectRatio {
    final int? w = width;
    final int? h = height;
    if (w == null || h == null) return null;
    return w / h;
  }

  /// V2 chapter images must use the public media route for [mediaId]
  /// (not Admin routes or arbitrary CDN hosts). [mediaId] is a 24-char
  /// Mongo ObjectId.
  static RichTextImage? tryParse(
    Map<String, dynamic> json, {
    required int documentVersion,
  }) {
    // Official contract: image blocks are V2-only.
    if (documentVersion < 2) return null;
    final String? mediaId = asStringOrNull(json['mediaId']);
    final String? url = RichTextMedia.mediaUrl(json['url']);
    if (mediaId == null || url == null) return null;
    if (!isValidChapterMedia(mediaId: mediaId, url: url)) return null;
    return RichTextImage(
      url: url,
      mediaId: mediaId,
      mimeType: asStringOrNull(json['mimeType']),
      caption: RichTextMedia.text(json['caption']),
      alt: RichTextMedia.text(json['alt']),
      width: RichTextMedia.dimension(json['width']),
      height: RichTextMedia.dimension(json['height']),
      fit: asString(json['fit'], 'contain'),
      source: RichTextSource.tryParse(json['source']),
    );
  }

  static final RegExp _objectId = RegExp(r'^[a-fA-F0-9]{24}$');

  /// True when [url] is a mobile media URL for [mediaId].
  static bool isValidChapterMedia({
    required String mediaId,
    required String url,
  }) {
    if (!_objectId.hasMatch(mediaId)) return false;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return false;
    final List<String> segments =
        uri.pathSegments.where((String s) => s.isNotEmpty).toList();
    if (segments.contains('admin')) return false;
    final int mediaIndex = segments.lastIndexOf('media');
    if (mediaIndex < 0 || mediaIndex + 1 >= segments.length) return false;
    // Reject /media/covers/:id
    if (segments[mediaIndex + 1] == 'covers') return false;
    if (segments[mediaIndex + 1] != mediaId) return false;
    // No extra path after the id.
    return mediaIndex + 2 == segments.length;
  }
}

/// Prepared for a future release; not rendered.
class RichTextAudio extends RichTextMedia {
  const RichTextAudio({
    required super.url,
    super.mediaId,
    super.mimeType,
    super.caption,
    this.title,
    this.durationSeconds,
  });

  final String? title;
  final int? durationSeconds;

  Duration? get duration =>
      durationSeconds == null ? null : Duration(seconds: durationSeconds!);

  static RichTextAudio? tryParse(Map<String, dynamic> json) {
    final String? url = RichTextMedia.mediaUrl(json['url']);
    if (url == null) return null;
    return RichTextAudio(
      url: url,
      mediaId: asStringOrNull(json['mediaId']),
      mimeType: asStringOrNull(json['mimeType']),
      caption: RichTextMedia.text(json['caption']),
      title: RichTextMedia.text(json['title']),
      durationSeconds: RichTextMedia.dimension(json['durationSeconds']),
    );
  }
}

/// Prepared for a future release; not rendered.
class RichTextVideo extends RichTextMedia {
  const RichTextVideo({
    required super.url,
    super.mediaId,
    super.mimeType,
    super.caption,
    this.title,
    this.thumbnailUrl,
    this.durationSeconds,
    this.width,
    this.height,
  });

  final String? title;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int? width;
  final int? height;

  Duration? get duration =>
      durationSeconds == null ? null : Duration(seconds: durationSeconds!);

  static RichTextVideo? tryParse(Map<String, dynamic> json) {
    final String? url = RichTextMedia.mediaUrl(json['url']);
    if (url == null) return null;
    return RichTextVideo(
      url: url,
      mediaId: asStringOrNull(json['mediaId']),
      mimeType: asStringOrNull(json['mimeType']),
      caption: RichTextMedia.text(json['caption']),
      title: RichTextMedia.text(json['title']),
      thumbnailUrl: RichTextMedia.mediaUrl(json['thumbnailUrl']),
      durationSeconds: RichTextMedia.dimension(json['durationSeconds']),
      width: RichTextMedia.dimension(json['width']),
      height: RichTextMedia.dimension(json['height']),
    );
  }
}

/// Block `type` values. First five are frozen Rich Text V1; `image` is V2.
abstract final class RichTextBlockType {
  static const String paragraph = 'paragraph';
  static const String heading = 'heading';
  static const String bulletList = 'bullet_list';
  static const String orderedList = 'ordered_list';
  static const String quote = 'quote';
  static const String image = 'image';
  static const String audio = 'audio';
  static const String video = 'video';

  static const String presentationInstruction = 'instruction';

  static const Set<String> text = <String>{
    paragraph,
    heading,
    bulletList,
    orderedList,
    quote,
  };

  static const Set<String> media = <String>{image, audio, video};
}
