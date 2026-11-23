-- Rollback for 20261123000000_identity_v1. Drops in FK-reverse order.
-- Run via `npm run migrate:rollback -- 20261123000000_identity_v1` (never by hand in shared envs).
DROP TABLE IF EXISTS idempotency_keys;
DROP TABLE IF EXISTS entitlements;
DROP TABLE IF EXISTS profiles;
DROP TABLE IF EXISTS abuse_logs;
DROP TABLE IF EXISTS device_cooldowns;
DROP TABLE IF EXISTS transfer_tokens;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS device_bindings;
DROP TABLE IF EXISTS identities;
DROP TABLE IF EXISTS accounts;
DELETE FROM _prisma_migrations WHERE migration_name = '20261123000000_identity_v1';
