import 'dart:async';

import 'package:dio/dio.dart';

import '../config/build_config.dart';
import '../ids/uuid_v7.dart';
import '../security/token_store.dart';
import 'api_failure.dart';

enum RefreshResult { ok, rejected, offline }

/// HTTP client for `/v1` (API contract §0).
///
/// * `X-Request-Id` (UUIDv7) on every request.
/// * `Idempotency-Key` (UUIDv7) on every write — callers that retry (the outbox)
///   pass their own stable key so the server can replay (SKILL rule 4).
/// * Access token attached when `auth: true`; a 401 triggers ONE single-flight
///   refresh (rotation, SPEC §5.3) and a single retry with the same key.
/// * Errors are normalised to [ApiFailure]. Token values are never logged.
class ApiClient {
  ApiClient({
    required TokenStore tokens,
    String? baseUrl,
    Dio? dio,
    this.onSessionExpired,
  })  : _tokens = tokens,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl ?? BuildConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
            ));

  final Dio _dio;
  final TokenStore _tokens;

  /// Called when the refresh token is rejected (rotated/revoked/reused).
  void Function()? onSessionExpired;

  Future<RefreshResult>? _refreshing;

  Dio get dio => _dio;

  Future<Map<String, dynamic>?> get(String path, {bool auth = true}) =>
      _send('GET', path, auth: auth);

  Future<Map<String, dynamic>?> post(String path, {Object? body, bool auth = false, String? idempotencyKey}) =>
      _send('POST', path, body: body, auth: auth, idempotencyKey: idempotencyKey);

  Future<Map<String, dynamic>?> patch(String path, {Object? body, bool auth = true, String? idempotencyKey}) =>
      _send('PATCH', path, body: body, auth: auth, idempotencyKey: idempotencyKey);

  Future<Map<String, dynamic>?> delete(String path, {bool auth = true, String? idempotencyKey}) =>
      _send('DELETE', path, auth: auth, idempotencyKey: idempotencyKey);

  Future<Map<String, dynamic>?> _send(
    String method,
    String path, {
    Object? body,
    required bool auth,
    String? idempotencyKey,
  }) async {
    final String? key = method == 'GET' ? null : (idempotencyKey ?? uuidV7());
    try {
      return await _raw(method, path, body: body, auth: auth, idempotencyKey: key);
    } on DioException catch (e) {
      if (auth && e.response?.statusCode == 401) {
        final RefreshResult r = await refreshSession();
        if (r == RefreshResult.ok) {
          try {
            return await _raw(method, path, body: body, auth: auth, idempotencyKey: key);
          } on DioException catch (e2) {
            throw mapError(e2);
          }
        }
        if (r == RefreshResult.offline) throw const ApiFailure.offline();
      }
      throw mapError(e);
    }
  }

  Future<Map<String, dynamic>?> _raw(
    String method,
    String path, {
    Object? body,
    required bool auth,
    String? idempotencyKey,
  }) async {
    final Map<String, dynamic> headers = <String, dynamic>{
      'X-Request-Id': uuidV7(),
      'X-App-Version': BuildConfig.appVersion,
      if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
    };
    if (auth) {
      final String? access = await _tokens.read(SecureKey.accessToken);
      if (access != null) headers['Authorization'] = 'Bearer $access';
    }
    final Response<dynamic> res = await _dio.request<dynamic>(
      path,
      data: body,
      options: Options(method: method, headers: headers),
    );
    final Object? data = res.data;
    return data is Map<String, dynamic> ? data : null;
  }

  /// Single-flight refresh: concurrent 401s share one rotation call, so the
  /// server never sees the same refresh token twice (which would be treated
  /// as reuse and revoke the family).
  Future<RefreshResult> refreshSession() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<RefreshResult> _doRefresh() async {
    final String? refresh = await _tokens.read(SecureKey.refreshToken);
    final String? device = await _tokens.read(SecureKey.deviceToken);
    if (refresh == null || device == null) {
      _expire();
      return RefreshResult.rejected;
    }
    try {
      final Map<String, dynamic>? r = await _raw('POST', '/v1/auth/refresh',
          body: <String, String>{'refresh_token': refresh, 'device_token': device},
          auth: false,
          idempotencyKey: uuidV7());
      await _tokens.write(SecureKey.accessToken, r!['access_token'] as String);
      await _tokens.write(SecureKey.refreshToken, r['refresh_token'] as String);
      return RefreshResult.ok;
    } on DioException catch (e) {
      final ApiFailure f = mapError(e);
      if (f.isOffline || (f.status ?? 0) >= 500) return RefreshResult.offline;
      await _tokens.delete(SecureKey.accessToken);
      await _tokens.delete(SecureKey.refreshToken);
      _expire();
      return RefreshResult.rejected;
    }
  }

  void _expire() => onSessionExpired?.call();

  static ApiFailure mapError(DioException e) {
    final Response<dynamic>? res = e.response;
    if (res == null) return const ApiFailure.offline();
    final Object? data = res.data;
    final Object? err = data is Map<String, dynamic> ? data['error'] : null;
    final String? retryAfter = res.headers.value('retry-after');
    if (err is Map<String, dynamic>) {
      return ApiFailure(
        code: (err['code'] as String?) ?? 'internal_error',
        status: res.statusCode,
        messageKey: err['message_key'] as String?,
        details: err['details'] is Map<String, dynamic> ? err['details'] as Map<String, dynamic> : null,
        requestId: err['request_id'] as String?,
        retryAfterSeconds: retryAfter == null ? null : int.tryParse(retryAfter),
      );
    }
    return ApiFailure(code: 'internal_error', status: res.statusCode);
  }
}
