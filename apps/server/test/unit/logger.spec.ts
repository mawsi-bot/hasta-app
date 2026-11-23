import { log, redact } from '../../src/common/logging/logger';

describe('log redaction (SPEC §15 Logs)', () => {
  it('never writes tokens, emails, phone numbers, raw device ids or bodies', () => {
    const lines: string[] = [];
    log.setSink((l) => lines.push(l), false);
    log.info('x', {
      refresh_token: 'rt_abcdefghijklmnop',
      raw_device_id: 'android-123',
      email: 'a@b.com',
      note: 'contact a@b.com +95 9 1234 5678 eyJhbGciOi.eyJzdWIiOi.sig dt_abcdefghijklmn',
      nested: { authorization: 'Bearer x', body: 'secret message' },
      request_id: 'r1',
    });
    const out = lines.join('\n');
    for (const s of ['rt_abcdefghijklmnop', 'android-123', 'a@b.com', '1234 5678', 'eyJhbGciOi', 'dt_abcdefghijklmn', 'Bearer x', 'secret message']) {
      expect(out).not.toContain(s);
    }
    expect(out).toContain('"request_id":"r1"');
    log.setSink(() => undefined, true);
  });
  it('handles arrays and deep nesting', () => {
    expect(redact(['a@b.com'])).toEqual(['[email]']);
    let deep: Record<string, unknown> = { v: 1 };
    for (let i = 0; i < 10; i++) deep = { d: deep };
    expect(JSON.stringify(redact(deep))).toContain('[depth]');
  });
});
