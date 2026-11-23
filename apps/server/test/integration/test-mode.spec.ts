import { bootApp, registerDevice, resetDb, type TestCtx } from '../helpers';

describe('quick test accounts — enabled (dev/test/beta)', () => {
  let ctx: TestCtx;
  beforeAll(async () => {
    ctx = await bootApp({ HASTA_ENV: 'test', HASTA_QUICK_TEST_ACCOUNTS_ENABLED: 'true' });
    await resetDb(ctx);
  });
  afterAll(async () => {
    await ctx.app.close();
  });

  it('lists the 6 seeded handles (idempotent seeding)', async () => {
    const a = await ctx.http().get('/v1/test/accounts');
    const b = await ctx.http().get('/v1/test/accounts');
    expect(a.status).toBe(200);
    expect(a.body.accounts.map((x: { handle: string }) => x.handle)).toEqual([
      'tester.a', 'tester.b', 'tester.social', 'tester.premium', 'tester.minor', 'tester.fresh',
    ]);
    expect(b.body).toEqual(a.body);
    expect(await ctx.prisma.account.count()).toBe(6);
  });

  it('one-tap session for a seeded account; premium has a linked masked Gmail + entitlement', async () => {
    const d = await registerDevice(ctx);
    const s = await ctx.http().post('/v1/test/accounts/tester.premium/session').send({ device_token: d.device_token });
    expect(s.status).toBe(200);
    const me = await ctx.http().get('/v1/me').set('Authorization', `Bearer ${s.body.access_token}`);
    expect(me.body.account.is_guest).toBe(false);
    expect(me.body.identities).toEqual([expect.objectContaining({ provider: 'google', email_masked: 't***@example.test' })]);
    expect(me.body.flags.premium).toBe(true);
    expect(JSON.stringify(me.body)).not.toContain('tester.premium@example.test');
  });

  it('tester.minor is under 18 and tester.fresh has no profile', async () => {
    const d = await registerDevice(ctx);
    const minor = await ctx.http().post('/v1/test/accounts/tester.minor/session').send({ device_token: d.device_token });
    const p = await ctx.http().get('/v1/profile').set('Authorization', `Bearer ${minor.body.access_token}`);
    const age = (Date.now() - new Date(p.body.birth_date).getTime()) / (365.25 * 86_400_000);
    expect(age).toBeLessThan(18);
    const fresh = await ctx.http().post('/v1/test/accounts/tester.fresh/session').send({ device_token: d.device_token });
    const me = await ctx.http().get('/v1/me').set('Authorization', `Bearer ${fresh.body.access_token}`);
    expect(me.body.profile).toBeNull();
    expect(me.body.account.is_guest).toBe(true);
  });

  it('reset restores the seed state', async () => {
    const d = await registerDevice(ctx);
    const s = await ctx.http().post('/v1/test/accounts/tester.a/session').send({ device_token: d.device_token });
    await ctx.http().patch('/v1/profile').set('Authorization', `Bearer ${s.body.access_token}`)
      .set('Idempotency-Key', '01937a8e-0000-7000-8000-000000000001').send({ bio: 'changed', hlc: '999999999999' });
    const r = await ctx.http().post('/v1/test/accounts/tester.a/reset');
    expect(r.status).toBe(200);
    const p = await ctx.http().get('/v1/profile').set('Authorization', `Bearer ${s.body.access_token}`);
    expect(p.body.bio).toBe('QA dating pair (A)');
  });

  it('unknown handle → 400', async () => {
    const res = await ctx.http().post('/v1/test/accounts/admin/reset');
    expect(res.status).toBe(400);
  });
});

describe('quick test accounts — disabled', () => {
  it('flag off → every test endpoint is 404 and no account is seeded', async () => {
    const ctx = await bootApp({ HASTA_ENV: 'beta', HASTA_QUICK_TEST_ACCOUNTS_ENABLED: 'false' });
    try {
      await resetDb(ctx);
      expect((await ctx.http().get('/v1/test/accounts')).status).toBe(404);
      expect((await ctx.http().post('/v1/test/accounts/tester.a/session').send({ device_token: 'dt_xxxxxxxxxxxx' })).status).toBe(404);
      expect((await ctx.http().post('/v1/test/accounts/tester.a/reset')).status).toBe(404);
      expect(await ctx.prisma.account.count()).toBe(0);
    } finally {
      await ctx.app.close();
    }
  });
});
