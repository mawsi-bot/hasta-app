import { mergeFields, parseHlc } from '../../src/modules/user/hlc-merge';
import { maskEmail } from '../../src/modules/user/mask-email';

const hlc = (ms: number, c = 0) => (BigInt(ms) << 16n) | BigInt(c);

describe('field-level HLC LWW merge (SPEC §11.3, T18 groundwork)', () => {
  it('applies newer fields and ignores stale ones independently', () => {
    const current = { bio: hlc(2000).toString(), display_name: hlc(1000).toString() };
    const r = mergeFields(['bio', 'display_name', 'username'], hlc(1500), current);
    expect(r.applied).toEqual(['display_name', 'username']);
    expect(r.ignored).toEqual(['bio']);
    expect(r.clocks.bio).toBe(hlc(2000).toString());
    expect(r.maxHlc).toBe(hlc(2000));
  });
  it('device A edits bio, device B edits avatar → both survive', () => {
    const afterA = mergeFields(['bio'], hlc(1000, 1), {});
    const afterB = mergeFields(['display_name'], hlc(1000, 0), afterA.clocks);
    expect(afterB.applied).toEqual(['display_name']);
    expect(Object.keys(afterB.clocks).sort()).toEqual(['bio', 'display_name']);
  });
  it('equal clocks do not overwrite (deterministic)', () => {
    const r = mergeFields(['bio'], hlc(5), { bio: hlc(5).toString() });
    expect(r.applied).toEqual([]);
  });
  it('parses only valid 64-bit decimal HLCs', () => {
    expect(parseHlc('123')).toBe(123n);
    expect(() => parseHlc('-1')).toThrow();
    expect(() => parseHlc('abc')).toThrow();
    expect(() => parseHlc('18446744073709551616')).toThrow();
  });
});

describe('email masking (SPEC §5.4)', () => {
  it('masks to first char + *** + domain', () => {
    expect(maskEmail('heinhtet@gmail.com')).toBe('h***@gmail.com');
    expect(maskEmail('@x.com')).toBe('***');
    expect(maskEmail(null)).toBeNull();
  });
});
