import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small on-device key/value store for app preferences (reader settings,
/// Home language, deep-link bookkeeping). Values never leave the device.
///
/// Uses its own `maanthirigam.pref.*` keys, which the session store never
/// touches, so preferences survive sign-out.
class LocalPreferences {
  LocalPreferences({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const String _prefix = 'maanthirigam.pref.';

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: '$_prefix$key');
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: '$_prefix$key', value: value);
    } catch (_) {
      // Preferences are best-effort; the in-memory value still applies.
    }
  }

  Future<void> remove(String key) async {
    try {
      await _storage.delete(key: '$_prefix$key');
    } catch (_) {}
  }
}
