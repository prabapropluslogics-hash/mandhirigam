import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Serves [image] synchronously, after failing the first [failures] loads.
class TestImageProvider extends ImageProvider<TestImageProvider> {
  TestImageProvider(this.image, {this.failures = 0});

  final ui.Image image;
  int failures;
  int loads = 0;

  @override
  Future<TestImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<TestImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    TestImageProvider key,
    ImageDecoderCallback decode,
  ) {
    loads++;
    if (failures > 0) {
      failures--;
      return OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(StateError('image failed')),
      );
    }
    return OneFrameImageStreamCompleter(
      SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
    );
  }
}
