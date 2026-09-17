import '../../core/network/api_envelope.dart';
import '../models/library_item.dart';
import '../services/library_api.dart';

class LibraryRepository {
  LibraryRepository(this._api);

  final LibraryApi _api;

  Future<Paginated<LibraryItem>> list({int page = 1, int limit = 20}) {
    return _api.list(page: page, limit: limit);
  }
}
