import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../../data/models/transparent_pages.dart';
import 'transparent_page_bytes.dart';

/// Downloads one protected PNG. Concurrent calls for the same page share
/// one request. Bytes are not written to disk.
class TransparentPageClient {
  TransparentPageClient(this._api);

  final ApiClient _api;
  final Map<String, Future<Uint8List>> _inflight =
      <String, Future<Uint8List>>{};

  /// [scope] is account, book, chapter, and package. It must not contain a token.
  Future<Uint8List> fetch({
    required String scope,
    required TransparentPage page,
  }) {
    final String key = '$scope:${page.pageNumber}';
    final Future<Uint8List>? existing = _inflight[key];
    if (existing != null) return existing;
    final Future<Uint8List> created = _download(page);
    _inflight[key] = created;
    return created.whenComplete(() {
      if (identical(_inflight[key], created)) {
        _inflight.remove(key);
      }
    });
  }

  void clear() {
    _inflight.clear();
  }

  Future<Uint8List> _download(TransparentPage page) async {
    final ProtectedHttpBody response =
        await _api.getProtectedBody(page.apiRelativePath);
    verifyTransparentPageBytes(
      page: page,
      bytes: response.bytes,
      contentType: response.contentType,
      contentLengthHeader: response.contentLength,
      statusCode: response.statusCode,
    );
    return response.bytes;
  }
}
