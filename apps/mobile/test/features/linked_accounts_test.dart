import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/app.dart';
import 'package:hasta/features/linked_accounts/data/google_auth_launcher.dart';
import 'package:hasta/features/linked_accounts/presentation/linked_accounts_sheet.dart';
import 'package:hasta/features/settings/presentation/settings_screen.dart';
import 'package:hasta/shared/widgets/hasta_button.dart';

import '../support/gmail_link.dart';
import '../support/harness.dart';
import '../support/signed_in.dart';

/// SPEC 1.0.2 §5.4 / §14.7 — Linked accounts sheet UI. T43 (real), T44 (client half); wire boundary is in
/// test/core/gmail_link_client_test.dart.
Future<(Harness, FakeLauncher)> openSheet(WidgetTester tester, {List<Map<String, dynamic>> identities = const <Map<String, dynamic>>[]}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final Harness h = await signedInHarness(tester);
  final FakeLauncher launcher = FakeLauncher();
  h.api.on('GET', '/v1/me', (_) => FakeResponse(200, meJson()..['identities'] = identities));
  h.api.on('POST', kStart, (_) => startOk());
  await tester.pumpWidget(ProviderScope(
      overrides: <Override>[...h.overrides, googleAuthLauncherProvider.overrideWithValue(launcher)], child: const HastaApp()));
  await h.settle(tester);
  await tester.tap(find.text('ပရိုဖိုင်'));
  await h.settle(tester);
  await tester.tap(find.byKey(const Key('open-settings')));
  await h.settle(tester);
  await tester.tap(find.byKey(SettingsScreen.connectGmailKey));
  await h.settle(tester);
  expect(find.byType(LinkedAccountsSheet), findsOneWidget);
  return (h, launcher);
}

HastaButton connect(WidgetTester tester) => tester.widget<HastaButton>(find.byKey(LinkedAccountsSheet.connectKey));

Future<void> tapConnect(WidgetTester tester, Harness h) async {
  await tester.tap(find.byKey(LinkedAccountsSheet.connectKey), warnIfMissed: false);
  await h.settle(tester);
}

