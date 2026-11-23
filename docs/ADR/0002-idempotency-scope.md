# ADR-0002 — Idempotency-Key scope and stored response

Status: accepted (Sprint 1)

## Decision
`idempotency_keys` has primary key `(scope, key)`, where scope is `acct:<account_id>` for authenticated writes. We store `request_hash` (sha256 of method + route + JSON body), `status_code` and `response_body`, and keep them for `idempotency_retention_days` = 7 (SPEC §3.3, remote config). A replay with the same hash returns the stored response; a different hash returns `409 idempotency_conflict`; a concurrent in-flight replay returns `409` with `details.reason=in_progress`.

Pre-login and token endpoints (`/auth/device/register`, `/auth/guest`, `/auth/refresh`, `/auth/logout`) are marked `@IdempotentByDesign`: the device lock / advisory lock and rotation already make them safe to retry, and storing their responses would persist live tokens, which the logging/privacy rule forbids.
