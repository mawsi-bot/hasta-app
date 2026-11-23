# Enum registry (snake_case, enforced by CHECK constraints)

| Column | Values |
|---|---|
| accounts.status | active, paused, deleted, banned |
| identities.provider | guest, google, apple |
| devices.role | primary, secondary |
| devices.platform | android, ios |
| sessions.revoked_reason | rotated, logout, logout_everywhere, reuse_detected, transfer, admin, account_deleted |
| device_transfers.status | pending, confirmed, expired, rejected |
| abuse_log.event | guest_created, account_deleted |
| entitlements.store | apple, google |
| entitlements.status | active, expired, revoked, pending, grace |

## API error codes
unauthenticated, forbidden, not_found, validation_failed, rate_limited, idempotency_conflict, device_cooldown, token_expired, feature_disabled (new), username_taken (new), internal_error (new).
