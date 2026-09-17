import '../../core/network/api_client.dart';
import '../../core/network/api_envelope.dart';
import '../../core/utils/json_map.dart';
import '../models/library_item.dart';

class LibraryApi {
  LibraryApi(this._client);

  final ApiClient _client;

  Future<Paginated<LibraryItem>> list({int page = 1, int limit = 20}) async {
    final envelope = await _client.getAuthorized(
      '/library',
      query: <String, String>{
        'page': '$page',
        'limit': '${limit.clamp(1, 50)}',
      },
    );
    final PaginationMeta pagination = envelope.pagination ??
        PaginationMeta(
          page: page,
          limit: limit,
          total: asJsonMapList(envelope.data).length,
          totalPages: 1,
        );
    return Paginated<LibraryItem>(
      items: asJsonMapList(envelope.data).map(LibraryItem.fromJson).toList(),
      pagination: pagination,
    );
  }
}
