import { Inject, Injectable } from '@nestjs/common';
import { OAuth2Client } from 'google-auth-library';
import { ENV } from '../../config/config.module';
import type { Env } from '../../config/env';
import { ApiError } from '../../common/errors/api-error';
import { GoogleOAuthPort } from './google-oauth.port';

const ISSUERS = ['accounts.google.com', 'https://accounts.google.com'];

export interface VerifiedGoogleIdentity { sub: string; email: string }

/**
 * Verifies an id_token the SERVER obtained from Google's token endpoint — never one sent by the client
 * (SPEC 1.0.2 §5.4; T39). Signature, iss, aud and exp are checked by the library and re-checked here;
 * nonce and email_verified are ours. Gate T37 fails the build if any of the five checks disappears.
 */
@Injectable()
export class GoogleIdTokenVerifier {
  private readonly lib = new OAuth2Client();

  constructor(
    @Inject(ENV) private readonly env: Env,
    private readonly google: GoogleOAuthPort,
  ) {}

  async verify(idToken: string, expectedNonce: string): Promise<VerifiedGoogleIdentity> {
    const expected = { audience: this.env.HASTA_GOOGLE_CLIENT_ID!, issuers: ISSUERS };
    const bad = () => ApiError.unauthenticated({ reason: 'google_token_invalid' });
    let p;
    try {
      const certs = await this.google.certs();
      p = (await this.lib.verifySignedJwtWithCertsAsync(idToken, certs, expected.audience, expected.issuers)).getPayload();
    } catch {
      throw bad();
    }
    if (!p || !ISSUERS.includes(p.iss) || p.aud !== expected.audience) throw bad();
    if (p.exp * 1000 <= Date.now()) throw bad();
    if (p.nonce !== expectedNonce) throw bad();
    if (p.email_verified !== true || !p.email) {
      throw new ApiError(422, 'google_email_unverified', 'identity.googleEmailUnverified');
    }
    return { sub: p.sub, email: p.email };
  }
}
