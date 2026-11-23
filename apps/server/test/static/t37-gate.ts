/**
 * T37 gate (SPEC 1.0.1 §16): fails on Google/Apple SIGN-IN ROUTES and on ID-token verification that skips
 * iss / aud / exp / nonce / email_verified. The Google auth library is PERMITTED (and required) inside
 * src/modules/identity — the gate targets routes and trust boundaries, never dependencies.
 * Pure function so fixtures prove it both passes and fails.
 */
export interface SourceFile { path: string; text: string }
export interface GateInput { deps: string[]; files: SourceFile[] }

const SIGN_IN_ROUTE = /@(Post|Get|Put|Patch)\(\s*['"`][^'"`]*(sign-?in|log-?in|id_token|token-login)[^'"`]*['"`]/i;
const GOOGLE_LIB = /from\s+['"](google-auth-library|passport-google[\w-]*|passport-apple|apple-signin[\w-]*)['"]/;
const IDENTITY_MODULE = /(^|\/)src\/modules\/identity\//;
const REQUIRED_CLAIMS: ReadonlyArray<[string, RegExp]> = [
  ['iss', /\.iss\b/],
  ['aud', /\baudience\s*:/],
  ['exp', /\.exp\b/],
  ['nonce', /\.nonce\b/],
  ['email_verified', /\.email_verified\b/],
];

export function t37Violations({ files }: GateInput): string[] {
  const out: string[] = [];
  for (const f of files) {
    if (SIGN_IN_ROUTE.test(f.text)) out.push(`sign-in route: ${f.path}`);
    if (GOOGLE_LIB.test(f.text) && !IDENTITY_MODULE.test(f.path)) out.push(`google auth outside modules/identity: ${f.path}`);
    if (/verifyIdToken\s*\(/.test(f.text)) {
      for (const [claim, re] of REQUIRED_CLAIMS) if (!re.test(f.text)) out.push(`verification skips ${claim}: ${f.path}`);
    }
  }
  return out;
}
