import '../../core/network/api_client.dart';
import '../../core/network/api_envelope.dart';
import '../../core/utils/json_map.dart';
import '../models/catalog_book.dart';
import '../models/chapter.dart';

class BookQuery {
  const BookQuery({
    this.page = 1,
    this.limit = 20,
    this.language,
    this.accessType,
    this.search,
  });

  final int page;
  final int limit;
  final String? language;
  final String? accessType;
  final String? search;

  Map<String, String> toQuery() {
    final Map<String, String> query = <String, String>{
      'page': '$page',
      'limit': '${limit.clamp(1, 50)}',
    };
    if (language != null && language!.isNotEmpty && language != 'all') {
      query['language'] = language!;
    }
    if (accessType != null && accessType!.isNotEmpty) {
      query['accessType'] = accessType!;
    }
    if (search != null && search!.trim().isNotEmpty) {
      query['search'] = search!.trim();
    }
    return query;
  }
}

class BooksApi {
  BooksApi(this._client);

  final ApiClient _client;

  Future<Paginated<CatalogBook>> list(BookQuery query) async {
    final envelope = await _client.get('/books', query: query.toQuery());
    final PaginationMeta pagination = envelope.pagination ??
        PaginationMeta(
          page: query.page,
          limit: query.limit,
          total: asJsonMapList(envelope.data).length,
          totalPages: 1,
        );
    return Paginated<CatalogBook>(
      items: asJsonMapList(envelope.data).map(CatalogBook.fromJson).toList(),
      pagination: pagination,
    );
  }

  Future<CatalogBook> detail(String id) async {
    final envelope = await _client.get('/books/$id');
    return CatalogBook.fromJson(asJsonMap(envelope.data));
  }

  Future<List<ChapterSummary>> chapters(String bookId) async {
    final envelope = await _client.get('/books/$bookId/chapters');
    final List<ChapterSummary> items =
        asJsonMapList(envelope.data).map(ChapterSummary.fromJson).toList();
    items.sort((ChapterSummary a, ChapterSummary b) {
      final int byNumber = a.chapterNumber.compareTo(b.chapterNumber);
      if (byNumber != 0) return byNumber;
      return a.id.compareTo(b.id);
    });
    return items;
  }

  Future<ChapterContent> chapterContent(String bookId, String chapterId) async {
    final envelope = await _client.getOptionalAuth(
      '/books/$bookId/chapters/$chapterId',
    );
    return ChapterContent.fromJson(asJsonMap(envelope.data));
  }
}
