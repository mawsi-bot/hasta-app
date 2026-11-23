import { t37Violations, type SourceFile } from './t37-gate';

const verifier = (checks: string): SourceFile => ({
  path: 'src/modules/identity/google-id-token.verifier.ts',
  text: `import { OAuth2Client } from 'google-auth-library';
    const ticket = await client.verifyIdToken({ idToken, audience: env.HASTA_GOOGLE_CLIENT_ID });
    const p = ticket.getPayload();${checks}`,
});
const ALL_CHECKS = `
    if (!ISSUERS.includes(p.iss)) throw bad(); if (p.exp * 1000 <= Date.now()) throw bad();
    if (p.nonce !== expectedNonce) throw bad(); if (p.email_verified !== true) throw bad();`;
const linkController: SourceFile = {
  path: 'src/modules/identity/identity.controller.ts',
  text: `@Post('identities/google/link:complete') complete() {}  @Delete('identities/google') unlink() {}`,
};

describe('T37 gate — SPEC 1.0.1 (routes and trust boundaries, not dependencies)', () => {
  it('PERMITS google-auth-library inside modules/identity with a full verification (positive fixture)', () => {
    expect(t37Violations({ deps: ['google-auth-library'], files: [verifier(ALL_CHECKS), linkController] })).toEqual([]);
  });
});

describe('T37 gate — negative fixtures (must fail the build)', () => {
  it.each([
    ["@Post('auth/google/signin')", 'sign-in route'],
    ["@Post('login') body: { id_token }", 'sign-in route'],
    ["@Post('auth/apple/sign-in')", 'sign-in route'],
  ])('%s', (route, expected) => {
    const v = t37Violations({ deps: [], files: [{ path: 'src/modules/identity/x.controller.ts', text: route }] });
    expect(v.join()).toContain(expected);
  });

  it.each(['iss', 'exp', 'nonce', 'email_verified'])('verification that skips %s', (claim) => {
    const re = { iss: /if \(!ISSUERS.*?bad\(\);/, exp: /if \(p\.exp.*?bad\(\);/, nonce: /if \(p\.nonce.*?bad\(\);/, email_verified: /if \(p\.email_verified.*?bad\(\);/ }[claim]!;
    expect(t37Violations({ deps: [], files: [verifier(ALL_CHECKS.replace(re, ''))] })).toEqual([`verification skips ${claim}: ${verifier('').path}`]);
  });

  it('verification without an audience', () => {
    const f = verifier(ALL_CHECKS);
    expect(t37Violations({ deps: [], files: [{ ...f, text: f.text.replace(/, audience: [^}]+/, ' ') }] })).toContain(`verification skips aud: ${f.path}`);
  });

  it('cert-based verification (verifySignedJwtWithCertsAsync) that skips nonce', () => {
    const f = { ...verifier(ALL_CHECKS.replace(/if \(p\.nonce.*?bad\(\);/, '')) };
    f.text = f.text.replace('client.verifyIdToken({ idToken, ', 'client.verifySignedJwtWithCertsAsync(idToken, certs, { ');
    expect(t37Violations({ deps: [], files: [f] })).toEqual([`verification skips nonce: ${f.path}`]);
  });

  it('google-auth-library imported outside modules/identity', () => {
    const f = { ...verifier(ALL_CHECKS), path: 'src/modules/auth/google.ts' };
    expect(t37Violations({ deps: [], files: [f] })).toEqual(['google auth outside modules/identity: src/modules/auth/google.ts']);
  });
});
