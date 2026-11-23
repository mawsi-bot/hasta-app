import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { t37Violations } from './t37-gate';

const ROOT = join(__dirname, '..', '..');

function walk(dir: string, out: string[] = []): string[] {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) walk(p, out);
    else if (/\.(ts|json|prisma|sql)$/.test(name)) out.push(p);
  }
  return out;
}

const pkg = JSON.parse(readFileSync(join(ROOT, 'package.json'), 'utf8')) as Record<string, Record<string, string>>;
const deps = Object.keys({ ...pkg.dependencies, ...pkg.devDependencies });
const src = walk(join(ROOT, 'src')).map((f) => ({ f, text: readFileSync(f, 'utf8') }));

describe('T20 — no OTP / SMS anywhere (static)', () => {
  it('no SMS/OTP provider dependency', () => {
    expect(deps.filter((d) => /twilio|nexmo|vonage|messagebird|plivo|sinch|otp|sms|speakeasy|firebase-auth/i.test(d))).toEqual([]);
  });
  it('no OTP/SMS route decorator or handler in source', () => {
    const hits = src.filter(({ text }) => /@(Post|Get|Put|Patch)\(\s*['"`][^'"`]*(otp|sms)[^'"`]*['"`]/i.test(text)).map((x) => x.f);
    expect(hits).toEqual([]);
  });
});

describe('T37 — SPEC 1.0.1: no sign-in route, no weak ID-token verification (static)', () => {
  it('the gate finds no violation in src/', () => {
    const files = src.map(({ f, text }) => ({ path: relative(ROOT, f), text }));
    expect(t37Violations({ deps, files })).toEqual([]);
  });
});

describe('abuse log hygiene (SPEC §5.10)', () => {
  it('AbuseLogService.record never takes an account id', () => {
    const svc = src.find((x) => x.f.endsWith('abuse-log.service.ts'))!.text;
    const sig = /record\(([^)]*)\)/.exec(svc)![1]!;
    expect(sig).not.toMatch(/account/i);
  });
});
