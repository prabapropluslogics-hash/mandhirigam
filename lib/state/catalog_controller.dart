import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../core/network/api_envelope.dart';
import '../../data/models/catalog_book.dart';
import '../../data/repositories/books_repository.dart';
import '../../data/services/books_api.dart';

class CatalogController extends ChangeNotifier {
  CatalogController(this._repository);

  final BooksRepository _repository;

  List<CatalogBook> books = const <CatalogBook>[];
  bool loading = false;
  bool loadingMore = false;
  String? errorMessage;
  String search = '';
  String? language;
  String? accessType;
  PaginationMeta? pagination;
  bool _loadLocked = false;

  bool get hasMore => pagination?.hasMore ?? false;
  bool get isEmpty => !loading && books.isEmpty && errorMessage == null;

  Future<void> refresh() => load(reset: true);

  Future<void> load({bool reset = true}) async {
    if (_loadLocked) return;
    _loadLocked = true;
    if (reset) {
      loading = true;
      errorMessage = null;
      notifyListeners();
    }
    try {
      final Paginated<CatalogBook> result = await _repository.list(
        BookQuery(
          page: 1,
          language: language,
          accessType: accessType,
          search: search,
        ),
      );
      books = result.items;
      pagination = result.pagination;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
      if (reset) books = const <CatalogBook>[];
    } catch (_) {
      errorMessage = 'Could not load the catalogue.';
    } finally {
      loading = false;
      _loadLocked = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore || loading || _loadLocked) return;
    _loadLocked = true;
    loadingMore = true;
    notifyListeners();
    try {
      final int nextPage = (pagination?.page ?? 1) + 1;
      final Paginated<CatalogBook> result = await _repository.list(
        BookQuery(
          page: nextPage,
          language: language,
          accessType: accessType,
          search: search,
        ),
      );
      books = <CatalogBook>[...books, ...result.items];
      pagination = result.pagination;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } finally {
      loadingMore = false;
      _loadLocked = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    search = value;
  }

  Future<void> applyFilters({String? language, String? accessType}) {
    this.language = language;
    this.accessType = accessType;
    return load(reset: true);
  }
}
