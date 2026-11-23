import { Injectable } from '@nestjs/common';
import type { Prisma } from '@prisma/client';
import { uuidv7 } from '../../common/ids/uuidv7';
import { TokenService } from './token.service';

export interface IssuedTokens {
  sessionId: string;
  access_token: string;
  refresh_token: string;
  expires_in: number;
}

/** Creates a session row (refresh hash only) and signs the matching access token. */
@Injectable()
export class SessionIssuer {
  constructor(private readonly tokens: TokenService) {}

  async issue(
    tx: Prisma.TransactionClient,
    accountId: string,
    deviceHash: string,
    familyId: string = uuidv7(),
  ): Promise<IssuedTokens> {
    const { token, hash } = this.tokens.newRefreshToken();
    const sessionId = uuidv7();
    await tx.session.create({
      data: { id: sessionId, accountId, deviceHash, refreshHash: hash, familyId, expiresAt: this.tokens.refreshExpiry() },
    });
    return {
      sessionId,
      access_token: this.tokens.signAccess(accountId, sessionId),
      refresh_token: token,
      expires_in: this.tokens.accessTtlSeconds,
    };
  }
}
