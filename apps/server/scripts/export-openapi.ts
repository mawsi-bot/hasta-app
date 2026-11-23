import 'reflect-metadata';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { buildOpenApi, createApp } from '../src/bootstrap';
import { parseEnv } from '../src/config/env';

/** Writes docs/api/openapi.json without connecting to a DB (Prisma/ioredis connect lazily on use). */
async function main(): Promise<void> {
  const env = parseEnv({
    HASTA_ENV: 'dev',
    HASTA_DATABASE_URL: 'postgresql://openapi:openapi@postgres:5432/openapi',
    HASTA_REDIS_URL: 'redis://redis:6379/15',
    HASTA_QUICK_TEST_ACCOUNTS_ENABLED: 'false',
  });
  const dummy = 'openapi-export-only-0123456789abcdef';
  const app = await createApp(env, { devicePepper: dummy, jwtAccessSecret: dummy, deviceTokenSecret: dummy });
  const doc = buildOpenApi(app);
  const out = join(__dirname, '..', '..', '..', 'docs', 'api', 'openapi.json');
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, `${JSON.stringify(doc, null, 2)}\n`);
  await app.close().catch(() => undefined);
  process.exit(0);
}
void main();
