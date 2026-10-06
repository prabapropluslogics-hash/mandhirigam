import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../core/network/api_envelope.dart';
import '../../data/models/library_item.dart';
import '../../data/repositories/library_repository.dart';

/// Active entitlements of the signed-in user. This is the app's source of
/// truth for "does the user own this paid book".
class LibraryController extends ChangeNotifier {
  LibraryController(this._repository);

  final LibraryRepository _repository;

  static const int _pageSize = 50;

  List<LibraryItem> items = const <LibraryItem>[];
  bool loading = false;
  bool loadingMore = false;
  String? errorMessage;
  PaginationMeta? pagination;

  /// True once entitlements were fetched for the current session.
  bool loaded = false;

  /// Books the backend confirmed as entitled (verify / already-owned) that may
  /// not be in [items] yet because a library refresh failed.
  final Set<String> _verifiedOwned = <String>{};
  Future<void>? _inFlight;

  bool get hasMore => pagination?.hasMore ?? false;
  bool get isEmpty => !loading && items.isEmpty && errorMessage == null;

  bool owns(String bookId) =>
      _verifiedOwned.contains(bookId) ||
      items.any((LibraryItem item) => item.bookId == bookId);

  /// Records a backend-confirmed entitlement and reloads the library.
  Future<void> recordVerifiedPurchase(String bookId) {
    _verifiedOwned.add(bookId);
    notifyListeners();
    return refresh();
  }

  Future<void> refresh() => load(reset: true);

  /// Loads every page so ownership checks are not limited to the first page.
  /// Concurrent callers share the same request.
  Future<void> load({bool reset = true}) {
    return _inFlight ??= _loadAll(reset: reset).whenComplete(() {
      _inFlight = null;
    });
  }

  Future<void> _loadAll({required bool reset}) async {
    loading = true;
    if (reset) errorMessage = null;
    notifyListeners();
    try {
      final List<LibraryItem> all = <LibraryItem>[];
      int page = 1;
      Paginated<LibraryItem> result;
      do {
        result = await _repository.list(page: page, limit: _pageSize);
        all.addAll(result.items);
        page += 1;
      } while (result.pagination.hasMore);
      items = all;
      pagination = result.pagination;
      loaded = true;
      errorMessage = null;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Could not load your library.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Kept for the library list's scroll listener; [load] already fetches all
  /// pages, so this only runs if a page was added server-side meanwhile.
  Future<void> loadMore() async {
    if (!hasMore || loadingMore || loading || _inFlight != null) return;
    loadingMore = true;
    notifyListeners();
    try {
      final int nextPage = (pagination?.page ?? 1) + 1;
      final Paginated<LibraryItem> result =
          await _repository.list(page: nextPage, limit: _pageSize);
      items = <LibraryItem>[...items, ...result.items];
      pagination = result.pagination;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  void clearLocal() {
    items = const <LibraryItem>[];
    pagination = null;
    errorMessage = null;
    loaded = false;
    _verifiedOwned.clear();
    notifyListeners();
  }
}
