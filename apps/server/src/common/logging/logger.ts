/**
 * Structured JSON logger with mandatory redaction (SPEC §15 Logs): tokens, emails, phone-like
 * strings, message bodies and raw device ids are never written. Keep request_id, account_id,
 * route, duration, status.
 */
const REDACT_KEYS = new Set([
  'authorization', 'access_token', 'refresh_token', 'device_token', 'raw_device_id', 'token', 'id_token',
  'code', 'password', 'secret', 'email', 'body', 'message', 'cookie', 'idempotency_key', 'device_hash', 'pepper',
]);
const EMAIL_RE = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi;
const PHONE_RE = /\+?\d[\d\s-]{7,}\d/g;
const JWT_RE = /eyJ[\w-]+\.[\w-]+\.[\w-]+/g;
const OPAQUE_RE = /\b(?:rt|dt|tt)_[\w-]{10,}/g;

export function redact(value: unknown, depth = 0): unknown {
  if (depth > 6) return '[depth]';
  if (typeof value === 'string') {
    return value.replace(JWT_RE, '[jwt]').replace(OPAQUE_RE, '[token]').replace(EMAIL_RE, '[email]').replace(PHONE_RE, '[phone]');
  }
  if (Array.isArray(value)) return value.map((v) => redact(v, depth + 1));
  if (value && typeof value === 'object') {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
      out[k] = REDACT_KEYS.has(k.toLowerCase()) ? '[redacted]' : redact(v, depth + 1);
    }
    return out;
  }
  return value;
}

type Level = 'debug' | 'info' | 'warn' | 'error';
let sink: (line: string) => void = (line) => process.stdout.write(`${line}\n`);
let silent = process.env.HASTA_ENV === 'test';

function write(level: Level, msg: string, fields: Record<string, unknown> = {}): void {
  if (silent && level !== 'error') return;
  sink(JSON.stringify({ ts: new Date().toISOString(), level, msg, ...(redact(fields) as object) }));
}

export const log = {
  debug: (m: string, f?: Record<string, unknown>) => write('debug', m, f),
  info: (m: string, f?: Record<string, unknown>) => write('info', m, f),
  warn: (m: string, f?: Record<string, unknown>) => write('warn', m, f),
  error: (m: string, f?: Record<string, unknown>) => write('error', m, f),
  /** test hook */
  setSink(fn: (line: string) => void, isSilent = false) {
    sink = fn;
    silent = isSilent;
  },
};
