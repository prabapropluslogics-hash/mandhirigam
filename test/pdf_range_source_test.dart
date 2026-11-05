import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:maanthirigam/core/errors/api_exception.dart';
import 'package:maanthirigam/core/network/api_client.dart';
import 'package:maanthirigam/data/models/chapter.dart';
import 'package:maanthirigam/data/services/authenticated_pdf_range_source.dart';

const String _bookId = 'bookpdf001';
const String _chapterId = 'chpdf001';
const String _path = '/api/v1/books/$_bookId/chapters/$_chapterId/document';

ChapterDocument _doc({int size = 20, String sha = 'checksum'}) {
  return ChapterDocument(
    mediaId: 'media1',
    fileName: 'original-book.pdf',
    mimeType: 'application/pdf',
    size: size,
    pageCount: 3,
    sha256: sha,
    downloadPath: '/books/$_bookId/chapters/$_chapterId/document',
  );
}

class _RangeBackend extends http.BaseClient {
  _RangeBackend({
    Uint8List? payload,
    this.status = 206,
    this.forceForbidden = false,
    this.forceNotFound = false,
    this.forceUnauthorizedOnce = false,
    this.forceInvalidRange = false,
    this.forceNetworkError = false,
    this.wrongTotal,
    this.wrongRangeStart,
    this.omitContentRange = false,
  }) : payload =
            payload ?? Uint8List.fromList(List<int>.generate(20, (int i) => i));

  final Uint8List payload;
  final int status;
  final bool forceForbidden;
  final bool forceNotFound;
  final bool forceUnauthorizedOnce;
  final bool forceInvalidRange;
  final bool forceNetworkError;
  final int? wrongTotal;
  final int? wrongRangeStart;
  final bool omitContentRange;
  bool _unauthorizedUsed = false;
  final List<http.BaseRequest> requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    expect(request.url.query, isEmpty);
    expect(request.url.toString().contains('Bearer'), isFalse);

    if (forceNetworkError) {
      throw const SocketException('Network unreachable');
    }
    if (forceNotFound) {
      return _json(404, 'NOT_FOUND', 'gone');
    }
    if (forceForbidden) {
      return _json(403, 'PURCHASE_REQUIRED', 'buy');
    }
    if (forceUnauthorizedOnce && !_unauthorizedUsed) {
      _unauthorizedUsed = true;
      return _json(401, 'TOKEN_EXPIRED', 'expired');
    }
    if (forceInvalidRange) {
      return _json(416, 'INVALID_RANGE', 'bad range');
    }

    final String? range = request.headers['Range'];
    expect(range, isNotNull);
    final Match match = RegExp(r'bytes=(\d+)-(\d+)').firstMatch(range!)!;
    final int start = int.parse(match.group(1)!);
    final int end = int.parse(match.group(2)!);
    final int total = wrongTotal ?? payload.length;

    if (status == 200) {
      // Validated full-body 200: client may slice the requested window.
      final Map<String, String> headers = <String, String>{
        'content-type': 'application/pdf',
        'accept-ranges': 'bytes',
        'cache-control': 'private, no-store',
        'content-length': '${payload.length}',
      };
      return http.StreamedResponse(
        Stream<List<int>>.fromIterable(<List<int>>[payload]),
        200,
        headers: headers,
        request: request,
      );
    }

