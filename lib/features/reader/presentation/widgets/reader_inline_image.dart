import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_container.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../data/models/rich_text_document.dart';
import '../../../../data/services/chapter_media_loader.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_spacing.dart';
import 'reader_image_viewer.dart';
import 'rich_text_document_view.dart';

/// Replaces the chapter image source in tests (no AppContainer required).
ImageProvider<Object> Function(RichTextImage image)? debugReaderImageProvider;

/// Optional loader for widget tests that do not mount [AppContainer].
ChapterMediaLoader? debugChapterMediaLoader;

ImageProvider<Object> readerImageProvider(
  RichTextImage image,
  ChapterMediaLoader loader,
) {
  return debugReaderImageProvider?.call(image) ??
      AuthenticatedMediaImageProvider(
        mediaId: image.mediaId,
        loader: loader,
      );
}

enum ReaderImageStatus { loading, loaded, failed, restricted }

/// An `image` block: framed at its own aspect ratio, with caption, loading /
/// failure / access-restricted states, and a tap to view it larger.
class ReaderInlineImage extends StatefulWidget {
  const ReaderInlineImage({
    super.key,
    required this.image,
    this.style = const ReadingStyle(),
  });

  final RichTextImage image;
  final ReadingStyle style;

  static const int maxDecodeWidth = 1800;
  static const double minAspectRatio = 0.5;
  static const double maxAspectRatio = 3;

  @override
  State<ReaderInlineImage> createState() => _ReaderInlineImageState();
}

class _ReaderInlineImageState extends State<ReaderInlineImage> {
  static final Map<String, double> _knownRatios = <String, double>{};

  static const double _placeholderRatio = 16 / 10;
  static const double _radius = AppRadii.md;
  static const double _matte = 3;

  ImageProvider<Object>? _provider;
  ImageStream? _stream;
  late final ImageStreamListener _listener =
      ImageStreamListener(_onImage, onError: _onError);
  ReaderImageStatus _status = ReaderImageStatus.loading;
  bool _restricted = false;

  ChapterMediaLoader get _loader =>
      debugChapterMediaLoader ??
      context.read<AppContainer>().chapterMediaLoader;

