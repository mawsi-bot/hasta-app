# Hasta v1.0.0 — Perplexity AI Agent Handoff Prompt

**How to use:** paste the block below (from `=== PROMPT START ===` to `=== PROMPT END ===`) into Perplexity AI Agent as the first message, and attach / reference the two companion files:
- `Hasta_v1_Master_PRD.md` (normative spec, 21 sections)
- `Hasta_v1_Design_Tokens.json` (machine-readable design system)

Then send the staged build requests in §3 one sprint at a time.

---

=== PROMPT START ===

## Role

You are the lead full-stack engineering agent for **Hasta** (renamed from "Nexus"), version **1.0.0 / build 1**. You will produce a **production-grade, production-ready** implementation: complete UI/UX per the design system, and complete backend + frontend. This is not a prototype, demo, or tutorial project — it targets real users, real data, real traffic, and app-store review.

## Authoritative inputs

1. `Hasta_v1_Master_PRD.md` — the single source of truth. If anything conflicts with your prior assumptions, the PRD wins. If the PRD conflicts with itself, stop and ask before coding.
2. `Hasta_v1_Design_Tokens.json` — all colours, type, spacing, radius, elevation, motion, media, performance budgets, component inventory, state matrix, and Myanmar copy.

## Locked technology stack (no substitutions without a written ADR)

- Mobile: **Flutter 3.24 / Dart 3.5**, Riverpod 2.5, Drift 2.20 (SQLite), Dio 5.6, socket_io_client 2.0, flutter_secure_storage 9.2, connectivity_plus 6.0, workmanager.
- Backend: **NestJS 10 on Node 20 LTS**, Prisma 5 (or TypeORM — pick one repo-wide), Socket.IO 4.7 + Redis adapter, BullMQ 5, class-validator + zod.
- Data: **PostgreSQL 16 + PostGIS 3.4**, Redis 7.2, Meilisearch 1.10, S3-compatible object storage + CDN.
- Infra: **Terraform 1.9** on AWS (ECS Fargate, RDS, ElastiCache, S3, CloudFront, IAM, Secrets Manager). GitHub Actions + Fastlane. Sentry + Prometheus + Grafana + OpenTelemetry.
- Tests: Jest, Testcontainers, `flutter test` / Patrol, k6.

## Naming and versioning (apply everywhere)

App name `Hasta`; version `1.0.0`; build `1`; API prefix `/v1/`; applicationId/bundleId `app.hasta.mobile`; repo `hasta-app`; ticket prefix `HAS-`; database `hasta`; env prefix `HASTA_`; design system `DS 1.0.0`. The string "Nexus" must not appear anywhere in source, UI copy, store metadata, or logs (CI gate `grep -ri nexus` → 0 matches).

## Identity & access model for v1.0.0 (critical, do not "improve" it)

- **No phone OTP, no SMS provider, no phone-number sign-in.** CI static test asserts no `/auth/otp*` route and no SMS dependency.
- **Sign-in entry point is one-tap Guest only.** The welcome screen has exactly one primary button (`စတင်အသုံးပြုရန်`) plus a Privacy & Terms link. **There is no "Continue with Google" button and no Google/Apple sign-in endpoint in v1.**
- Guest account = device-bound. Client sends the raw device id once over TLS to `/v1/auth/device/register`; the server stores only `device_hash = HMAC-SHA256(HASTA_DEVICE_PEPPER, raw_id)` and never persists the raw id. Sessions: JWT access 15 min + rotating refresh with family reuse detection, stored in Keychain/Keystore.
- **Gmail is connected AFTER login**, from `Settings → Account → Linked accounts → Connect Gmail`, implemented as OAuth **account linking** (`link:start` / `link:complete`), never as authentication. Linking requires `email_verified=true`, rejects an identity already bound to another account (409, no merge), sets `accounts.is_guest=false`, and unlocks Premium purchase + Restore + device-loss recovery.
- Device change = **QR one-time transfer token** (120 s TTL, stored hashed, single use, old-device biometric/passcode confirm, single transaction that moves the binding and revokes old sessions). Reject if the target device has a guest account. If the old device is lost, recovery uses the linked Gmail.
- Premium entitlement binds to `account_id`; store receipts are verified **server-side**; `UNIQUE(store, store_txn_hash)`; refunds via store webhooks revoke; guests cannot purchase.
- Account deletion: T0 soft-delete + session revoke + identity detach + 30-day device cooldown → T0+30 d hard purge; DB backups expire ≤ 35 d. Report evidence lives only in a server-side restricted vault (30 d + 30 d on action, indefinite under legal hold) — **never in user Drive**. User Drive/iCloud backup is client-side encrypted; the key never reaches the server.
- Test-mode convenience: in `dev`/`test`/`beta` builds only, a `Quick test accounts` sheet (long-press logo 3 s) gives one-tap access to 6 seeded accounts and a `Reset data` action. It **must not compile into release/production builds** (CI gate). The Gmail linking flow used from that panel must be the real production code path.

