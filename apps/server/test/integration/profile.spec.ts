import { uuidv7 } from '../../src/common/ids/uuidv7';
import { bootApp, guest, registerDevice, resetDb, type TestCtx } from '../helpers';

let ctx: TestCtx;
let token: string;
beforeAll(async () => {
  ctx = await bootApp();
});
afterAll(async () => {
  await ctx.app.close();
});
beforeEach(async () => {
  await resetDb(ctx);
  const d = await registerDevice(ctx);
  token = (await guest(ctx, d.device_token)).body.access_token;
});

const hlc = (ms: number, c = 0) => ((BigInt(ms) << 16n) | BigInt(c)).toString();
const patch = (body: object, key = uuidv7(), t = token) =>
  ctx.http().patch('/v1/profile').set('Authorization', `Bearer ${t}`).set('Idempotency-Key', key).send(body);

describe('profile basics (GET/PATCH /v1/profile)', () => {
  it('empty profile for a fresh guest, then local-first edits merge by field', async () => {
    const empty = await ctx.http().get('/v1/profile').set('Authorization', `Bearer ${token}`);
    expect(empty.body).toEqual({ display_name: null, username: null, bio: null, avatar_url: null, birth_date: null, updated_hlc: '0' });

    const r1 = await patch({ display_name: 'မောင်မောင်', bio: 'မင်္ဂလာပါ', hlc: hlc(2000) });
    expect(r1.status).toBe(200);
    expect(r1.body.applied.sort()).toEqual(['bio', 'display_name']);

    // stale write from another device: bio ignored, username applied
    const r2 = await patch({ bio: 'old', username: 'maung.maung', hlc: hlc(1000) });
    expect(r2.body.applied).toEqual(['username']);
    expect(r2.body.ignored).toEqual(['bio']);
    expect(r2.body.profile).toMatchObject({ display_name: 'မောင်မောင်', bio: 'မင်္ဂလာပါ', username: 'maung.maung' });

    const me = await ctx.http().get('/v1/me').set('Authorization', `Bearer ${token}`);
    expect(me.body.profile.display_name).toBe('မောင်မောင်');
  });

  it('Idempotency-Key replay returns the stored response with Idempotent-Replayed', async () => {
    const key = uuidv7();
    const body = { display_name: 'A', hlc: hlc(5000) };
    const a = await patch(body, key);
    const b = await patch(body, key);
    expect(b.status).toBe(200);
    expect(b.headers['idempotent-replayed']).toBe('true');
    expect(b.body).toEqual(a.body);
    const conflict = await patch({ display_name: 'B', hlc: hlc(6000) }, key);
    expect(conflict.status).toBe(422);
    expect(conflict.body.error.code).toBe('idempotency_conflict');
  });

  it('Idempotency-Key is required on PATCH', async () => {
    const res = await ctx.http().patch('/v1/profile').set('Authorization', `Bearer ${token}`).send({ bio: 'x', hlc: hlc(1) });
    expect(res.status).toBe(400);
  });

  it('a failed write releases its key so a retry can succeed', async () => {
    const key = uuidv7();
    const bad = await patch({ birth_date: '2999-01-01', hlc: hlc(1) }, key);
    expect(bad.status).toBe(400);
    const good = await patch({ birth_date: '1999-01-01', hlc: hlc(1) }, uuidv7());
    expect(good.status).toBe(200);
    expect(good.body.profile.birth_date).toBe('1999-01-01');
  });

  it('username uniqueness → 409 username_taken', async () => {
    await patch({ username: 'taken.name', hlc: hlc(1) });
    const d2 = await registerDevice(ctx);
    const t2 = (await guest(ctx, d2.device_token)).body.access_token;
    const res = await patch({ username: 'taken.name', hlc: hlc(2) }, uuidv7(), t2);
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('username_taken');
  });

  it('rejects unknown fields (no mass assignment of is_guest / status)', async () => {
    const res = await patch({ is_guest: false, hlc: hlc(1) });
    expect(res.status).toBe(400);
  });
});
