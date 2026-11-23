import { createSign, generateKeyPairSync, type KeyObject } from 'node:crypto';

/** Deterministic stand-in for Google's token endpoint + JWKS. A fresh RSA key per test run. */
export const GOOGLE_TEST_CLIENT_ID = 'hasta-test.apps.googleusercontent.com';
const signing = generateKeyPairSync('rsa', { modulusLength: 2048 });
const foreign = generateKeyPairSync('rsa', { modulusLength: 2048 });
export const GOOGLE_TEST_CERTS = { 'kid-1': signing.publicKey.export({ type: 'spki', format: 'pem' }).toString() };

const b64 = (o: unknown) => Buffer.from(JSON.stringify(o)).toString('base64url');

export function signIdToken(claims: Record<string, unknown>, opts: { foreignKey?: boolean } = {}): string {
  const key: KeyObject = opts.foreignKey ? foreign.privateKey : signing.privateKey;
  const head = `${b64({ alg: 'RS256', kid: 'kid-1', typ: 'JWT' })}.${b64(claims)}`;
  return `${head}.${createSign('RSA-SHA256').update(head).sign(key).toString('base64url')}`;
}

export function googleClaims(nonce: string, over: Record<string, unknown> = {}): Record<string, unknown> {
  const now = Math.floor(Date.now() / 1000);
  return {
    iss: 'https://accounts.google.com', aud: GOOGLE_TEST_CLIENT_ID, sub: 'g-sub-1', email: 'heinhtet@gmail.com',
    email_verified: true, iat: now, exp: now + 600, nonce, ...over,
  };
}

export const GOOGLE_TEST_ENV = {
  HASTA_GOOGLE_CLIENT_ID: GOOGLE_TEST_CLIENT_ID,
  HASTA_GOOGLE_CLIENT_SECRET: 'test-only-google-client-secret',
  HASTA_GOOGLE_REDIRECT_URI: 'https://api.hasta.test/v1/auth/identities/google/link:callback',
};
