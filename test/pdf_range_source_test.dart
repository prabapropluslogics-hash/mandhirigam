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
    this.shortenEndBy = 0,
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
  final int shortenEndBy;
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

    final int actualEnd =
        shortenEndBy > 0 ? (end - shortenEndBy).clamp(start, end) : end;
    final Uint8List slice =
        Uint8List.sublistView(payload, start, actualEnd + 1);
    final Map<String, String> headers = <String, String>{
      'content-type': 'application/pdf',
      'accept-ranges': 'bytes',
      'cache-control': 'private, no-store',
      'content-length': '${slice.length}',
    };
    if (!omitContentRange) {
      final int reportedStart = wrongRangeStart ?? start;
      headers['content-range'] = 'bytes $reportedStart-$actualEnd/$total';
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
      // Must return 0 (not throw): pdfrx FileAccess treats thrown -1 as success.
      expect(await source.read(Uint8List(2), 0, 2), 0);
      expect(source.lastError, isA<ApiException>());
      expect(
        (source.lastError! as ApiException).isForbidden ||
            (source.lastError! as ApiException).isPurchaseRequired,
        isTrue,
      );
      expect(refreshCalls, 0);
      expect(httpClient.requests, hasLength(1));
    });

    test('404 and 416 map to lastError without throwing into PDFium', () async {
      final ApiClient missing = ApiClient(
        httpClient: _RangeBackend(forceNotFound: true),
        readAccessToken: () async => 't',
      );
      final AuthenticatedPdfRangeSource missingSource =
          AuthenticatedPdfRangeSource(
        client: missing,
        document: _doc(),
        bookId: _bookId,
        chapterId: _chapterId,
      );
      expect(await missingSource.read(Uint8List(1), 0, 1), 0);
      expect((missingSource.lastError! as ApiException).isNotFound, isTrue);

      final ApiClient range = ApiClient(
        httpClient: _RangeBackend(forceInvalidRange: true),
        readAccessToken: () async => 't',
      );
      final AuthenticatedPdfRangeSource rangeSource =
          AuthenticatedPdfRangeSource(
        client: range,
        document: _doc(),
        bookId: _bookId,
        chapterId: _chapterId,
      );
      expect(await rangeSource.read(Uint8List(1), 0, 1), 0);
      expect((rangeSource.lastError! as ApiException).statusCode, 416);
    });

    test('size mismatch on Content-Range total is rejected', () async {
      final ApiClient client = ApiClient(
        httpClient: _RangeBackend(wrongTotal: 999),
        readAccessToken: () async => 't',
      );
      final AuthenticatedPdfRangeSource source = AuthenticatedPdfRangeSource(
        client: client,
        document: _doc(),
        bookId: _bookId,
        chapterId: _chapterId,
      );
      expect(await source.read(Uint8List(2), 0, 2), 0);
      expect((source.lastError! as ApiException).code, 'DOCUMENT_SIZE_MISMATCH');
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
      expect(await source.read(Uint8List(1), 0, 1), 0);
      expect((source.lastError! as ApiException).code, 'CANCELLED');
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
      final AuthenticatedPdfRangeSource source = AuthenticatedPdfRangeSource(
        client: client,
        document: _doc(),
        bookId: _bookId,
        chapterId: _chapterId,
      );
      expect(await source.read(Uint8List(3), 0, 3), 0);
      expect((source.lastError! as ApiException).code, 'MALFORMED_RESPONSE');
    });

    test('missing Content-Range on 206 is rejected', () async {
      final ApiClient client = ApiClient(
        httpClient: _RangeBackend(omitContentRange: true),
        readAccessToken: () async => 't',
      );
      final AuthenticatedPdfRangeSource source = AuthenticatedPdfRangeSource(
        client: client,
        document: _doc(),
        bookId: _bookId,
        chapterId: _chapterId,
      );
      expect(await source.read(Uint8List(2), 0, 2), 0);
      expect((source.lastError! as ApiException).code, 'MALFORMED_RESPONSE');
    });

    test('network failure maps to NetworkException on lastError', () async {
      final ApiClient client = ApiClient(
        httpClient: _RangeBackend(forceNetworkError: true),
        readAccessToken: () async => 't',
      );
      final AuthenticatedPdfRangeSource source = AuthenticatedPdfRangeSource(
        client: client,
        document: _doc(),
        bookId: _bookId,
        chapterId: _chapterId,
      );
      expect(await source.read(Uint8List(2), 0, 2), 0);
      expect(source.lastError, isA<NetworkException>());
    });

    test('First Temp Book fixture: full document metadata + chunked open read',
        () async {
      // Production First Temp Book By Developer chapter document.
      const String bookId = '6ae9f5bd360a5bdcd2e7307e';
      const String chapterId = '6aea182e76bf708b45cc5f45';
      const String sha =
          'd9d6ebfaea32e221e9a4465980e4cd7feaee8a45dd186d3e8001eb1199d95231';
      const int size = 5380261;

      final ChapterContent chapter = ChapterContent.fromJson(<String, dynamic>{
        'id': chapterId,
        'bookId': bookId,
        'chapterNumber': 1,
        'title': 'This is Sample Chapter',
        'contentFormat': 'RICH_TEXT',
        'readerMode': 'ORIGINAL_PDF',
        'status': 'PUBLISHED',
        'document': <String, dynamic>{
          'mediaId': '6aea183376bf708b45cc5f5b',
          'fileName': '_ _ __260823_184815.pdf',
          'mimeType': 'application/pdf',
          'size': size,
          'pageCount': 33,
          'sha256': sha,
          'downloadPath':
              '/api/v1/books/$bookId/chapters/$chapterId/document',
        },
      });
      expect(chapter.pdfOpenError(), isNull);
      expect(chapter.document!.sha256, sha);
      expect(chapter.document!.size, size);

      // Synthetic PDF bytes: real %PDF header + deterministic payload.
      final Uint8List payload = Uint8List(size);
      payload.setAll(0, '%PDF-1.7'.codeUnits);
      for (int i = 8; i < size; i++) {
        payload[i] = i & 0xff;
      }

      final _RangeBackend httpClient = _RangeBackend(payload: payload);
      final AuthenticatedPdfRangeSource source = AuthenticatedPdfRangeSource(
        client: ApiClient(
          httpClient: httpClient,
          readAccessToken: () async => 't',
        ),
        document: chapter.document!,
        bookId: bookId,
        chapterId: chapterId,
      );

      // Memory-open path asks for the entire file once; source chunks it.
      final Uint8List buffer = Uint8List(size);
      expect(await source.read(buffer, 0, size), size);
      expect(buffer.sublist(0, 8), '%PDF-1.7'.codeUnits);
      expect(buffer[1000], 1000 & 0xff);
      expect(source.rangeRequestCount, greaterThan(1));
      expect(
        source.rangeRequestCount,
        (size / AuthenticatedPdfRangeSource.rangeChunkBytes).ceil(),
      );
      expect(httpClient.requests.first.headers['Range'], 'bytes=0-262143');
      expect(
        httpClient.requests.last.headers['Range'],
        'bytes=${(source.rangeRequestCount - 1) * AuthenticatedPdfRangeSource.rangeChunkBytes}-${size - 1}',
      );
      // Working Thandhrigam book shares the same checksum/size; identity differs.
      expect(
        source.sourceName,
        'chapter-pdf:$bookId:$chapterId:$sha:$size',
      );
      expect(
        source.sourceName,
        isNot(
          'chapter-pdf:6aead7cd76bf708b45cc60ab:6aead7f676bf708b45cc60de:$sha:$size',
        ),
      );
      source.dispose();
    });

    test('early Content-Range end is rejected (incomplete GetBlock window)',
        () async {
      final ApiClient client = ApiClient(
        httpClient: _RangeBackend(shortenEndBy: 4),
        readAccessToken: () async => 't',
      );
      final AuthenticatedPdfRangeSource source = AuthenticatedPdfRangeSource(
        client: client,
        document: _doc(),
        bookId: _bookId,
        chapterId: _chapterId,
      );
      expect(await source.read(Uint8List(8), 0, 8), 0);
      expect((source.lastError! as ApiException).code, 'MALFORMED_RESPONSE');
    });
  });
}
