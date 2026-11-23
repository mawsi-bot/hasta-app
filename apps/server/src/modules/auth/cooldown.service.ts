import { Inject, Injectable } from '@nestjs/common';
import { ENV } from '../../config/config.module';
import type { Env } from '../../config/env';
import { PrismaService } from '../../infra/prisma.service';
import { ApiError } from '../../common/errors/api-error';

const DAY_MS = 86_400_000;

/** SPEC §5.9 — device-hash-only cooldown; blocks NEW guest creation, never resume or transfer. */
@Injectable()
export class CooldownService {
  constructor(
    @Inject(ENV) private readonly env: Env,
    private readonly prisma: PrismaService,
  ) {}

  /** Pure rule (unit-tested, T42): remaining whole days, or 0 when not cooling down. */
  static remainingDays(until: Date | null, now: Date): number {
    if (!until) return 0;
    const ms = until.getTime() - now.getTime();
    return ms > 0 ? Math.ceil(ms / DAY_MS) : 0;
  }

  async assertNotCoolingDown(deviceHash: string, tx: Pick<PrismaService, 'deviceCooldown'> = this.prisma): Promise<void> {
    if (!this.env.HASTA_DEVICE_COOLDOWN_ENABLED) return;
    const row = await tx.deviceCooldown.findUnique({ where: { deviceHash }, select: { until: true } });
    const now = new Date();
    const days = CooldownService.remainingDays(row?.until ?? null, now);
    if (days > 0) {
      const retryAfter = Math.ceil((row!.until.getTime() - now.getTime()) / 1000);
      throw new ApiError(429, 'device_cooldown', 'auth.deviceCooldown', { retry_after_days: days }, retryAfter);
    }
  }
}
