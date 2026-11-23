#!/usr/bin/env node
// Generates apps/mobile/lib/core/design/tokens.dart from design/hasta-ds-1.0.2.json.
// SKILL rule 8: the Dart token file is GENERATED, never hand-edited.
// CI runs this script and fails on `git diff --exit-code` (token drift gate).
//
// Usage: node tools/scripts/generate-tokens.mjs [--check]
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const srcPath = resolve(root, 'design/hasta-ds-1.0.2.json');
const outPath = resolve(root, 'apps/mobile/lib/core/design/tokens.dart');
const ds = JSON.parse(readFileSync(srcPath, 'utf8'));

const MYANMAR_MIN_LINE_HEIGHT = ds.typography.myanmarRules.minLineHeightRatio; // 1.65
const BOLD_MAX = ds.typography.myanmarRules.boldMaxWeight; // 600
const HEADING_BOLD_MAX = ds.typography.myanmarRules.headingBoldMaxWeight; // 700
const HEADING_STYLES = new Set(['display', 'h1']);

const camel = (dotted) =>
  dotted.split(/[.\-_]/).map((p, i) => (i === 0 ? p : p[0].toUpperCase() + p.slice(1))).join('');

// '#RRGGBB' or '#RRGGBBAA' (CSS order) -> Dart 0xAARRGGBB
// A token-level `opacity` (DS 1.0.1 bg.brandDisabled) becomes the alpha channel.
function dartColor(hex, opacity) {
  const h = hex.replace('#', '').toUpperCase();
  const a = Math.round((opacity ?? 1) * 255).toString(16).toUpperCase().padStart(2, '0');
  if (h.length === 6) return `Color(0x${a}${h})`;
  if (h.length === 8) return `Color(0x${h.slice(6)}${h.slice(0, 6)})`;
  throw new Error(`Unsupported colour literal ${hex}`);
}

const semantic = ds.tier2_semantic.color;
const names = Object.keys(semantic);
const themes = ['light', 'dark', 'amoled'];
// amoled falls back to dark when a token defines no amoled value.
const valueFor = (tok, theme) => tok[theme] ?? (theme === 'amoled' ? tok.dark : undefined) ?? tok.light;

const lines = [];
const w = (s = '') => lines.push(s);

w('// GENERATED CODE — DO NOT EDIT BY HAND.');
w(`// Source: design/hasta-ds-1.0.2.json (DS ${ds.meta.dsVersion})`);
w('// Regenerate: node tools/scripts/generate-tokens.mjs');
w('// ignore_for_file: public_member_api_docs, constant_identifier_names');
w();
w("import 'package:flutter/material.dart';");
w();
w('/// Semantic colour tokens (tier 2). Components must use these only.');
w('@immutable');
w('class HastaColors extends ThemeExtension<HastaColors> {');
w('  const HastaColors({');
for (const n of names) w(`    required this.${camel(n)},`);
w('  });');
w();
for (const n of names) {
  w(`  /// ${n} — ${semantic[n].use ?? ''}`);
  w(`  final Color ${camel(n)};`);
}
w();
for (const t of themes) {
  w(`  static const HastaColors ${t} = HastaColors(`);
  for (const n of names) w(`    ${camel(n)}: ${dartColor(valueFor(semantic[n], t), semantic[n].opacity)},`);
  w('  );');
  w();
}
w('  @override');
w('  HastaColors copyWith() => this;');
w();
w('  @override');
w('  HastaColors lerp(ThemeExtension<HastaColors>? other, double t) {');
w('    if (other is! HastaColors) return this;');
w('    return HastaColors(');
for (const n of names) w(`      ${camel(n)}: Color.lerp(${camel(n)}, other.${camel(n)}, t)!,`);
w('    );');
w('  }');
w('}');
w();

// Typography
const scale = ds.typography.scale;
w('/// Type scale. Line height is clamped to the Myanmar minimum ratio');
w(`/// (${MYANMAR_MIN_LINE_HEIGHT}x) and weights to the Myanmar bold caps (${BOLD_MAX}/${HEADING_BOLD_MAX}).`);
w('abstract final class HastaType {');
w(`  static const double myanmarMinLineHeightRatio = ${MYANMAR_MIN_LINE_HEIGHT};`);
w(`  static const String myanmarFamily = 'NotoSansMyanmar';`);
w(`  static const String latinFamily = 'Inter';`);
w();
const weightName = (n) => `FontWeight.w${n}`;
for (const [name, s] of Object.entries(scale)) {
  if (!s.lineHeight) continue;
  const ratio = Math.max(s.lineHeight / s.size, MYANMAR_MIN_LINE_HEIGHT);
  const cap = HEADING_STYLES.has(name) ? HEADING_BOLD_MAX : BOLD_MAX;
  const weight = Math.min(s.weight, cap);
  w(`  /// ${s.use ?? name}`);
  w(`  static const TextStyle ${name} = TextStyle(`);
  w(`    fontFamily: myanmarFamily,`);
  w(`    fontFamilyFallback: <String>[latinFamily],`);
  w(`    fontSize: ${s.size},`);
  w(`    height: ${ratio.toFixed(4)},`);
  w(`    fontWeight: ${weightName(weight)},`);
  w(`    letterSpacing: ${s.letterSpacing ?? 0},`);
  w('  );');
}
if (scale.largeTextModeBody) w(`  static const double largeTextModeBodySize = ${scale.largeTextModeBody.size};`);
w('}');
w();

// Spacing
w('abstract final class HastaSpace {');
for (const v of ds.spacing.scale) w(`  static const double s${v} = ${v};`);
for (const [k, v] of Object.entries(ds.spacing.usage)) {
  if (typeof v === 'number') w(`  static const double ${camel(k)} = ${v};`);
}
w('}');
w();

w('abstract final class HastaRadius {');
for (const [k, v] of Object.entries(ds.shape.radius)) w(`  static const double ${camel(k)} = ${v};`);
for (const [k, v] of Object.entries(ds.shape.borderWidth)) w(`  static const double border${k[0].toUpperCase() + k.slice(1)} = ${v};`);
w('}');
w();

w('abstract final class HastaMotion {');
for (const [k, v] of Object.entries(ds.motion.duration)) w(`  static const Duration ${camel(k)} = Duration(milliseconds: ${v});`);
w('}');
w();

w('abstract final class HastaSize {');
for (const [k, v] of Object.entries(ds.components.buttonSizes)) w(`  static const double button${k[0].toUpperCase() + k.slice(1)} = ${v};`);
w(`  static const double touchTargetAndroid = ${ds.components.touchTarget.android};`);
w(`  static const double touchTargetIos = ${ds.components.touchTarget.ios};`);
w(`  static const double contentMaxWidth = ${ds.layout.contentMaxWidth};`);
w(`  static const int skeletonRowsMax = ${ds.performanceBudget.skeletonRowsMax};`);
w('}');
w();

const output = lines.join('\n');
if (process.argv.includes('--check')) {
  const current = readFileSync(outPath, 'utf8');
  if (current !== output) {
    console.error('tokens.dart is out of date — run node tools/scripts/generate-tokens.mjs');
    process.exit(1);
  }
  console.log('tokens.dart up to date');
} else {
  writeFileSync(outPath, output);
  console.log(`wrote ${outPath} (${names.length} colour tokens)`);
}
