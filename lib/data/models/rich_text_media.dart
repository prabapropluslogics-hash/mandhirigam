import '../../core/utils/json_map.dart';

/// Media carried by an `image`, `audio` or `video` block.
///
/// The backend contract (Rich Text V1) does not define media blocks yet.
/// These fields are the expected shape, flat on the block like the V1 text
/// fields; see `Docs/FLUTTER_IMPLEMENTATION.md`. Every field except `url` is
/// optional, and a block without a usable `url` is dropped.
sealed class RichTextMedia {
  const RichTextMedia({
    required this.url,
    this.mediaId,
    this.mimeType,
    this.caption,
  });

  /// Absolute http(s) URL of the media file.
  final String url;
  final String? mediaId;
  final String? mimeType;
  final String? caption;

  /// Parses the media of a block of [type], or returns null when the type is
  /// not a media type or the block has no usable URL.
  static RichTextMedia? fromBlock(String type, Map<String, dynamic> json) {
    final String? url = mediaUrl(json['url']);
    if (url == null) return null;
    switch (type) {
      case RichTextBlockType.image:
        return RichTextImage(
          url: url,
          mediaId: asStringOrNull(json['mediaId']),
          mimeType: asStringOrNull(json['mimeType']),
          caption: _text(json['caption']),
          alt: _text(json['alt']),
          width: _dimension(json['width']),
          height: _dimension(json['height']),
        );
      case RichTextBlockType.audio:
        return RichTextAudio(
          url: url,
          mediaId: asStringOrNull(json['mediaId']),
          mimeType: asStringOrNull(json['mimeType']),
          caption: _text(json['caption']),
          title: _text(json['title']),
          durationSeconds: _dimension(json['durationSeconds']),
        );
      case RichTextBlockType.video:
        return RichTextVideo(
          url: url,
          mediaId: asStringOrNull(json['mediaId']),
          mimeType: asStringOrNull(json['mimeType']),
          caption: _text(json['caption']),
          title: _text(json['title']),
          thumbnailUrl: mediaUrl(json['thumbnailUrl']),
          durationSeconds: _dimension(json['durationSeconds']),
          width: _dimension(json['width']),
          height: _dimension(json['height']),
        );
    }
    return null;
  }

  /// [value] as an absolute http(s) URL, or null.
  static String? mediaUrl(Object? value) {
    if (value is! String) return null;
    final String text = value.trim();
    final Uri? uri = Uri.tryParse(text);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    return text;
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final String text = value.trim();
    return text.isEmpty ? null : text;
  }

  static int? _dimension(Object? value) {
    final int number = asInt(value);
    return number > 0 ? number : null;
  }
}

class RichTextImage extends RichTextMedia {
  const RichTextImage({
    required super.url,
    super.mediaId,
    super.mimeType,
    super.caption,
    this.alt,
    this.width,
    this.height,
  });

  /// Accessibility text supplied by the backend.
  final String? alt;
  final int? width;
  final int? height;

  /// Width / height when both are supplied.
  double? get aspectRatio {
    final int? w = width;
    final int? h = height;
    if (w == null || h == null) return null;
    return w / h;
  }
}

/// Recognised and kept, but not shown by the Reader yet.
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
}

/// Recognised and kept, but not shown by the Reader yet.
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
}

/// Block `type` values. The first five are the frozen Rich Text V1 types.
abstract final class RichTextBlockType {
  static const String paragraph = 'paragraph';
  static const String heading = 'heading';
  static const String bulletList = 'bullet_list';
  static const String orderedList = 'ordered_list';
  static const String quote = 'quote';
  static const String image = 'image';
  static const String audio = 'audio';
  static const String video = 'video';

  static const Set<String> text = <String>{
    paragraph,
    heading,
    bulletList,
    orderedList,
    quote,
  };

  static const Set<String> media = <String>{image, audio, video};
}
