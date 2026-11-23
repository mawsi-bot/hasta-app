import { uuidv7 } from '../../src/common/ids/uuidv7';
import { bootApp, guest, registerDevice, resetDb, type TestCtx } from '../helpers';

// SPEC 1.0.1 ruling on ADR-0002: authenticated writes key on (account_id, key); pre-auth keys are never
// replayable across devices. One test per direction.
let ctx: TestCtx;
beforeAll(async () => { ctx = await bootApp(); });
afterAll(async () => { await ctx.app.close(); });
beforeEach(async () => { await resetDb(ctx); });

const login = async () => (await guest(ctx, (await registerDevice(ctx)).device_token)).body as { access_token: string; account: { id: string } };

describe('idempotency scope', () => {
  it('authenticated: the same key from two accounts is two independent writes (keyed by account_id)', async () => {
    const [a, b] = [await login(), await login()];
    const key = uuidv7();
    const send = (t: string, name: string) =>
      ctx.http().patch('/v1/profile').set('Authorization', `Bearer ${t}`).set('Idempotency-Key', key).send({ display_name: name, hlc: '131072000' });
    expect((await send(a.access_token, 'A')).status).toBe(200);
    const rb = await send(b.access_token, 'B');
    expect(rb.status).toBe(200);
    expect(rb.headers['idempotent-replayed']).toBeUndefined();
    const rows = await ctx.prisma.idempotencyKey.findMany({ where: { key }, select: { scope: true } });
    expect(rows.map((r) => r.scope).sort()).toEqual([`acct:${a.account.id}`, `acct:${b.account.id}`].sort());
  });

  it('pre-auth: the same key from two devices never replays one device\'s response on the other', async () => {
    const key = uuidv7();
    const [x, y] = [await registerDevice(ctx), await registerDevice(ctx)];
    const post = (dt: string) => ctx.http().post('/v1/auth/guest').set('Idempotency-Key', key).send({ device_token: dt, locale: 'my' });
    const rx = await post(x.device_token);
    const ry = await post(y.device_token);
    expect(ry.headers['idempotent-replayed']).toBeUndefined();
    expect(ry.body.account.id).not.toBe(rx.body.account.id);
  });
});
