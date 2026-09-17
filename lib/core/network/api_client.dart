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
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final UnauthorizedHandler? onUnauthorized;
  final Future<String?> Function()? readAccessToken;

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

    try {
      final Uri uri = AppEnv.resolve(path).replace(
        queryParameters: query == null || query.isEmpty ? null : query,
      );
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
      return _parse(
        response,
        hadToken: token != null && token.isNotEmpty && auth != AuthMode.none,
      );
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

  Future<ApiEnvelope> _parse(
    http.Response response, {
    required bool hadToken,
  }) async {
    if (AppEnv.isDevelopment) {
      // ignore: avoid_print
      print(
        '[api] ${response.request?.method} ${response.request?.url.path} '
        '→ ${response.statusCode}',
      );
    }
    if (response.body.isEmpty) {
      throw ApiException(
        statusCode: response.statusCode,
        code: 'MALFORMED_RESPONSE',
        message: 'Empty response from server.',
      );
    }
    final ApiEnvelope envelope =
        ApiEnvelope.parse(response.body, response.statusCode);
    try {
      envelope.throwIfError(response.statusCode);
    } on ApiException catch (error) {
      if (hadToken && error.isUnauthorized) {
        await onUnauthorized?.call(error);
      }
      rethrow;
    }
    return envelope;
  }
}

enum AuthMode { none, optional, required }
