import { uuidv7 } from '../../src/common/ids/uuidv7';
import { bootApp, guest, rawId, registerDevice, resetDb, type TestCtx } from '../helpers';

let ctx: TestCtx;
beforeAll(async () => {
  ctx = await bootApp();
});
afterAll(async () => {
  await ctx.app.close();
});
beforeEach(async () => {
  await resetDb(ctx);
});

describe('POST /v1/auth/device/register', () => {
  it('returns HMAC hash + device token and never persists or echoes the raw id', async () => {
    const raw = rawId();
    const res = await ctx.http().post('/v1/auth/device/register').send({ raw_device_id: raw, platform: 'ios', app_version: '1.0.0' });
    expect(res.status).toBe(200);
    expect(res.body.device_hash).toMatch(/^[0-9a-f]{64}$/);
    expect(res.body.device_token).toMatch(/^dt_/);
    expect(JSON.stringify(res.body)).not.toContain(raw);
    expect(res.headers['x-request-id']).toBeDefined();
    const again = await ctx.http().post('/v1/auth/device/register').send({ raw_device_id: raw, platform: 'ios', app_version: '1.0.0' });
    expect(again.body.device_hash).toBe(res.body.device_hash);
  });

  it('validates input with the uniform error envelope', async () => {
    const res = await ctx.http().post('/v1/auth/device/register').send({ raw_device_id: 'x', platform: 'windows' });
    expect(res.status).toBe(400);
    expect(res.body.error).toMatchObject({ code: 'validation_failed', status: 400, message_key: 'error.validation' });
    expect(res.body.error.request_id).toBe(res.headers['x-request-id']);
  });
});

describe('T40 — guest one-tap on a fresh device', () => {
  it('creates an account with is_guest=true and issues a session', async () => {
    const d = await registerDevice(ctx);
    const res = await guest(ctx, d.device_token);
    expect(res.status).toBe(200);
    expect(res.body.is_new_account).toBe(true);
    expect(res.body.account).toMatchObject({ is_guest: true, status: 'active' });
    expect(res.body.account.id).toMatch(/^[0-9a-f-]{8}-[0-9a-f]{4}-7/);
    expect(res.body.expires_in).toBe(900);
    expect(res.body.device_binding).toMatchObject({ role: 'primary', device_hash: d.device_hash });

    const me = await ctx.http().get('/v1/me').set('Authorization', `Bearer ${res.body.access_token}`);
    expect(me.status).toBe(200);
    expect(me.body.account).toMatchObject({ id: res.body.account.id, is_guest: true });
    expect(me.body.identities).toEqual([]);
    expect(me.body.flags).toEqual({ dating_enabled: false, dating_paused: false, premium: false, test_mode_panel: true });

    const abuse = await ctx.prisma.abuseLog.findMany();
    expect(abuse).toHaveLength(1);
    expect(abuse[0]).toMatchObject({ deviceHash: d.device_hash, event: 'guest_created' });
  });

  it('stores only hashes: raw device id and refresh token appear in no table', async () => {
    const d = await registerDevice(ctx);
    const res = await guest(ctx, d.device_token);
    const dump = await ctx.prisma.$queryRawUnsafe<{ t: string }[]>(
      `SELECT string_agg(t::text, ' ') AS t FROM (
         SELECT row_to_json(a)::text t FROM accounts a UNION ALL SELECT row_to_json(i)::text FROM identities i
         UNION ALL SELECT row_to_json(b)::text FROM device_bindings b UNION ALL SELECT row_to_json(s)::text FROM sessions s
         UNION ALL SELECT row_to_json(l)::text FROM abuse_logs l) x`,
    );
    const all = dump[0]!.t;
    expect(all).not.toContain(d.raw);
    expect(all).not.toContain(res.body.refresh_token);
    expect(all).not.toContain(res.body.access_token);
  });

  it('abuse_logs has no account_id column (SPEC §5.10)', async () => {
    const cols = await ctx.prisma.$queryRaw<{ column_name: string }[]>`
      SELECT column_name FROM information_schema.columns WHERE table_name = 'abuse_logs'`;
    expect(cols.map((c) => c.column_name).sort()).toEqual(['device_hash', 'event', 'id', 'occurred_at']);
  });
});

