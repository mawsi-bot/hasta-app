import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import { TokenService } from '../../modules/auth/token.service';
import { PrismaService } from '../../infra/prisma.service';
import { ApiError } from '../errors/api-error';
import { PUBLIC_META } from './public.decorator';
import type { AuthContext } from './auth-context';

const LIVE_STATUSES = new Set(['active', 'paused']);

/**
 * Global guard. Verifies the 15-min access JWT AND that its session row is still live, so
 * logout / reuse-detection / transfer revocations take effect immediately (not after expiry).
 */
@Injectable()
export class SessionGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly tokens: TokenService,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(PUBLIC_META, [ctx.getHandler(), ctx.getClass()]);
    if (isPublic) return true;
    const req = ctx.switchToHttp().getRequest<Request & { auth?: AuthContext }>();
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) throw ApiError.unauthenticated();
    const claims = this.tokens.verifyAccess(header.slice(7));
    const session = await this.prisma.session.findUnique({
      where: { id: claims.sid },
      select: { id: true, accountId: true, deviceHash: true, revokedAt: true, revokedReason: true, expiresAt: true, account: { select: { status: true } } },
    });
    if (
      !session ||
      session.accountId !== claims.sub ||
      // A rotated row keeps serving its still-unexpired access token; any other revocation is immediate.
      (session.revokedAt !== null && session.revokedReason !== 'rotated') ||
      session.expiresAt.getTime() <= Date.now() ||
      !LIVE_STATUSES.has(session.account.status)
    ) {
      throw ApiError.unauthenticated();
    }
    req.auth = { accountId: session.accountId, sessionId: session.id, deviceHash: session.deviceHash };
    return true;
  }
}
