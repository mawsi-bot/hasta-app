import { Inject, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { SECRETS } from '../../config/config.module';
import type { Secrets } from '../../config/secrets';
import { RemoteConfigService } from '../../config/remote-config';
import { opaqueToken, sha256Hex } from '../../common/crypto/crypto';
import { ApiError } from '../../common/errors/api-error';

export interface AccessClaims {
  sub: string;
  sid: string;
  typ: 'access';
}

export interface DeviceClaims {
  dh: string;
  plt: 'android' | 'ios';
  typ: 'device';
}

const DEVICE_PREFIX = 'dt_';
const REFRESH_PREFIX = 'rt_';
const ISSUER = 'hasta-api';

/**
 * Access JWT (15 min, HS256), opaque rotating refresh tokens (hash-only at rest) and signed
 * device tokens. Separate keys per token type so one can never be replayed as another.
 */
@Injectable()
export class TokenService {
  private readonly access: JwtService;
  private readonly device: JwtService;

  constructor(
    @Inject(SECRETS) secrets: Secrets,
    private readonly rc: RemoteConfigService,
  ) {
    this.access = new JwtService({ secret: secrets.jwtAccessSecret, signOptions: { algorithm: 'HS256', issuer: ISSUER } });
    this.device = new JwtService({ secret: secrets.deviceTokenSecret, signOptions: { algorithm: 'HS256', issuer: ISSUER } });
  }

  get accessTtlSeconds(): number {
    return this.rc.get('access_token_ttl_seconds');
  }

  signAccess(accountId: string, sessionId: string): string {
    const claims: AccessClaims = { sub: accountId, sid: sessionId, typ: 'access' };
    return this.access.sign(claims, { expiresIn: this.accessTtlSeconds });
  }

  verifyAccess(token: string): AccessClaims {
    try {
      const c = this.access.verify<AccessClaims>(token, { algorithms: ['HS256'], issuer: ISSUER });
      if (c.typ !== 'access' || typeof c.sub !== 'string' || typeof c.sid !== 'string') throw new Error('typ');
      return c;
    } catch {
      throw ApiError.unauthenticated();
    }
  }

  signDevice(deviceHash: string, platform: 'android' | 'ios'): string {
    const claims: DeviceClaims = { dh: deviceHash, plt: platform, typ: 'device' };
    return DEVICE_PREFIX + this.device.sign(claims, { expiresIn: `${this.rc.get('device_token_ttl_days')}d` });
  }

  verifyDevice(token: string): DeviceClaims {
    if (typeof token !== 'string' || !token.startsWith(DEVICE_PREFIX)) throw ApiError.unauthenticated({ reason: 'device_token' });
    try {
      const c = this.device.verify<DeviceClaims>(token.slice(DEVICE_PREFIX.length), { algorithms: ['HS256'], issuer: ISSUER });
      if (c.typ !== 'device' || typeof c.dh !== 'string') throw new Error('typ');
      return c;
    } catch {
      throw ApiError.unauthenticated({ reason: 'device_token' });
    }
  }

  newRefreshToken(): { token: string; hash: string } {
    const token = opaqueToken(REFRESH_PREFIX);
    return { token, hash: sha256Hex(token) };
  }

  hashRefresh(token: string): string {
    return sha256Hex(token);
  }

  refreshExpiry(from = new Date()): Date {
    return new Date(from.getTime() + this.rc.get('refresh_token_ttl_days') * 86_400_000);
  }
}
