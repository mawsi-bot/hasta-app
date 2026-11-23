import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createApp } from '../src/bootstrap';
import { parseEnv, type Env } from '../src/config/env';
import { loadSecrets } from '../src/config/secrets';
import { PrismaService } from '../src/infra/prisma.service';
import { RedisService } from '../src/infra/redis.service';
import { uuidv7 } from '../src/common/ids/uuidv7';

export interface TestCtx {
  app: INestApplication;
  prisma: PrismaService;
  redis: RedisService;
  http: () => ReturnType<typeof request>;
  env: Env;
}

export async function bootApp(overrides: Record<string, string> = {}): Promise<TestCtx> {
  const env = parseEnv({ ...process.env, ...overrides });
  const app = await createApp(env, await loadSecrets(env));
  await app.init();
  return {
    app,
    env,
    prisma: app.get(PrismaService),
    redis: app.get(RedisService),
    http: () => request(app.getHttpServer()),
  };
}

/** FK-reverse cleanup order (SPEC §21 test isolation). */
export async function resetDb(ctx: TestCtx): Promise<void> {
  await ctx.prisma.$executeRawUnsafe(
    'TRUNCATE idempotency_keys, entitlements, profiles, abuse_logs, device_cooldowns, transfer_tokens, sessions, device_bindings, identities, accounts RESTART IDENTITY CASCADE',
  );
  await ctx.redis.client.flushdb();
}

export const rawId = () => `qa-${uuidv7().replace(/-/g, '').slice(0, 24)}`;

export async function registerDevice(ctx: TestCtx, raw = rawId(), platform: 'android' | 'ios' = 'android') {
  const res = await ctx.http().post('/v1/auth/device/register').send({ raw_device_id: raw, platform, app_version: '1.0.0', os_version: '14' });
  if (res.status !== 200) throw new Error(`register failed ${res.status} ${JSON.stringify(res.body)}`);
  return { raw, ...(res.body as { device_hash: string; device_token: string }) };
}

export async function guest(ctx: TestCtx, deviceToken: string) {
  return ctx.http().post('/v1/auth/guest').set('Idempotency-Key', uuidv7()).send({ device_token: deviceToken, locale: 'my' });
}
