import { uuidv7 } from '../../src/common/ids/uuidv7';
import { sha256Hex } from '../../src/common/crypto/crypto';
import { GoogleOAuthPort } from '../../src/modules/identity/google-oauth.port';
import { bootApp, guest, registerDevice, resetDb, type TestCtx } from '../helpers';
import { GOOGLE_TEST_CERTS, GOOGLE_TEST_ENV, googleClaims, signIdToken } from '../google-fake';

/** SPEC 1.0.2 §5.4 Gmail linking — T38, T39, T44 (server half). Google is faked at the port, never in the verifier. */
let ctx: TestCtx;
let issue: (claims: Record<string, unknown>, opts?: { foreignKey?: boolean }) => string;
beforeAll(async () => {
  ctx = await bootApp(GOOGLE_TEST_ENV);
  const port = ctx.app.get(GoogleOAuthPort);
  const codes = new Map<string, string>();
  issue = (claims, opts) => { const code = `c-${uuidv7()}`; codes.set(code, signIdToken(claims, opts)); return code; };
  jest.spyOn(port, 'certs').mockResolvedValue(GOOGLE_TEST_CERTS);
  jest.spyOn(port, 'exchangeCode').mockImplementation(async (code) => {
    const t = codes.get(code);
    if (!t) throw new Error('invalid_grant');
    return t;
  });
});
afterAll(async () => { await ctx.app.close(); });
beforeEach(async () => { await resetDb(ctx); });

const BASE = '/v1/auth/identities/google';
const login = async () => (await guest(ctx, (await registerDevice(ctx)).device_token)).body as { access_token: string; account: { id: string } };
const start = async (at: string) => (await ctx.http().post(`${BASE}/link:start`).set('Authorization', `Bearer ${at}`).send({})).body as { state: string; nonce: string; auth_url: string; expires_in: number };
const complete = (at: string, body: Record<string, unknown>) =>
  ctx.http().post(`${BASE}/link:complete`).set('Authorization', `Bearer ${at}`).set('Idempotency-Key', uuidv7()).send(body);
const link = async (at: string, over: Record<string, unknown> = {}, opts?: { foreignKey?: boolean }) => {
  const s = await start(at);
  return complete(at, { state: s.state, code: issue(googleClaims(s.nonce, over), opts) });
};
const identities = () => ctx.prisma.identity.count({ where: { provider: 'google' } });

describe('link:start', () => {
  it('returns a PKCE S256 auth_url bound to state + nonce, stores only sha256(state) with a 300 s TTL', async () => {
    const a = await login();
    const s = await start(a.access_token);
    const url = new URL(s.auth_url);
    expect(url.origin + url.pathname).toBe('https://accounts.google.com/o/oauth2/v2/auth');
    expect(Object.fromEntries(url.searchParams)).toMatchObject({
      client_id: GOOGLE_TEST_ENV.HASTA_GOOGLE_CLIENT_ID, redirect_uri: GOOGLE_TEST_ENV.HASTA_GOOGLE_REDIRECT_URI, response_type: 'code',
      scope: 'openid email profile', state: s.state, nonce: s.nonce, code_challenge_method: 'S256', prompt: 'select_account',
    });
    expect(url.searchParams.get('code_challenge')).toMatch(/^[\w-]{43}$/);
    expect(s.expires_in).toBe(300);
    const keys = await ctx.redis.client.keys('*');
    expect(keys.join()).not.toContain(s.state);
    const ttl = await ctx.redis.client.ttl(`link:google:${sha256Hex(s.state)}`);
    expect(ttl).toBeGreaterThan(290);
    expect(ttl).toBeLessThanOrEqual(300);
  });
});