## Non-negotiable architecture rules

1. **Privacy boundary:** social profile and dating profile are separate entities/tables. No social-facing API, notification, badge, deep link, or shared-media surface may reveal dating usage. Push payloads contain no name or photo.
2. **Consent-first messaging:** dating chat can only be written to in state `matched`; enforced server-side in the `dating-core` policy layer.
3. **Single chat engine, multiple domains:** one engine for private/secret/group/channel/saved/dating; dating rules live only in the policy layer via a `canSend(chatId, userId)` hook.
4. **Offline-first:** Drift (SQLite) is the source of truth; repositories read local first, then sync; every mutation writes locally then enqueues into a durable outbox; client-generated UUIDv7 ids + `Idempotency-Key` on all writes; field-level HLC LWW merge for profile/settings/post edits; messages ordered by server `seq`; cursor-based delta sync.
5. **Location privacy:** never return raw coordinates to another client; banded distance strings; store a geohash-snapped point with a consistent 200–500 m random offset.
6. **Safety by default:** 18+ gate derived from `birth_date`; block/report on every profile, photo, and chat surface; AI moderation hooks; critical reports (child safety, violence, extortion) reach a human moderator within 24 h.
7. **Myanmar-first UI:** Noto Sans Myanmar bundled, Zawgyi detect→convert (never bundled), line-height ≥ 1.65×, syllable-aware wrapping, `min-height` only, ellipsis not clip, Myanmar bold ≤ 600, +2 px input padding, Arabic numerals default with a Myanmar-numerals toggle.
8. **Semantic tokens only** from the DS JSON; hard-coded hex is a CI failure; the Dart token file is generated, never hand-edited.
9. Every screen ships ≥ 4 states (loading / empty / error / offline) plus permission-denied where relevant, using the DS state matrix and the exact Myanmar copy provided.

## Quality bar per feature (definition of done)

For each feature deliver all of: backward-compatible migration + rollback · NestJS module with OpenAPI annotations · Flutter `data|domain|presentation` layers reading local-first · `my` + `en` i18n keys (no hard-coded strings) · semantic tokens · unit tests for rules, integration test for the endpoint, E2E for critical flows, each mapped to a test-matrix ID · all UI states · ADR entry for any deviation.

Coverage ≥ 70% on business logic. Zero Critical/Major bugs. CI green including static gates T20, T36, T37, T45.

## Hard prohibitions

- No dependency outside the locked stack without an ADR. No manual DDL — migrations only. No renaming `.env` variables.
- No skipping authorisation checks; deny-by-default; IDOR-safe (no sequential ids in responses).
- No hard-coded secrets/keys/passwords/hex colours. No logging of tokens, emails, message bodies, or raw device ids.
- No new Google/Apple **sign-in** path (linking only). No phone/OTP/SMS anywhere.
- No dating data in social responses. No client-side entitlement decisions.
- No non-idempotent state-changing write endpoint.
- Uniform types globally: `timestamptz` everywhere (UTC), UUIDv7 client ids, `snake_case` enum literals identical in DB/API/Dart.
- No lazy loading in the async ORM — declare eager loading explicitly.
- Tests use an isolated database and a separate Redis DB index; cleanup fixtures ordered by FK-reverse.
- Docker services address each other by service name, never `localhost`.
- Before the first feature, prove the stack with a minimal async end-to-end smoke test.

