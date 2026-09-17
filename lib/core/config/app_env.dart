/// Compile-time environment for the Mantirigam API.
///
/// Pass values with:
/// `flutter run --dart-define=API_BASE_URL=https://host/api/v1`
abstract final class AppEnv {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5050/api/v1',
  );

  /// Google Cloud **Web** OAuth client ID used as `serverClientId`.
  /// This is not a client secret.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static const bool isDevelopment = bool.fromEnvironment(
    'DEV',
    defaultValue: true,
  );

  static Uri resolve(String path) {
    final String base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final String suffix = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$suffix');
  }
}
