import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../errors/api_exception.dart';
import 'api_envelope.dart';

typedef UnauthorizedHandler = Future<void> Function(ApiException error);

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this.onUnauthorized,
    this.readAccessToken,
    this.refreshAccessToken,
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final UnauthorizedHandler? onUnauthorized;
  final Future<String?> Function()? readAccessToken;

  /// Called once when a request with a token gets a 401; a non-empty result
  /// is used to retry that request.
  final Future<String?> Function()? refreshAccessToken;

  static const Duration _timeout = Duration(seconds: 20);

  Future<ApiEnvelope> get(
    String path, {
    Map<String, String>? query,
  }) {
    return send('GET', path, query: query, auth: AuthMode.none);
  }

  Future<ApiEnvelope> post(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return send('POST', path, body: body, auth: AuthMode.none);
  }

  Future<ApiEnvelope> getAuthorized(
    String path, {
    Map<String, String>? query,
  }) {
    return send('GET', path, query: query, auth: AuthMode.required);
  }

  Future<ApiEnvelope> postAuthorized(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return send('POST', path, body: body, auth: AuthMode.required);
  }

  Future<ApiEnvelope> getOptionalAuth(
    String path, {
    Map<String, String>? query,
  }) {
    return send('GET', path, query: query, auth: AuthMode.optional);
  }

  Future<ApiEnvelope> send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    AuthMode auth = AuthMode.none,
  }) async {
    final String? token = await readAccessToken?.call();
    if (auth == AuthMode.required && (token == null || token.isEmpty)) {
      const ApiException error = ApiException(
        statusCode: 401,
        code: 'UNAUTHENTICATED',
        message: 'Sign in required.',
      );
      await onUnauthorized?.call(error);
      throw error;
    }

    final bool sendsToken = auth != AuthMode.none && token != null && token.isNotEmpty;
    try {
      return await _sendOnce(method, path, query: query, body: body, auth: auth, token: token);
    } on ApiException catch (error) {
      if (!sendsToken || !error.isUnauthorized) rethrow;
      final String? fresh = await refreshAccessToken?.call();
      if (fresh != null && fresh.isNotEmpty && fresh != token) {
        try {
          return await _sendOnce(method, path, query: query, body: body, auth: auth, token: fresh);
        } on ApiException catch (retryError) {
          if (retryError.isUnauthorized) await onUnauthorized?.call(retryError);
          rethrow;
        }
      }
      await onUnauthorized?.call(error);
      rethrow;
    }
  }

  Future<ApiEnvelope> _sendOnce(
    String method,
    String path, {
    required Map<String, String>? query,
    required Map<String, dynamic>? body,
    required AuthMode auth,
    required String? token,
  }) async {
    try {
      final Uri uri = AppEnv.resolve(path).replace(
        queryParameters: query == null || query.isEmpty ? null : query,
      );
      if (AppEnv.isDevelopment) {
        // ignore: avoid_print
        print('[api] → $method $uri');
      }
      final http.Request request = http.Request(method, uri);
      request.headers['Accept'] = 'application/json';
      if (auth != AuthMode.none && token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final http.StreamedResponse streamed =
          await _http.send(request).timeout(_timeout);
      final http.Response response = await http.Response.fromStream(streamed);
      return _parse(response);
    } on TimeoutException {
      throw const TimeoutApiException();
    } on SocketException {
      throw const NetworkException();
    } on HttpException {
      throw const NetworkException();
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException(
        statusCode: 0,
        code: 'MALFORMED_RESPONSE',
        message: 'Unexpected response from server.',
      );
    }
  }

  ApiEnvelope _parse(http.Response response) {
    if (response.body.isEmpty) {
      throw ApiException(
        statusCode: response.statusCode,
        code: 'MALFORMED_RESPONSE',
        message: 'Empty response from server.',
      );
    }
    final ApiEnvelope envelope =
        ApiEnvelope.parse(response.body, response.statusCode);
    if (AppEnv.isDevelopment) {
      // ignore: avoid_print
      print(
        '[api] ${response.request?.method} ${response.request?.url.path} '
        '→ ${response.statusCode}'
        '${envelope.errorCode == null ? '' : ' ${envelope.errorCode}'}',
      );
    }
    envelope.throwIfError(response.statusCode);
    return envelope;
  }
}

enum AuthMode { none, optional, required }
