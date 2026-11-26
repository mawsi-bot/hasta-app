import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/core/design/tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasta/app.dart';
import 'package:hasta/features/auth/presentation/welcome_screen.dart';
import 'package:hasta/features/linked_accounts/presentation/linked_accounts_sheet.dart';

import '../support/harness.dart';
import '../support/signed_in.dart';

void expectNoClipping(WidgetTester tester, Finder root) {
  final Iterable<RenderParagraph> paragraphs = tester
      .renderObjectList<RenderObject>(find.descendant(of: root, matching: find.byType(RichText)))
      .whereType<RenderParagraph>();
  expect(paragraphs, isNotEmpty);
  for (final RenderParagraph p in paragraphs) {
    final String text = p.text.toPlainText();
    expect(p.didExceedMaxLines, isFalse, reason: 'truncated: $text');
    expect(p.getMaxIntrinsicHeight(p.size.width), lessThanOrEqualTo(p.size.height + 0.5), reason: 'clipped: $text');
  }
}

// SPEC 1.0.1 §14.2 + SKILL rule 5: Myanmar text at 200 % scale on a small phone must never clip —
// min-height only, never a fixed height. Match-reveal does not exist yet (dating sprint) → still open.
void main() {
  // Real glyph metrics: the default test font draws every code point as a 1 em square and would
  // overstate Myanmar width several-fold.
  setUpAll(() async {
    await (FontLoader(HastaType.myanmarFamily)..addFont(rootBundle.load('assets/fonts/NotoSansMyanmar-Variable.ttf'))).load();
    await (FontLoader(HastaType.latinFamily)..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
  });

  testWidgets('welcome hero at 200 % text scale on 320×568: no overflow, no clipped or truncated text',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final Harness h = Harness();
    await h.pumpApp(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    final Iterable<RenderParagraph> paragraphs = tester
        .renderObjectList<RenderObject>(find.descendant(of: find.byType(WelcomeScreen), matching: find.byType(RichText)))
        .whereType<RenderParagraph>();
    expect(paragraphs, isNotEmpty);
    for (final RenderParagraph p in paragraphs) {
      final String text = p.text.toPlainText();
      expect(p.didExceedMaxLines, isFalse, reason: 'truncated: $text');
      expect(p.getMaxIntrinsicHeight(p.size.width), lessThanOrEqualTo(p.size.height + 0.5), reason: 'clipped: $text');
    }
    await h.dispose(tester);
  });

  for (final bool linked in <bool>[false, true]) {
    testWidgets('Linked accounts sheet (${linked ? 'linked' : 'empty'}) at 200 % on 320×568: no clipped text',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320 * 3, 568 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final Harness h = await signedInHarness(tester);
      h.api.on('GET', '/v1/me', (_) => FakeResponse(200, meJson()
        ..['identities'] = <Map<String, dynamic>>[
          if (linked) <String, dynamic>{'provider': 'google', 'email_masked': 'h***@gmail.com'},
        ]));
      await tester.pumpWidget(ProviderScope(overrides: h.overrides, child: const HastaApp()));
      await h.settle(tester);
      unawaited(showLinkedAccountsSheet(tester.element(find.byType(Navigator).first)));
      await h.settle(tester);
      expect(find.byKey(linked ? LinkedAccountsSheet.unlinkKey : LinkedAccountsSheet.connectKey), findsOneWidget);
      expect(tester.takeException(), isNull);
      expectNoClipping(tester, find.byType(LinkedAccountsSheet));
      await h.dispose(tester);
    });
  }
}
