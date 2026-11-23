import { randomBytes } from 'node:crypto';

let lastMs = 0;
let seq = 0;

/**
 * RFC 9562 UUIDv7 (48-bit unix ms + 74 random bits), monotonic within the same millisecond
 * via a 12-bit counter in rand_a. Dependency-free to respect the locked stack.
 */
export function uuidv7(now: number = Date.now()): string {
  const bytes = randomBytes(16);
  if (now <= lastMs) {
    now = lastMs;
    seq += 1;
    if (seq > 0x0fff) {
      now = lastMs + 1;
      seq = 0;
    }
  } else {
    seq = ((bytes[6]! << 8) | bytes[7]!) & 0x07ff; // random start, head-room for in-ms increments
  }
  lastMs = now;
  const ms = BigInt(now);
  bytes[0] = Number((ms >> 40n) & 0xffn);
  bytes[1] = Number((ms >> 32n) & 0xffn);
  bytes[2] = Number((ms >> 24n) & 0xffn);
  bytes[3] = Number((ms >> 16n) & 0xffn);
  bytes[4] = Number((ms >> 8n) & 0xffn);
  bytes[5] = Number(ms & 0xffn);
  bytes[6] = 0x70 | ((seq >> 8) & 0x0f);
  bytes[7] = seq & 0xff;
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;
  const h = bytes.toString('hex');
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20)}`;
}

export const UUID_V7_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

export function isUuidV7(v: unknown): v is string {
  return typeof v === 'string' && UUID_V7_RE.test(v);
}
