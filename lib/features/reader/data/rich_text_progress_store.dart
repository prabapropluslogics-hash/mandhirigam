import '../../../services/local_preferences.dart';

String richTextProgressKey({
  required String? userId,
  required String bookId,
  required String chapterId,
}) {
  final String scope = userId ?? 'guest';
  return '${RichTextProgressStore.keyPrefix}$scope:$bookId:$chapterId';
}

/// Device-local scroll fraction (0..1) for Rich Text chapters.
///
/// HTTP reading-progress APIs are not implemented. Keys are account-scoped.
class RichTextProgressStore {
  RichTextProgressStore(this._prefs);

  final LocalPreferences _prefs;

  static const String keyPrefix = 'richtext.progress.';

  String? _userId;

  void bindUser(String? userId) {
    _userId = userId;
  }

  String? get userId => _userId;

  Future<double?> readOffset({
    required String bookId,
    required String chapterId,
  }) async {
    final String? raw = await _prefs.read(
      richTextProgressKey(
        userId: _userId,
        bookId: bookId,
        chapterId: chapterId,
      ),
    );
    if (raw == null || raw.isEmpty) return null;
    final double? value = double.tryParse(raw);
    if (value == null || value.isNaN || value < 0) return null;
    return value.clamp(0.0, 1.0);
  }

  Future<void> writeOffset({
    required String bookId,
    required String chapterId,
    required double fraction,
  }) async {
    if (fraction.isNaN) return;
    await _prefs.write(
      richTextProgressKey(
        userId: _userId,
        bookId: bookId,
        chapterId: chapterId,
      ),
      fraction.clamp(0.0, 1.0).toStringAsFixed(4),
    );
  }
}
