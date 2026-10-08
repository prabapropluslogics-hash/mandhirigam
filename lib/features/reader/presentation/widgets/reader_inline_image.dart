import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/rich_text_document.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_spacing.dart';
import 'reader_image_viewer.dart';
import 'rich_text_document_view.dart';

/// Replaces the network image source in tests.
@visibleForTesting
ImageProvider<Object> Function(String url)? debugReaderImageProvider;

/// Chapter images share the app's `cached_network_image` disk cache, so the
/// inline image and the full-screen viewer download a URL once.
ImageProvider<Object> readerImageProvider(String url) =>
    debugReaderImageProvider?.call(url) ?? CachedNetworkImageProvider(url);

/// An `image` block: framed on the page at its own aspect ratio, with a
/// caption, a compact loading / failure state, and a tap to view it larger.
class ReaderInlineImage extends StatefulWidget {
  const ReaderInlineImage({
    super.key,
    required this.image,
    this.style = const ReadingStyle(),
  });

  final RichTextImage image;
  final ReadingStyle style;

  /// Upper bound for the decoded width in pixels; the reading column is
  /// never wider than about 900 logical pixels.
  static const int maxDecodeWidth = 1800;

  /// Very tall or very wide images are letterboxed to stay readable.
  static const double minAspectRatio = 0.5;
  static const double maxAspectRatio = 3;

  @override
  State<ReaderInlineImage> createState() => _ReaderInlineImageState();
}

enum _ImageLoad { loading, loaded, failed }

class _ReaderInlineImageState extends State<ReaderInlineImage> {
  /// Natural aspect ratios of images already shown, so a lazily rebuilt
  /// block keeps its height and the page does not jump while scrolling.
  static final Map<String, double> _knownRatios = <String, double>{};

  static const double _placeholderRatio = 16 / 10;
  static const double _radius = AppRadii.md;
  static const double _matte = 3;

  ImageProvider<Object>? _provider;
  ImageStream? _stream;
  late final ImageStreamListener _listener =
      ImageStreamListener(_onImage, onError: _onError);
  _ImageLoad _load = _ImageLoad.loading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(ReaderInlineImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.url != widget.image.url) {
      _load = _ImageLoad.loading;
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
      readerImageProvider(widget.image.url),
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
      _knownRatios[widget.image.url] = info.image.width / height;
    }
    info.dispose();
    if (!mounted || _load == _ImageLoad.loaded) return;
    if (synchronousCall) {
      _load = _ImageLoad.loaded;
    } else {
      setState(() => _load = _ImageLoad.loaded);
    }
  }

  void _onError(Object error, StackTrace? stackTrace) {
    if (!mounted) return;
    setState(() => _load = _ImageLoad.failed);
  }

  Future<void> _retry() async {
    await _provider?.evict();
    if (!mounted) return;
    setState(() {
      _load = _ImageLoad.loading;
      _stream?.removeListener(_listener);
      _stream = null;
      _provider = null;
    });
    _resolve();
  }

  void _open() {
    ReaderImageViewer.show(context, widget.image);
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

    if (_load == _ImageLoad.failed) {
      return _ImageUnavailable(
        decoration: frame,
        style: style,
        onRetry: _retry,
      );
    }

    final RichTextImage image = widget.image;
    final double? ratio = image.aspectRatio ?? _knownRatios[image.url];
    final double shown = (ratio ?? _placeholderRatio).clamp(
      ReaderInlineImage.minAspectRatio,
      ReaderInlineImage.maxAspectRatio,
    );
    final Widget content = _load == _ImageLoad.loaded
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
          button: true,
          image: true,
          label: image.alt ?? 'Image',
          onTapHint: 'View larger',
          onTap: _open,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: _open,
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
