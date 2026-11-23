import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/core/db/drift/app_database.dart';
import 'package:hasta/core/network/api_failure.dart';
import 'package:hasta/features/linked_accounts/data/google_auth_launcher.dart';
import 'package:hasta/features/linked_accounts/data/identity_repository.dart';

import '../support/gmail_link.dart';
import '../support/harness.dart';
import '../support/signed_in.dart';

/// SPEC 1.0.2 §5.4 client boundary (rules 1–3) + T44 client half, below the UI. ADR-0009.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Harness h;
  late FakeLauncher launcher;
  late IdentityRepository repo;

  setUp(() async {
    h = Harness();
    launcher = FakeLauncher();
    repo = IdentityRepository(api: h.client, db: h.db, launcher: launcher);
    await h.db.into(h.db.localAccounts).insert(LocalAccountsCompanion.insert(
        id: kAccountId, isGuest: true, status: 'active', createdAt: DateTime.utc(2026), syncedAt: DateTime.utc(2026)));
    h.api.on('POST', kStart, (_) => startOk());
    h.api.on('POST', kComplete, (_) => linkedOk('x***@gmail.com'));
  });
  tearDown(() => h.db.close());

  test('link opens exactly the server auth_url, posts only {state, code}, flips Drift is_guest', () async {
    expect((await repo.link()).emailMasked, 'x***@gmail.com');
    expect(launcher.launched, <Uri>[Uri.parse(authUrl(lastState))]);
    expect(h.api.calls('POST', kComplete).map((dynamic o) => o.data), <dynamic>[<String, String>{'state': lastState, 'code': 'c-1'}]);
    expect((await h.db.select(h.db.localAccounts).getSingle()).isGuest, isFalse);
  });

  test('a callback whose state does not match link:start is refused before link:complete', () async {
    launcher.respond = (_) => Uri.parse('hasta://link/google?code=c-1&state=attacker');
    await expectLater(repo.link(), throwsA(isA<ApiFailure>()));
    expect(h.api.calls('POST', kComplete), isEmpty);
    expect((await h.db.select(h.db.localAccounts).getSingle()).isGuest, isTrue);
  });

  test('error=access_denied is a cancel, not a failure', () async {
    launcher.respond = (_) => Uri.parse('hasta://link/google?error=access_denied&state=$lastState');
    await expectLater(repo.link(), throwsA(isA<AuthCancelled>()));
    expect(h.api.calls('POST', kComplete), isEmpty);
  });

  test('current() reads the server mask; unlink is DELETE and surfaces 409 recovery_required', () async {
    expect(await repo.current(), isNull);
    h.api.on('DELETE', kIdentity, (_) => FakeResponse.error(409, 'recovery_required'));
    await expectLater(repo.unlink(), throwsA(isA<ApiFailure>().having((ApiFailure f) => f.code, 'code', 'recovery_required')));
    expect(h.api.calls('DELETE', kIdentity), hasLength(1));
  });

  group('WebAuthGoogleLauncher (flutter_web_auth_2 4.1.0 channel)', () {
    const MethodChannel channel = MethodChannel('flutter_web_auth_2');
    void reply(Object? Function(MethodCall c) f) =>
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall c) async => f(c));
    tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    test('passes url + scheme through and returns the callback', () async {
      late MethodCall seen;
      reply((MethodCall c) => (seen = c, 'hasta://link/google?code=c&state=s').$2);
      expect(await const WebAuthGoogleLauncher().authenticate(Uri.parse(authUrl('s')), 'hasta'), Uri.parse('hasta://link/google?code=c&state=s'));
      expect(seen.arguments, containsPair('url', authUrl('s')));
      expect(seen.arguments, containsPair('callbackUrlScheme', 'hasta'));
    });

    test('CANCELED → AuthCancelled; any other platform error is rethrown', () async {
      reply((_) => throw PlatformException(code: 'CANCELED'));
      await expectLater(const WebAuthGoogleLauncher().authenticate(Uri.parse(authUrl('s')), 'hasta'), throwsA(isA<AuthCancelled>()));
      reply((_) => throw PlatformException(code: 'EUNKNOWN'));
      await expectLater(const WebAuthGoogleLauncher().authenticate(Uri.parse(authUrl('s')), 'hasta'), throwsA(isA<PlatformException>()));
    });
  });
}
