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
    return _cached(_detailInFlight, id, force, () => _api.detail(id));
  }

  Future<List<ChapterSummary>> chapters(String bookId, {bool force = false}) {
    return _cached(_chaptersInFlight, bookId, force, () => _api.chapters(bookId));
  }

  Future<ChapterContent> chapterContent(
    String bookId,
    String chapterId, {
    bool force = false,
  }) {
    return _cached(
      _contentInFlight,
      '$bookId:$chapterId',
      force,
      () => _api.chapterContent(bookId, chapterId),
    );
  }

  /// Shares one request per key; failed requests are evicted so a retry
  /// actually hits the network again.
  static Future<T> _cached<T>(
    Map<String, Future<T>> cache,
    String key,
    bool force,
    Future<T> Function() fetch,
  ) {
    if (force) cache.remove(key);
    final Future<T>? existing = cache[key];
    if (existing != null) return existing;
    final Future<T> request = fetch();
    cache[key] = request;
    request.then<void>((_) {}, onError: (Object _) {
      if (identical(cache[key], request)) cache.remove(key);
    });
    return request;
  }
}
