import { Inject, Injectable, Logger, OnModuleInit, Optional } from '@nestjs/common';

/**
 * Remote-config tunables. Values tagged [PROPOSAL] are pending PO/legal sign-off (SPEC §20) —
 * they are defaults, not legally validated numbers, and must stay overridable at runtime.
 * Resolution (SPEC §16 T50): remote `config.hasta.<key>` > env `HASTA_RC_<KEY>` > code default.
 * There is no live source until Sprint 4 (§20.11): the fetch fails, boot warns once and serves env/defaults.
 */
export interface RemoteConfigValues {
  /** Access token lifetime. Fixed by SPEC §5.3 (15 min). */
  access_token_ttl_seconds: number;
  /** [PROPOSAL] Refresh token absolute lifetime (not specified in SPEC). */
  refresh_token_ttl_days: number;
  /** [PROPOSAL] Device cooldown after account deletion (SPEC §5.9, 30 d). */
  device_cooldown_days: number;
  /** [PROPOSAL] Abuse-log raw retention before aggregation (SPEC §5.10, 90 d). */
  abuse_log_retention_days: number;
  /** Guest create/resume rate limit per device per hour (API contract §1.2). */
  guest_rate_limit_per_hour: number;
  /** [PROPOSAL] Device register rate limit per device per hour (not specified in SPEC). */
  device_register_rate_limit_per_hour: number;
  /** Idempotency key retention (SPEC §3.3, 7 d). */
  idempotency_retention_days: number;
  /** Device token lifetime — the device credential re-registers after expiry. [PROPOSAL] */
  device_token_ttl_days: number;
  /** SPEC 1.0.2 interim: reject Zawgyi profile text until convert-on-write lands (Sprint 3). */
  zawgyi_reject_enabled: boolean;
}

export const REMOTE_CONFIG_DEFAULTS: Readonly<RemoteConfigValues> = Object.freeze({
  access_token_ttl_seconds: 900,
  refresh_token_ttl_days: 30, // [PROPOSAL]
  device_cooldown_days: 30, // [PROPOSAL]
  abuse_log_retention_days: 90, // [PROPOSAL]
  guest_rate_limit_per_hour: 3,
  device_register_rate_limit_per_hour: 10, // [PROPOSAL]
  idempotency_retention_days: 7,
  device_token_ttl_days: 365, // [PROPOSAL]
  zawgyi_reject_enabled: true,
});

type Key = keyof RemoteConfigValues;
export const remoteKey = (k: Key): string => `config.hasta.${k}`;
export const envKey = (k: Key): string => `HASTA_RC_${k.toUpperCase()}`;

export interface RemoteConfigSource {
  fetch(): Promise<Record<string, unknown>>;
}
export const REMOTE_CONFIG_SOURCE = Symbol('REMOTE_CONFIG_SOURCE');
export const REMOTE_CONFIG_ENV = Symbol('REMOTE_CONFIG_ENV');

/** Placeholder until the Sprint 4 poller: behaves like an unreachable provider. */
const noLiveSource: RemoteConfigSource = { fetch: () => Promise.reject(new Error('no remote-config source')) };

function coerce<K extends Key>(k: K, raw: unknown): RemoteConfigValues[K] | undefined {
  const def = REMOTE_CONFIG_DEFAULTS[k];
  if (typeof def === 'boolean') {
    const v = raw === true || raw === 'true' ? true : raw === false || raw === 'false' ? false : undefined;
    return v as RemoteConfigValues[K] | undefined;
  }
  const n = typeof raw === 'number' ? raw : typeof raw === 'string' && raw.trim() !== '' ? Number(raw) : NaN;
  return (Number.isFinite(n) ? n : undefined) as RemoteConfigValues[K] | undefined;
}

@Injectable()
export class RemoteConfigService implements OnModuleInit {
  private readonly log = new Logger('RemoteConfig');
  private overrides: Partial<RemoteConfigValues> = {};
  private remote: Record<string, unknown> = {};
  private warned = false;

  constructor(
    @Optional() @Inject(REMOTE_CONFIG_SOURCE) private readonly source: RemoteConfigSource = noLiveSource,
    @Optional() @Inject(REMOTE_CONFIG_ENV) private readonly env: Record<string, string | undefined> = process.env,
  ) {}

  /** Never awaited: a slow or failing provider must not block boot (T50). */
  onModuleInit(): void {
    void this.refresh();
  }

  async refresh(): Promise<void> {
    try {
      this.remote = await this.source.fetch();
    } catch {
      if (!this.warned) {
        this.warned = true;
        this.log.warn('remote config unavailable; serving env and code defaults');
      }
    }
  }

  get<K extends Key>(key: K): RemoteConfigValues[K] {
    return (this.overrides[key] ??
      coerce(key, this.remote[remoteKey(key)]) ??
      coerce(key, this.env[envKey(key)]) ??
      REMOTE_CONFIG_DEFAULTS[key]) as RemoteConfigValues[K];
  }

  /** Applied by the remote-config poller (Sprint 4) and by tests. */
  applyOverrides(values: Partial<RemoteConfigValues>): void {
    this.overrides = { ...this.overrides, ...values };
  }

  reset(): void {
    this.overrides = {};
  }
}
