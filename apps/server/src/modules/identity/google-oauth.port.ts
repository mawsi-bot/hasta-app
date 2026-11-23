import { Inject, Injectable } from '@nestjs/common';
import { OAuth2Client } from 'google-auth-library';
import { ENV, SECRETS } from '../../config/config.module';
import type { Env } from '../../config/env';
import type { Secrets } from '../../config/secrets';

/**
 * The only network boundary to Google (SPEC 1.0.2 §5.4, §19 web client). Tests replace these two methods;
 * the verifier that consumes them is always the real one.
 */
export abstract class GoogleOAuthPort {
  /** Server-side authorization-code exchange (PKCE). Resolves to the raw id_token. */
  abstract exchangeCode(code: string, codeVerifier: string): Promise<string>;
  /** Google's current signing certificates, keyed by kid. */
  abstract certs(): Promise<Record<string, string>>;
}

@Injectable()
export class GoogleOAuthHttp extends GoogleOAuthPort {
  private readonly client: OAuth2Client;

  constructor(@Inject(ENV) env: Env, @Inject(SECRETS) secrets: Secrets) {
    super();
    this.client = new OAuth2Client({
      clientId: env.HASTA_GOOGLE_CLIENT_ID,
      clientSecret: secrets.googleClientSecret,
      redirectUri: env.HASTA_GOOGLE_REDIRECT_URI,
    });
  }

  async exchangeCode(code: string, codeVerifier: string): Promise<string> {
    const { tokens } = await this.client.getToken({ code, codeVerifier });
    if (!tokens.id_token) throw new Error('no id_token in token response');
    return tokens.id_token;
  }

  async certs(): Promise<Record<string, string>> {
    return (await this.client.getFederatedSignonCertsAsync()).certs as Record<string, string>;
  }
}
