import { parseEnv } from '../../src/config/env';
import { loadSecrets } from '../../src/config/secrets';
import { REMOTE_CONFIG_DEFAULTS, RemoteConfigService } from '../../src/config/remote-config';

const base = {
  HASTA_ENV: 'dev',
  HASTA_DATABASE_URL: 'postgresql://u:p@postgres:5432/hasta',
  HASTA_REDIS_URL: 'redis://redis:6379/0',
};

describe('environment contract', () => {
  it('rejects any Google sign-in flag (T37 runtime guard)', () => {
    expect(() => parseEnv({ ...base, HASTA_AUTH_GOOGLE_SIGNIN_ENABLED: 'true' })).toThrow(/Google sign-in/);
  });
  it('rejects quick test accounts outside dev/test/beta (T36 runtime guard)', () => {
    expect(() => parseEnv({ ...base, HASTA_ENV: 'production', HASTA_SECRETS_ARN: 'arn', HASTA_QUICK_TEST_ACCOUNTS_ENABLED: 'true' })).toThrow(/forbidden/);
    expect(() => parseEnv({ ...base, HASTA_ENV: 'staging', HASTA_SECRETS_ARN: 'arn', HASTA_QUICK_TEST_ACCOUNTS_ENABLED: 'true' })).toThrow();
    expect(parseEnv({ ...base, HASTA_ENV: 'beta', HASTA_QUICK_TEST_ACCOUNTS_ENABLED: 'true' }).HASTA_QUICK_TEST_ACCOUNTS_ENABLED).toBe(true);
  });
  it('requires Secrets Manager in staging/production', () => {
    expect(() => parseEnv({ ...base, HASTA_ENV: 'production' })).toThrow(/HASTA_SECRETS_ARN/);
  });
  it('rejects Apple link in v1 and never echoes values in errors', () => {
    try {
      parseEnv({ ...base, HASTA_AUTH_APPLE_LINK_ENABLED: 'true', HASTA_DEVICE_PEPPER: 'short-secret' });
      fail('should throw');
    } catch (e) {
      expect(String(e)).not.toContain('short-secret');
    }
  });
});

describe('secrets loading (pepper from Secrets Manager)', () => {
  const secret = JSON.stringify({
    HASTA_DEVICE_PEPPER: 'p'.repeat(40),
    HASTA_JWT_ACCESS_SECRET: 'a'.repeat(40),
    HASTA_DEVICE_TOKEN_SECRET: 'd'.repeat(40),
  });
  it('uses the AWS fetcher when HASTA_SECRETS_ARN is set', async () => {
    const env = parseEnv({ ...base, HASTA_ENV: 'production', HASTA_SECRETS_ARN: 'arn:aws:secretsmanager:x' });
    const fetcher = jest.fn().mockResolvedValue(secret);
    const s = await loadSecrets(env, fetcher);
    expect(fetcher).toHaveBeenCalledWith('arn:aws:secretsmanager:x', 'ap-southeast-1');
    expect(s.devicePepper).toBe('p'.repeat(40));
  });
  it('fails closed on a short/missing secret without printing it', async () => {
    const env = parseEnv({ ...base, HASTA_DEVICE_PEPPER: 'x'.repeat(32) });
    await expect(loadSecrets(env)).rejects.toThrow(/HASTA_JWT_ACCESS_SECRET/);
  });
});

describe('remote config [PROPOSAL] defaults', () => {
  it('exposes defaults and runtime overrides', () => {
    const rc = new RemoteConfigService();
    expect(rc.get('access_token_ttl_seconds')).toBe(900);
    expect(rc.get('device_cooldown_days')).toBe(REMOTE_CONFIG_DEFAULTS.device_cooldown_days);
    rc.applyOverrides({ device_cooldown_days: 14 });
    expect(rc.get('device_cooldown_days')).toBe(14);
    rc.reset();
    expect(rc.get('device_cooldown_days')).toBe(30);
  });
});
