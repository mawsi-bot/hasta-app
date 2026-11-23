import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/core/db/drift/app_database.dart';
import 'package:hasta/features/profile/presentation/edit_profile_screen.dart';

import '../support/harness.dart';
import '../support/signed_in.dart';

Map<String, dynamic> profileJson({String? name, String hlc = '0'}) => <String, dynamic>{
      'display_name': name,
      'username': null,
      'bio': null,
      'avatar_url': null,
      'birth_date': null,
      'updated_hlc': hlc,
    };

void main() {
  testWidgets('Home shell: exactly 5 tabs in DS order, empty states, offline banner', (WidgetTester tester) async {
    final Harness h = await signedInHarness(tester, online: false);
    await h.pumpApp(tester);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    for (final String label in <String>['ပင်မ', 'ရှာဖွေ', 'ချတ်', 'အသိပေး', 'ပရိုဖိုင်']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('အသိုင်းအဝိုင်းနဲ့ စတင်ပါ'), findsOneWidget);
    await tester.tap(find.text('ချတ်'));
    await h.settle(tester);
    expect(find.text('စကားပြောမှု မရှိသေး'), findsOneWidget);
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('Profile loading state: skeleton until the first local/remote result', (WidgetTester tester) async {
    final Harness h = await signedInHarness(tester, withProfile: false);
    h.api.on('GET', '/v1/me', (_) => const FakeResponse.offline());
    await h.pumpApp(tester);
    await tester.tap(find.text('ပရိုဖိုင်'));
    await h.settle(tester, 1);
    expect(find.byKey(const Key('skeleton')).evaluate().isNotEmpty || find.byKey(const Key('error-message')).evaluate().isNotEmpty,
        isTrue);
    await h.dispose(tester);
  });

  testWidgets('Profile error state: no cache + /v1/me fails → retry with hidden code', (WidgetTester tester) async {
    final Harness h = await signedInHarness(tester, withProfile: false);
    h.api.on('GET', '/v1/me', (_) => FakeResponse.error(500, 'internal_error'));
    await h.pumpApp(tester);
    await tester.tap(find.text('ပရိုဖိုင်'));
    await h.settle(tester);
    expect(find.text('မအောင်မြင်ပါ။ ခဏနေမှ ပြန်ကြိုးစားပါ။ (E-500)'), findsOneWidget);
    h.api.on('GET', '/v1/me', (_) => FakeResponse(200, meJson(profile: profileJson(name: 'Aung'))));
    await tester.tap(find.text('ပြန်ကြိုးစားရန်'));
    await h.settle(tester);
    expect(find.text('Aung'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('Offline edit → Drift + outbox (waiting badge) → online drain sends PATCH with Idempotency-Key + hlc',
      (WidgetTester tester) async {
    final Harness h = await signedInHarness(tester, online: false);
    String? sentKey;
    Map<String, dynamic>? sentBody;
    h.api.on('PATCH', '/v1/profile', (o) {
      sentKey = o.headers['Idempotency-Key'] as String?;
      sentBody = o.data as Map<String, dynamic>;
      return FakeResponse(200, <String, dynamic>{
        'profile': profileJson(name: 'မောင်မောင်', hlc: sentBody!['hlc'] as String),
        'applied': <String>['display_name'],
        'ignored': <String>[],
      });
    });
    await h.pumpApp(tester);
    await tester.tap(find.text('ပရိုဖိုင်'));
    await h.settle(tester);
    expect(find.text('အမည် မထည့်ရသေးပါ'), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit-profile')));
    await h.settle(tester);
    expect(find.byType(EditProfileScreen), findsOneWidget);
    await tester.enterText(find.byKey(const Key('field-display-name')), 'မောင်မောင်');
    await tester.tap(find.byKey(const Key('save-profile')));
    await h.settle(tester);

    // Local-first: visible immediately, queued, nothing sent.
    expect(tester.widget<Text>(find.byKey(const Key('profile-name'))).data, 'မောင်မောင်');
    expect(find.byKey(const Key('profile-pending')), findsOneWidget);
    expect(h.api.calls('PATCH', '/v1/profile'), isEmpty);
    final OutboxEntry queued = (await tester.runAsync(() => h.db.select(h.db.outboxEntries).getSingle()))!;

    h.connectivity.online = true;
    await h.settle(tester, 10);
    expect(sentKey, queued.idempotencyKey);
    expect(sentBody!['display_name'], 'မောင်မောင်');
    expect(sentBody!['hlc'], matches(RegExp(r'^\d+$')));
    expect(sentBody!.containsKey('account_id'), isFalse);
    expect(find.byKey(const Key('profile-pending')), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('Username rule validated client-side (a–z 0–9 . _ , 3–32)', (WidgetTester tester) async {
    final Harness h = await signedInHarness(tester);
    await h.pumpApp(tester);
    await tester.tap(find.text('ပရိုဖိုင်'));
    await h.settle(tester);
    await tester.tap(find.byKey(const Key('edit-profile')));
    await h.settle(tester);
    await tester.enterText(find.byKey(const Key('field-username')), 'Bad Name');
    await tester.tap(find.byKey(const Key('save-profile')));
    await h.settle(tester);
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(h.api.calls('PATCH', '/v1/profile'), isEmpty);
    await h.dispose(tester);
  });
}
