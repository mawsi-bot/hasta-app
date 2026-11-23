import { createHash, createHmac, randomBytes, timingSafeEqual } from 'node:crypto';

/** device_hash = HMAC-SHA256(HASTA_DEVICE_PEPPER, raw_id) — SPEC §5.3. Hex, lowercase. */
export function deviceHash(pepper: string, rawDeviceId: string): string {
  return createHmac('sha256', pepper).update(rawDeviceId, 'utf8').digest('hex');
}

export function sha256Hex(input: string): string {
  return createHash('sha256').update(input, 'utf8').digest('hex');
}

/** Opaque high-entropy secret with a type prefix (e.g. `rt_`). */
export function opaqueToken(prefix: string, bytes = 32): string {
  return `${prefix}${randomBytes(bytes).toString('base64url')}`;
}

export function safeEqualHex(a: string, b: string): boolean {
  const ab = Buffer.from(a, 'hex');
  const bb = Buffer.from(b, 'hex');
  return ab.length === bb.length && timingSafeEqual(ab, bb);
}

/** Short, non-reversible label for UI/session lists (never the full hash). */
export function shortHash(hash: string): string {
  return hash.slice(0, 8);
}
