import { createHash, randomBytes } from 'node:crypto';
import { Inject, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { ENV } from '../../config/config.module';
import type { Env } from '../../config/env';
import { PrismaService } from '../../infra/prisma.service';
import { RedisService } from '../../infra/redis.service';
import { ApiError } from '../../common/errors/api-error';
import type { AuthContext } from '../../common/auth/auth-context';
import { sha256Hex } from '../../common/crypto/crypto';
import { uuidv7 } from '../../common/ids/uuidv7';
import { log } from '../../common/logging/logger';
import { maskEmail } from '../user/mask-email';
import { GoogleOAuthPort } from './google-oauth.port';
import { GoogleIdTokenVerifier } from './google-id-token.verifier';
import type { LinkCompleteResponse, LinkStartResponse } from './dto/link.dto';

const STATE_TTL_S = 300; // SPEC 1.0.2 §5.4: link state lives 5 minutes, single use
const AUTH_ENDPOINT = 'https://accounts.google.com/o/oauth2/v2/auth';
const SCOPES = ['openid', 'email', 'profile'];
export const UNLOCKED = ['premium_purchase', 'restore_purchases', 'device_recovery'];

interface LinkState { account_id: string; device_hash: string; nonce: string; verifier: string }
const rand = () => randomBytes(32).toString('base64url');
const stateKey = (state: string) => `link:google:${sha256Hex(state)}`;

@Injectable()
export class IdentityService {
  constructor(
    @Inject(ENV) private readonly env: Env,
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly google: GoogleOAuthPort,
    private readonly verifier: GoogleIdTokenVerifier,
  ) {}

  private assertEnabled(): void {
    if (!this.env.HASTA_AUTH_GOOGLE_LINK_ENABLED || !this.env.HASTA_GOOGLE_CLIENT_ID || !this.env.HASTA_GOOGLE_REDIRECT_URI) {
      throw new ApiError(403, 'feature_disabled', 'identity.googleLinkDisabled');
    }
  }

  async start(auth: AuthContext): Promise<LinkStartResponse> {
    this.assertEnabled();
    const [state, nonce, verifier] = [rand(), rand(), rand()];
    const value: LinkState = { account_id: auth.accountId, device_hash: auth.deviceHash, nonce, verifier };
    await this.redis.client.set(stateKey(state), JSON.stringify(value), 'EX', STATE_TTL_S);
    const q = new URLSearchParams({
      client_id: this.env.HASTA_GOOGLE_CLIENT_ID!, redirect_uri: this.env.HASTA_GOOGLE_REDIRECT_URI!, response_type: 'code',
      scope: SCOPES.join(' '), state, nonce, prompt: 'select_account',
      code_challenge: createHash('sha256').update(verifier).digest('base64url'), code_challenge_method: 'S256',
    });
    log.info('identity_link_started', { account_id: auth.accountId, provider: 'google' });
    return { state, nonce, scopes: SCOPES, auth_url: `${AUTH_ENDPOINT}?${q.toString()}`, expires_in: STATE_TTL_S };
  }

  async complete(auth: AuthContext, state: string, code: string): Promise<LinkCompleteResponse> {
    this.assertEnabled();
    const raw = await this.redis.client.getdel(stateKey(state)); // single use: burnt on first read
    if (!raw) throw new ApiError(401, 'token_expired', 'identity.linkStateExpired');
    const s = JSON.parse(raw) as LinkState;
    if (s.account_id !== auth.accountId || s.device_hash !== auth.deviceHash) throw ApiError.unauthenticated({ reason: 'link_state' });
    let idToken: string;
    try {
      idToken = await this.google.exchangeCode(code, s.verifier);
    } catch {
      throw ApiError.unauthenticated({ reason: 'google_code_invalid' });
    }
    const g = await this.verifier.verify(idToken, s.nonce);
    try {
      const identity = await this.prisma.$transaction(async (tx) => {
        const row = await tx.identity.create({
          data: { id: uuidv7(), accountId: auth.accountId, provider: 'google', providerSub: g.sub, email: g.email, emailVerified: true },
        });
        await tx.account.update({ where: { id: auth.accountId }, data: { isGuest: false } });
        return row;
      });
      log.info('identity_linked', { account_id: auth.accountId, provider: 'google' });
      return {
        identity: { provider: 'google', email_masked: maskEmail(identity.email), linked_at: identity.linkedAt.toISOString() },
        account: { id: auth.accountId, is_guest: false },
        unlocked: UNLOCKED,
      };
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        log.warn('identity_link_conflict', { account_id: auth.accountId, provider: 'google' });
        throw new ApiError(409, 'identity_in_use', 'identity.inUse');
      }
      throw e;
    }
  }
}
