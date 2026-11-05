import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:maanthirigam/core/errors/api_exception.dart';
import 'package:maanthirigam/core/network/api_client.dart';
import 'package:maanthirigam/data/services/chapter_media_loader.dart';

import 'support/scripted_http.dart';

/// 1×1 PNG.
final Uint8List _png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
);

const String _mediaId = '507f1f77bcf86cd799439011';

void main() {
  test('loads chapter media with Bearer and never puts the token in the URL',
      () async {
    String? token = 'user-jwt';
    final ScriptedHttpClient httpClient =
        ScriptedHttpClient(<String, http.Response>{
      'GET /api/v1/media/$_mediaId': http.Response.bytes(
        _png,
        200,
        headers: <String, String>{'content-type': 'image/png'},
      ),
    });
    final ApiClient api = ApiClient(
      httpClient: httpClient,
      readAccessToken: () async => token,
    );
    final ChapterMediaLoader loader = ChapterMediaLoader(api);
    loader.bindUser('u1');

    final Uint8List bytes = await loader.load(_mediaId);
    expect(bytes, _png);
    expect(httpClient.sentAuth('GET', '/api/v1/media/$_mediaId'), isTrue);
    final http.BaseRequest request = httpClient.requests.single;
    expect(request.url.query, isEmpty);
    expect(request.url.toString().contains('user-jwt'), isFalse);
    expect(request.url.toString().contains('token='), isFalse);

    // Second load is memory-only.
    await loader.load(_mediaId);
    expect(httpClient.requests, hasLength(1));
  });

  test('403 does not expose image bytes and is not cached', () async {
    final ScriptedHttpClient httpClient =
        ScriptedHttpClient(<String, http.Response>{
      'GET /api/v1/media/$_mediaId': jsonOk(
        '{"success":false,"error":{"code":"PURCHASE_REQUIRED","message":"Buy"}}',
        status: 403,
      ),
    });
    final ChapterMediaLoader loader = ChapterMediaLoader(
      ApiClient(
        httpClient: httpClient,
        readAccessToken: () async => 'user-jwt',
      ),
    );

    await expectLater(
      loader.load(_mediaId),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.isForbidden,
          'forbidden',
          isTrue,
        ),
      ),
    );

    // Retry still hits the network (nothing cached).
    await expectLater(loader.load(_mediaId), throwsA(isA<ApiException>()));
    expect(httpClient.requests, hasLength(2));
  });

  test('logout / account change clears the memory cache', () async {
    final ScriptedHttpClient httpClient =
        ScriptedHttpClient(<String, http.Response>{
      'GET /api/v1/media/$_mediaId': http.Response.bytes(
        _png,
        200,
        headers: <String, String>{'content-type': 'image/png'},
      ),
    });
    final ChapterMediaLoader loader = ChapterMediaLoader(
      ApiClient(
        httpClient: httpClient,
        readAccessToken: () async => 'user-jwt',
      ),
    );
    loader.bindUser('u1');
    await loader.load(_mediaId);
    expect(httpClient.requests, hasLength(1));

    loader.bindUser('u2');
    await loader.load(_mediaId);
    expect(httpClient.requests, hasLength(2));

    loader.clear();
    await loader.load(_mediaId);
    expect(httpClient.requests, hasLength(3));
  });

  test('404 produces NOT_FOUND', () async {
    final ScriptedHttpClient httpClient =
        ScriptedHttpClient(<String, http.Response>{
      'GET /api/v1/media/$_mediaId': jsonOk(
        '{"success":false,"error":{"code":"NOT_FOUND","message":"Gone"}}',
        status: 404,
      ),
    });
    final ChapterMediaLoader loader = ChapterMediaLoader(
      ApiClient(httpClient: httpClient),
    );
    await expectLater(
      loader.load(_mediaId),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.isNotFound,
          'not found',
          isTrue,
        ),
      ),
    );
  });
}
