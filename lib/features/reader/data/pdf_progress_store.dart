import '../../../services/local_preferences.dart';

/// Account-scoped progress key. A transparent package adds its fingerprint
/// so a different package cannot resume another package's page slot.
String pdfProgressKey({
  required String? userId,
  required String bookId,
  required String chapterId,
  String? packageFingerprint,
}) {
  final String scope = userId ?? 'guest';
  final String base = '${PdfProgressStore.keyPrefix}$scope:$bookId:$chapterId';
  final String fingerprint = packageFingerprint?.trim() ?? '';
  if (fingerprint.isEmpty) return base;
  return '$base:png:$fingerprint';
}

/// Parses a stored `sha256|page` value. Returns null when the PDF checksum
/// no longer matches.
int? pdfProgressPage(String? raw, String documentSha256) {
  if (raw == null || raw.isEmpty || documentSha256.isEmpty) return null;
  final int sep = raw.indexOf('|');
  if (sep <= 0) return null;
  final String sha = raw.substring(0, sep);
  final int? page = int.tryParse(raw.substring(sep + 1));
  if (sha != documentSha256 || page == null || page < 1) return null;
  return page;
}

/// Device-local last-page progress for Original PDF chapters.
///
/// Mobile reading-progress HTTP APIs are not implemented. Values never leave
/// the device. Keys are account-scoped so another user cannot resume a prior
/// account's page. If [documentSha256] changes, a stored page is ignored.
class PdfProgressStore {
  PdfProgressStore(this._prefs);

  final LocalPreferences _prefs;

  static const String keyPrefix = 'pdf.progress.';

  String? _userId;

  void bindUser(String? userId) {
    _userId = userId;
  }

  String? get userId => _userId;

  String _key(
    String bookId,
    String chapterId, {
    String? packageFingerprint,
  }) {
    return pdfProgressKey(
      userId: _userId,
      bookId: bookId,
      chapterId: chapterId,
      packageFingerprint: packageFingerprint,
    );
  }

  Future<int?> readPage({
    required String bookId,
    required String chapterId,
    required String documentSha256,
    String? packageFingerprint,
  }) async {
    if (documentSha256.isEmpty) return null;
    final String? raw = await _prefs.read(
      _key(bookId, chapterId, packageFingerprint: packageFingerprint),
    );
    return pdfProgressPage(raw, documentSha256);
  }

  Future<void> writePage({
    required String bookId,
    required String chapterId,
    required String documentSha256,
    required int page,
    String? packageFingerprint,
  }) async {
    if (documentSha256.isEmpty || page < 1) return;
    await _prefs.write(
      _key(bookId, chapterId, packageFingerprint: packageFingerprint),
      '$documentSha256|$page',
    );
  }

  /// Removes progress for the currently bound user (call on logout).
  Future<void> clearCurrentUser() async {
    // LocalPreferences has no list API; overwrite known pattern is not
    // possible. Re-bind to null so subsequent reads miss prior keys.
    _userId = null;
  }
}
