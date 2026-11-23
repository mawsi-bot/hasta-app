/**
 * Seeds the 6 QA accounts (SPEC §19) into the configured database.
 * Refuses to run unless HASTA_ENV is dev, test or beta — seeded accounts can
 * never be created in staging/production.
 *
 * Run from apps/server:  npm run seed:test-accounts
 */
import 'reflect-metadata';
import { createApp } from '../../apps/server/src/bootstrap';
import { parseEnv, TEST_MODE_ENVS } from '../../apps/server/src/config/env';
import { loadSecrets } from '../../apps/server/src/config/secrets';
import { TestModeService } from '../../apps/server/src/modules/test-mode/test-mode.service';

async function main(): Promise<void> {
  const env = parseEnv(process.env);
  if (!TEST_MODE_ENVS.includes(env.HASTA_ENV)) {
    console.error(`refusing to seed test accounts in HASTA_ENV=${env.HASTA_ENV}`);
    process.exit(2);
  }
  const app = await createApp(env, await loadSecrets(env));
  try {
    const svc = app.get(TestModeService);
    await svc.ensureSeeded();
    const rows = await svc.list();
    for (const r of rows) console.log(`${r.handle.padEnd(16)} ${r.is_guest ? 'guest ' : 'linked'}  ${r.purpose}`);
  } finally {
    await app.close();
  }
}

main().catch((e: unknown) => {
  console.error('seed failed:', e instanceof Error ? e.message : 'unknown');
  process.exit(1);
});
