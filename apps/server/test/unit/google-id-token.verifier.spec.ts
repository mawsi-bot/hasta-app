import { parseEnv } from '../../src/config/env';
import { GoogleIdTokenVerifier } from '../../src/modules/identity/google-id-token.verifier';
import type { GoogleOAuthPort } from '../../src/modules/identity/google-oauth.port';
import { GOOGLE_TEST_CERTS, GOOGLE_TEST_ENV, googleClaims, signIdToken } from '../google-fake';

/** T39b–f + email_verified at the trust boundary. Only Google's certs are faked; the verifier is real. */
const port = { certs: async () => GOOGLE_TEST_CERTS, exchangeCode: async () => '' } as unknown as GoogleOAuthPort;
const verifier = new GoogleIdTokenVerifier(parseEnv({ ...process.env, ...GOOGLE_TEST_ENV }), port);
const NONCE = 'expected-nonce';
const now = () => Math.floor(Date.now() / 1000);

describe('GoogleIdTokenVerifier', () => {
  it('accepts a correctly signed token with the expected iss/aud/exp/nonce and a verified email', async () => {
    await expect(verifier.verify(signIdToken(googleClaims(NONCE)), NONCE)).resolves.toEqual({ sub: 'g-sub-1', email: 'heinhtet@gmail.com' });
  });

  it.each([
    ['T39b signature (foreign key)', {}, { foreignKey: true }],
    ['T39c iss', { iss: 'https://evil.example.com' }, {}],
    ['T39d aud', { aud: 'other-client.apps.googleusercontent.com' }, {}],
    ['T39e exp', { exp: now() - 3600, iat: now() - 7200 }, {}],
    ['T39f nonce', { nonce: 'replayed-nonce' }, {}],
  ])('%s → 401 unauthenticated', async (_n, over, opts) => {
    await expect(verifier.verify(signIdToken(googleClaims(NONCE, over), opts), NONCE)).rejects.toMatchObject({ status: 401, code: 'unauthenticated' });
  });

  it('T39b — a tampered payload under a valid signature → 401', async () => {
    const [h, , s] = signIdToken(googleClaims(NONCE)).split('.');
    const forged = Buffer.from(JSON.stringify(googleClaims(NONCE, { sub: 'victim' }))).toString('base64url');
    await expect(verifier.verify(`${h}.${forged}.${s}`, NONCE)).rejects.toMatchObject({ status: 401 });
  });

  it('email_verified=false → 422 google_email_unverified', async () => {
    await expect(verifier.verify(signIdToken(googleClaims(NONCE, { email_verified: false })), NONCE)).rejects.toMatchObject({
      status: 422, code: 'google_email_unverified',
    });
  });
});
