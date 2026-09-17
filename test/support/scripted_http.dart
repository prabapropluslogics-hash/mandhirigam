import 'package:http/http.dart' as http;

class ScriptedHttpClient extends http.BaseClient {
  ScriptedHttpClient(this.routes);

  /// Keys are `"METHOD /path"` e.g. `"GET /api/v1/books"`.
  final Map<String, http.Response> routes;
  final List<http.BaseRequest> requests = <http.BaseRequest>[];

  int statusFor(String method, String path, {int fallback = 404}) {
    return routes['$method $path']?.statusCode ?? fallback;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final String key = '${request.method} ${request.url.path}';
    http.Response? response = routes[key];
    if (response == null) {
      for (final MapEntry<String, http.Response> entry in routes.entries) {
        if (entry.key.startsWith('${request.method} ') &&
            request.url.path.startsWith(entry.key.substring(request.method.length + 1))) {
          response = entry.value;
          break;
        }
      }
    }
    response ??= http.Response(
      '{"success":false,"error":{"code":"NOT_FOUND","message":"Missing scripted route $key"}}',
      404,
      headers: <String, String>{'content-type': 'application/json'},
    );
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[response.bodyBytes]),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }

  bool sentAuth(String method, String path) {
    return requests.any((http.BaseRequest request) {
      return request.method == method &&
          request.url.path == path &&
          request.headers['Authorization']?.startsWith('Bearer ') == true;
    });
  }
}

http.Response jsonOk(String body, {int status = 200}) {
  return http.Response(
    body,
    status,
    headers: <String, String>{'content-type': 'application/json'},
  );
}
