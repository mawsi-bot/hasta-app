import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/core/config/build_config.dart';
import 'package:hasta/core/db/drift/app_database.dart';
import 'package:hasta/core/security/token_store.dart';
import 'package:hasta/features/auth/presentation/welcome_screen.dart';
import 'package:hasta/features/home/presentation/home_shell.dart';
import 'package:hasta/features/test_mode/quick_test_panel.dart';
import 'package:hasta/shared/widgets/hasta_button.dart';

import '../support/harness.dart';

void main() {
  Harness freshDevice({bool online = true}) {
    final Harness h = Harness(online: online);
    h.api.on('POST', '/v1/auth/device/register', (_) => const FakeResponse(200, <String, dynamic>{
          'device_hash': 'h',
          'device_token': 'dt_new',
          'platform': 'android',
          'registered_at': '2026-11-23T00:00:00.000Z',
        }));
    return h;
  }

  Future<void> tapPrimary(WidgetTester tester, Harness h) async {
    await tester.tap(find.byKey(WelcomeScreen.primaryButtonKey));
    await h.settle(tester);
  }

  testWidgets('Welcome renders ONE primary button + DS guest explainer/risk copy, no Gmail/Google/phone CTA',
      (WidgetTester tester) async {
    final Harness h = freshDevice();
    await h.pumpApp(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(HastaButton), findsOneWidget);
    expect(find.text('စတင်အသုံးပြုရန်'), findsOneWidget);
    expect(find.text('အီးမေးလ်၊ ဖုန်းနံပါတ် မလိုပါ။ ဤဖုန်းတွင် ချက်ချင်း စတင်နိုင်သည်။'), findsOneWidget);
    expect(find.text('ဖုန်းပျောက်ပါက ဤအကောင့်ကို ပြန်ရနိုင်မည် မဟုတ်ပါ။ Gmail ချိတ်ဆက်ထားရန် အကြံပြုသည်။'), findsOneWidget);
    expect(find.textContaining('Google'), findsNothing);
    expect(find.text('Gmail ချိတ်ဆက်ရန်'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('T40 guest one-tap on a fresh device: registers device, creates guest, session stored, Home shown',
      (WidgetTester tester) async {
    final Harness h = freshDevice();
    h.api.on('POST', '/v1/auth/guest', (_) => FakeResponse(200, sessionJson()));
    await h.pumpApp(tester);
    await tapPrimary(tester, h);

    expect(h.api.calls('POST', '/v1/auth/device/register'), hasLength(1));
    final Map<String, dynamic> body = h.api.calls('POST', '/v1/auth/guest').single.data as Map<String, dynamic>;
    expect(body['device_token'], 'dt_new');
    expect(await h.tokens.read(SecureKey.accessToken), 'at_1');
    expect(await h.tokens.read(SecureKey.refreshToken), 'rt_1');
    final LocalAccount a = (await tester.runAsync(() => h.db.select(h.db.localAccounts).getSingle()))!;
    expect(a.isGuest, isTrue);
    expect(find.byType(HomeShell), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('T41 device with an existing binding: reuses the stored device token and resumes (no re-register)',
      (WidgetTester tester) async {
    final Harness h = freshDevice();
    await h.tokens.write(SecureKey.deviceToken, 'dt_existing');
    h.api.on('POST', '/v1/auth/guest', (_) => FakeResponse(200, sessionJson(isNew: false)));
    await h.pumpApp(tester);
    await tapPrimary(tester, h);
    expect(h.api.calls('POST', '/v1/auth/device/register'), isEmpty);
    expect((h.api.calls('POST', '/v1/auth/guest').single.data as Map<String, dynamic>)['device_token'], 'dt_existing');
    expect(h.device.reads, 0, reason: 'raw device id is not re-read when a device token exists');
    expect(find.byType(HomeShell), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('T42 cooldown: 429 device_cooldown shows remaining days and disables the CTA',
      (WidgetTester tester) async {
    final Harness h = freshDevice();
    h.api.on('POST', '/v1/auth/guest',
        (_) => FakeResponse.error(429, 'device_cooldown', details: <String, dynamic>{'retry_after_days': 12}));
    await h.pumpApp(tester);
    await tapPrimary(tester, h);
    expect(find.byKey(WelcomeScreen.issueKey), findsOneWidget);
    expect(find.textContaining('12'), findsOneWidget);
    final TextButton btn = tester.widget(find.descendant(of: find.byKey(WelcomeScreen.primaryButtonKey), matching: find.byType(TextButton)));
    expect(btn.onPressed, isNull);
    await h.dispose(tester);
  });

  testWidgets('disabled state: guest flag off (feature_disabled) shows reason, CTA disabled', (WidgetTester tester) async {
    final Harness h = freshDevice();
    h.api.on('POST', '/v1/auth/guest', (_) => FakeResponse.error(403, 'feature_disabled'));
    await h.pumpApp(tester);
    await tapPrimary(tester, h);
    expect(find.text('အကောင့်အသစ် ဖွင့်ခြင်းကို ယာယီ ပိတ်ထားပါသည်။ ခဏနေမှ ပြန်ကြိုးစားပါ။'), findsOneWidget);
    final TextButton btn = tester.widget(find.descendant(of: find.byKey(WelcomeScreen.primaryButtonKey), matching: find.byType(TextButton)));
    expect(btn.onPressed, isNull);
    await h.dispose(tester);
  });

  testWidgets('error state follows the DS formula with hidden code; CTA stays enabled for retry',
      (WidgetTester tester) async {
    final Harness h = freshDevice();
    h.api.on('POST', '/v1/auth/guest', (_) => FakeResponse.error(500, 'internal_error'));
    await h.pumpApp(tester);
    await tapPrimary(tester, h);
    expect(find.text('မအောင်မြင်ပါ။ ခဏနေမှ ပြန်ကြိုးစားပါ။ (E-500)'), findsOneWidget);
    final TextButton btn = tester.widget(find.descendant(of: find.byKey(WelcomeScreen.primaryButtonKey), matching: find.byType(TextButton)));
    expect(btn.onPressed, isNotNull);
    await h.dispose(tester);
  });

  testWidgets('loading state: spinner while signing in; double tap sends one request', (WidgetTester tester) async {
    final Harness h = freshDevice();
    final Completer<FakeResponse> gate = Completer<FakeResponse>();
    h.api.on('POST', '/v1/auth/guest', (_) => gate.future);
    await h.pumpApp(tester);
    await tester.tap(find.byKey(WelcomeScreen.primaryButtonKey));
    await h.settle(tester, 3);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(WelcomeScreen.primaryButtonKey), warnIfMissed: false);
    await h.settle(tester, 2);
    expect(h.api.calls('POST', '/v1/auth/guest'), hasLength(1));
    gate.complete(FakeResponse(200, sessionJson()));
    await h.settle(tester);
    expect(find.byType(HomeShell), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('offline state: banner + disabled CTA + reason, no network call', (WidgetTester tester) async {
    final Harness h = freshDevice(online: false);
    await h.pumpApp(tester);
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    expect(find.text('အင်တာနက်မရှိပါ။ ပို့ထားသော စာများကို ချိတ်ဆက်သည်နှင့် ပို့ပေးပါမည်။'), findsOneWidget);
    expect(find.byKey(const Key('welcome-offline-hint')), findsOneWidget);
    await tester.tap(find.byKey(WelcomeScreen.primaryButtonKey), warnIfMissed: false);
    await h.settle(tester);
    expect(h.api.requests.where((r) => r.path.startsWith('/v1/auth')), isEmpty);
    h.connectivity.online = true;
    await h.settle(tester);
    expect(find.byKey(const Key('offline-banner')), findsNothing);
    await h.dispose(tester);
  });

  group('default flavour', () => testWidgets('T36 (app side): default build has the quick-test flag compiled off; 3 s long-press opens nothing',
      (WidgetTester tester) async {
    expect(BuildConfig.quickTestAccountsEnabled, isFalse);
    final Harness h = freshDevice();
    await h.pumpApp(tester);
    await tester.longPress(find.byKey(WelcomeScreen.logoKey));
    await tester.pump(const Duration(seconds: 4));
    await h.settle(tester);
    expect(find.byKey(const Key(kQuickTestPanelMarker)), findsNothing);
    await h.dispose(tester);
  }), skip: BuildConfig.quickTestAccountsEnabled ? 'HAS-103 (#4): default-build assertion; QA run covers the opposite' : false);

  testWidgets('restore: stored session + cached account opens Home offline (offline-first)', (WidgetTester tester) async {
    final Harness h = freshDevice(online: false);
    await h.tokens.write(SecureKey.refreshToken, 'rt_1');
    await h.tokens.write(SecureKey.accessToken, 'at_1');
    await h.db.into(h.db.localAccounts).insert(LocalAccountsCompanion.insert(
        id: 'acc', isGuest: true, status: 'active', createdAt: DateTime.utc(2026), syncedAt: DateTime.utc(2026)));
    await h.pumpApp(tester);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    await h.dispose(tester);
  });
}
