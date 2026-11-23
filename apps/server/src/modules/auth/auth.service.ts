import { Inject, Injectable } from '@nestjs/common';
import { ENV } from '../../config/config.module';
import type { Env } from '../../config/env';
import { RemoteConfigService } from '../../config/remote-config';
import { PrismaService } from '../../infra/prisma.service';
import { ApiError } from '../../common/errors/api-error';
import { uuidv7 } from '../../common/ids/uuidv7';
import { RateLimiterService } from '../../common/rate-limit/rate-limiter.service';
import { log } from '../../common/logging/logger';
import { AbuseLogService } from './abuse-log.service';
import { CooldownService } from './cooldown.service';
import { SessionIssuer } from './session-issuer.service';
import { TokenService } from './token.service';
import { accountView, bindingView } from './views';
import type { SessionResponse, TokenPairResponse } from './dto/guest.dto';

const RESUMABLE = new Set(['active', 'paused']);
const ACCOUNT_SELECT = { id: true, status: true, isGuest: true, displayName: true, username: true, createdAt: true } as const;

type RefreshOutcome =
  | { kind: 'ok'; pair: TokenPairResponse }
  | { kind: 'reject'; reuse: boolean };

@Injectable()
export class AuthService {
  constructor(
    @Inject(ENV) private readonly env: Env,
    private readonly prisma: PrismaService,
    private readonly tokens: TokenService,
    private readonly issuer: SessionIssuer,
    private readonly cooldown: CooldownService,
    private readonly abuse: AbuseLogService,
    private readonly limiter: RateLimiterService,
    private readonly rc: RemoteConfigService,
  ) {}

  /**
   * POST /v1/auth/guest — SPEC §5.3 step 4. Serialised per device with a transaction-scoped
   * advisory lock so concurrent taps can never create two accounts for one device (T41).
   */
  async guest(deviceToken: string): Promise<SessionResponse> {
    if (!this.env.HASTA_AUTH_GUEST_ENABLED) throw new ApiError(403, 'feature_disabled', 'auth.guestDisabled');
    const device = this.tokens.verifyDevice(deviceToken);
    await this.limiter.consume('guest', device.dh, this.rc.get('guest_rate_limit_per_hour'), 3600);

    return this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${device.dh}, 0))::text`;

      const existing = await tx.deviceBinding.findFirst({
        where: { deviceHash: device.dh, revokedAt: null },
        select: { id: true, role: true, deviceHash: true, boundAt: true, account: { select: ACCOUNT_SELECT } },
      });

      if (existing) {
        if (!RESUMABLE.has(existing.account.status)) throw ApiError.forbidden('auth.accountUnavailable');
        const issued = await this.issuer.issue(tx, existing.account.id, device.dh);
        log.info('guest_resumed', { account_id: existing.account.id });
        return {
          access_token: issued.access_token,
          refresh_token: issued.refresh_token,
          expires_in: issued.expires_in,
          account: accountView(existing.account),
          device_binding: bindingView(existing),
          is_new_account: false,
        };
      }

      await this.cooldown.assertNotCoolingDown(device.dh, tx);

      const accountId = uuidv7();
      const account = await tx.account.create({ data: { id: accountId, isGuest: true }, select: ACCOUNT_SELECT });
      await tx.identity.create({ data: { id: uuidv7(), accountId, provider: 'guest', providerSub: accountId } });
      const binding = await tx.deviceBinding.create({
        data: { id: uuidv7(), accountId, deviceHash: device.dh, role: 'primary', platform: device.plt },
        select: { id: true, role: true, deviceHash: true, boundAt: true },
      });
      await this.abuse.record(device.dh, 'guest_created', tx);
      const issued = await this.issuer.issue(tx, accountId, device.dh);
      log.info('guest_created', { account_id: accountId });
      return {
        access_token: issued.access_token,
        refresh_token: issued.refresh_token,
        expires_in: issued.expires_in,
        account: accountView(account),
        device_binding: bindingView(binding),
        is_new_account: true,
      };
    });
  }

  /**
   * POST /v1/auth/refresh — rotation with family reuse detection (SPEC §5.3, §15).
   * A rotated token presented again ⇒ the whole family is revoked and the client must re-guest.
   * Revocation is committed BEFORE the 401 is thrown so it cannot be rolled back.
   */
  async refresh(refreshToken: string, deviceToken: string): Promise<TokenPairResponse> {
    const device = this.tokens.verifyDevice(deviceToken);
    const hash = this.tokens.hashRefresh(refreshToken);

    const outcome = await this.prisma.$transaction(async (tx): Promise<RefreshOutcome> => {
      const s = await tx.session.findUnique({
        where: { refreshHash: hash },
        select: { id: true, accountId: true, deviceHash: true, familyId: true, revokedAt: true, revokedReason: true, expiresAt: true, account: { select: { status: true } } },
      });
      if (!s) return { kind: 'reject', reuse: false };

      const revokeFamily = async () => {
        await tx.session.updateMany({
          where: { familyId: s.familyId },
          data: { revokedAt: new Date(), revokedReason: 'reuse_detected' },
        });
        return { kind: 'reject', reuse: true } as const;
      };

      if (s.revokedAt !== null) return s.revokedReason === 'rotated' ? revokeFamily() : { kind: 'reject', reuse: false };
      if (s.deviceHash !== device.dh) return revokeFamily();
      if (s.expiresAt.getTime() <= Date.now() || !RESUMABLE.has(s.account.status)) return { kind: 'reject', reuse: false };

      const claimed = await tx.session.updateMany({
        where: { id: s.id, revokedAt: null },
        data: { revokedAt: new Date(), revokedReason: 'rotated' },
      });
      if (claimed.count !== 1) return revokeFamily(); // lost a race with a concurrent rotation

      const issued = await this.issuer.issue(tx, s.accountId, s.deviceHash, s.familyId);
      return { kind: 'ok', pair: { access_token: issued.access_token, refresh_token: issued.refresh_token, expires_in: issued.expires_in } };
    });

    if (outcome.kind === 'ok') return outcome.pair;
    if (outcome.reuse) log.warn('refresh_reuse_detected', {});
    throw ApiError.unauthenticated(outcome.reuse ? { reason: 'reuse_detected' } : null);
  }

  /** POST /v1/auth/logout — revokes this session family, or every session when `everywhere`. */
  async logout(sessionId: string, accountId: string, sessionDeviceHash: string, deviceToken: string, everywhere: boolean): Promise<void> {
    const device = this.tokens.verifyDevice(deviceToken);
    if (device.dh !== sessionDeviceHash) throw ApiError.forbidden();
    const now = new Date();
    if (everywhere) {
      await this.prisma.session.updateMany({
        where: { accountId, OR: [{ revokedAt: null }, { revokedReason: 'rotated' }] },
        data: { revokedAt: now, revokedReason: 'logout_everywhere' },
      });
      return;
    }
    const s = await this.prisma.session.findUnique({ where: { id: sessionId }, select: { familyId: true } });
    if (!s) return;
    await this.prisma.session.updateMany({
      where: { familyId: s.familyId, OR: [{ revokedAt: null }, { revokedReason: 'rotated' }] },
      data: { revokedAt: now, revokedReason: 'logout' },
    });
  }
}
