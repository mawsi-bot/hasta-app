import { Reflector } from '@nestjs/core';
import { MetadataScanner } from '@nestjs/core';
import { RequestMethod } from '@nestjs/common';
import { METHOD_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { IDEMPOTENCY_META } from '../../src/common/idempotency/idempotency.decorator';
import { bootApp, type TestCtx } from '../helpers';

interface Route { method: string; path: string; idempotency: unknown }

function collectRoutes(ctx: TestCtx): Route[] {
  const reflector = ctx.app.get(Reflector);
  const scanner = new MetadataScanner();
  const container = (ctx.app as unknown as { container: { getModules(): Map<string, { controllers: Map<unknown, { instance: object; metatype: object }> }> } }).container;
  const routes: Route[] = [];
  for (const mod of container.getModules().values()) {
    for (const wrapper of mod.controllers.values()) {
      const { instance, metatype } = wrapper;
      if (!instance) continue;
      const base = String(Reflect.getMetadata(PATH_METADATA, metatype) ?? '');
      const proto = Object.getPrototypeOf(instance) as Record<string, unknown>;
      for (const name of scanner.getAllMethodNames(proto)) {
        const handler = proto[name] as object;
        const p = Reflect.getMetadata(PATH_METADATA, handler);
        if (p === undefined) continue;
        const m = Reflect.getMetadata(METHOD_METADATA, handler) as RequestMethod;
        routes.push({ method: RequestMethod[m], path: `/v1/${base}/${String(p)}`.replace(/\/+/g, '/').replace(/\/$/, ''), idempotency: reflector.get(IDEMPOTENCY_META, handler as never) });
      }
    }
  }
  return routes;
}

describe('route static gates on the live app', () => {
  let ctx: TestCtx;
  let routes: Route[];
  beforeAll(async () => {
    ctx = await bootApp();
    routes = collectRoutes(ctx);
  });
  afterAll(async () => {
    await ctx.app.close();
  });

  it('exposes exactly the Sprint 1 surface', () => {
    const list = routes.map((r) => `${r.method} ${r.path}`).sort();
    expect(list).toEqual(
      [
        'GET /v1/health',
        'GET /v1/me',
        'GET /v1/profile',
        'GET /v1/test/accounts',
        'PATCH /v1/profile',
        'POST /v1/auth/device/register',
        'POST /v1/auth/guest',
        'POST /v1/auth/logout',
        'POST /v1/auth/refresh',
        'POST /v1/test/accounts/:handle/reset',
        'POST /v1/test/accounts/:handle/session',
      ].sort(),
    );
  });

  it('T20 — no OTP/SMS/phone sign-in route exists', () => {
    expect(routes.filter((r) => /otp|sms|phone|verify-code/i.test(r.path))).toEqual([]);
  });

  it('T37 — no Google/Apple sign-in or token-only login route exists', () => {
    expect(routes.filter((r) => /sign-?in|log-?in|id_token|token-login/i.test(r.path))).toEqual([]);
    // Provider routes may only ever be account *linking* (SPEC §5.4)
    expect(routes.filter((r) => /google|apple/i.test(r.path) && !/link|recover/i.test(r.path))).toEqual([]);
  });

  it('every state-changing handler declares its idempotency mode', () => {
    const writes = routes.filter((r) => ['POST', 'PATCH', 'PUT', 'DELETE'].includes(r.method));
    expect(writes.length).toBeGreaterThan(0);
    expect(writes.filter((r) => !r.idempotency).map((r) => `${r.method} ${r.path}`)).toEqual([]);
  });

  it('smoke: async HTTP → Postgres + Redis round-trip', async () => {
    const res = await ctx.http().get('/v1/health');
    expect(res.body).toEqual({ status: 'ok', db: true, redis: true, version: '1.0.0' });
  });
});
