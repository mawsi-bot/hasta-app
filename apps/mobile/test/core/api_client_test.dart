import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/core/network/api_client.dart';
import 'package:hasta/core/network/api_failure.dart';
import 'package:hasta/core/security/token_store.dart';

import '../support/harness.dart';

void main() {
  late FakeApi api;
  late MemoryTokenStore tokens;
  late ApiClient client;
  int expired = 0;

  setUp(() {
    api = FakeApi();
    tokens = MemoryTokenStore();
    expired = 0;
    client = ApiClient(tokens: tokens, dio: Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = api)
      ..onSessionExpired = () => expired++;
  });

  test('every write carries Idempotency-Key + X-Request-Id (UUIDv7); GET has no key', () async {
    api.on('POST', '/x', (_) => const FakeResponse(200, <String, dynamic>{}));
    api.on('GET', '/y', (_) => const FakeResponse(200, <String, dynamic>{}));
    await client.post('/x', body: <String, int>{'a': 1});
    await client.get('/y', auth: false);
    final RequestOptions post = api.calls('POST', '/x').single;
    final RequestOptions get = api.calls('GET', '/y').single;
    expect(post.headers['Idempotency-Key'], matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(post.headers['X-Request-Id'], isNotNull);
    expect(get.headers.containsKey('Idempotency-Key'), isFalse);
  });

  test('caller-supplied Idempotency-Key is reused on the post-refresh retry', () async {
    await tokens.write(SecureKey.accessToken, 'old');
    await tokens.write(SecureKey.refreshToken, 'rt_old');
    await tokens.write(SecureKey.deviceToken, 'dt_x');
    int n = 0;
    api.on('PATCH', '/v1/profile', (_) => n++ == 0 ? FakeResponse.error(401, 'token_expired') : const FakeResponse(200, <String, dynamic>{}));
    api.on('POST', '/v1/auth/refresh',
        (_) => const FakeResponse(200, <String, dynamic>{'access_token': 'new', 'refresh_token': 'rt_new', 'expires_in': 900}));
    await client.patch('/v1/profile', body: <String, String>{}, idempotencyKey: 'k-1');
    final List<RequestOptions> calls = api.calls('PATCH', '/v1/profile');
    expect(calls.map((RequestOptions o) => o.headers['Idempotency-Key']), <String>['k-1', 'k-1']);
    expect(calls.last.headers['Authorization'], 'Bearer new');
    expect(await tokens.read(SecureKey.refreshToken), 'rt_new');
  });

  test('concurrent 401s trigger exactly ONE refresh (single-flight; avoids reuse detection)', () async {
    await tokens.write(SecureKey.accessToken, 'old');
    await tokens.write(SecureKey.refreshToken, 'rt_old');
    await tokens.write(SecureKey.deviceToken, 'dt_x');
    api.on('GET', '/v1/me', (RequestOptions o) =>
        o.headers['Authorization'] == 'Bearer new' ? const FakeResponse(200, <String, dynamic>{}) : FakeResponse.error(401, 'token_expired'));
    final Completer<void> gate = Completer<void>();
    api.on('POST', '/v1/auth/refresh', (_) async {
      await gate.future;
      return const FakeResponse(200, <String, dynamic>{'access_token': 'new', 'refresh_token': 'rt_new', 'expires_in': 900});
    });
    final Future<List<Map<String, dynamic>?>> all = Future.wait(<Future<Map<String, dynamic>?>>[
      client.get('/v1/me'),
      client.get('/v1/me'),
      client.get('/v1/me'),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    gate.complete();
    await all;
    expect(api.calls('POST', '/v1/auth/refresh'), hasLength(1));
  });

  test('rejected refresh (reuse / revoked family) clears tokens and expires the session', () async {
    await tokens.write(SecureKey.accessToken, 'old');
    await tokens.write(SecureKey.refreshToken, 'rt_old');
    await tokens.write(SecureKey.deviceToken, 'dt_x');
    api.on('GET', '/v1/me', (_) => FakeResponse.error(401, 'unauthenticated'));
    api.on('POST', '/v1/auth/refresh', (_) => FakeResponse.error(401, 'unauthenticated', details: <String, dynamic>{'reason': 'reuse_detected'}));
    await expectLater(client.get('/v1/me'), throwsA(isA<ApiFailure>()));
    expect(expired, 1);
    expect(await tokens.read(SecureKey.refreshToken), isNull);
  });

  test('offline refresh keeps the session (offline-first)', () async {
    await tokens.write(SecureKey.accessToken, 'old');
    await tokens.write(SecureKey.refreshToken, 'rt_old');
    await tokens.write(SecureKey.deviceToken, 'dt_x');
    api.on('GET', '/v1/me', (_) => FakeResponse.error(401, 'token_expired'));
    api.on('POST', '/v1/auth/refresh', (_) => const FakeResponse.offline());
    await expectLater(client.get('/v1/me'), throwsA(isA<ApiFailure>().having((ApiFailure f) => f.isOffline, 'offline', true)));
    expect(expired, 0);
    expect(await tokens.read(SecureKey.refreshToken), 'rt_old');
  });

  test('T42 mapping: 429 device_cooldown exposes retry_after_days + Retry-After', () async {
    api.on('POST', '/v1/auth/guest', (_) => FakeResponse.error(429, 'device_cooldown',
        details: <String, dynamic>{'retry_after_days': 12}, headers: <String, String>{'retry-after': '1036800'}));
    try {
      await client.post('/v1/auth/guest', body: <String, String>{});
      fail('expected failure');
    } on ApiFailure catch (f) {
      expect(f.code, 'device_cooldown');
      expect(f.retryAfterDays, 12);
      expect(f.retryAfterSeconds, 1036800);
      expect(f.displayCode, 'E-429');
      expect(f.requestId, 'req-1');
    }
  });

  test('transport failure maps to offline', () async {
    api.on('GET', '/z', (_) => const FakeResponse.offline());
    await expectLater(client.get('/z', auth: false),
        throwsA(isA<ApiFailure>().having((ApiFailure f) => f.code, 'code', ApiFailure.offlineCode)));
  });
}