  ImageProvider<Object> _baseProvider() {
    final ImageProvider<Object> Function(RichTextImage image)? override =
        debugReaderImageProvider;
    if (override != null) return override(widget.image);
    return AuthenticatedMediaImageProvider(
      mediaId: widget.image.mediaId,
      loader: _loader,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(ReaderInlineImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.mediaId != widget.image.mediaId) {
      _status = ReaderImageStatus.loading;
      _restricted = false;
      _resolve();
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  ImageProvider<Object> _decodeProvider() {
    final double logicalWidth = math.min(MediaQuery.sizeOf(context).width, 900);
    final int width = (logicalWidth * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(1, ReaderInlineImage.maxDecodeWidth);
    return ResizeImage(
      _baseProvider(),
      width: width,
      height: width * 4,
      policy: ResizeImagePolicy.fit,
    );
  }

  void _resolve() {
    final ImageProvider<Object> provider = _decodeProvider();
    if (provider == _provider && _stream != null) return;
    _provider = provider;
    _stream?.removeListener(_listener);
    _stream = provider.resolve(createLocalImageConfiguration(context))
      ..addListener(_listener);
  }

  void _onImage(ImageInfo info, bool synchronousCall) {
    final int height = info.image.height;
    if (height > 0) {
      _knownRatios[widget.image.mediaId] = info.image.width / height;
    }
    info.dispose();
    if (!mounted || _status == ReaderImageStatus.loaded) return;
    if (synchronousCall) {
      _status = ReaderImageStatus.loaded;
      _restricted = false;
    } else {
      setState(() {
        _status = ReaderImageStatus.loaded;
        _restricted = false;
      });
    }
  }

  void _onError(Object error, StackTrace? stackTrace) {
    if (!mounted) return;
    final bool restricted = error is ApiException &&
        (error.isForbidden ||
            error.isAuthenticationRequired ||
            error.isUnauthorized);
    setState(() {
      _restricted = restricted;
      _status =
          restricted ? ReaderImageStatus.restricted : ReaderImageStatus.failed;
    });
  }

  Future<void> _retry() async {
    if (_restricted) return;
    await _provider?.evict();
    if (!mounted) return;
    setState(() {
      _status = ReaderImageStatus.loading;
      _stream?.removeListener(_listener);
      _stream = null;
      _provider = null;
    });
    _resolve();
  }

  void _open() {
    if (_status != ReaderImageStatus.loaded) return;
    ReaderImageViewer.show(
      context,
      widget.image,
      provider: _provider,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ReadingStyle style = widget.style;
    final Color accent = style.accent(context);
    final Color secondary = style.secondary(context);
    final BoxDecoration frame = BoxDecoration(
      color: accent.withOpacity(0.07),
      borderRadius: BorderRadius.circular(_radius),
      border: Border.all(color: accent.withOpacity(0.3), width: 0.8),
    );

    if (_status == ReaderImageStatus.restricted) {
      return _ImageAccessRestricted(decoration: frame, style: style);
    }
    if (_status == ReaderImageStatus.failed) {
      return _ImageUnavailable(
        decoration: frame,
        style: style,
        onRetry: _retry,
      );
    }

    final RichTextImage image = widget.image;
    final double? ratio = image.aspectRatio ?? _knownRatios[image.mediaId];
    final double shown = (ratio ?? _placeholderRatio).clamp(
      ReaderInlineImage.minAspectRatio,
      ReaderInlineImage.maxAspectRatio,
    );
    final Widget content = _status == ReaderImageStatus.loaded
        ? Image(
            image: _provider!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            excludeFromSemantics: true,
          )
        : Center(
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: accent.withOpacity(0.75),
              ),
            ),
          );

    final String? caption = image.caption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          button: _status == ReaderImageStatus.loaded,
          image: true,
          label: image.alt ?? 'Image',
          onTapHint: 'View larger',
          onTap: _status == ReaderImageStatus.loaded ? _open : null,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: _status == ReaderImageStatus.loaded ? _open : null,
            excludeFromSemantics: true,
            child: DecoratedBox(
              decoration: frame,
              child: Padding(
                padding: const EdgeInsets.all(_matte),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_radius - _matte),
                  child: AspectRatio(aspectRatio: shown, child: content),
                ),
              ),
            ),
          ),
        ),
        if (caption != null) ...[
          SizedBox(height: style.fontSize * 0.55),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: style.body(context).copyWith(
                  fontSize: style.fontSize * 0.82,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  color: secondary,
                ),
          ),
        ],
      ],
    );
  }
}

class _ImageUnavailable extends StatelessWidget {
  const _ImageUnavailable({
    required this.decoration,
    required this.style,
    required this.onRetry,
  });

  final BoxDecoration decoration;
  final ReadingStyle style;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Color secondary = style.secondary(context);
    final Color accent = style.accent(context);
    return DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(AppIcons.imageUnavailable, size: 20, color: secondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Image unavailable',
                style: style.body(context).copyWith(
                      fontSize: style.fontSize * 0.82,
                      height: 1.3,
                      color: secondary,
                    ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: accent),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageAccessRestricted extends StatelessWidget {
  const _ImageAccessRestricted({
    required this.decoration,
    required this.style,
  });

  final BoxDecoration decoration;
  final ReadingStyle style;

  @override
  Widget build(BuildContext context) {
    final Color secondary = style.secondary(context);
    return DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(AppIcons.lockOutline, size: 20, color: secondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'This illustration requires access to the book.',
                style: style.body(context).copyWith(
                      fontSize: style.fontSize * 0.82,
                      height: 1.3,
                      color: secondary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
