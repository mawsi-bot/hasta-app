import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/core/design/tokens.dart';
import 'package:hasta/features/auth/presentation/welcome_screen.dart';

import '../support/harness.dart';

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
}
