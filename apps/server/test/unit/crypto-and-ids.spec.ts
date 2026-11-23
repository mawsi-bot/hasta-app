import { deviceHash, opaqueToken, safeEqualHex, sha256Hex, shortHash } from '../../src/common/crypto/crypto';
import { isUuidV7, uuidv7 } from '../../src/common/ids/uuidv7';

describe('device hash (SPEC §5.3) — supports T40/T41', () => {
  it('is HMAC-SHA256(pepper, raw): deterministic, 64 hex, pepper-dependent, raw not recoverable', () => {
    const a = deviceHash('pepper-1'.padEnd(32, 'x'), 'android-id-123');
    expect(a).toMatch(/^[0-9a-f]{64}$/);
    expect(deviceHash('pepper-1'.padEnd(32, 'x'), 'android-id-123')).toBe(a);
    expect(deviceHash('pepper-2'.padEnd(32, 'x'), 'android-id-123')).not.toBe(a);
    expect(a).not.toContain('android');
    expect(a).not.toBe(sha256Hex('android-id-123')); // keyed, not a plain hash
  });

  it('helpers', () => {
    expect(opaqueToken('rt_')).toMatch(/^rt_[\w-]{43}$/);
    expect(safeEqualHex('abcd', 'abcd')).toBe(true);
    expect(safeEqualHex('abcd', 'abce')).toBe(false);
    expect(safeEqualHex('ab', 'abcd')).toBe(false);
    expect(shortHash('0123456789abcdef')).toBe('01234567');
  });
});

describe('uuidv7 (rule 9)', () => {
  it('produces RFC 9562 v7 ids that sort by creation time', () => {
    const ids = Array.from({ length: 2000 }, () => uuidv7());
    ids.forEach((id) => expect(isUuidV7(id)).toBe(true));
    expect([...ids].sort()).toEqual(ids);
    expect(new Set(ids).size).toBe(ids.length);
  });
  it('embeds the timestamp and rejects non-v7 values', () => {
    const t = Date.UTC(2026, 10, 23, 9, 30);
    const id = uuidv7(t + 10_000);
    expect(parseInt(id.replace(/-/g, '').slice(0, 12), 16)).toBeGreaterThanOrEqual(t);
    expect(isUuidV7('00000000-0000-4000-8000-000000000000')).toBe(false);
    expect(isUuidV7(42)).toBe(false);
  });
});
