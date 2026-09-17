import 'package:flutter/services.dart';

abstract final class ScreenSecurity {
  static const MethodChannel _channel =
      MethodChannel('maanthirigam/screen_security');

  static Future<void> setSecure(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setSecure', enabled);
    } on PlatformException {
      // Hardening only; never fail the reader.
    } on MissingPluginException {
      // Tests / platforms without the channel.
    }
  }
}
