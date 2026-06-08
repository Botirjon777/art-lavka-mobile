import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/env.dart';
import '../utils/result.dart';
import 'token_store.dart';

/// A backend error surfaced to repositories. [code] is a [FailureCode] (the API
/// returns `{ error: { code, message } }` with codes mirroring the Dart enum),
/// so [ErrorMapper] can map it straight to localized copy.
class ApiException implements Exception {
  ApiException(this.code, this.message, {this.statusCode});
  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($code, $message, $statusCode)';
}

/// Thin Dio wrapper that talks to the NestJS API.
///
/// - Attaches `Authorization: Bearer <access>` to every request.
/// - On a 401 (non-auth route), tries a one-shot refresh and retries; if refresh
///   fails it clears the session (→ session expired).
/// - Converts Dio errors into [ApiException] with a [FailureCode].
class ApiClient {
  ApiClient({required this.tokenStore, Dio? dio, String? baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? Env.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              contentType: 'application/json',
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final Dio _dio;
  final TokenStore tokenStore;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? data}) =>
      _send(() => _dio.post(path, data: data));

  Future<dynamic> patch(String path, {Object? data}) =>
      _send(() => _dio.patch(path, data: data));

  Future<dynamic> delete(String path, {Object? data}) =>
      _send(() => _dio.delete(path, data: data));

  /// PUT raw bytes to an ABSOLUTE url (e.g. a presigned storage upload URL).
  /// Bypasses the base URL and auth header.
  Future<void> putBinary(
    String absoluteUrl,
    Uint8List bytes, {
    String? contentType,
  }) async {
    try {
      await Dio().put(
        absoluteUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            Headers.contentTypeHeader: ?contentType,
            Headers.contentLengthHeader: bytes.length,
          },
        ),
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final res = await request();
      return res.data;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.headers.containsKey('Authorization')) {
      final token = await tokenStore.accessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final isAuthRoute = err.requestOptions.path.contains('/auth/');
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (status == 401 && !isAuthRoute && !alreadyRetried) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final opts = err.requestOptions;
        opts.extra['retried'] = true;
        opts.headers['Authorization'] =
            'Bearer ${tokenStore.cachedAccessToken}';
        try {
          final res = await _dio.fetch<dynamic>(opts);
          return handler.resolve(res);
        } on DioException catch (retryErr) {
          return handler.next(retryErr);
        }
      }
      await tokenStore.clear();
    }
    handler.next(err);
  }

  /// Exchange the refresh token for a new pair. Uses a bare Dio (no interceptor)
  /// to avoid recursion. Returns whether it succeeded.
  Future<bool> _tryRefresh() async {
    final refresh = await tokenStore.refreshToken();
    if (refresh == null) return false;
    try {
      final res = await Dio(
        BaseOptions(baseUrl: _dio.options.baseUrl),
      ).post('/auth/refresh', data: {'refreshToken': refresh});
      final data = res.data;
      if (data is Map &&
          data['access_token'] is String &&
          data['refresh_token'] is String) {
        await tokenStore.save(
          access: data['access_token'] as String,
          refresh: data['refresh_token'] as String,
        );
        return true;
      }
      return false;
    } on DioException {
      return false;
    }
  }

  ApiException _toApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = (data['error'] as Map).cast<String, dynamic>();
      return ApiException(
        error['code']?.toString() ?? FailureCode.server,
        error['message']?.toString() ?? 'Request failed',
        statusCode: e.response?.statusCode,
      );
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return ApiException(FailureCode.network, 'No connection');
      default:
        return ApiException(
          FailureCode.server,
          e.message ?? 'Server error',
          statusCode: e.response?.statusCode,
        );
    }
  }
}
