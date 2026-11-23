import { Inject, Injectable } from '@nestjs/common';
import type { Prisma } from '@prisma/client';
import { ENV } from '../../config/config.module';
import { TEST_MODE_ENVS, type Env } from '../../config/env';
import { PrismaService } from '../../infra/prisma.service';
import { ApiError } from '../../common/errors/api-error';
import { uuidv7 } from '../../common/ids/uuidv7';
import { SessionIssuer } from '../auth/session-issuer.service';
import { TokenService } from '../auth/token.service';
import { accountView } from '../auth/views';
import type { SessionResponse } from '../auth/dto/guest.dto';
import { SEED_ACCOUNTS, type SeedAccount, type SeedHandle } from './seed-accounts';

const SELECT = { id: true, status: true, isGuest: true, displayName: true, username: true, createdAt: true } as const;

@Injectable()
export class TestModeService {
  constructor(
    @Inject(ENV) private readonly env: Env,
    private readonly prisma: PrismaService,
    private readonly tokens: TokenService,
    private readonly issuer: SessionIssuer,
  ) {}

  private assertEnv(): void {
    if (!TEST_MODE_ENVS.includes(this.env.HASTA_ENV)) throw ApiError.notFound();
  }

  /** Idempotent: safe to call on every request. Refuses to run outside dev/test/beta. */
  async ensureSeeded(): Promise<void> {
    this.assertEnv();
    for (const seed of SEED_ACCOUNTS) {
      await this.prisma.$transaction(async (tx) => {
        const existing = await tx.account.findUnique({ where: { username: seed.handle }, select: { id: true } });
        if (existing) return;
        const id = uuidv7();
        await tx.account.create({ data: { id, username: seed.handle, displayName: seed.displayName, isGuest: !seed.linkedGoogle } });
        await tx.identity.create({ data: { id: uuidv7(), accountId: id, provider: 'guest', providerSub: id } });
        await this.applySeed(tx, id, seed);
      });
    }
  }

  async list() {
    await this.ensureSeeded();
    const rows = await this.prisma.account.findMany({
      where: { username: { in: SEED_ACCOUNTS.map((s) => s.handle) } },
      select: { id: true, username: true, isGuest: true },
    });
    return SEED_ACCOUNTS.map((s) => {
      const r = rows.find((x) => x.username === s.handle)!;
      return { handle: s.handle, purpose: s.purpose, account_id: r.id, is_guest: r.isGuest };
    });
  }

  /** One-tap session for a seeded account on the calling device (no OTP, no email, no password). */
  async session(handle: SeedHandle, deviceToken: string): Promise<SessionResponse> {
    const device = this.tokens.verifyDevice(deviceToken);
    await this.ensureSeeded();
    return this.prisma.$transaction(async (tx) => {
      const account = await tx.account.findUnique({ where: { username: handle }, select: SELECT });
      if (!account) throw ApiError.notFound();
      const issued = await this.issuer.issue(tx, account.id, device.dh);
      return {
        access_token: issued.access_token,
        refresh_token: issued.refresh_token,
        expires_in: issued.expires_in,
        account: accountView(account),
        device_binding: null,
        is_new_account: false,
      };
    });
  }

  /** Restores the seed state (profile + linked identities + entitlements). Keeps the account id. */
  async reset(handle: SeedHandle): Promise<{ handle: SeedHandle; reset: true }> {
    await this.ensureSeeded();
    const seed = SEED_ACCOUNTS.find((s) => s.handle === handle)!;
    await this.prisma.$transaction(async (tx) => {
      const a = await tx.account.findUniqueOrThrow({ where: { username: handle }, select: { id: true } });
      await tx.identity.deleteMany({ where: { accountId: a.id, provider: { not: 'guest' } } });
      await tx.entitlement.deleteMany({ where: { accountId: a.id } });
      await tx.profile.deleteMany({ where: { userId: a.id } });
      await tx.account.update({ where: { id: a.id }, data: { displayName: seed.displayName, isGuest: !seed.linkedGoogle, status: 'active', updatedHlc: 0 } });
      await this.applySeed(tx, a.id, seed);
    });
    return { handle, reset: true };
  }

  private async applySeed(tx: Prisma.TransactionClient, id: string, seed: SeedAccount): Promise<void> {
    const birth = seed.birthDate(new Date());
    if (seed.displayName !== null) {
      await tx.profile.create({
        data: { userId: id, displayName: seed.displayName, bio: seed.bio, birthDate: birth ? new Date(`${birth}T00:00:00Z`) : null },
      });
    }
    if (seed.linkedGoogle) {
      await tx.identity.create({
        data: { id: uuidv7(), accountId: id, provider: 'google', providerSub: `seed-${seed.handle}`, email: `${seed.handle}@example.test`, emailVerified: true },
      });
    }
    if (seed.premium) {
      const now = new Date();
      await tx.entitlement.create({
        data: {
          id: uuidv7(), accountId: id, store: 'google', productId: 'hasta.premium.monthly',
          storeTxnHash: `mock-${seed.handle}`, status: 'active', startsAt: now, expiresAt: new Date(now.getTime() + 30 * 86_400_000),
        },
      });
    }
  }
}
