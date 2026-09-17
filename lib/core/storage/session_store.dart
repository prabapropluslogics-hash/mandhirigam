import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/user_profile.dart';

/// Platform-secure session store (Keychain / EncryptedSharedPreferences).
class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'mantirigam.accessToken';
  static const String _userKey = 'mantirigam.user';

  Future<void> saveSession({
    required String accessToken,
    required UserProfile user,
  }) async {
    await _storage.write(key: _tokenKey, value: accessToken);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<String?> readAccessToken() => _storage.read(key: _tokenKey);

  Future<UserProfile?> readUser() async {
    final String? raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return UserProfile.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