describe('link:complete', () => {
  it('T44 (server half) — links, flips is_guest, returns masked email + unlocked capabilities; /v1/me agrees', async () => {
    const a = await login();
    const res = await link(a.access_token);
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      identity: { provider: 'google', email_masked: 'h***@gmail.com' }, account: { id: a.account.id, is_guest: false },
      unlocked: ['premium_purchase', 'restore_purchases', 'device_recovery'],
    });
    expect(JSON.stringify(res.body)).not.toContain('heinhtet');
    const me = await ctx.http().get('/v1/me').set('Authorization', `Bearer ${a.access_token}`);
    expect(me.body.account.is_guest).toBe(false);
    expect(me.body.identities).toEqual([expect.objectContaining({ provider: 'google', email_masked: 'h***@gmail.com' })]);
  });

  it('T38 — the same Google sub on a second account → 409 identity_in_use, no new identity', async () => {
    const a = await login();
    const b = await login();
    expect((await link(a.access_token)).status).toBe(200);
    const res = await link(b.access_token);
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('identity_in_use');
    expect(await identities()).toBe(1);
    expect((await ctx.prisma.account.findUniqueOrThrow({ where: { id: b.account.id } })).isGuest).toBe(true);
  });

  it('T39g — a client-supplied id_token is not accepted (400) and links nothing', async () => {
    const a = await login();
    const s = await start(a.access_token);
    const res = await complete(a.access_token, { state: s.state, code: 'none', id_token: signIdToken(googleClaims(s.nonce)) });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('validation_failed');
    expect(await identities()).toBe(0);
  });

  it('T39b–f end to end — the endpoint runs the real verifier (bad nonce → 401, nothing linked)', async () => {
    const a = await login();
    const res = await link(a.access_token, { nonce: 'replayed-nonce' });
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('unauthenticated');
    expect(await identities()).toBe(0);
  });

  it('T39a — an unknown / forged authorization code → 401', async () => {
    const a = await login();
    const s = await start(a.access_token);
    expect((await complete(a.access_token, { state: s.state, code: 'forged' })).status).toBe(401);
    expect(await identities()).toBe(0);
  });

  it('email_verified=false → 422 google_email_unverified', async () => {
    const a = await login();
    const res = await link(a.access_token, { email_verified: false });
    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('google_email_unverified');
    expect(await identities()).toBe(0);
  });

  it('state is single-use, expires, and is bound to the account that started it', async () => {
    const a = await login();
    const b = await login();
    const s = await start(a.access_token);
    const code = issue(googleClaims(s.nonce));
    expect((await complete(b.access_token, { state: s.state, code })).status).toBe(401); // wrong account burns it
    expect((await complete(a.access_token, { state: s.state, code })).body.error.code).toBe('token_expired');
    const s2 = await start(a.access_token);
    await ctx.redis.client.pexpire(`link:google:${sha256Hex(s2.state)}`, 1);
    await new Promise((r) => setTimeout(r, 20));
    expect((await complete(a.access_token, { state: s2.state, code: issue(googleClaims(s2.nonce)) })).body.error.code).toBe('token_expired');
  });

  it('replaying the same Idempotency-Key returns the stored response without re-linking', async () => {
    const a = await login();
    const s = await start(a.access_token);
    const key = uuidv7();
    const body = { state: s.state, code: issue(googleClaims(s.nonce)) };
    const send = () => ctx.http().post(`${BASE}/link:complete`).set('Authorization', `Bearer ${a.access_token}`).set('Idempotency-Key', key).send(body);
    const first = await send();
    const again = await send();
    expect(again.status).toBe(200);
    expect(again.headers['idempotent-replayed']).toBe('true');
    expect(again.body).toEqual(first.body);
  });
});

describe('Gmail link flag off', () => {
  it('HASTA_AUTH_GOOGLE_LINK_ENABLED=false → 403 feature_disabled', async () => {
    const off = await bootApp({ ...GOOGLE_TEST_ENV, HASTA_AUTH_GOOGLE_LINK_ENABLED: 'false' });
    try {
      const at = (await guest(off, (await registerDevice(off)).device_token)).body.access_token as string;
      const res = await off.http().post(`${BASE}/link:start`).set('Authorization', `Bearer ${at}`).send({});
      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe('feature_disabled');
    } finally {
      await off.app.close();
    }
  });
});
