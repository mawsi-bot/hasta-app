import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/app.dart';
import 'package:hasta/core/connectivity/connectivity.dart';
import 'package:hasta/core/db/drift/app_database.dart';
import 'package:hasta/core/network/api_client.dart';
import 'package:hasta/core/providers.dart';
import 'package:hasta/core/security/device_identity.dart';
import 'package:hasta/core/security/token_store.dart';

class FakeResponse {
  const FakeResponse(this.status, [this.body, this.headers = const <String, String>{}]) : offline = false;
  const FakeResponse.offline()
      : status = 0,
        body = null,
        headers = const <String, String>{},
        offline = true;

  final int status;
  final Object? body;
  final Map<String, String> headers;
  final bool offline;

  static FakeResponse error(int status, String code, {Map<String, dynamic>? details, Map<String, String>? headers}) =>
      FakeResponse(
        status,
        <String, dynamic>{
          'error': <String, dynamic>{'code': code, 'message_key': 'k', 'details': details, 'request_id': 'req-1'},
        },
        headers ?? const <String, String>{},
      );
}

typedef Handler = FutureOr<FakeResponse> Function(RequestOptions o);

/// In-process fake of the Hasta API used by Dio.
class FakeApi implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];
  final Map<String, Handler> _routes = <String, Handler>{};

  void on(String method, String path, Handler h) => _routes['$method $path'] = h;

  List<RequestOptions> calls(String method, String path) =>
      requests.where((RequestOptions o) => o.method == method && o.path == path).toList();

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(o);
    final Handler? h = _routes['${o.method} ${o.path}'];
    final FakeResponse r = h == null ? FakeResponse.error(404, 'not_found') : await h(o);
    if (r.offline) {
      throw DioException.connectionError(requestOptions: o, reason: 'offline');
    }
    return ResponseBody.fromString(
      r.body == null ? '' : jsonEncode(r.body),
      r.status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        for (final MapEntry<String, String> e in r.headers.entries) e.key: <String>[e.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeDevice implements DeviceIdentity {
  int reads = 0;
  @override
  Future<String> rawDeviceId() async {
    reads++;
    return 'a1b2c3d4e5f60718';
  }

  @override
  Future<String> platform() async => 'android';
}

Map<String, dynamic> accountJson({String id = '01934f00-0000-7000-8000-000000000001', bool isGuest = true}) =>
    <String, dynamic>{
      'id': id,
      'status': 'active',
      'is_guest': isGuest,
      'display_name': null,
      'username': null,
      'created_at': '2026-11-23T00:00:00.000Z',
    };

Map<String, dynamic> sessionJson({bool isNew = true, String refresh = 'rt_1', Map<String, dynamic>? account}) =>
    <String, dynamic>{
      'access_token': 'at_1',
      'refresh_token': refresh,
      'expires_in': 900,
      'account': account ?? accountJson(),
      'device_binding': <String, dynamic>{
        'id': 'b1',
        'role': 'primary',
        'device_hash': 'h',
        'bound_at': '2026-11-23T00:00:00.000Z'
      },
      'is_new_account': isNew,
    };

Map<String, dynamic> meJson({Map<String, dynamic>? profile, bool isGuest = true}) => <String, dynamic>{
      'account': <String, dynamic>{
        'id': accountJson()['id'],
        'status': 'active',
        'is_guest': isGuest,
        'created_at': '2026-11-23T00:00:00.000Z'
      },
      'profile': profile,
      'identities': <dynamic>[],
      'entitlements': <dynamic>[],
      'flags': <String, bool>{'dating_enabled': false, 'dating_paused': false, 'premium': false, 'test_mode_panel': false},
    };

/// Everything a test needs; overrides the composition root.
class Harness {
  Harness({bool online = true})
      : api = FakeApi(),
        tokens = MemoryTokenStore(),
        device = FakeDevice(),
        connectivity = ManualConnectivity(online: online) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    client = ApiClient(tokens: tokens, baseUrl: 'http://api.test', dio: Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = api);
    api.on('GET', '/v1/me', (_) => FakeResponse(200, meJson()));
  }

  final FakeApi api;
  final MemoryTokenStore tokens;
  final FakeDevice device;
  final ManualConnectivity connectivity;
  late final AppDatabase db;
  late final ApiClient client;

  List<Override> get overrides => <Override>[
        tokenStoreProvider.overrideWithValue(tokens),
        deviceIdentityProvider.overrideWithValue(device),
        connectivityProvider.overrideWithValue(connectivity),
        databaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(client),
      ];

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: overrides, child: const HastaApp()));
    await settle(tester);
  }

  /// Drift + Dio do real async work; let it run, then pump frames.
  Future<void> settle(WidgetTester tester, [int rounds = 6]) async {
    for (int i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // Let drift's stream-cancellation timers fire inside the fake clock, then
    // close the in-memory database.
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close().timeout(const Duration(seconds: 2), onTimeout: () {}));
    await tester.pump(const Duration(seconds: 1));
  }
}
