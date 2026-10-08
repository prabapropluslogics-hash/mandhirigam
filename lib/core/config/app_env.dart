/// Compile-time environment for the Mantirigam API.
///
/// Override with:
/// `flutter run --dart-define=API_BASE_URL=https://host/api/v1`
/// or `--dart-define-from-file=dart_defines.json`
///
/// For a local Android emulator against a PC backend:
/// `--dart-define=API_BASE_URL=http://10.0.2.2:5050/api/v1`
abstract final class AppEnv {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mandhirigam-admin.onrender.com/api/v1',
  );

  /// Optional override for the Google **Web** OAuth client ID (`serverClientId`).
  /// When empty, Android uses the Web client from google-services.json.
  /// This is not a client secret.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// Public website origin used for shareable book links and verified
  /// Android App Links / iOS Universal Links, e.g. `https://example.com`.
  /// Book links take the form `<APP_SHARE_BASE_URL>/book/<bookId>`.
  /// When empty (or not a public https origin) sharing is hidden.
  /// Must never be the API host.
  static const String shareBaseUrl = String.fromEnvironment(
    'APP_SHARE_BASE_URL',
  );

  /// Public Razorpay **test** Key ID (`rzp_test_…`) for development builds.
  /// Optional. Orders are created by the backend, whose key pair decides
  /// test or live; when set, development builds refuse any other key so a
  /// misconfigured backend cannot open a real (live) checkout. Never put the
  /// Key Secret here — it belongs only on the backend.
  static const String razorpayTestKeyId = String.fromEnvironment(
    'RAZORPAY_TEST_KEY_ID',
  );

  static const bool isDevelopment = bool.fromEnvironment(
    'DEV',
    defaultValue: true,
  );

  static Uri get baseUri => Uri.parse(apiBaseUrl);

  /// True when the configured host only works on an Android emulator / local PC.
  static bool get isEmulatorOrLocalHost {
    final String host = baseUri.host.toLowerCase();
    return host == '10.0.2.2' ||
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1';
  }

  static Uri resolve(String path) {
    final String base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final String suffix = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$suffix');
  }
}
