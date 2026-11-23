#!/usr/bin/env node
// Static gates T45 (legacy name), T48 (Postgres major 16), T49 (store tag), T37 mobile boundary.
// CLI: node tools/ci/gates.mjs <t45|t48|t49 <tag>|mobile-deps|all>. Tests: node --test tools/ci/
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

export const ROOT = join(dirname(fileURLToPath(import.meta.url)), '../..');
const LEGACY = 'nex' + 'us'; // concatenated so this file never matches itself
const SCAN = ['apps', 'infra', 'tools', '.github', 'design', 'docs'];
const SKIP = ['node_modules', 'build', '.dart_tool', 'dist', 'coverage'].flatMap((d) => ['--glob', `!**/${d}/**`]);

/** SPEC §16 T45: explicit docs files that exist to perform the rename. Nothing else. */
export const readAllowlist = () =>
  readFileSync(join(ROOT, 'tools/ci/t45-allowlist.txt'), 'utf8').split('\n').map((l) => l.trim()).filter((l) => l && !l.startsWith('#'));

export function allowlistErrors(list) {
  const ok = /^docs\/(Hasta_v1_[A-Za-z_]+\.md|ADR\/\d{4}-[a-z0-9-]+\.md|copy-review\/[A-Za-z0-9_.-]+\.md)$/;
  return list.flatMap((p) => {
    if (/^(apps|infra|design|tools)\//.test(p)) return [`${p}: forbidden tree`];
    if (/[*?[\]{}]|\.\./.test(p)) return [`${p}: globs and parent paths are not allowed`];
    if (!ok.test(p)) return [`${p}: only docs spec, ADR and copy-review files may be allowlisted`];
    return existsSync(join(ROOT, p)) ? [] : [`${p}: does not exist`];
  });
}

export function t45Violations() {
  const allow = new Set(readAllowlist());
  let out = '';
  try {
    out = execFileSync('rg', ['-l', '-i', ...SKIP, LEGACY, ...SCAN], { cwd: ROOT, encoding: 'utf8' });
  } catch (e) {
    if (e.status !== 1) throw e; // 1 = no matches
  }
  return out.split('\n').filter(Boolean).filter((f) => !allow.has(f)).sort();
}

const serviceImage = (yaml, svc) => {
  const m = yaml.match(new RegExp(`^(\\s+)${svc}:\\n(?:\\1\\s+.*\\n)*?\\1\\s+image:\\s*(\\S+)`, 'm'));
  return m ? m[2] : undefined;
};

/** SPEC 1.0.2 §16 T48: the gate pins the PostgreSQL MAJOR (16); postgis/postgis:16-x satisfies it. */
export function t48Violations(composeYaml, ciYaml) {
  const img = serviceImage(composeYaml, 'postgres');
  const out = [];
  if (!img || !/^(postgres:16(\.\d+)*|postgis\/postgis:16-\d+(\.\d+)*)(@sha256:[0-9a-f]{64})?$/.test(img)) {
    out.push(`compose postgres image '${img ?? 'missing'}' is not PostgreSQL major 16`);
  }
  const ci = serviceImage(ciYaml, 'postgres');
  if (ci !== img) out.push(`CI service image '${ci ?? 'missing'}' differs from compose '${img}'`);
  return out;
}

/** SPEC §0.1 Tag rule / T49: only v1.* tags may reach a store track. */
export const storeTagAllowed = (tag) => typeof tag === 'string' && /^v1\./.test(tag);

/** Mobile boundary of T37: Gmail linking is browser-based (§5.4), the app never ships a sign-in SDK. */
export const mobileDepViolations = (pubspec) =>
  ['google_sign_in', 'sign_in_with_apple'].filter((p) => new RegExp(`^\\s+${p}\\s*:`, 'm').test(pubspec));

const SDK_IMPORT = /^\s*import\s+['"]package:(google_sign_in|sign_in_with_apple)\//m;
const dartFiles = (dir) => readdirSync(join(ROOT, dir), { recursive: true }).filter((f) => f.endsWith('.dart'))
  .map((f) => ({ path: `${dir}/${f}`, text: readFileSync(join(ROOT, dir, f), 'utf8') }));

/** T37 mobile boundary, source side: no sign-in SDK import anywhere in apps/mobile/lib (even if a dep sneaks in transitively). */
export const mobileImportViolations = (files = dartFiles('apps/mobile/lib')) =>
  files.filter((f) => SDK_IMPORT.test(f.text)).map((f) => f.path).sort();

function main([cmd, arg]) {
  const read = (p) => readFileSync(join(ROOT, p), 'utf8');
  const checks = {
    t45: () => [...allowlistErrors(readAllowlist()), ...t45Violations().map((f) => `${f}: legacy product name`)],
    t48: () => t48Violations(read('docker-compose.yml'), read('.github/workflows/ci.yml')),
    t49: () => (storeTagAllowed(arg) ? [] : [`tag '${arg ?? ''}' does not match ^v1\\. — store upload refused`]),
    'mobile-deps': () => [
      ...mobileDepViolations(read('apps/mobile/pubspec.yaml')).map((p) => `${p}: forbidden in the app`),
      ...mobileImportViolations().map((f) => `${f}: sign-in SDK import`),
    ],
  };
  const run = cmd === 'all' ? ['t45', 't48', 'mobile-deps'] : [cmd];
  let fail = false;
  for (const c of run) {
    if (!checks[c]) throw new Error(`unknown gate ${c}`);
    const v = checks[c]();
    console.log(`${c.toUpperCase()} ${v.length ? 'FAIL' : 'PASS'}`);
    v.forEach((m) => console.log(`  ${m}`));
    fail ||= v.length > 0;
  }
  process.exit(fail ? 1 : 0);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main(process.argv.slice(2));