    final Uint8List slice = Uint8List.sublistView(payload, start, end + 1);
    final Map<String, String> headers = <String, String>{
      'content-type': 'application/pdf',
      'accept-ranges': 'bytes',
      'cache-control': 'private, no-store',
      'content-length': '${slice.length}',
    };
    if (!omitContentRange) {
      final int reportedStart = wrongRangeStart ?? start;
      headers['content-range'] = 'bytes $reportedStart-$end/$total';
    }
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[slice]),
      status,
      headers: headers,
      request: request,
    );
  }

  http.StreamedResponse _json(int code, String err, String message) {
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[
        '{"success":false,"error":{"code":"$err","message":"$message"}}'
            .codeUnits,
      ]),
      code,
      headers: <String, String>{'content-type': 'application/json'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthenticatedPdfRangeSource', () {
    test('sends Bearer only in Authorization and reads 206 ranges', () async {
      final _RangeBackend httpClient = _RangeBackend();
      String? token = 'access-1';
      final ApiClient client = ApiClient(
        httpClient: httpClient,
        readAccessToken: () async => token,
        refreshAccessToken: () async => 'access-2',
      );
      final AuthenticatedPdfRangeSource source = AuthenticatedPdfRangeSource(
        client: client,
        document: _doc(),
        bookId: _bookId,
        chapterId: _chapterId,
      );

      final Uint8List buffer = Uint8List(4);
      final int read = await source.read(buffer, 2, 4);
      expect(read, 4);
      expect(buffer, <int>[2, 3, 4, 5]);
      expect(httpClient.requests, hasLength(1));
      final http.BaseRequest req = httpClient.requests.single;
      expect(req.url.path, _path);
      expect(req.headers['Authorization'], 'Bearer access-1');
      expect(req.headers['Range'], 'bytes=2-5');
      expect(req.url.queryParameters.containsKey('access_token'), isFalse);
      expect(req.url.queryParameters.containsKey('token'), isFalse);
      source.dispose();
    });

    test('sourceName embeds the document sha256 for Range identity', () {
      const String checksum =
          'd9d6ebfaea32e221e9a4465980e4cd7feaee8a45dd186d3e8001eb1199d95231';
      final AuthenticatedPdfRangeSource source = AuthenticatedPdfRangeSource(
        client: ApiClient(
          httpClient: _RangeBackend(),
          readAccessToken: () async => 't',
        ),
        document: _doc(sha: checksum),
        bookId: _bookId,
        chapterId: _chapterId,
      );
      expect(
        source.sourceName,
        'chapter-pdf:$_bookId:$_chapterId:$checksum:20',
      );
      expect(source.apiPath, '/books/$_bookId/chapters/$_chapterId/document');
      source.dispose();
    });

    test('multiple range reads keep correct offsets', () async {
      final _RangeBackend httpClient = _RangeBackend();
      final ApiClient client = ApiClient(
        httpClient: httpClient,
        readAccessToken: () async => 't',
      );
      final AuthenticatedPdfRangeSource source = AuthenticatedPdfRangeSource(
        client: client,
        document: _doc(),
        bookId: _bookId,
        chapterId: _chapterId,
      );
      final Uint8List a = Uint8List(3);
      final Uint8List b = Uint8List(3);
      expect(await source.read(a, 0, 3), 3);
      expect(await source.read(b, 10, 3), 3);
      expect(a, <int>[0, 1, 2]);
      expect(b, <int>[10, 11, 12]);
      expect(httpClient.requests[0].headers['Range'], 'bytes=0-2');
      expect(httpClient.requests[1].headers['Range'], 'bytes=10-12');
    });

    test('401 refreshes once and retries the same range', () async {
      final _RangeBackend httpClient =
          _RangeBackend(forceUnauthorizedOnce: true);
      String token = 'old';
      int refreshCalls = 0;
      final ApiClient client = ApiClient(
        httpClient: httpClient,
        readAccessToken: () async => token,
        refreshAccessToken: () async {
          refreshCalls++;
          token = 'fresh';
          return token;
        },
      );
      final AuthenticatedPdfRangeSource source = AuthenticatedPdfRangeSource(
        client: client,
        document: _doc(),
        bookId: _bookId,
        chapterId: _chapterId,
      );
      final Uint8List buffer = Uint8List(2);
      expect(await source.read(buffer, 0, 2), 2);
      expect(refreshCalls, 1);
      expect(httpClient.requests, hasLength(2));
      expect(httpClient.requests[0].headers['Range'], 'bytes=0-1');
      expect(httpClient.requests[1].headers['Range'], 'bytes=0-1');
      expect(httpClient.requests[1].headers['Authorization'], 'Bearer fresh');
    });

    test('403 surfaces purchase/forbidden without retry loop', () async {
      final _RangeBackend httpClient = _RangeBackend(forceForbidden: true);
      int refreshCalls = 0;
      final ApiClient client = ApiClient(
        httpClient: httpClient,
        readAccessToken: () async => 't',
        refreshAccessToken: () async {
          refreshCalls++;
          return 't2';
        },
      );
      final AuthenticatedPdfRangeSource source = AuthenticatedPdfRangeSource(
        client: client,
        document: _doc(),
        bookId: _bookId,
        chapterId: _chapterId,
      );
      await expectLater(
        source.read(Uint8List(2), 0, 2),
        throwsA(isA<ApiException>().having(
          (ApiException e) => e.isForbidden || e.isPurchaseRequired,
          'forbidden',
          isTrue,
        )),
      );
      expect(refreshCalls, 0);
      expect(httpClient.requests, hasLength(1));
    });

    test('404 and 416 map to ApiException', () async {
      final ApiClient missing = ApiClient(
        httpClient: _RangeBackend(forceNotFound: true),
        readAccessToken: () async => 't',
      );
      await expectLater(
        AuthenticatedPdfRangeSource(
          client: missing,
          document: _doc(),
          bookId: _bookId,
          chapterId: _chapterId,
        ).read(Uint8List(1), 0, 1),
        throwsA(isA<ApiException>().having(
          (ApiException e) => e.isNotFound,
          'notFound',
          isTrue,
        )),
      );

      final ApiClient range = ApiClient(
        httpClient: _RangeBackend(forceInvalidRange: true),
        readAccessToken: () async => 't',
      );
      await expectLater(
        AuthenticatedPdfRangeSource(
          client: range,
          document: _doc(),
          bookId: _bookId,
          chapterId: _chapterId,
        ).read(Uint8List(1), 0, 1),
        throwsA(isA<ApiException>().having(
          (ApiException e) => e.statusCode,
          'status',
          416,
        )),
      );
    });

    test('size mismatch on Content-Range total is rejected', () async {
      final ApiClient client = ApiClient(
        httpClient: _RangeBackend(wrongTotal: 999),
        readAccessToken: () async => 't',
      );
      await expectLater(
        AuthenticatedPdfRangeSource(
          client: client,
          document: _doc(),
          bookId: _bookId,
          chapterId: _chapterId,
        ).read(Uint8List(2), 0, 2),
        throwsA(isA<ApiException>().having(
          (ApiException e) => e.code,
          'code',
          'DOCUMENT_SIZE_MISMATCH',
        )),
      );
    });

    test('disposed source cancels further reads', () async {
      final ApiClient client = ApiClient(
        httpClient: _RangeBackend(),
        readAccessToken: () async => 't',
      );
      final AuthenticatedPdfRangeSource source = AuthenticatedPdfRangeSource(
        client: client,
        document: _doc(),
        bookId: _bookId,
        chapterId: _chapterId,
      );
      source.dispose();
      await expectLater(
        source.read(Uint8List(1), 0, 1),
        throwsA(isA<ApiException>().having(
          (ApiException e) => e.code,
          'code',
          'CANCELLED',
        )),
      );
    });

    test('apiRelativePath never doubles /api/v1', () {
      const ChapterDocument withPrefix = ChapterDocument(
        mediaId: 'm',
        fileName: 'a.pdf',
        mimeType: 'application/pdf',
        size: 10,
        pageCount: 1,
        sha256: 's',
        downloadPath: '/api/v1/books/$_bookId/chapters/$_chapterId/document',
      );
      expect(withPrefix.apiRelativePath,
          '/books/$_bookId/chapters/$_chapterId/document');
      final Uri resolved = Uri.parse(
        'https://api.example.com/api/v1${withPrefix.apiRelativePath}',
      );
      expect(resolved.path.contains('/api/v1/api/v1'), isFalse);
    });

    test('validated 200 full-body response is sliced to the requested range',
        () async {
      final ApiClient client = ApiClient(
        httpClient: _RangeBackend(status: 200),
        readAccessToken: () async => 't',
      );
      final AuthenticatedPdfRangeSource source = AuthenticatedPdfRangeSource(
        client: client,
        document: _doc(),
        bookId: _bookId,
        chapterId: _chapterId,
      );
      final Uint8List buffer = Uint8List(4);
      expect(await source.read(buffer, 4, 4), 4);
      expect(buffer, <int>[4, 5, 6, 7]);
    });

    test('incorrect Content-Range start is rejected', () async {
      final ApiClient client = ApiClient(
        // Requested 0-2, but server claims the window starts at 1.
        httpClient: _RangeBackend(wrongRangeStart: 1),
        readAccessToken: () async => 't',
      );
      await expectLater(
        AuthenticatedPdfRangeSource(
          client: client,
          document: _doc(),
          bookId: _bookId,
          chapterId: _chapterId,
        ).read(Uint8List(3), 0, 3),
        throwsA(isA<ApiException>().having(
          (ApiException e) => e.code,
          'code',
          'MALFORMED_RESPONSE',
        )),
      );
    });

    test('missing Content-Range on 206 is rejected', () async {
      final ApiClient client = ApiClient(
        httpClient: _RangeBackend(omitContentRange: true),
        readAccessToken: () async => 't',
      );
      await expectLater(
        AuthenticatedPdfRangeSource(
          client: client,
          document: _doc(),
          bookId: _bookId,
          chapterId: _chapterId,
        ).read(Uint8List(2), 0, 2),
        throwsA(isA<ApiException>().having(
          (ApiException e) => e.code,
          'code',
          'MALFORMED_RESPONSE',
        )),
      );
    });

    test('network failure maps to NetworkException', () async {
      final ApiClient client = ApiClient(
        httpClient: _RangeBackend(forceNetworkError: true),
        readAccessToken: () async => 't',
      );
      await expectLater(
        AuthenticatedPdfRangeSource(
          client: client,
          document: _doc(),
          bookId: _bookId,
          chapterId: _chapterId,
        ).read(Uint8List(2), 0, 2),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
