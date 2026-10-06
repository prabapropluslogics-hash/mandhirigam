import '../core/config/app_env.dart';

/// Builds and parses the one public link shape the app understands:
/// `<APP_SHARE_BASE_URL>/book/<bookId>`.
///
/// Anything else (other paths, other hosts, http, malformed ids) is rejected,
/// so a link can never reach payment, account or admin screens.
class BookLinks {
  BookLinks._(this._base, this._basePath);

  factory BookLinks.fromConfig({
    required String shareBaseUrl,
    required String apiBaseUrl,
  }) {
    final Uri? base = _validBase(shareBaseUrl, apiBaseUrl);
    final List<String> basePath = base == null
        ? const <String>[]
        : base.pathSegments.where((String s) => s.isNotEmpty).toList();
    return BookLinks._(base, basePath);
  }

  static final BookLinks current = BookLinks.fromConfig(
    shareBaseUrl: AppEnv.shareBaseUrl,
    apiBaseUrl: AppEnv.apiBaseUrl,
  );

  static final RegExp _bookId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  final Uri? _base;
  final List<String> _basePath;

  bool get isConfigured => _base != null;

  String? get host => _base?.host;

  static bool isValidBookId(String id) => _bookId.hasMatch(id);

  Uri? bookUri(String bookId) {
    final Uri? base = _base;
    if (base == null || !isValidBookId(bookId)) return null;
    return Uri(
      scheme: 'https',
      host: base.host,
      port: base.hasPort ? base.port : null,
      pathSegments: <String>[..._basePath, 'book', bookId],
    );
  }

  /// Returns the book id when [uri] is exactly one of our book links.
  String? parseBookId(Uri uri) {
    final Uri? base = _base;
    if (base == null) return null;
    if (uri.scheme.toLowerCase() != 'https') return null;
    if (uri.host.toLowerCase() != base.host.toLowerCase()) return null;
    if (uri.userInfo.isNotEmpty) return null;
    if ((uri.hasPort ? uri.port : 443) != (base.hasPort ? base.port : 443)) {
      return null;
    }
    final List<String> segments =
        uri.pathSegments.where((String s) => s.isNotEmpty).toList();
    if (segments.length != _basePath.length + 2) return null;
    for (int i = 0; i < _basePath.length; i++) {
      if (segments[i] != _basePath[i]) return null;
    }
    if (segments[_basePath.length] != 'book') return null;
    final String id = segments.last;
    return isValidBookId(id) ? id : null;
  }

  String? parseLink(String raw) {
    final Uri? uri = Uri.tryParse(raw.trim());
    return uri == null ? null : parseBookId(uri);
  }

  /// Reads the book id from a Google Play install referrer, which carries the
  /// URL-encoded `referrer` parameter of the Play Store link, e.g.
  /// `book_id=<id>&utm_source=share`. A full `deep_link=<book url>` is also
  /// accepted and validated like a normal link.
  String? parseInstallReferrer(String referrer) {
    if (referrer.isEmpty || referrer.length > 1024) return null;
    final Map<String, String> params;
    try {
      params = Uri.splitQueryString(referrer);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
    final String? id = params['book_id'];
    if (id != null) return isValidBookId(id) ? id : null;
    final String? link = params['deep_link'];
    if (link != null) return parseLink(link);
    return null;
  }

  static Uri? _validBase(String raw, String apiBaseUrl) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme.toLowerCase() != 'https') return null;
    final String host = uri.host.toLowerCase();
    if (host.isEmpty || uri.userInfo.isNotEmpty) return null;
    if (uri.hasQuery || uri.hasFragment) return null;
    if (!host.contains('.') || _isIpLiteral(host)) return null;
    if (host == 'localhost' || host.endsWith('.localhost')) return null;
    final Uri? api = Uri.tryParse(apiBaseUrl);
    if (api != null && api.host.toLowerCase() == host) return null;
    return uri;
  }

  static bool _isIpLiteral(String host) {
    if (host.contains(':')) return true;
    return RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
  }
}
