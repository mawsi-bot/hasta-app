import { bootApp, guest, registerDevice, resetDb, type TestCtx } from '../helpers';

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

async function login() {
  const d = await registerDevice(ctx);
  const g = await guest(ctx, d.device_token);
  return { d, g: g.body as { access_token: string; refresh_token: string; account: { id: string } } };
}
const refresh = (refresh_token: string, device_token: string) =>
  ctx.http().post('/v1/auth/refresh').send({ refresh_token, device_token });

describe('refresh rotation + family reuse detection (SPEC §5.3)', () => {
  it('rotates: new pair issued, old refresh token invalidated', async () => {
    const { d, g } = await login();
    const r1 = await refresh(g.refresh_token, d.device_token);
    expect(r1.status).toBe(200);
    expect(r1.body.refresh_token).not.toBe(g.refresh_token);
    expect(r1.body.expires_in).toBe(900);
    const me = await ctx.http().get('/v1/me').set('Authorization', `Bearer ${r1.body.access_token}`);
    expect(me.status).toBe(200);
  });

  it('reuse of a rotated token revokes the whole family', async () => {
    const { d, g } = await login();
    const r1 = await refresh(g.refresh_token, d.device_token);
    const reuse = await refresh(g.refresh_token, d.device_token);
    expect(reuse.status).toBe(401);
    expect(reuse.body.error.details).toEqual({ reason: 'reuse_detected' });
    // the legitimately-rotated token is now dead too
    expect((await refresh(r1.body.refresh_token, d.device_token)).status).toBe(401);
    // and its access token is revoked immediately
    const me = await ctx.http().get('/v1/me').set('Authorization', `Bearer ${r1.body.access_token}`);
    expect(me.status).toBe(401);
    const live = await ctx.prisma.session.count({ where: { revokedAt: null } });
    expect(live).toBe(0);
  });

  it('concurrent refresh with the same token: at most one succeeds and the family is revoked', async () => {
    const { d, g } = await login();
    const rs = await Promise.all([refresh(g.refresh_token, d.device_token), refresh(g.refresh_token, d.device_token)]);
    expect(rs.filter((r) => r.status === 200).length).toBeLessThanOrEqual(1);
    expect(rs.some((r) => r.status === 401)).toBe(true);
  });

  it('refresh from another device revokes the family (stolen token)', async () => {
    const { g } = await login();
    const other = await registerDevice(ctx);
    const res = await refresh(g.refresh_token, other.device_token);
    expect(res.status).toBe(401);
    expect(await ctx.prisma.session.count({ where: { revokedAt: null } })).toBe(0);
  });

  it('unknown and expired refresh tokens are rejected', async () => {
    const { d, g } = await login();
    expect((await refresh('rt_unknownunknownunknown', d.device_token)).status).toBe(401);
    await ctx.prisma.session.updateMany({ data: { expiresAt: new Date(Date.now() - 1000) } });
    expect((await refresh(g.refresh_token, d.device_token)).status).toBe(401);
  });

  it('a rotated session keeps serving its unexpired access token (no thundering 401s)', async () => {
    const { d, g } = await login();
    await refresh(g.refresh_token, d.device_token);
    const me = await ctx.http().get('/v1/me').set('Authorization', `Bearer ${g.access_token}`);
    expect(me.status).toBe(200);
  });
});

describe('POST /v1/auth/logout', () => {
  it('revokes the session family; Continue resumes the same guest account afterwards', async () => {
    const { d, g } = await login();
    const out = await ctx.http().post('/v1/auth/logout').set('Authorization', `Bearer ${g.access_token}`).send({ device_token: d.device_token });
    expect(out.status).toBe(204);
    expect((await ctx.http().get('/v1/me').set('Authorization', `Bearer ${g.access_token}`)).status).toBe(401);
    expect((await refresh(g.refresh_token, d.device_token)).status).toBe(401);
    const again = await guest(ctx, d.device_token);
    expect(again.body.account.id).toBe(g.account.id);
    expect(again.body.is_new_account).toBe(false);
  });

  it('everywhere=true revokes every session of the account', async () => {
    const { d, g } = await login();
    const second = await guest(ctx, d.device_token);
    const out = await ctx.http().post('/v1/auth/logout').set('Authorization', `Bearer ${g.access_token}`).send({ device_token: d.device_token, everywhere: true });
    expect(out.status).toBe(204);
    expect((await ctx.http().get('/v1/me').set('Authorization', `Bearer ${second.body.access_token}`)).status).toBe(401);
  });

  it('requires the matching device token', async () => {
    const { g } = await login();
    const other = await registerDevice(ctx);
    const res = await ctx.http().post('/v1/auth/logout').set('Authorization', `Bearer ${g.access_token}`).send({ device_token: other.device_token });
    expect(res.status).toBe(403);
  });
});

describe('deny-by-default auth guard', () => {
  it('rejects missing, malformed and wrong-type tokens', async () => {
    const { d } = await login();
    expect((await ctx.http().get('/v1/me')).status).toBe(401);
    expect((await ctx.http().get('/v1/me').set('Authorization', 'Bearer nope')).status).toBe(401);
    // a device token must never work as an access token
    expect((await ctx.http().get('/v1/me').set('Authorization', `Bearer ${d.device_token.slice(3)}`)).status).toBe(401);
  });

  it('banned accounts lose access and cannot resume', async () => {
    const { d, g } = await login();
    await ctx.prisma.account.update({ where: { id: g.account.id }, data: { status: 'banned' } });
    expect((await ctx.http().get('/v1/me').set('Authorization', `Bearer ${g.access_token}`)).status).toBe(401);
    expect((await guest(ctx, d.device_token)).status).toBe(403);
  });
});
