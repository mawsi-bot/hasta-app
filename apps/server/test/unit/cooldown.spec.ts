import { CooldownService } from '../../src/modules/auth/cooldown.service';
import { ApiError } from '../../src/common/errors/api-error';
import type { Env } from '../../src/config/env';

const DAY = 86_400_000;

describe('T42 — device cooldown rule', () => {
  const now = new Date('2026-11-23T09:30:00Z');
  it('reports whole remaining days, rounding up', () => {
    expect(CooldownService.remainingDays(new Date(now.getTime() + 30 * DAY), now)).toBe(30);
    expect(CooldownService.remainingDays(new Date(now.getTime() + 29 * DAY + 1), now)).toBe(30);
    expect(CooldownService.remainingDays(new Date(now.getTime() + 1), now)).toBe(1);
  });
  it('is 0 when expired or absent', () => {
    expect(CooldownService.remainingDays(new Date(now.getTime() - 1), now)).toBe(0);
    expect(CooldownService.remainingDays(now, now)).toBe(0);
    expect(CooldownService.remainingDays(null, now)).toBe(0);
  });

  const svc = (enabled: boolean, until: Date | null) =>
    new CooldownService({ HASTA_DEVICE_COOLDOWN_ENABLED: enabled } as Env, {
      deviceCooldown: { findUnique: async () => (until ? { until } : null) },
    } as never);

  it('throws 429 device_cooldown with retry_after_days + Retry-After seconds', async () => {
    const until = new Date(Date.now() + 12 * DAY - 1000);
    const err = await svc(true, until).assertNotCoolingDown('h').catch((e: unknown) => e);
    expect(err).toBeInstanceOf(ApiError);
    const e = err as ApiError;
    expect(e.status).toBe(429);
    expect(e.code).toBe('device_cooldown');
    expect(e.details).toEqual({ retry_after_days: 12 });
    expect(e.retryAfterSeconds).toBeGreaterThan(11 * 86400);
  });
  it('passes when no cooldown row, or when the flag is off (dev/test per SPEC §19)', async () => {
    await expect(svc(true, null).assertNotCoolingDown('h')).resolves.toBeUndefined();
    await expect(svc(false, new Date(Date.now() + DAY)).assertNotCoolingDown('h')).resolves.toBeUndefined();
  });
});
