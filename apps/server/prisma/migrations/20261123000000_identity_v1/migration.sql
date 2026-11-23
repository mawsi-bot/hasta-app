-- HAS-1 · Sprint 1 · identity schema v1 (SPEC §13 IDENTITY + profiles + entitlements + idempotency)
-- Expand-only migration: creates new tables, no destructive change. Rollback: ./rollback.sql
-- PostGIS is enabled by the Sprint 8 radar migration (not needed by identity tables).

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ========== IDENTITY ==========
CREATE TABLE accounts (
  id              uuid PRIMARY KEY,
  status          text NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active','paused','deleted','banned')),
  is_guest        boolean NOT NULL DEFAULT true,
  display_name    text,
  username        text UNIQUE,
  created_at      timestamptz NOT NULL DEFAULT now(),
  deleted_at      timestamptz,
  purge_at        timestamptz,
  updated_hlc     bigint NOT NULL DEFAULT 0,
  CHECK (username IS NULL OR username ~ '^[a-z0-9._]{3,32}$')
);

CREATE TABLE identities (
  id             uuid PRIMARY KEY,
  account_id     uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  provider       text NOT NULL CHECK (provider IN ('guest','google','apple')),
  provider_sub   text NOT NULL,
  email          text,
  email_verified boolean NOT NULL DEFAULT false,
  linked_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, provider_sub)
);
CREATE UNIQUE INDEX uq_identities_account_provider ON identities(account_id, provider);

CREATE TABLE device_bindings (
  id           uuid PRIMARY KEY,
  account_id   uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  device_hash  text NOT NULL,
  role         text NOT NULL DEFAULT 'primary' CHECK (role IN ('primary','secondary')),
  platform     text NOT NULL CHECK (platform IN ('android','ios')),
  push_token   text,
  bound_at     timestamptz NOT NULL DEFAULT now(),
  revoked_at   timestamptz,
  UNIQUE (account_id, device_hash)
);
CREATE INDEX idx_device_bindings_hash ON device_bindings(device_hash) WHERE revoked_at IS NULL;
-- One active binding per device across all accounts (a device holds at most one live account).
CREATE UNIQUE INDEX uq_device_bindings_active_hash ON device_bindings(device_hash) WHERE revoked_at IS NULL;

CREATE TABLE sessions (
  id             uuid PRIMARY KEY,
  account_id     uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  device_hash    text NOT NULL,
  refresh_hash   text NOT NULL UNIQUE,
  family_id      uuid NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  expires_at     timestamptz NOT NULL,
  revoked_at     timestamptz,
  revoked_reason text CHECK (revoked_reason IS NULL OR revoked_reason IN
                   ('rotated','logout','logout_everywhere','reuse_detected','transfer','admin','account_deleted')),
  last_seen_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX sessions_family_id_idx ON sessions(family_id);
CREATE INDEX sessions_account_id_idx ON sessions(account_id);

CREATE TABLE transfer_tokens (
  id           uuid PRIMARY KEY,
  account_id   uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  token_hash   text NOT NULL UNIQUE,
  from_device  text NOT NULL,
  to_device    text,
  status       text NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending','confirmed','expired','rejected')),
  created_at   timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz NOT NULL,
  used_at      timestamptz
);

CREATE TABLE device_cooldowns (
  device_hash  text PRIMARY KEY,
  reason       text NOT NULL DEFAULT 'account_deleted',
  until        timestamptz NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE abuse_logs (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  device_hash  text NOT NULL,                -- NO account_id, NO raw device id (SPEC §5.10)
  event        text NOT NULL CHECK (event IN ('guest_created','account_deleted')),
  occurred_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_abuse_device_window ON abuse_logs(device_hash, occurred_at);

-- ========== SOCIAL (profile basics) ==========
CREATE TABLE profiles (
  user_id      uuid PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
  display_name text NOT NULL,
  bio          text CHECK (bio IS NULL OR char_length(bio) <= 300),
  avatar_key   text,
  birth_date   date,
  privacy      jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_hlc  bigint NOT NULL DEFAULT 0,
  field_hlc    jsonb NOT NULL DEFAULT '{}'::jsonb
);

-- ========== BILLING (read-only in Sprint 1; written from Sprint 9) ==========
CREATE TABLE entitlements (
  id               uuid PRIMARY KEY,
  account_id       uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  store            text NOT NULL CHECK (store IN ('apple','google')),
  product_id       text NOT NULL,
  store_txn_hash   text NOT NULL,
  status           text NOT NULL DEFAULT 'active'
                   CHECK (status IN ('active','expired','revoked','pending','grace')),
  starts_at        timestamptz NOT NULL,
  expires_at       timestamptz,
  last_verified_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store, store_txn_hash)
);

-- ========== SYNC / IDEMPOTENCY ==========
CREATE TABLE idempotency_keys (
  scope         text NOT NULL,
  key           text NOT NULL,
  request_hash  text NOT NULL,
  response_hash text NOT NULL,
  status_code   integer NOT NULL,
  response_body jsonb,
  created_at    timestamptz NOT NULL DEFAULT now(),
  expires_at    timestamptz NOT NULL,
  PRIMARY KEY (scope, key)
);
CREATE INDEX idempotency_keys_expires_at_idx ON idempotency_keys(expires_at);