## Build order

Sprint 0 (repo, CI, Terraform baseline, DS foundations, DB schema v1, i18n scaffolding) → 1 (guest auth, device binding, sessions, cooldown, abuse log, profile basics, settings shell, test-mode panel) → 2 (Gmail linking + recovery, QR transfer, friends) → 3 (posts, feed ranking, reactions, comments) → 4 (groups, pages, notifications, search) → 5 (chat engine 1:1, WS, delivery states, outbox, delta sync, push) → 6 (group/channel/saved, folders, media pipeline) → 7 (dating profile, 18+ gate, swipe, likes, match state machine) → 8 (radar + location privacy, dating chat rules R1–R8, safety, block/report, moderation) → 9 (premium + restore + webhooks, full settings, Drive encrypted backup, purge job, evidence vault) → 10 (hardening, a11y, security testing, store assets, launch checklist).

Do not start dating before the chat engine passes T16/T17. Do not start premium before identity linking passes T38–T44.

## Values that are proposals, not facts

Retention windows (30 d purge / 35 d backups / 30 d evidence), Super Like and Undo caps, opener limit (3), dormant window (7 d), feed and dating score weights, and KPI targets are **proposals pending legal/PO sign-off**. Implement them as remote-config-tunable values with the documented defaults, and flag them in code comments as `[PROPOSAL]`. Never present them as legally validated.

## First response expected from you

1. A short confirmation of the stack, naming, and auth model as above (bullet list, no code yet).
2. The Sprint 0 deliverables: monorepo skeleton matching §17.4 of the PRD, `docker-compose.yml`, baseline Terraform, CI workflow with the static gates, Prisma schema for the identity tables, generated Dart token file from the DS JSON, and i18n scaffolding for `my`/`en`.
3. A list of any ambiguity you found in the PRD, with your proposed resolution — ask before implementing anything ambiguous.

=== PROMPT END ===

---

## 3. Staged follow-up prompts (send one per sprint)

**Sprint 1 — Auth (guest-first):**
> Implement Sprint 1 exactly per PRD §5.2–5.3, §13 (identity tables), §19 (flags + seeded test accounts). Deliver: `POST /v1/auth/device/register`, `POST /v1/auth/guest`, `POST /v1/auth/refresh`, `POST /v1/auth/logout`, `GET /v1/me`; device-hash HMAC with pepper from Secrets Manager; refresh-token rotation with family reuse detection; cooldown check; abuse log (device hash only, no account_id); Flutter welcome screen with a single primary button, guest explainer + risk copy from DS `keyStrings`, long-press quick-test panel behind `HASTA_QUICK_TEST_ACCOUNTS_ENABLED`. Include tests T20, T36, T40, T41, T42 and the offline/disabled states.

**Sprint 2 — Gmail linking + QR transfer:**
> Implement PRD §5.4 and §5.5 end to end: `link:start`/`link:complete` with state+nonce, server-side ID-token verification, `email_verified` requirement, 409 on identity already in use, no account merge; unlink guard; recovery flow for a lost device; QR transfer `start`/`redeem`/`confirm` in one transaction with 120 s hashed single-use token, `FLAG_SECURE`/secure screen, rate limit ≤2/3 min, guest-on-target rejection. Flutter: Settings → Account → Linked accounts sheet with all 5 states, masked email, benefit copy, Change-device QR screen + scanner, Security → active sessions + "sign out from all other devices". Tests T25–T30, T37, T38, T39, T43, T44.

