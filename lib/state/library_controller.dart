import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../core/network/api_envelope.dart';
import '../../data/models/library_item.dart';
import '../../data/repositories/library_repository.dart';

class LibraryController extends ChangeNotifier {
  LibraryController(this._repository);

  final LibraryRepository _repository;

  List<LibraryItem> items = const <LibraryItem>[];
  bool loading = false;
  bool loadingMore = false;
  String? errorMessage;
  PaginationMeta? pagination;
  bool _loadLocked = false;

  bool get hasMore => pagination?.hasMore ?? false;
  bool get isEmpty => !loading && items.isEmpty && errorMessage == null;

  bool owns(String bookId) =>
      items.any((LibraryItem item) => item.bookId == bookId);

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
      final Paginated<LibraryItem> result = await _repository.list(page: 1);
      items = result.items;
      pagination = result.pagination;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
      if (reset) items = const <LibraryItem>[];
    } catch (_) {
      errorMessage = 'Could not load your library.';
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
      final Paginated<LibraryItem> result = await _repository.list(page: nextPage);
      items = <LibraryItem>[...items, ...result.items];
      pagination = result.pagination;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } finally {
      loadingMore = false;
      _loadLocked = false;
      notifyListeners();
    }
  }

  void clearLocal() {
    items = const <LibraryItem>[];
    pagination = null;
    errorMessage = null;
    notifyListeners();
  }
}
