import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/features/auth/presentation/welcome_screen.dart';
import 'package:hasta/features/settings/presentation/settings_screen.dart';
import 'package:hasta/shared/widgets/list_row.dart';

import '../support/harness.dart';
import '../support/signed_in.dart';

Future<void> openSettings(WidgetTester tester, Harness h) async {
  await h.pumpApp(tester);
  await tester.tap(find.text('ပရိုဖိုင်'));
  await h.settle(tester);
  await tester.tap(find.byKey(const Key('open-settings')));
  await h.settle(tester);
  expect(find.byType(SettingsScreen), findsOneWidget);
}

void main() {
  testWidgets('Settings shell lists all 11 sections (SPEC §10.3)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 12000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final Harness h = await signedInHarness(tester);
    await openSettings(tester, h);
    const List<String> sections = <String>[
      'အကောင့်', 'ကိုယ်ရေးအချက်အလက် နှင့် လုံခြုံရေး', 'အသိပေးချက်များ', 'ဒေတာ နှင့် သိုလှောင်မှု', 'ချတ်',
      'အသွင်အပြင်', 'Dating', 'စက်များ', 'ဘာသာစကား', 'Premium', 'အကူအညီ',
    ];
    final Iterable<String> rendered = tester
        .widgetList<SectionHeader>(find.byType(SectionHeader, skipOffstage: false))
        .map((SectionHeader w) => w.label);
    expect(rendered.toList(), sections);
    await h.dispose(tester);
  });

  testWidgets('T43 Connect Gmail while offline: row visibly disabled with reason copy', (WidgetTester tester) async {
    final Harness h = await signedInHarness(tester, online: false);
    await openSettings(tester, h);
    final HastaListRow row = tester.widget(find.byKey(SettingsScreen.connectGmailKey));
    expect(row.enabled, isFalse);
    expect(find.descendant(of: find.byKey(SettingsScreen.connectGmailKey), matching: find.text('Gmail ချိတ်ဆက်ရန်')), findsOneWidget);
    expect(find.descendant(of: find.byKey(SettingsScreen.connectGmailKey), matching: find.text('အင်တာနက် ချိတ်ဆက်ထားမှ အသုံးပြုနိုင်ပါသည်')),
        findsOneWidget);
    // Offline settings state: local-only banner.
    expect(find.textContaining('ချိန်ညှိမှု သိမ်းမထားပါ'), findsOneWidget);
    // Tapping does nothing.
    await tester.tap(find.byKey(SettingsScreen.connectGmailKey), warnIfMissed: false);
    await h.settle(tester, 2);
    expect(find.byType(SnackBar), findsNothing);
    // Back online → enabled.
    h.connectivity.online = true;
    await h.settle(tester);
    expect(tester.widget<HastaListRow>(find.byKey(SettingsScreen.connectGmailKey)).enabled, isTrue);
    await h.dispose(tester);
  });

  testWidgets('Language switch is local-only and re-renders in English', (WidgetTester tester) async {
    final Harness h = await signedInHarness(tester, online: false);
    await openSettings(tester, h);
    await tester.dragUntilVisible(find.byKey(const Key('lang-en')), find.byKey(const Key('settings-list')), const Offset(0, -200));
    await tester.tap(find.byKey(const Key('lang-en')));
    await h.settle(tester);
    expect(find.text('Settings'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('Sign out keeps the device token (binding) and returns to Welcome', (WidgetTester tester) async {
    final Harness h = await signedInHarness(tester);
    h.api.on('POST', '/v1/auth/logout', (_) => const FakeResponse(204));
    await openSettings(tester, h);
    await tester.dragUntilVisible(find.byKey(const Key('settings-sign-out')), find.byKey(const Key('settings-list')), const Offset(0, -300));
    await tester.tap(find.byKey(const Key('settings-sign-out')));
    await h.settle(tester);
    await tester.tap(find.byKey(const Key('confirm-sign-out')));
    await h.settle(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(h.api.calls('POST', '/v1/auth/logout'), hasLength(1));
    expect(h.tokens.values.keys.map((k) => k.name), <String>['deviceToken']);
    await h.dispose(tester);
  });
}
