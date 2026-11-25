import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../../core/errors/api_exception.dart';

/// Decodes a verified PNG at its metadata size and returns the owned image.
Future<ui.Image> decodeTransparentPageImage(
  Uint8List bytes, {
  required int width,
  required int height,
}) async {
  final ui.Codec codec = await ui.instantiateImageCodec(bytes);
  try {
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;
    if (image.width != width || image.height != height) {
      final int actualWidth = image.width;
      final int actualHeight = image.height;
      image.dispose();
      throw ApiException(
        statusCode: 200,
        code: 'PAGE_DIMENSION_MISMATCH',
        message: 'Page decoded as ${actualWidth}x$actualHeight.',
      );
    }
    return image;
  } finally {
    codec.dispose();
  }
}
