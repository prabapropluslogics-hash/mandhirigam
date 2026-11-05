import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../errors/api_exception.dart';
import 'api_envelope.dart';
import 'byte_range_response.dart';

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
  static const Duration _rangeTimeout = Duration(seconds: 45);

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

  /// Raw image/media bytes with optional Bearer auth (never put the token
  /// in the URL). Uses the same one-shot refresh path as [send].
  Future<Uint8List> getMediaBytes(
    String path, {
    AuthMode auth = AuthMode.optional,
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
    final bool sendsToken =
        auth != AuthMode.none && token != null && token.isNotEmpty;
    try {
      return await _sendBytesOnce(path, auth: auth, token: token);
    } on ApiException catch (error) {
      if (!sendsToken || !error.isUnauthorized) rethrow;
      final String? fresh = await refreshAccessToken?.call();
      if (fresh != null && fresh.isNotEmpty && fresh != token) {
        try {
          return await _sendBytesOnce(path, auth: auth, token: fresh);
        } on ApiException catch (retryError) {
          if (retryError.isUnauthorized) await onUnauthorized?.call(retryError);
          rethrow;
        }
      }
      await onUnauthorized?.call(error);
      rethrow;
    }
  }

  /// Authenticated `Range: bytes=start-end` GET for original PDF streaming.
  ///
  /// Token is only sent in the Authorization header. Uses the same single
  /// refresh-and-retry path as other authorized calls. Never loops.
  Future<ByteRangeResponse> getByteRange(
    String path, {
    required int start,
    required int endInclusive,
    int? expectedTotalSize,
    AuthMode auth = AuthMode.required,
  }) async {
    if (start < 0 || endInclusive < start) {
      throw const ApiException(
        statusCode: 416,
        code: 'INVALID_RANGE',
        message: 'Invalid byte range.',
      );
    }
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
    final bool sendsToken =
        auth != AuthMode.none && token != null && token.isNotEmpty;
    try {
      return await _sendByteRangeOnce(
        path,
        start: start,
        endInclusive: endInclusive,
        expectedTotalSize: expectedTotalSize,
        auth: auth,
        token: token,
      );
    } on ApiException catch (error) {
      if (!sendsToken || !error.isUnauthorized) rethrow;
      final String? fresh = await refreshAccessToken?.call();
      if (fresh != null && fresh.isNotEmpty && fresh != token) {
        try {
          return await _sendByteRangeOnce(
            path,
            start: start,
            endInclusive: endInclusive,
            expectedTotalSize: expectedTotalSize,
            auth: auth,
            token: fresh,
          );
        } on ApiException catch (retryError) {
          if (retryError.isUnauthorized) await onUnauthorized?.call(retryError);
          rethrow;
        }
      }
      await onUnauthorized?.call(error);
      rethrow;
    }
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

    final bool sendsToken =
        auth != AuthMode.none && token != null && token.isNotEmpty;
    try {
      return await _sendOnce(method, path,
          query: query, body: body, auth: auth, token: token);
    } on ApiException catch (error) {
      if (!sendsToken || !error.isUnauthorized) rethrow;
      final String? fresh = await refreshAccessToken?.call();
      if (fresh != null && fresh.isNotEmpty && fresh != token) {
        try {
          return await _sendOnce(method, path,
              query: query, body: body, auth: auth, token: fresh);
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

  Future<Uint8List> _sendBytesOnce(
    String path, {
    required AuthMode auth,
    required String? token,
  }) async {
    try {
      final Uri uri = AppEnv.resolve(path);
      if (AppEnv.isDevelopment) {
        // ignore: avoid_print
        print('[api] → GET $uri (bytes)');
      }
      final http.Request request = http.Request('GET', uri);
      request.headers['Accept'] = 'image/*,application/json';
      if (auth != AuthMode.none && token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      final http.StreamedResponse streamed =
          await _http.send(request).timeout(_timeout);
      final http.Response response = await http.Response.fromStream(streamed);
      if (AppEnv.isDevelopment) {
        // ignore: avoid_print
        print(
          '[api] GET ${uri.path} → ${response.statusCode} '
          '(${response.headers['content-type'] ?? 'unknown'})',
        );
      }
      return _parseBytes(response);
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

  Future<ByteRangeResponse> _sendByteRangeOnce(
    String path, {
    required int start,
    required int endInclusive,
    required int? expectedTotalSize,
    required AuthMode auth,
    required String? token,
  }) async {
    try {
      final Uri uri = AppEnv.resolve(path);
      if (AppEnv.isDevelopment) {
        // ignore: avoid_print
        print('[api] → GET $uri Range bytes=$start-$endInclusive');
      }
      final http.Request request = http.Request('GET', uri);
      request.headers['Accept'] = 'application/pdf,application/octet-stream';
      request.headers['Range'] = 'bytes=$start-$endInclusive';
      if (auth != AuthMode.none && token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      final http.StreamedResponse streamed =
          await _http.send(request).timeout(_rangeTimeout);
      final http.Response response = await http.Response.fromStream(streamed);
      if (AppEnv.isDevelopment) {
        // ignore: avoid_print
        print(
          '[api] GET ${uri.path} Range → ${response.statusCode} '
          '(${response.headers['content-type'] ?? 'unknown'})',
        );
      }
      return _parseByteRange(
        response,
        requestedStart: start,
        requestedEndInclusive: endInclusive,
        expectedTotalSize: expectedTotalSize,
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

  ByteRangeResponse _parseByteRange(
    http.Response response, {
    required int requestedStart,
    required int requestedEndInclusive,
    required int? expectedTotalSize,
  }) {
    final String contentType =
        (response.headers['content-type'] ?? '').toLowerCase();
    final bool looksJson = contentType.contains('application/json') ||
        contentType.contains('text/json') ||
        (response.body.isNotEmpty && response.body.trimLeft().startsWith('{'));

    if (looksJson ||
        response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 404 ||
        response.statusCode == 416 ||
        response.statusCode >= 400) {
      if (response.body.isNotEmpty &&
          response.body.trimLeft().startsWith('{')) {
        final ApiEnvelope envelope =
            ApiEnvelope.parse(response.body, response.statusCode);
        envelope.throwIfError(response.statusCode);
      }
      throw ApiException(
        statusCode: response.statusCode,
        code: response.statusCode == 416
            ? 'INVALID_RANGE'
            : response.statusCode == 404
                ? 'NOT_FOUND'
                : response.statusCode == 403
                    ? 'FORBIDDEN'
                    : response.statusCode == 401
                        ? 'UNAUTHENTICATED'
                        : 'INTERNAL_ERROR',
        message: response.statusCode == 416
            ? 'The requested document range is invalid.'
            : response.statusCode == 403
                ? 'You do not have access to this document.'
                : response.statusCode == 404
                    ? 'This document is no longer available.'
                    : 'Document request failed.',
      );
    }

    final Uint8List body = response.bodyBytes;
    if (body.isEmpty) {
      throw ApiException(
        statusCode: response.statusCode,
        code: 'MALFORMED_RESPONSE',
        message: 'Empty document range response.',
      );
    }

    final int requestedLength = requestedEndInclusive - requestedStart + 1;

    if (response.statusCode == 206) {
      final ContentRangeHeader? range = ContentRangeHeader.tryParse(
        response.headers['content-range'],
      );
      if (range == null) {
        throw const ApiException(
          statusCode: 206,
          code: 'MALFORMED_RESPONSE',
          message: 'Partial response missing Content-Range.',
        );
      }
      if (range.start != requestedStart) {
        throw const ApiException(
          statusCode: 206,
          code: 'MALFORMED_RESPONSE',
          message: 'Partial response start offset mismatch.',
        );
      }
      if (body.length != (range.endInclusive - range.start + 1)) {
        throw const ApiException(
          statusCode: 206,
          code: 'MALFORMED_RESPONSE',
          message: 'Partial response length mismatch.',
        );
      }
      if (expectedTotalSize != null &&
          range.total > 0 &&
          range.total != expectedTotalSize) {
        throw const ApiException(
          statusCode: 416,
          code: 'DOCUMENT_SIZE_MISMATCH',
          message: 'Document size changed. Please reopen the chapter.',
        );
      }
      return ByteRangeResponse(
        bytes: body,
        statusCode: 206,
        start: range.start,
        endInclusive: range.endInclusive,
        totalSize: range.total > 0
            ? range.total
            : (expectedTotalSize ?? (range.endInclusive + 1)),
        fromPartialContent: true,
      );
    }

    if (response.statusCode == 200) {
      // Accept a full-body 200 only when we can verify and slice the request.
      final int contentLength = int.tryParse(
            response.headers['content-length'] ?? '',
          ) ??
          body.length;
      if (contentLength != body.length) {
        throw const ApiException(
          statusCode: 200,
          code: 'MALFORMED_RESPONSE',
          message: 'Document length mismatch.',
        );
      }
      if (body.length == requestedLength) {
        // Server ignored Range but returned exactly the requested window.
        return ByteRangeResponse(
          bytes: body,
          statusCode: 200,
          start: requestedStart,
          endInclusive: requestedEndInclusive,
          totalSize: expectedTotalSize ??
              (requestedStart == 0 ? body.length : requestedEndInclusive + 1),
          fromPartialContent: false,
        );
      }
      if (expectedTotalSize != null && body.length == expectedTotalSize) {
        if (requestedEndInclusive >= body.length) {
          throw const ApiException(
            statusCode: 416,
            code: 'INVALID_RANGE',
            message: 'Requested range exceeds document size.',
          );
        }
        final int end = requestedEndInclusive.clamp(0, body.length - 1);
        return ByteRangeResponse(
          bytes: Uint8List.sublistView(body, requestedStart, end + 1),
          statusCode: 200,
          start: requestedStart,
          endInclusive: end,
          totalSize: expectedTotalSize,
          fromPartialContent: false,
        );
      }
      throw const ApiException(
        statusCode: 200,
        code: 'MALFORMED_RESPONSE',
        message: 'Unexpected full document response for a range request.',
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      code: 'INTERNAL_ERROR',
      message: 'Document request failed.',
    );
  }

  Uint8List _parseBytes(http.Response response) {
    final String contentType =
        (response.headers['content-type'] ?? '').toLowerCase();
    final bool looksJson = contentType.contains('application/json') ||
        contentType.contains('text/json') ||
        (response.body.isNotEmpty && response.body.trimLeft().startsWith('{'));
    if (looksJson || response.statusCode >= 400) {
      if (response.body.isNotEmpty &&
          response.body.trimLeft().startsWith('{')) {
        final ApiEnvelope envelope =
            ApiEnvelope.parse(response.body, response.statusCode);
        envelope.throwIfError(response.statusCode);
      }
      throw ApiException(
        statusCode: response.statusCode,
        code: response.statusCode == 404
            ? 'NOT_FOUND'
            : response.statusCode == 403
                ? 'FORBIDDEN'
                : response.statusCode == 401
                    ? 'UNAUTHENTICATED'
                    : 'INTERNAL_ERROR',
        message: 'Media request failed.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        code: 'INTERNAL_ERROR',
        message: 'Media request failed.',
      );
    }
    if (response.bodyBytes.isEmpty) {
      throw ApiException(
        statusCode: response.statusCode,
        code: 'MALFORMED_RESPONSE',
        message: 'Empty media response.',
      );
    }
    return response.bodyBytes;
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