describe('T41 — guest one-tap on a device with an existing active binding', () => {
  it('resumes the same account (no duplicate)', async () => {
    const d = await registerDevice(ctx);
    const first = await guest(ctx, d.device_token);
    const second = await guest(ctx, d.device_token);
    expect(second.status).toBe(200);
    expect(second.body.is_new_account).toBe(false);
    expect(second.body.account.id).toBe(first.body.account.id);
    expect(await ctx.prisma.account.count()).toBe(1);
    expect(await ctx.prisma.abuseLog.count()).toBe(1);
  });

  it('concurrent taps on one device still produce exactly one account', async () => {
    const d = await registerDevice(ctx);
    const results = await Promise.all([guest(ctx, d.device_token), guest(ctx, d.device_token), guest(ctx, d.device_token)]);
    results.forEach((r) => expect(r.status).toBe(200));
    expect(new Set(results.map((r) => r.body.account.id)).size).toBe(1);
    expect(results.filter((r) => r.body.is_new_account)).toHaveLength(1);
    expect(await ctx.prisma.account.count()).toBe(1);
  });

  it('different devices get different accounts', async () => {
    const a = await guest(ctx, (await registerDevice(ctx)).device_token);
    const b = await guest(ctx, (await registerDevice(ctx)).device_token);
    expect(a.body.account.id).not.toBe(b.body.account.id);
  });
});

describe('T42 — guest creation during device cooldown', () => {
  it('429 device_cooldown with remaining days; resume of an existing binding is unaffected', async () => {
    const d = await registerDevice(ctx);
    await ctx.prisma.deviceCooldown.create({ data: { deviceHash: d.device_hash, until: new Date(Date.now() + 21.5 * 86_400_000) } });
    const res = await guest(ctx, d.device_token);
    expect(res.status).toBe(429);
    expect(res.body.error).toMatchObject({ code: 'device_cooldown', message_key: 'auth.deviceCooldown', details: { retry_after_days: 22 } });
    expect(Number(res.headers['retry-after'])).toBeGreaterThan(21 * 86400);
    expect(await ctx.prisma.account.count()).toBe(0);
  });

  it('expired cooldown allows creation', async () => {
    const d = await registerDevice(ctx);
    await ctx.prisma.deviceCooldown.create({ data: { deviceHash: d.device_hash, until: new Date(Date.now() - 1000) } });
    expect((await guest(ctx, d.device_token)).status).toBe(200);
  });
});

describe('guest rate limit (API §1.2 — 3 / device / hour)', () => {
  it('4th call within the window → 429 rate_limited with Retry-After', async () => {
    const d = await registerDevice(ctx);
    for (let i = 0; i < 3; i++) expect((await guest(ctx, d.device_token)).status).toBe(200);
    const res = await guest(ctx, d.device_token);
    expect(res.status).toBe(429);
    expect(res.body.error.code).toBe('rate_limited');
    expect(Number(res.headers['retry-after'])).toBeGreaterThan(0);
  });
});

describe('device token integrity', () => {
  it('rejects forged / tampered device tokens', async () => {
    const d = await registerDevice(ctx);
    const tampered = d.device_token.slice(0, -2) + (d.device_token.endsWith('a') ? 'bb' : 'aa');
    for (const t of [tampered, 'dt_not.a.jwt', 'no-prefix-token']) {
      const res = await guest(ctx, t);
      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('unauthenticated');
    }
  });
});

describe('guest flag off', () => {
  it('HASTA_AUTH_GUEST_ENABLED=false → 403 feature_disabled', async () => {
    const off = await bootApp({ HASTA_AUTH_GUEST_ENABLED: 'false' });
    try {
      const d = await registerDevice(off);
      const res = await off.http().post('/v1/auth/guest').send({ device_token: d.device_token });
      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe('feature_disabled');
    } finally {
      await off.app.close();
    }
  });
});

describe('idempotency header validation', () => {
  it('rejects a non-UUIDv7 Idempotency-Key', async () => {
    const d = await registerDevice(ctx);
    const res = await ctx.http().post('/v1/auth/guest').set('Idempotency-Key', 'not-a-uuid').send({ device_token: d.device_token });
    expect(res.status).toBe(400);
  });
  it('accepts a UUIDv7 key', async () => {
    const d = await registerDevice(ctx);
    const res = await ctx.http().post('/v1/auth/guest').set('Idempotency-Key', uuidv7()).send({ device_token: d.device_token });
    expect(res.status).toBe(200);
  });
});