**Sprint 3–6 — Social + chat engine:**
> Implement feed (weighted ranking as a pure injectable function with remote-config weights), reactions, comments (depth 2), groups/pages, notifications with strict social/dating badge separation, Meilisearch, then the chat engine: 6 chat types, `pending→sent→delivered→read`, per-chat `seq` ordering, folders incl. the dating folder, durable outbox, delta sync with cursors, resumable chunked media uploads with WebP thumbnails + BlurHash, push via FCM/APNs with privacy-safe payloads. Tests T15–T18.

**Sprint 7–8 — Dating:**
> Implement dating profile with the 18+ hard gate, selfie verification states, pause; candidate pipeline (hard filters → scoring → dedupe/shuffle); swipe/like/pass/super-like with daily quota and undo; transactional mutual-match creation with `UNIQUE(user_a,user_b)` and canonical ordering; `Likes You` / `Matches`; radar with banded distance and 200–500 m obfuscation; dating chat rules R1–R8 enforced server-side (opener limit, icebreaker, media blur + NSFW thresholds 0.5/0.8, no forward/export, read receipts default off, unmatch with 30-day evidence retention, 7-day dormant → read-only + reopen); safety banner triggered by money/link/personal-data patterns; block/report everywhere with moderation queue priority and 24 h SLA for critical. Tests T1–T14, T19.

**Sprint 9 — Premium, backup, purge, evidence:**
> Implement entitlements bound to `account_id`, server-side receipt verification (App Store Server API / Google Play Developer API), `appAccountToken`/`obfuscatedAccountId` attribution, `UNIQUE(store, store_txn_hash)`, restore flow (online only) with the visible iOS Restore button, renewal/cancel/refund webhooks, guest purchase block with the Connect-Gmail prompt; client-side-encrypted Drive/CloudKit backup with the key in Keychain/Keystore; deletion purge pipeline T0 → T0+30 d with backup expiry ≤ 35 d; restricted evidence vault with KMS keys, role-gated access, access log, retention job and legal hold. Tests T21–T24, T31–T35.

**Sprint 10 — Hardening & launch:**
> Perf budget verification on a 2–3 GB RAM Android device (cold start ≤ 2.5 s, feed ≥ 55 fps, APK < 45 MB), accessibility pass (targets, 200% text scaling, screen-reader labels, reduced motion, contrast), k6 load test to 10 000 concurrent users (feed p95 ≤ 300 ms, delivery ≤ 500 ms), SAST/DAST/dependency/secret scans, pen-test remediation, store submission assets (privacy policy URL, ToS, data-safety form, nutrition labels, 18+ rating, account-deletion path, location purpose strings), monitoring/alerting/backup/DR runbooks, and the launch checklist from PRD §21.

---

## 4. What changed from the source documents (audit trail)

| Change | Reason |
| --- | --- |
| Product renamed Nexus → **Hasta**; version fixed at **1.0.0 / build 1**; ticket prefix `NEX-` → `HAS-`; ids `app.hasta.mobile` | User instruction |
| Google/Gmail **sign-in removed** from v1; welcome screen = one-tap guest only | User instruction: no direct Gmail login; easy test-mode entry |
| Gmail becomes **post-login account linking** + recovery + premium eligibility | User instruction: log in first, then connect Gmail and test the connection |
| Test-mode quick-access panel + 6 seeded accounts specified, release-build exclusion enforced by CI | User instruction: easy account entry in test conditions |
| Phone OTP removed from Must-have (Build Guide) | Conflict with Identity Guide v1.3 — v1.3 wins |
| Two different sprint maps merged into one 11-sprint plan; OTP sprint replaced by guest + Gmail-link | Conflict between Build Guide and Identity/Dating guides |
| SMS budget line voided | No SMS provider in v1 |
| Apple identity linking kept in schema but UI-flagged off for v1.1 | Keeps recovery model symmetric without expanding v1 scope |
| Retention/limits/weights explicitly marked `[PROPOSAL]` and made remote-config tunable | Source docs themselves flagged these as needing legal/PO sign-off |
| All UI copy, tokens, and the state matrix converted into machine-readable JSON | An AI coding agent needs deterministic values, not prose |
