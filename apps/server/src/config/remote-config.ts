import { Injectable } from '@nestjs/common';

/**
 * Remote-config tunables. Values tagged [PROPOSAL] are pending PO/legal sign-off (SPEC §20) —
 * they are defaults, not legally validated numbers, and must stay overridable at runtime.
 * Sprint 1 ships the typed defaults + override hook; the remote source is wired in Sprint 4.
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
});

@Injectable()
export class RemoteConfigService {
  private overrides: Partial<RemoteConfigValues> = {};

  get<K extends keyof RemoteConfigValues>(key: K): RemoteConfigValues[K] {
    return (this.overrides[key] ?? REMOTE_CONFIG_DEFAULTS[key]) as RemoteConfigValues[K];
  }

  /** Applied by the remote-config poller (Sprint 4) and by tests. */
  applyOverrides(values: Partial<RemoteConfigValues>): void {
    this.overrides = { ...this.overrides, ...values };
  }

  reset(): void {
    this.overrides = {};
  }
}
