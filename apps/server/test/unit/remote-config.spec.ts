import { Logger } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import {
  REMOTE_CONFIG_DEFAULTS, REMOTE_CONFIG_ENV, REMOTE_CONFIG_SOURCE, RemoteConfigService, RemoteConfigSource, envKey, remoteKey,
} from '../../src/config/remote-config';

const src = (fetch: RemoteConfigSource['fetch']): RemoteConfigSource => ({ fetch });

describe('T50 remote-config resolution and boot', () => {
  let warn: jest.SpyInstance;
  beforeEach(() => {
    warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation(() => undefined);
  });
  afterEach(() => warn.mockRestore());

  it('keys are namespaced: config.hasta.<key> remotely, HASTA_RC_<KEY> in env', () => {
    expect(remoteKey('device_token_ttl_days')).toBe('config.hasta.device_token_ttl_days');
    expect(envKey('device_token_ttl_days')).toBe('HASTA_RC_DEVICE_TOKEN_TTL_DAYS');
  });

  it('resolves remote > env > code default', async () => {
    const env = { HASTA_RC_REFRESH_TOKEN_TTL_DAYS: '14', HASTA_RC_GUEST_RATE_LIMIT_PER_HOUR: '5' };
    const rc = new RemoteConfigService(src(async () => ({ 'config.hasta.refresh_token_ttl_days': 7 })), env);
    await rc.refresh();
    expect(rc.get('refresh_token_ttl_days')).toBe(7); // remote wins over env
    expect(rc.get('guest_rate_limit_per_hour')).toBe(5); // env wins over default
    expect(rc.get('device_token_ttl_days')).toBe(REMOTE_CONFIG_DEFAULTS.device_token_ttl_days); // default
  });

  it('ignores unprefixed or malformed remote/env values', async () => {
    const env = { HASTA_RC_DEVICE_TOKEN_TTL_DAYS: 'abc' };
    const rc = new RemoteConfigService(
      src(async () => ({ device_register_rate_limit_per_hour: 99, 'config.hasta.refresh_token_ttl_days': 'x' })),
      env,
    );
    await rc.refresh();
    expect(rc.get('device_register_rate_limit_per_hour')).toBe(10);
    expect(rc.get('refresh_token_ttl_days')).toBe(30);
    expect(rc.get('device_token_ttl_days')).toBe(365);
  });

  it('fetch failure falls back to env/code defaults with exactly ONE warning, no value or error detail logged', async () => {
    const rc = new RemoteConfigService(src(async () => { throw new Error('token=secret'); }), { HASTA_RC_REFRESH_TOKEN_TTL_DAYS: '14' });
    await rc.refresh();
    await rc.refresh();
    expect(rc.get('refresh_token_ttl_days')).toBe(14);
    expect(rc.get('device_token_ttl_days')).toBe(365);
    expect(warn).toHaveBeenCalledTimes(1);
    expect(JSON.stringify(warn.mock.calls)).not.toContain('secret');
  });

  it('a hanging remote source never blocks boot', async () => {
    const hang = src(() => new Promise<never>(() => undefined));
    const mod = await Test.createTestingModule({
      providers: [RemoteConfigService, { provide: REMOTE_CONFIG_SOURCE, useValue: hang }, { provide: REMOTE_CONFIG_ENV, useValue: {} }],
    }).compile();
    const booted = await Promise.race([mod.init().then(() => 'booted'), new Promise((r) => setTimeout(() => r('blocked'), 500))]);
    expect(booted).toBe('booted');
    expect(mod.get(RemoteConfigService).get('refresh_token_ttl_days')).toBe(30);
    await mod.close();
  });

  it('with no live source (until Sprint 4) boot warns once and serves code defaults', async () => {
    const rc = new RemoteConfigService(undefined, {});
    await rc.refresh();
    expect(warn).toHaveBeenCalledTimes(1);
    expect(rc.get('guest_rate_limit_per_hour')).toBe(3);
  });
});
