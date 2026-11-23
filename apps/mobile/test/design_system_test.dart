import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasta/core/design/tokens.dart';

/// DS + Myanmar-first rules (SKILL rules 7–8, DS qaGate).
void main() {
  final Map<String, dynamic> ds =
      jsonDecode(File('../../design/hasta-ds-1.0.1.json').readAsStringSync()) as Map<String, dynamic>;
  final Map<String, dynamic> my = jsonDecode(File('lib/l10n/app_my.arb').readAsStringSync()) as Map<String, dynamic>;
  final Map<String, dynamic> en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;

  test('type scale: line-height ≥ 1.65×, bold ≤ 600 (headings ≤ 700)', () {
    const Map<String, TextStyle> styles = <String, TextStyle>{
      'display': HastaType.display, 'h1': HastaType.h1, 'h2': HastaType.h2, 'subtitle': HastaType.subtitle,
      'body': HastaType.body, 'bodyStrong': HastaType.bodyStrong, 'bodySm': HastaType.bodySm,
      'caption': HastaType.caption, 'micro': HastaType.micro, 'overline': HastaType.overline,
    };
    styles.forEach((String name, TextStyle s) {
      expect(s.height, greaterThanOrEqualTo(1.65), reason: name);
      final int cap = (name == 'display' || name == 'h1') ? 700 : 600;
      expect(s.fontWeight!.value, lessThanOrEqualTo(cap), reason: name);
      expect(s.fontFamily, HastaType.myanmarFamily);
    });
  });

  test('DS keyStrings used verbatim in the Myanmar ARB', () {
    final Map<String, dynamic> keys = (ds['copy'] as Map<String, dynamic>)['keyStrings'] as Map<String, dynamic>;
    const Map<String, String> map = <String, String>{
      'welcome.primary': 'welcomePrimary',
      'welcome.guestExplainer': 'welcomeGuestExplainer',
      'welcome.guestRisk': 'welcomeGuestRisk',
      'settings.connectGmail': 'settingsConnectGmail',
      'offline.banner': 'offlineBanner',
      'premium.guestBlocked': 'premiumGuestBlocked',
    };
    map.forEach((String dsKey, String arbKey) => expect(my[arbKey], keys[dsKey], reason: dsKey));
    expect((my['errorGeneric'] as String).replaceAll('{code}', 'E-500'), keys['error.generic']);
  });

  test('glossary: forbidden transliterations never appear in copy', () {
    final List<dynamic> forbidden = (ds['copy'] as Map<String, dynamic>)['forbidden'] as List<dynamic>;
    final Iterable<String> values = my.entries.where((MapEntry<String, dynamic> e) => !e.key.startsWith('@')).map((e) => '${e.value}');
    for (final Object? f in forbidden) {
      expect(values.where((String v) => v.contains('$f')), isEmpty, reason: '$f');
    }
  });

  test('ARB parity: every Myanmar key has an English translation', () {
    final Set<String> a = my.keys.where((String k) => !k.startsWith('@')).toSet();
    final Set<String> b = en.keys.where((String k) => !k.startsWith('@')).toSet();
    expect(a, b);
  });

  test('bottom navigation labels match DS navigation', () {
    final List<dynamic> items = (ds['navigation'] as Map<String, dynamic>)['bottomNavItems'] as List<dynamic>;
    expect(items.map((dynamic i) => (i as Map<String, dynamic>)['labelMy']).toList(),
        <String>[my['navHome'] as String, my['navDiscover'] as String, my['navChat'] as String, my['navNotifications'] as String, my['navProfile'] as String]);
  });

  test('qaGate hardCodedColors = 0: no hex / Color(0x…) / Colors.* outside generated tokens', () {
    final RegExp bad = RegExp(r'(#[0-9a-fA-F]{6}\b|Color\(0x[0-9a-fA-F]{8}\)|\bColors\.[a-z])');
    final List<String> hits = <String>[];
    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('core/design/tokens.dart') || f.path.endsWith('.g.dart')) continue;
      final List<String> lines = f.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        if (bad.hasMatch(lines[i])) hits.add('${f.path}:${i + 1}');
      }
    }
    expect(hits, isEmpty);
  });

  test('font budget: ≤ 3 bundled font files, no Zawgyi font', () {
    final List<FileSystemEntity> fonts =
        Directory('assets/fonts').listSync().where((FileSystemEntity f) => f.path.endsWith('.ttf') || f.path.endsWith('.otf')).toList();
    expect(fonts.length, lessThanOrEqualTo(3));
    expect(fonts.where((FileSystemEntity f) => f.path.toLowerCase().contains('zawgyi')), isEmpty);
  });
}
