import { Inject, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { ENV } from '../../config/config.module';
import { TEST_MODE_ENVS, type Env } from '../../config/env';
import { PrismaService } from '../../infra/prisma.service';
import { looksLikeZawgyi } from '../../common/text/zawgyi';
import { ApiError } from '../../common/errors/api-error';
import { mergeFields, parseHlc, type FieldClocks } from './hlc-merge';
import { maskEmail } from './mask-email';
import type { MeResponse, PatchProfileDto, PatchProfileResponse, ProfileView } from './dto/profile.dto';

const PROFILE_FIELDS = ['display_name', 'username', 'bio', 'birth_date'] as const;
type ProfileField = (typeof PROFILE_FIELDS)[number];

@Injectable()
export class ProfileService {
  constructor(
    @Inject(ENV) private readonly env: Env,
    private readonly prisma: PrismaService,
  ) {}

  /** GET /v1/me — own view. Never includes dating fields beyond the two boolean flags (SPEC §1 rule 1). */
  async me(accountId: string): Promise<MeResponse> {
    const a = await this.prisma.account.findUniqueOrThrow({
      where: { id: accountId },
      select: {
        id: true, status: true, isGuest: true, createdAt: true, username: true,
        profile: { select: { displayName: true, bio: true, avatarKey: true, birthDate: true, updatedHlc: true } },
        identities: { where: { provider: { in: ['google', 'apple'] } }, select: { provider: true, email: true, linkedAt: true } },
        entitlements: { select: { store: true, productId: true, status: true, expiresAt: true } },
      },
    });
    const now = Date.now();
    const premium = a.entitlements.some(
      (e) => (e.status === 'active' || e.status === 'grace') && (e.expiresAt === null || e.expiresAt.getTime() > now),
    );
    return {
      account: { id: a.id, status: a.status, is_guest: a.isGuest, created_at: a.createdAt.toISOString() },
      profile: a.profile ? toView(a.profile, a.username) : null,
      identities: a.identities.map((i) => ({ provider: i.provider, email_masked: maskEmail(i.email), linked_at: i.linkedAt.toISOString() })),
      entitlements: a.entitlements.map((e) => ({ store: e.store, product_id: e.productId, status: e.status, expires_at: e.expiresAt?.toISOString() ?? null })),
      flags: {
        dating_enabled: false, // dating_profiles arrive in Sprint 7
        dating_paused: false,
        premium,
        test_mode_panel: this.env.HASTA_QUICK_TEST_ACCOUNTS_ENABLED && TEST_MODE_ENVS.includes(this.env.HASTA_ENV),
      },
    };
  }

  async get(accountId: string): Promise<ProfileView> {
    const a = await this.prisma.account.findUniqueOrThrow({
      where: { id: accountId },
      select: { username: true, profile: { select: { displayName: true, bio: true, avatarKey: true, birthDate: true, updatedHlc: true } } },
    });
    return a.profile ? toView(a.profile, a.username) : emptyView(a.username);
  }

  /** PATCH /v1/profile — field-level HLC LWW; row-locked so concurrent patches merge deterministically. */
  async patch(accountId: string, dto: PatchProfileDto): Promise<PatchProfileResponse> {
    let hlc: bigint;
    try {
      hlc = parseHlc(dto.hlc);
    } catch {
      throw ApiError.validation({ hlc: 'invalid' });
    }
    if (dto.birth_date !== undefined) assertPlausibleBirthDate(dto.birth_date);
    for (const f of ['display_name', 'bio'] as const) {
      const v = dto[f];
      if (typeof v === 'string' && looksLikeZawgyi(v)) throw ApiError.validation({ [f]: 'zawgyi_detected' });
    }
    const present = PROFILE_FIELDS.filter((f) => dto[f] !== undefined);

    try {
      return await this.prisma.$transaction(async (tx) => {
        await tx.$queryRaw`SELECT id FROM accounts WHERE id = ${accountId}::uuid FOR UPDATE`;
        const current = await tx.profile.findUnique({ where: { userId: accountId }, select: { fieldHlc: true } });
        const clocks = (current?.fieldHlc ?? {}) as FieldClocks;
        const merge = mergeFields<ProfileField>(present, hlc, clocks);
        const set = new Set(merge.applied);

        const profileData = {
          ...(set.has('display_name') ? { displayName: dto.display_name! } : {}),
          ...(set.has('bio') ? { bio: dto.bio === '' ? null : dto.bio! } : {}),
          ...(set.has('birth_date') ? { birthDate: new Date(`${dto.birth_date}T00:00:00Z`) } : {}),
          fieldHlc: merge.clocks as Prisma.InputJsonValue,
          updatedHlc: merge.maxHlc,
        };
        await tx.profile.upsert({
          where: { userId: accountId },
          create: { userId: accountId, displayName: '', ...profileData },
          update: profileData,
        });
        if (set.has('username') || set.has('display_name')) {
          await tx.account.update({
            where: { id: accountId },
            data: {
              ...(set.has('username') ? { username: dto.username! } : {}),
              ...(set.has('display_name') ? { displayName: dto.display_name! } : {}),
              updatedHlc: merge.maxHlc,
            },
          });
        }
        const fresh = await tx.account.findUniqueOrThrow({
          where: { id: accountId },
          select: { username: true, profile: { select: { displayName: true, bio: true, avatarKey: true, birthDate: true, updatedHlc: true } } },
        });
        return { profile: toView(fresh.profile!, fresh.username), applied: merge.applied, ignored: merge.ignored };
      });
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        throw new ApiError(409, 'username_taken', 'profile.usernameTaken');
      }
      throw e;
    }
  }
}

function assertPlausibleBirthDate(v: string): void {
  const d = new Date(`${v}T00:00:00Z`);
  const now = new Date();
  if (Number.isNaN(d.getTime()) || d.toISOString().slice(0, 10) !== v || d > now || now.getUTCFullYear() - d.getUTCFullYear() > 120) {
    throw ApiError.validation({ birth_date: 'implausible' });
  }
}

function toView(
  p: { displayName: string; bio: string | null; avatarKey: string | null; birthDate: Date | null; updatedHlc: bigint },
  username: string | null,
): ProfileView {
  return {
    display_name: p.displayName === '' ? null : p.displayName,
    username,
    bio: p.bio,
    avatar_url: null, // media pipeline + CDN signing arrive in Sprint 6
    birth_date: p.birthDate ? p.birthDate.toISOString().slice(0, 10) : null,
    updated_hlc: p.updatedHlc.toString(),
  };
}

function emptyView(username: string | null): ProfileView {
  return { display_name: null, username, bio: null, avatar_url: null, birth_date: null, updated_hlc: '0' };
}
