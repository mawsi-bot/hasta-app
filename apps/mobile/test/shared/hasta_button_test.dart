import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/core/design/hasta_theme.dart';
import 'package:hasta/shared/widgets/hasta_button.dart';

// SPEC 1.0.1 §14.1: the primary button fills with bg.brand / bg.brandPressed / bg.brandDisabled
// (ADR-0006 closes ADR-0005). Expected values come from the DS JSON, not from the generated Dart.
Color dsColor(String token, String theme) {
  final Map<String, dynamic> ds =
      jsonDecode(File('../../design/hasta-ds-1.0.2.json').readAsStringSync()) as Map<String, dynamic>;
  final Map<String, dynamic> t = (ds['tier2_semantic'] as Map<String, dynamic>)['color'][token] as Map<String, dynamic>;
  final String h = (t[theme] as String).substring(1);
  final int alpha = ((t['opacity'] as num? ?? 1) * 255).round();
  return Color(int.parse(h, radix: 16)).withAlpha(alpha);
}

Future<ButtonStyle> pumpPrimary(WidgetTester tester, ThemeData theme, {required bool enabled}) async {
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: Scaffold(body: HastaButton(label: 'Continue', onPressed: enabled ? () {} : null)),
  ));
  return tester.widget<TextButton>(find.byType(TextButton)).style!;
}

void main() {
  for (final (String name, ThemeData Function() theme) in <(String, ThemeData Function())>[
    ('light', HastaTheme.light),
    ('dark', HastaTheme.dark),
  ]) {
    testWidgets('primary fill = bg.brand / bg.brandPressed / bg.brandDisabled ($name)', (WidgetTester tester) async {
      final ButtonStyle on = await pumpPrimary(tester, theme(), enabled: true);
      expect(on.backgroundColor!.resolve(<WidgetState>{}), dsColor('bg.brand', name));
      expect(on.backgroundColor!.resolve(<WidgetState>{WidgetState.pressed}), dsColor('bg.brandPressed', name));
      final ButtonStyle off = await pumpPrimary(tester, theme(), enabled: false);
      expect(off.backgroundColor!.resolve(<WidgetState>{WidgetState.disabled}), dsColor('bg.brandDisabled', name));
    });
  }
}
