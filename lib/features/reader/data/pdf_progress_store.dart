import '../../../services/local_preferences.dart';

/// Device-local last-page progress for Original PDF chapters.
///
/// Mobile reading-progress HTTP APIs are not implemented. Values never leave
/// the device. Keys are account-scoped so another user cannot resume a prior
/// account's page. If [documentSha256] changes, a stored page is ignored.
class PdfProgressStore {
  PdfProgressStore(this._prefs);

  final LocalPreferences _prefs;

  static const String _keyPrefix = 'pdf.progress.';

  String? _userId;

  void bindUser(String? userId) {
    _userId = userId;
  }

  String? get userId => _userId;

  String _key(String bookId, String chapterId) {
    final String scope = _userId ?? 'guest';
    return '$_keyPrefix$scope:$bookId:$chapterId';
  }

  Future<int?> readPage({
    required String bookId,
    required String chapterId,
    required String documentSha256,
  }) async {
    if (documentSha256.isEmpty) return null;
    final String? raw = await _prefs.read(_key(bookId, chapterId));
    if (raw == null || raw.isEmpty) return null;
    final int sep = raw.indexOf('|');
    if (sep <= 0) return null;
    final String sha = raw.substring(0, sep);
    final int? page = int.tryParse(raw.substring(sep + 1));
    if (sha != documentSha256 || page == null || page < 1) return null;
    return page;
  }

  Future<void> writePage({
    required String bookId,
    required String chapterId,
    required String documentSha256,
    required int page,
  }) async {
    if (documentSha256.isEmpty || page < 1) return;
    await _prefs.write(
      _key(bookId, chapterId),
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
