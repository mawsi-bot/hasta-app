// Runs meaningfully only in QA builds:
//   flutter test test/features/quick_test_panel_test.dart \
//     --dart-define=HASTA_ENV=test --dart-define=HASTA_QUICK_TEST_ACCOUNTS_ENABLED=true
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/core/config/build_config.dart';
import 'package:hasta/features/auth/presentation/welcome_screen.dart';
import 'package:hasta/features/home/presentation/home_shell.dart';
import 'package:hasta/core/security/token_store.dart';
import 'package:hasta/features/test_mode/quick_test_panel.dart';

import '../support/harness.dart';

void main() {
  const bool qa = BuildConfig.quickTestAccountsEnabled;

  group('QA flavour', () => testWidgets('QA build: 3 s long-press on the logo opens Quick test accounts; tap signs in (SPEC §19)',
      (WidgetTester tester) async {
    final Harness h = Harness();
    await h.tokens.write(SecureKey.deviceToken, 'dt_1');
    h.api.on('GET', '/v1/test/accounts', (_) => const FakeResponse(200, <String, dynamic>{
          'accounts': <Map<String, dynamic>>[
            <String, dynamic>{'handle': 'tester.a', 'purpose': 'dating-verified A', 'account_id': 'x', 'is_guest': true},
            <String, dynamic>{'handle': 'tester.fresh', 'purpose': 'fresh guest', 'account_id': 'y', 'is_guest': true},
          ],
        }));
    h.api.on('POST', '/v1/test/accounts/tester.a/session', (_) => FakeResponse(200, sessionJson(isNew: false)));
    await h.pumpApp(tester);

    // A short press (< 3 s) must not open it.
    await tester.longPress(find.byKey(WelcomeScreen.logoKey));
    await h.settle(tester);
    expect(find.byKey(const Key(kQuickTestPanelMarker)), findsNothing);

    final TestGesture g = await tester.startGesture(tester.getCenter(find.byKey(WelcomeScreen.logoKey)));
    await tester.pump(const Duration(seconds: 3, milliseconds: 100));
    await g.up();
    await h.settle(tester);
    expect(find.byKey(const Key(kQuickTestPanelMarker)), findsOneWidget);
    expect(find.text('tester.a'), findsOneWidget);

    await tester.tap(find.text('tester.a'));
    await h.settle(tester);
    expect(find.byType(HomeShell), findsOneWidget);
    await h.dispose(tester);
  }), skip: qa ? false : 'HAS-103 (#4): QA defines only; runs unskipped in CI step "Quick-test panel (QA define)"');

  test('release/production config compiles the panel flag to false (T36 guard logic)', () {
    // Guard expression is `flag && env in {dev,test,beta}`.
    expect(BuildConfig.isQaEnvironment || !BuildConfig.quickTestAccountsEnabled, isTrue);
    if (BuildConfig.env == 'production' || BuildConfig.env == 'staging') {
      expect(BuildConfig.quickTestAccountsEnabled, isFalse);
    }
  });
}
