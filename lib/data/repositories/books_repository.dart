import '../../core/network/api_envelope.dart';
import '../models/catalog_book.dart';
import '../models/chapter.dart';
import '../services/books_api.dart';

class BooksRepository {
  BooksRepository(this._api);

  final BooksApi _api;
  final Map<String, Future<CatalogBook>> _detailInFlight = <String, Future<CatalogBook>>{};
  final Map<String, Future<List<ChapterSummary>>> _chaptersInFlight =
      <String, Future<List<ChapterSummary>>>{};
  final Map<String, Future<ChapterContent>> _contentInFlight =
      <String, Future<ChapterContent>>{};

  Future<Paginated<CatalogBook>> list(BookQuery query) => _api.list(query);

  Future<CatalogBook> detail(String id, {bool force = false}) {
    if (force) {
      _detailInFlight.remove(id);
    }
    return _detailInFlight[id] ??= _api.detail(id);
  }

  Future<List<ChapterSummary>> chapters(String bookId, {bool force = false}) {
    if (force) {
      _chaptersInFlight.remove(bookId);
    }
    return _chaptersInFlight[bookId] ??= _api.chapters(bookId);
  }

  Future<ChapterContent> chapterContent(
    String bookId,
    String chapterId, {
    bool force = false,
  }) {
    final String key = '$bookId:$chapterId';
    if (force) {
      _contentInFlight.remove(key);
    }
    return _contentInFlight[key] ??= _api.chapterContent(bookId, chapterId);
  }
}