void main() {
  testWidgets('empty: not linked, §14.7 benefit verbatim, guest risk, Connect enabled', (WidgetTester tester) async {
    final (Harness h, _) = await openSheet(tester);
    expect(find.text('မချိတ်ဆက်ရသေး'), findsOneWidget);
    expect(find.text('ချိတ်ဆက်ပါက — (၁) ဖုန်းပြောင်းလျှင် အကောင့် ပြန်ရနိုင်သည် (၂) Premium ဝယ်ယူနိုင်သည် (၃) Restore Purchases သုံးနိုင်သည်။'),
        findsOneWidget);
    expect(find.text('ဖုန်းပျောက်ပါက ဤအကောင့်ကို ပြန်ရနိုင်မည် မဟုတ်ပါ။ Gmail ချိတ်ဆက်ထားရန် အကြံပြုသည်။'), findsOneWidget);
    expect(connect(tester).onPressed, isNotNull);
    await h.dispose(tester);
  });

  testWidgets('T43 — offline: Connect disabled with reason, 0 server and 0 launcher calls; online again → one link:start',
      (WidgetTester tester) async {
    final (Harness h, FakeLauncher launcher) = await openSheet(tester);
    h.connectivity.online = false;
    await h.settle(tester);
    expect(connect(tester).onPressed, isNull);
    expect(find.descendant(of: find.byType(LinkedAccountsSheet), matching: find.text('အင်တာနက် ချိတ်ဆက်ထားမှ အသုံးပြုနိုင်ပါသည်')),
        findsOneWidget);
    await tapConnect(tester, h);
    expect(h.api.calls('POST', kStart), isEmpty);
    expect(launcher.launched, isEmpty);
    h.connectivity.online = true;
    h.api.on('POST', kComplete, (_) => linkedOk('h***@gmail.com'));
    await h.settle(tester);
    await tapConnect(tester, h);
    expect(h.api.calls('POST', kStart), hasLength(1));
    await h.dispose(tester);
  });

  testWidgets('T44 client half: shows only the server mask, then Settings drops the guest Premium block',
      (WidgetTester tester) async {
    final (Harness h, _) = await openSheet(tester);
    h.api.on('POST', kComplete, (_) => linkedOk('x***@gmail.com'));
    await tapConnect(tester, h);
    expect(find.text('ချိတ်ဆက်ပြီး — x***@gmail.com'), findsOneWidget);
    expect(find.textContaining('@gmail.com'), findsOneWidget); // nothing but the server mask
    final bool isGuest = await tester.runAsync(() async => (await h.db.select(h.db.localAccounts).getSingle()).isGuest) as bool;
    expect(isGuest, isFalse);
    Navigator.of(tester.element(find.byType(LinkedAccountsSheet))).pop();
    await h.settle(tester);
    expect(find.text('Premium ဝယ်ယူရန် Gmail ချိတ်ဆက်ထားရပါမည်။', skipOffstage: false), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('permissionDenied: OAuth cancelled → back to the sheet with a notice, no link:complete', (WidgetTester tester) async {
    final (Harness h, FakeLauncher launcher) = await openSheet(tester);
    launcher.respond = (_) => throw const AuthCancelled();
    await tapConnect(tester, h);
    expect(find.byKey(LinkedAccountsSheet.cancelledKey), findsOneWidget);
    expect(find.text('မချိတ်ဆက်ရသေး'), findsOneWidget);
    expect(connect(tester).onPressed, isNotNull);
    expect(h.api.calls('POST', kComplete), isEmpty);
    await h.dispose(tester);
  });

  testWidgets('loading: spinner while the browser is open; a double tap sends one link:start', (WidgetTester tester) async {
    final (Harness h, FakeLauncher launcher) = await openSheet(tester);
    final Completer<Uri> pending = Completer<Uri>();
    launcher.respond = (_) => pending.future;
    await tapConnect(tester, h);
    await tapConnect(tester, h);
    expect(connect(tester).loading, isTrue);
    expect(h.api.calls('POST', kStart), hasLength(1));
    pending.complete(Uri.parse('hasta://link/google?error=access_denied&state=$lastState'));
    await h.settle(tester);
    expect(find.byKey(LinkedAccountsSheet.cancelledKey), findsOneWidget);
    await h.dispose(tester);
  });

  for (final (String code, int status, String copy) in <(String, int, String)>[
    ('identity_in_use', 409, 'gmailIdentityInUse'),
    ('google_email_unverified', 422, 'gmailEmailUnverified'),
    ('internal_error', 500, 'E-500'),
  ]) {
    testWidgets('error $code → its own copy; Retry starts a NEW link:start', (WidgetTester tester) async {
      final (Harness h, _) = await openSheet(tester);
      h.api.on('POST', kComplete, (_) => FakeResponse.error(status, code));
      await tapConnect(tester, h);
      final String shown = tester.widget<Text>(find.byKey(const Key('error-message'))).data!;
      expect(shown, copy == 'E-500' ? copyFor('gmailLinkFailed').replaceAll('{code}', 'E-500') : copyFor(copy));
      final String first = h.api.calls('POST', kComplete).single.data['state'] as String;
      await tester.tap(find.descendant(of: find.byKey(LinkedAccountsSheet.retryKey), matching: find.byType(HastaButton)));
      await h.settle(tester);
      expect(h.api.calls('POST', kStart), hasLength(2));
      expect(h.api.calls('POST', kComplete).last.data['state'], isNot(first));
      await h.dispose(tester);
    });
  }

  testWidgets('linked from /v1/me; unlink blocked → 409 copy, identity still shown', (WidgetTester tester) async {
    final (Harness h, _) = await openSheet(tester, identities: <Map<String, dynamic>>[
      <String, dynamic>{'provider': 'google', 'email_masked': 'h***@gmail.com', 'linked_at': '2026-11-23T00:00:00.000Z'},
    ]);
    h.api.on('DELETE', kIdentity, (_) => FakeResponse.error(409, 'recovery_required'));
    expect(find.text('ချိတ်ဆက်ပြီး — h***@gmail.com'), findsOneWidget);
    await tester.tap(find.byKey(LinkedAccountsSheet.unlinkKey));
    await h.settle(tester);
    expect(h.api.calls('DELETE', kIdentity), hasLength(1));
    expect(find.text('Recovery နည်းလမ်း တစ်ခု ရှိမှသာ ဖြုတ်နိုင်သည်'), findsOneWidget);
    expect(find.text('ချိတ်ဆက်ပြီး — h***@gmail.com'), findsOneWidget);
    await h.dispose(tester);
  });
}

/// Myanmar values of the PENDING-COPY keys, read from the ARB so the test does not duplicate copy.
final Map<String, dynamic> _my = jsonDecode(File('lib/l10n/app_my.arb').readAsStringSync()) as Map<String, dynamic>;
String copyFor(String key) => _my[key] as String;
