import 'package:flutter_test/flutter_test.dart';
import 'package:maanthirigam/features/reader/data/pdf_progress_store.dart';
import 'package:maanthirigam/services/local_preferences.dart';

/// In-memory prefs for progress tests (no platform secure storage).
class _FakeLocalPreferences extends LocalPreferences {
  _FakeLocalPreferences() : super();

  final Map<String, String> map = <String, String>{};

  @override
  Future<String?> read(String key) async => map[key];

  @override
  Future<void> write(String key, String value) async {
    map[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    map.remove(key);
  }
}

void main() {
  test('progress is account and sha scoped', () async {
    final _FakeLocalPreferences prefs = _FakeLocalPreferences();
    final PdfProgressStore store = PdfProgressStore(prefs);

    store.bindUser('user-a');
    await store.writePage(
      bookId: 'b1',
      chapterId: 'c1',
      documentSha256: 'sha-1',
      page: 7,
    );
    expect(
      await store.readPage(
        bookId: 'b1',
        chapterId: 'c1',
        documentSha256: 'sha-1',
      ),
      7,
    );
    expect(
      await store.readPage(
        bookId: 'b1',
        chapterId: 'c1',
        documentSha256: 'sha-other',
      ),
      isNull,
    );

    store.bindUser('user-b');
    expect(
      await store.readPage(
        bookId: 'b1',
        chapterId: 'c1',
        documentSha256: 'sha-1',
      ),
      isNull,
    );
  });
}
