// Tests for tools/ci/gates.mjs. Run: node --test tools/ci/
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  ROOT, readAllowlist, allowlistErrors, t45Violations, t48Violations, storeTagAllowed, mobileDepViolations,
} from './gates.mjs';

const LEGACY = 'nex' + 'us';

test('T45 allowlist: explicit docs files only, never apps/ infra/ design/ tools/, no globs', () => {
  const list = readAllowlist();
  assert.ok(list.length > 0);
  assert.deepEqual(allowlistErrors(list), []);
  for (const bad of ['apps/server/src/x.ts', 'infra/a.tf', 'design/hasta-ds-1.0.2.json', 'tools/ci/x.sh', 'docs/**', 'docs/notes.md', '../x']) {
    assert.ok(allowlistErrors([bad]).length > 0, `${bad} must be rejected`);
  }
});

test('T45 has teeth: a planted legacy name inside apps/server/src fails the gate', () => {
  const plant = join(ROOT, 'apps/server/src/t45-plant.tmp.ts');
  assert.deepEqual(t45Violations(), []);
  try {
    writeFileSync(plant, `export const brand = '${LEGACY}';\n`);
    assert.deepEqual(t45Violations(), ['apps/server/src/t45-plant.tmp.ts']);
  } finally {
    rmSync(plant, { force: true });
  }
});

test('T45 has teeth: an unlisted docs file is scanned', () => {
  const dir = join(ROOT, 'docs/t45-plant');
  try {
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, 'Hasta_v1_Planted.md'), `${LEGACY}\n`);
    assert.deepEqual(t45Violations(), ['docs/t45-plant/Hasta_v1_Planted.md']);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('T48: compose DB must be PostgreSQL major 16 and match the CI service image', () => {
  const ci = 'services:\n  postgres:\n    image: postgis/postgis:16-3.4@sha256:' + 'a'.repeat(64) + '\n';
  const compose = (img) => `services:\n  postgres:\n    image: ${img}\n  redis:\n    image: redis:7.2\n`;
  const pinned = 'postgis/postgis:16-3.4@sha256:' + 'a'.repeat(64);
  assert.deepEqual(t48Violations(compose(pinned), ci), []);
  assert.deepEqual(t48Violations(compose('postgres:16.16'), compose('postgres:16.16')), []);
  assert.match(t48Violations(compose('postgres:18'), compose('postgres:18'))[0], /major 16/);
  assert.match(t48Violations(compose('postgis/postgis:17-3.4'), compose('postgis/postgis:17-3.4'))[0], /major 16/);
  assert.match(t48Violations(compose(pinned), compose('postgres:16.16')).join(), /CI service image/);
  assert.deepEqual(
    t48Violations(readFileSync(join(ROOT, 'docker-compose.yml'), 'utf8'), readFileSync(join(ROOT, '.github/workflows/ci.yml'), 'utf8')),
    [],
  );
});

test('T49: store upload fails closed on any tag not matching ^v1\\.', () => {
  for (const t of ['v0.1.0', 'v0.9.9-rc1', 'v10.0.0', 'v1', '1.0.0', '', undefined]) assert.equal(storeTagAllowed(t), false, String(t));
  for (const t of ['v1.0.0', 'v1.2.3-rc.1']) assert.equal(storeTagAllowed(t), true, t);
});

test('T49: every store-upload workflow job runs the tag guard first', () => {
  const wf = readFileSync(join(ROOT, '.github/workflows/store-upload.yml'), 'utf8');
  const firstRun = wf.split('\n').find((l) => /^\s+run:/.test(l));
  assert.match(firstRun ?? '', /gates\.mjs t49/);
});

test('T37 (mobile boundary): a planted google_sign_in / sign_in_with_apple dependency fails', () => {
  const real = readFileSync(join(ROOT, 'apps/mobile/pubspec.yaml'), 'utf8');
  assert.deepEqual(mobileDepViolations(real), []);
  const planted = real.replace(/^dependencies:\n/m, 'dependencies:\n  google_sign_in: ^6.2.1\n');
  assert.deepEqual(mobileDepViolations(planted), ['google_sign_in']);
  assert.deepEqual(mobileDepViolations('dev_dependencies:\n  sign_in_with_apple: ^6.0.0\n'), ['sign_in_with_apple']);
});
