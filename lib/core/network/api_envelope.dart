import 'dart:convert';

import '../errors/api_exception.dart';

class ApiEnvelope {
  const ApiEnvelope({
    required this.success,
    this.data,
    this.pagination,
    this.errorCode,
    this.errorMessage,
  });

  final bool success;
  final dynamic data;
  final PaginationMeta? pagination;
  final String? errorCode;
  final String? errorMessage;

  factory ApiEnvelope.parse(String body, int statusCode) {
    final Object? decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        statusCode: statusCode,
        code: 'MALFORMED_RESPONSE',
        message: 'Unexpected response from server.',
      );
    }
    final bool success = decoded['success'] == true;
    Map<String, dynamic>? error;
    final Object? errorRaw = decoded['error'];
    if (errorRaw is Map<String, dynamic>) {
      error = errorRaw;
    }
    PaginationMeta? pagination;
    final Object? paginationRaw = decoded['pagination'];
    if (paginationRaw is Map<String, dynamic>) {
      pagination = PaginationMeta.fromJson(paginationRaw);
    }
    return ApiEnvelope(
      success: success,
      data: decoded['data'],
      pagination: pagination,
      errorCode: error?['code']?.toString(),
      errorMessage: error?['message']?.toString(),
    );
  }

  void throwIfError(int statusCode) {
    if (success) return;
    throw ApiException(
      statusCode: statusCode,
      code: errorCode ?? 'INTERNAL_ERROR',
      message: errorMessage ?? 'Request failed.',
    );
  }
}

class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class Paginated<T> {
  const Paginated({required this.items, required this.pagination});

  final List<T> items;
  final PaginationMeta pagination;
}
