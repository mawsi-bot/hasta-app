# HASTA v1.0.0 — ALL-IN-ONE SPEC BUNDLE (single-file handoff)
> Paste or attach THIS one file to an AI coding agent. Sections are concatenated in reading order.


---

<!-- ===== BEGIN Hasta_v1_Index.md ===== -->

# Hasta v1.0.0 — Project Specification Package (Index)

Package prepared for handoff to **Perplexity AI Agent** so it can build a production-grade, production-ready app (full-function UI/UX + backend + frontend). Source: 9 uploaded files = 5 unique Myanmar-language design documents (4 were duplicates). All content has been de-duplicated, conflict-resolved, renamed, and restructured into normative engineering specifications.

## Files

| # | File | Purpose | Use it for |
| --- | --- | --- | --- |
| 1 | `Hasta_v1_Agent_Handoff_Prompt.md` | The paste-ready agent prompt + per-sprint follow-up prompts + change audit trail | **Send this first** |
| 2 | `Hasta_v1_Master_PRD.md` | Normative spec: 21 sections — scope, principles, architecture, stack, identity/auth, navigation, feed, chat engine, dating, settings, offline-first, state matrix, DDL, design system, security, 45-test matrix, sprint plan, deployment, test-mode config, open decisions, execution rules | Attach as the single source of truth |
| 3 | `Hasta_v1_API_Contract.md` | REST + WebSocket contract: conventions, error envelope, every endpoint with request/response JSON, sync protocol, Socket.IO event table, push payload rules | Attach with the PRD |
| 4 | `Hasta_v1_Design_Tokens.json` | Machine-readable design system: raw + semantic colour tokens (light/dark/AMOLED), contrast rules, Myanmar typography rules, spacing, layout, shape, elevation, motion, haptics, iconography, media specs, performance budget, navigation, 64 components, state matrix, Myanmar copy/glossary, handoff checklist, QA gates | Point the agent at this file; Dart tokens are generated from it |

## What was decided for you (key changes)

1. **Name:** Nexus → **Hasta** everywhere (code, ids `app.hasta.mobile`, tickets `HAS-`, DB `hasta`, env `HASTA_*`). CI gate fails the build if "Nexus" appears anywhere.
2. **Version:** fixed at **1.0.0 / build 1** across app, API (`/v1`), design system (DS 1.0.0) and spec (SPEC 1.0.0).
3. **Login = one-tap guest only.** No Gmail button on the welcome screen, and no Google/Apple *sign-in* endpoint exists in v1 (CI-enforced). Phone OTP/SMS was already removed by Identity Guide v1.3, so the conflicting "Phone OTP login (Must-have)" line in the Build Guide was voided.
4. **Gmail is connected after login** via `Settings → Account → Linked accounts → Connect Gmail`, implemented as OAuth **account linking** (not authentication). Linking unlocks Premium purchase, Restore Purchases, and device-loss recovery. A 7-step Gmail connectivity test procedure is specified (PRD §19).
5. **Test-mode easy access** is fully specified: 6 seeded accounts, long-press-logo panel, `dev/test/beta` only, compiled out of release builds (test T36). The panel's Gmail flow uses the real production code path, so linking is genuinely tested.
6. **Two conflicting sprint plans merged** into one 11-sprint / ~21-week plan with exit criteria per sprint.
7. Retention windows, limits (opener 3, dormant 7 d, Super Like/Undo caps), score weights and KPI targets are marked `[PROPOSAL]`, made remote-config tunable, and listed as open decisions requiring legal/PO sign-off — never presented as validated facts.

## Suggested handoff sequence

1. Open Perplexity AI Agent → paste the prompt block from `Hasta_v1_Agent_Handoff_Prompt.md`.
2. Attach `Hasta_v1_Master_PRD.md`, `Hasta_v1_API_Contract.md`, `Hasta_v1_Design_Tokens.json`.
3. Ask for Sprint 0 (repo skeleton, CI with static gates, Terraform baseline, Prisma identity schema, generated Dart tokens, i18n scaffolding).
4. Then send the sprint prompts in §3 of the handoff file, one at a time, and require the mapped test IDs (T1–T45) to pass before moving on.
5. Before any store submission, close the open decisions in PRD §20 (legal review of retention windows is the blocking item).


<!-- ===== END Hasta_v1_Index.md ===== -->


---

<!-- ===== BEGIN Hasta_v1_Agent_Handoff_Prompt.md ===== -->

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


<!-- ===== END Hasta_v1_Agent_Handoff_Prompt.md ===== -->


---

<!-- ===== BEGIN Hasta_v1_Master_PRD.md ===== -->

# Hasta — Master Product & Engineering Specification

**Product name:** Hasta (renamed from "Nexus" — see §0.2 Rename Map)
**Version:** 1.0.0 (build 1) — single authoritative version for all docs, code, store listings
**Document status:** FINAL — Ready for AI-agent execution (Perplexity AI Agent / coding agent)
**Audience:** Product Owner, UI/UX Designer, Frontend (Flutter), Backend (NestJS), QA, DevOps, Legal reviewer
**Source documents consolidated (5 unique):**
1. `Hasta Dating Combined App — Revised Preparing Guide` (architecture + dating + settings)
2. `Hasta Abuse Logging & Offline-First Design` (device-hash abuse logging, offline-first)
3. `Hasta Identity System Design & System Guide v1.3` (premium/restore, QR transfer, purge, evidence vault, cooldown, tests 21–35)
4. `Hasta Application Build Guide v1.0` (planning, design, tech stack, dev, testing, deployment, maintenance)
5. `UI/UX Design System (DS) v1.0` (tokens, 64 components, 68 screens, states, a11y, perf budget, Myanmar microcopy)

> Everything below is normative. Where source documents conflicted, the resolution is stated inline as **[CONFLICT-RESOLVED]**. Where a value is a proposal rather than a verified fact, it is marked **[PROPOSAL]** and listed again in §20 Open Decisions.

---

## 0. Document Control

### 0.1 Version rule

| Item | Value |
| --- | --- |
| App display name | `Hasta` |
| Semantic version | `1.0.0` |
| Build number | `1` |
| API version prefix | `/v1/` |
| Android `applicationId` | `app.hasta.mobile` |
| iOS bundle id | `app.hasta.mobile` |
| Repo name | `hasta-app` (monorepo) |
| Ticket prefix | `HAS-` (replaces `NEX-`) |
| DB schema/migration prefix | `hasta_` (no table prefix required; DB name `hasta`) |
| Env var prefix | `HASTA_` |
| Design System version | `DS 1.0.0` |
| Spec version | `SPEC 1.0.0` |

Version bumping: `MAJOR.MINOR.PATCH`. Design-token breaking change = DS MAJOR. API breaking change = new `/v2/` prefix, never in-place mutation of `/v1/`.

### 0.2 Rename map (apply mechanically everywhere, including strings, comments, CI, Terraform, store listings)

| Old | New |
| --- | --- |
| Nexus | Hasta |
| nexus | hasta |
| NEXUS_ | HASTA_ |
| NEX- (ticket) | HAS- |
| com.nexus.* / app.nexus.* | app.hasta.* |
| `Nexus Design System` | `Hasta Design System (DS 1.0.0)` |
| DB `nexus` | DB `hasta` |
| Push sender name "Nexus" | "Hasta" |

The word "Nexus" must not appear in the delivered codebase, UI copy, store metadata, or logs. CI gate: `grep -ri "nexus" --exclude-dir=.git` must return 0 matches (excluding this spec's rename table).

### 0.3 Non-goals for v1.0.0 (explicitly out of scope)

Marketplace, live streaming, in-app payment wallet, ML feed ranking model (weighted score only), CRDT collaborative editing, ScyllaDB migration, cross-platform premium portability, voice-message auto-transcript (Myanmar STT), phone/OTP + SMS provider (removed — see §5.1).

---

## 1. Product Definition

### 1.1 Vision

Hasta is a single app in which a person manages all of their relationships safely: social feed, messaging, and dating — with dating kept behind an explicit privacy boundary so that social contacts cannot detect dating usage.

### 1.2 Market

Myanmar-first (primary), UI languages `my` (default) and `en`. Design must be Myanmar-script-first, not a translation of English UI. Network reality (crowd-sourced measurement, speedof.me, as cited in source doc — treat as planning estimate, not SLA): median download ≈ 7.4 Mbps, upload ≈ 5.2 Mbps, latency ≈ 116 ms, rank 107/119. Consequences: offline-first is mandatory, delta sync is mandatory, WebSocket reconnect strategy is mandatory, media must be thumbnailed and resumable.

### 1.3 Personas (3 minimum, feature decisions must be checked against them)

| Persona | Profile | Primary jobs-to-be-done |
| --- | --- | --- |
| `မိုး` — student, 20 | Low/mid-range Android 2–3 GB RAM, mobile data, frequent power cuts | Chat with friends, groups, save data, work offline |
| `ကိုအောင်` — office worker, 29 | Mid-range Android, Wi-Fi at office, wants privacy | Feed + private chat + dating without colleagues knowing |
| `မသန်းနု` — page owner, 34 | Runs a community page/group | Post, moderate, manage members, grow audience |

### 1.4 Scope (MoSCoW) — **[CONFLICT-RESOLVED]**

Source docs conflicted: Build Guide listed "Phone OTP login" as Must-have, while Identity Guide v1.2/v1.3 removed Phone/OTP entirely. **Resolution: Identity Guide v1.3 wins.** There is no phone OTP, no SMS provider, and no phone-number-based sign-in in v1.

**Must have (v1.0.0):**
- One-tap guest account creation (device-bound) — the default and only entry-point sign-in in v1 (§5)
- Post-login identity linking: Connect Gmail (Google OAuth account link, NOT sign-in) (§5.4)
- QR device-to-device identity transfer (§5.5)
- Social profile + privacy settings (11 settings sections)
- Friend system, Feed (post, reaction, comment), Groups, Pages
- Chat engine: 1:1, group, channel, Saved Messages, secret chat, dating chat; folders; delivery states; multi-device sync; push
- Dating module: dating profile (18+ gate), card stack swipe, Super Like, match, Likes You, Matches, radar/nearby with location privacy, dating chat policy rules, unmatch/block/report
- Safety: block, report, AI moderation hooks, moderation queue, evidence vault
- Offline-first: local DB as source of truth, durable outbox, delta sync, 4-state connectivity UX
- Premium entitlement bound to account with server-verified store receipt + restore (§5.6)
- Account deletion purge pipeline + user-Drive encrypted backup (§5.7)

**Should have (v1.0.x):** search (Meilisearch), media sharing at scale, story ring/viewer, chat archive behaviours, compact density mode.
**Could have (v1.1+):** voice/video call (WebRTC + coturn), channels at scale, premium tiers expansion.
**Won't have (v1):** §0.3.

### 1.5 Release plan

`1.0.0` = all Must-have, soft-launch in one city/region, evaluate at ~1,000 users. `1.1.0` = Should-have. `2.0.0` = Could-have + Marketplace investigation.

### 1.6 KPIs

| Group | Metrics | Target |
| --- | --- | --- |
| Acquisition | install, guest→linked-account conversion, CAC | linked ≥ 35% of active guests by D30 **[PROPOSAL]** |
| Engagement | DAU/MAU, avg session, posts & messages sent, retention D1/D7/D30 | D1 ≥ 35%, D7 ≥ 20%, D30 ≥ 10% **[PROPOSAL]** |
| Dating | profile completion rate, swipe→match, match→first-message, report rate | first-message ≥ 45%; report ≤ 1% of matched chats **[PROPOSAL]** |
| Quality | crash-free sessions, ANR rate, API error rate, p95 latency | crash-free ≥ 99.5%, API error ≤ 1%, feed p95 ≤ 300 ms |

Analytics event naming: `object_action` (e.g. `dating_match_created`, `chat_message_sent`, `auth_guest_created`, `identity_gmail_linked`). Collect only after privacy consent.

---

## 2. Design Principles (binding review checklist)

**Architecture principles (A1–A4)**
- **A1 Privacy boundary.** Social profile and dating profile are separate entities in separate tables. A social friend must not be able to infer dating usage from any API response, notification, badge, deep link, or shared-media surface.
- **A2 Consent-first messaging.** In dating, no message can be sent before `matched`. Enforced server-side in the policy layer, not in the client.
- **A3 Single codebase, multiple domains.** One chat engine reused by social private/group/channel/saved and dating chat. Dating-specific rules live only in the dating policy layer. Changing a dating rule must never require editing the chat engine.
- **A4 Safety by default.** 18+ gate, report/block, and location obfuscation are defaults on every relevant feature, not opt-ins.

**UX principles (P1–P7, from DS v1.0)**

| # | Principle | Practical meaning | Violation example |
| --- | --- | --- | --- |
| P1 | Myanmar script first | line-height ≥ 1.65×, syllable-aware wrapping, Zawgyi detect→convert | Myanmar text clipped by English line-height |
| P2 | Fewer words, more affordance | icon + gesture first, label ≤ 4 words | text-heavy tooltip |
| P3 | Make privacy visible | dating entry only inside Profile, lock icon, audience shown next to the action | audience hidden in settings |
| P4 | Undo/confirm destructive actions | confirm sheet for delete/unmatch/block | one-tap unmatch |
| P5 | Complete without internet | offline banner + cached content + waiting states as first-class UI | infinite spinner |
| P6 | Save data | autoplay off, thumbnail first, "watch HD" on tap | feed video autoplay |
| P7 | Smoothness over beauty | limit blur/parallax/shadow, motion ≤ 320 ms | full-screen gradient animation |

---

## 3. System Architecture

### 3.1 Layers

```
┌───────────────────────────────────────────────────────────────┐
│ CLIENT  Flutter (Android + iOS, single codebase)              │
│  presentation (features/*/presentation)                       │
│  domain     (features/*/domain)                               │
│  data       (features/*/data) → Repository → Drift (SQLite)   │
│  Outbox worker · Sync engine · Socket client · Secure storage │
└───────────────┬───────────────────────────┬───────────────────┘
                │ HTTPS REST /v1            │ WSS (Socket.IO)
┌───────────────▼───────────────────────────▼───────────────────┐
│ EDGE  API Gateway / ALB                                        │
│  JWT verification · rate limiting · request id · routing       │
└───────────────┬────────────────────────────────────────────────┘
┌───────────────▼────────────────────────────────────────────────┐
│ SERVICE  NestJS modular monolith (domains, not microservices)  │
│  auth/identity · user · social(friend/feed/post/group/page)    │
│  chat-engine · dating-core(policy) · media · notification      │
│  moderation · billing(entitlements) · sync · admin             │
│  BullMQ workers: transcode · NSFW scan · push fan-out · purge  │
│  · evidence retention · match-decay · dormant-chat             │
└───────────────┬────────────────────────────────────────────────┘
┌───────────────▼────────────────────────────────────────────────┐
│ DATA  PostgreSQL 16 + PostGIS · Redis 7 (cache/session/GEO/     │
│  rate-limit/queue/pub-sub adapter) · S3-compatible object store │
│  + CDN · Meilisearch · Evidence vault (KMS-encrypted, isolated) │
└────────────────────────────────────────────────────────────────┘
```

**Rule:** dating permission decisions are made **only** in `dating-core` policy service. `chat-engine` exposes a generic `canSend(chatId, userId)` hook that delegates to the policy layer per chat type.

### 3.2 Module boundaries & ownership of rules

| Module | Owns | Must not know |
| --- | --- | --- |
| `chat-engine` | message send/store/sync/delivery states/edit/delete/folders/receipts/media attachments | why a dating chat is blocked; opener counters |
| `dating-core` | dating profile, swipe, likes, match state machine, opener limit, dormant, unmatch semantics, radar selection, 18+ gate | message transport internals |
| `auth-identity` | guest creation, device hash/binding, Gmail link, QR transfer, sessions, JWT, cooldown, abuse log | dating rules |
| `billing` | entitlements, store receipt verification, restore, refund/renewal webhooks | client-side trust of receipts |
| `moderation` | report intake, queue priority, evidence snapshot, vault retention, legal hold | user Drive backups |
| `sync` | cursor-based delta endpoints, idempotency registry, conflict metadata (HLC) | business rules |

### 3.3 Cross-cutting

- **Idempotency:** every write endpoint accepts `Idempotency-Key` (client-generated UUIDv7). Server stores `(account_id, idempotency_key) → response_hash` for 7 days; replays return the stored response with header `Idempotent-Replayed: true`.
- **Correlation:** `X-Request-Id` propagated gateway → service → worker → logs.
- **Time:** all timestamps UTC `timestamptz`; client displays in device tz. No naive datetimes anywhere.
- **IDs:** UUIDv7 for all client-created entities; server-side bigserial allowed for internal ordering keys (`messages.seq`).
- **Enums:** `snake_case` string enums, identical literal casing in DB, API, and Dart. One shared `enums.md` contract; mismatch is a CI failure.

---

## 4. Technology Stack (locked)

| Layer | Choice | Locked version (min) | Rationale |
| --- | --- | --- | --- |
| Mobile | Flutter + Dart | Flutter 3.24 / Dart 3.5 | single codebase, custom swipe animation |
| State | Riverpod | 2.5 | testable, no BuildContext coupling |
| Local DB | Drift (SQLite) | 2.20 | offline-first source of truth, type-safe |
| Network | Dio | 5.6 | interceptors, retry, cancel |
| WS client | socket_io_client | 2.0 | matches server Socket.IO |
| Secure storage | flutter_secure_storage | 9.2 | Keychain / Keystore |
| Background | workmanager (Android) / BGTaskScheduler via native (iOS) | 0.5 | battery-aware sync |
| Connectivity | connectivity_plus | 6.0 | network-type gating |
| Backend | NestJS on Node.js | NestJS 10 / Node 20 LTS | modular monolith, TS types, WS gateway |
| ORM | Prisma **or** TypeORM (pick one, repo-wide; Prisma recommended) | Prisma 5 | migrations, type safety |
| Realtime | Socket.IO + `@socket.io/redis-adapter` | 4.7 | horizontal scale |
| Queue | BullMQ | 5 | Redis-backed, retries, cron |
| Validation | class-validator + zod (DTO + boundary) | 0.14 / 3.23 | strict input validation |
| DB | PostgreSQL + PostGIS | 16 / 3.4 | relational + `ST_DWithin` radius |
| Cache | Redis | 7.2 | feed cache, sessions, presence, rate limit, GEO |
| Search | Meilisearch | 1.10 | lightweight, typo-tolerant |
| Object storage | S3-compatible (AWS S3 or Cloudflare R2) | — | media at scale; R2 for egress cost |
| CDN | CloudFront / Cloudflare | — | WebP/AVIF delivery |
| Push | FCM + APNs | — | required |
| Infra | Terraform on AWS (ECS Fargate, RDS, ElastiCache) | Terraform 1.9 | IaC, no manual prod change |
| CI/CD | GitHub Actions + Fastlane | — | automated build/release |
| Observability | Sentry + Prometheus + Grafana + OpenTelemetry | — | errors, metrics, traces |
| Tests | Jest (backend), `flutter test`/Patrol (mobile), Testcontainers, k6 | — | §16 |

**Dependency rule:** no third-party dependency outside this table may be added without a PR-level ADR entry. All versions pinned in `pubspec.yaml` / `package.json` (no `^` on runtime-critical libs).

---

## 5. Identity, Accounts & Access (v1.0.0 — MOST CHANGED AREA)

### 5.1 Decision summary

| # | Decision | Value |
| --- | --- | --- |
| D1 | Phone OTP / SMS | **Removed.** No SMS provider, no OTP endpoint, no phone-number sign-in. CI static test T20 asserts no `/auth/otp*` route exists. |
| D2 | Entry-point sign-in in v1 | **Guest one-tap only.** No "Continue with Google" button on the welcome/login screen. Google/Apple *sign-in* endpoints are **not implemented** in v1. |
| D3 | Gmail role | **Recovery + Premium eligibility**, connected *after* login from Settings. Implemented as account *linking*, not authentication. |
| D4 | Apple | Same treatment as Gmail in the data model (`provider=apple`) but **UI deferred** to v1.1 (flag `AUTH_APPLE_LINK_ENABLED=false`). |
| D5 | Device change | QR identity transfer (§5.5). Gmail link is the fallback when the old device is lost. |
| D6 | Premium | Bound to `account_id`; store receipt verified server-side; guests cannot purchase (§5.6). |
| D7 | Cooldown | Device-hash based only, 30 days after account deletion; alternatives deferred (§5.9). |
| D8 | Abuse logging | Device hash only, no raw device id, no `account_id`; 90-day retention then aggregated counts (§5.10). |
| D9 | Data purge | T0 soft-delete → T0+30d hard purge; DB backups rotate out within 35 days **[PROPOSAL, needs legal + store policy confirmation]** (§5.7). |
| D10 | Evidence | Server-side restricted vault, never user Drive; 30-day retention after report closure, +30 days if action taken, indefinite under legal hold (§5.8). |

### 5.2 Account & identity model

```
accounts        1 ── n  identities        (provider: guest | google | apple)
accounts        1 ── n  device_bindings   (device_hash, role: primary|secondary)
accounts        1 ── n  sessions          (refresh token family)
device_bindings 1 ── n  transfer_tokens   (one-time, 120 s TTL)
```

- `accounts.status`: `active | paused | deleted | banned`
- `accounts.is_guest`: `true` until at least one verified external identity is linked.
- An account may hold **at most one** identity per provider. A given external identity (`provider, provider_sub`) maps to **at most one** account (unique constraint).
- Guest accounts are full-featured except: purchase/restore blocked, Gmail-link prompt shown, and no recovery path if the device is lost.

### 5.3 Sign-in flow (v1.0.0 — as required)

**Welcome screen shows exactly two controls:**
1. `Continue` (primary button) → creates or resumes a **guest account** bound to this device. No email, no phone, no password, no OTP.
2. `Privacy & Terms` link.

There is **no** Google/Gmail button on this screen. Design must not add one; code review rejects it.

**Guest creation logic (`POST /v1/auth/guest`)**

```
1. client computes raw device id (Android ID / iOS identifierForVendor)
2. client sends raw id ONLY over TLS to /v1/auth/device/register
   → server computes device_hash = HMAC-SHA256(HASTA_DEVICE_PEPPER, raw_id)
   → server NEVER stores raw_id; returns {device_hash, device_token}
3. client calls POST /v1/auth/guest with device_token
4. server:
   a. if active device_binding exists for device_hash → return existing account (resume)
   b. else if device_cooldowns has unexpired row for device_hash
        → 429 {code:"device_cooldown", retry_after_days:N}
   c. else create account (is_guest=true), device_binding(role=primary),
      session + refresh token, write abuse_log event 'guest_created'
5. response: {access_token(15m), refresh_token(rotation), account, is_new:true}
```

**Tokens:** JWT access token 15 min; refresh token rotation with reuse detection (reuse ⇒ revoke whole family, force re-guest). Tokens stored in Keychain/Keystore only, never in SQLite or logs.

**Test-mode easy access (required for QA / beta):** see §19. In `test` and `beta` builds a `Quick test accounts` panel is available on the welcome screen behind a long-press of the logo (3 s), giving one-tap login to 6 pre-seeded accounts (2 dating-verified, 1 page owner, 1 under-18-blocked, 1 premium, 1 fresh guest). This panel **must not exist** in `release`/`production` builds (compile-time flag + CI check T36).

### 5.4 Connect Gmail after login (account linking)

Entry: `Profile → Settings → Account → Linked accounts → Connect Gmail`.

```
1. client requests link intent:  POST /v1/auth/identities/google/link:start
   → server returns {state, nonce, scopes:["openid","email","profile"], auth_url}
2. client opens Google OAuth consent (ASWebAuthenticationSession / Custom Tabs)
3. redirect with {code, state} → POST /v1/auth/identities/google/link:complete
4. server:
   - validates state (single-use, 5 min TTL) and nonce
   - exchanges code with Google, verifies ID token signature/iss/aud/exp/nonce
   - requires email_verified == true, else 422 {code:"google_email_unverified"}
   - if (provider='google', sub) already bound to another account
       → 409 {code:"identity_in_use"}  (no account merge in v1)
   - else insert identities row, set accounts.is_guest=false,
     grant recovery capability, write audit log
5. response: {identity:{provider:"google", email, linked_at}, account}
```

**Effects of linking (must be reflected in UI immediately):**
- Enables `Restore Purchases` and Premium purchase (§5.6).
- Enables recovery on a new device when the old device is unavailable (§5.5 fallback).
- Unlocks "Sign out from all other devices".
- Adds `Settings → Account → Email` display (masked: `h***@gmail.com`, tap to reveal own email).

**Unlink:** allowed only if another recovery method exists; otherwise blocked with copy "Recovery နည်းလမ်း တစ်ခု ရှိမှသာ ဖြုတ်နိုင်သည်". Guest accounts that unlink return to `is_guest=true` and lose premium purchase eligibility (existing paid entitlement remains until expiry — no refund).

**Negative requirements (enforced by tests):**
- No `POST /v1/auth/google/signin`, no `id_token`-only login route, no auto-account-creation from a Google token in v1 (T37).
- Linking never creates a *second* account (T38).
- Access tokens are never accepted from the client as proof of Google identity; server verifies with Google (T39).

### 5.5 Device change — QR identity transfer

| Step | Actor | Behaviour |
| --- | --- | --- |
| 1 | Old device | `Settings → Account → Change phone/device` → `POST /v1/auth/transfer/start` → one-time `transfer_token`, TTL **120 s**, stored **hashed only**, single use |
| 2 | Old device | Renders QR containing `{v:1, token}`. Screen recording disabled; Android `FLAG_SECURE`; iOS secure screen; rate limit ≤ 2 requests / 3 min per account |
| 3 | New device | Scans QR → `POST /v1/auth/transfer/redeem {token, device_token}` |
| 4 | Old device | Receives push/WS `transfer.confirm_required`; user confirms with biometric or device passcode → `POST /v1/auth/transfer/confirm` |
| 5 | Server | Single transaction: mark token `used_at`; delete old `device_binding`; create new binding for new device_hash; revoke **all** sessions of the old device; emit `session.revoked` |

Rules:
- If the new device already has a **guest account**, reject: 409 `{code:"guest_exists_on_target"}` with copy "ဤဖုန်းရှိ guest အကောင့်ကို ဖျက်ပြီးမှ ပြောင်းနိုင်သည်။"
- Cooldown does **not** apply to transfer (transfer ≠ new account).
- Transfer requires online on both devices; offline attempt shows the disabled state per §11.5.
- **Old device unavailable:** user signs in on the new device via the **linked Gmail recovery** path: `POST /v1/auth/recover:start {provider:"google"}` → Google OAuth → server finds account by identity → creates new binding, revokes others, and shows `Settings → Security → Sign out from all other devices`. Old binding may persist; that entry is the user's cleanup path.
- If no identity was ever linked and the old device is lost, the account is **unrecoverable**. The welcome screen and the Gmail link sheet must state this plainly (copy in §14.7).

### 5.6 Premium & store receipt

- Entitlement is bound to `account_id`, never to device hash.
- Guests cannot purchase: `POST /v1/billing/purchase:intent` returns 403 `{code:"identity_required"}` with prompt to Connect Gmail. (Test T21.)
- Client sends store receipt / purchase token; **server** verifies via App Store Server API / Google Play Developer API and only then writes `entitlements`. Client-set entitlements are a security bug.
- Purchase attribution: Apple `appAccountToken` = account UUID; Google `obfuscatedAccountId` = account UUID.
- `UNIQUE (store, store_txn_hash)` prevents one transaction being restored onto two accounts; second attempt → 409 with copy "ဤ subscription သည် အကောင့်တစ်ခုနှင့် ခိတ်ပြီးသား ဖြစ်သည်။" **No account merge in v1.**
- Restore: `POST /v1/billing/restore` (online only). iOS must show a visible "Restore Purchases" button.
- Renewal/cancel/refund via App Store Server Notifications & Google RTDN → webhook handlers update `entitlements.status` and `last_verified_at`; refunds revoke immediately (T24).
- Cross-platform portability (buy Android, use iOS) **not supported**; state it on the Premium page.

### 5.7 Account deletion & purge

| Stage | When | Actions |
| --- | --- | --- |
| T0 | immediate | `accounts.status='deleted'`; revoke all sessions; detach identities & bindings; set device cooldown (§5.9); write abuse_log `account_deleted` |
| T0 | immediate | Warn: Hasta cannot cancel store subscriptions; deep-link user to the store to cancel |
| T0 + Drive | immediate, if permitted | Client deletes its Drive/iCloud backup; if not permitted, show "Drive ထဲ backup ကို ကိုယ်တိုင်ဖျက်ပါ" |
| T0 + 30 d **[PROPOSAL]** | hard purge | Delete profile, posts, messages, media, dating data; delete non-legal-hold evidence |
| after purge | backups | RDS snapshots expire ≤ 35 days **[PROPOSAL]**; no restore into that window |

Undo during grace period: **open decision** (§20.1). If implemented, revisit cooldown interaction.

### 5.8 Report evidence vault

- Isolated restricted storage; access only for `moderator` and `legal` roles; every read writes an access log (who, when, what).
- Contents: report context, message snapshot, profile snapshot, media, metadata, `content_hash` for integrity; encryption keys in KMS.
- Retention: 30 days from report closure; +30 days if an action was taken (appeal window); `legal_hold=true` suspends deletion until legal clears it (T33).
- Evidence is **never** written to user Drive, and **never** deleted by user-side purge except at hard purge when no legal hold exists.
- Non-moderator access attempt → 403 and **no** access-log entry leakage (T34).

### 5.9 Cooldown

- After deletion: `device_cooldowns(device_hash, until = now()+30d)`; new guest creation blocked during cooldown.
- Transfer is exempt.
- Alternatives (device + Google/Apple sub; device + IP/Play Integrity) are **deferred** until 1 month of abuse data exists. Current choice = device-only (simple, bypassable by factory reset — accepted for v1).

### 5.10 Abuse logging

- Log guest creation and account deletion keyed by **device hash only**; never raw device id; never `account_id` in this log.
- Purpose: count "guest created / deleted per device per 30 days" to inform a future cooldown threshold.
- Device hash is pseudonymous personal data → must appear in the privacy policy; retention **90 days**, then roll up to aggregated counts.
- Review 1 month of logs before setting any threshold. No automatic blocking in v1 (log + observe).

---

## 6. Navigation & Module Map

**Bottom navigation — exactly 5 items (never 6):**

| # | Label (my) | Icon | Badge |
| --- | --- | --- | --- |
| 1 | ပင်မ (Home) | home | — |
| 2 | ရှာဖွေ (Discover) | compass | — |
| 3 | ချတ် (Chat) | chat | unread count (social + dating combined total, but see rule) |
| 4 | အသိပေး (Notifications) | bell | count — **social actions only** |
| 5 | ပရိုဖိုင် (Profile) | user | friend-request dot |

Rules:
- **Dating is not a tab.** Entry only via `Profile → ❤ Dating`. When dating mode is off, the row shows a lock + "ဖွင့်ရန်" and no one else can see it.
- Chat tab has folder tabs: `အားလုံး | ကိုယ်ရေး | အုပ်စု | ချန်နယ် | Dating | မဖတ်ရသေး`. The Dating folder exists only if dating mode is on; it carries its **own** unread badge that must never be merged into social badges in any list, notification, or lock-screen preview.
- Dating chat notifications have an independent settings channel.
- Re-tap active tab → scroll to top. Tab scroll positions preserved.
- At text scale > 1.3× hide bottom-nav labels, keep 28 px icons.

---

## 7. Social Feed (Home)

- Feed aggregates posts from Friends, Groups, Pages.
- Ranking v1 = deterministic weighted score (no ML):

```
score = w_affinity * affinity(viewer, author)
      + w_engagement * normalized(likes + 2*comments + 3*shares)
      + w_interest   * topic_match(viewer, post)
      + w_recency    * exp(-age_hours / 24)
defaults: w_affinity 0.35, w_engagement 0.30, w_interest 0.15, w_recency 0.20  [PROPOSAL, A/B tunable via remote config]
```

- Ranking function must be a pure, unit-tested function with injectable weights (remote-config driven) so an ML model can replace it later without API change.
- Media layout: 1 image = full-width card; ≥2 images = swipe carousel with dot indicator up to 10, counter beyond 10. Peek layout only in composer/preview, never in feed.
- Interactions: reaction (6 emoji, long-press 220 ms), comment (depth 2), share (social only — **not** from dating chat), friend request, group/page context header.
- Pagination: cursor-based, page size 20, pull-to-refresh, infinite-scroll footer with `loading | end ("ပြီးဆုံး") | retry`.
- Video: thumbnail + play button, autoplay off (P6), HLS, ≤ 8 s muted preview only if the user enabled it.
- Suggestion cards are dismissible; dismissed cards do not return for 7 days.
- Feed must render cached content offline with the top offline banner (§11.5, §12 state matrix).

---

## 8. Chat Engine

### 8.1 Chat types (6)

`private` · `secret` · `group` · `channel` · `saved` · `dating`

| Type | Server-stored | Multi-device | Encryption | Policy layer |
| --- | --- | --- | --- | --- |
| private | yes | yes | TLS + at-rest | social rules |
| secret | no (device only) | no | Signal Protocol E2EE, self-destruct timer | social rules |
| group | yes | yes | TLS + at-rest | membership/role rules |
| channel | yes | yes | TLS + at-rest | subscriber rules |
| saved | yes | yes | TLS + at-rest | self only |
| dating | yes (see retention) | yes | TLS + at-rest | **dating-core policy (§9.4)** |

### 8.2 Message lifecycle

`pending → sent → delivered → read`

- Client writes to Drift immediately (`pending`, clock icon), enqueues to outbox, sends when online.
- Server ack → `sent` (✓). Recipient device receives → `delivered` (✓✓ grey). Read receipt → `read` (✓✓ blue) **only if the recipient has read receipts enabled** (dating default off, §9.4 R5).
- Failed send → per-bubble "ပြန်ပို့ရန်" action; unsent messages can be edited or deleted without the user thinking they were delivered.
- Ordering: server-assigned monotonically increasing `seq` per chat; clients sort by `seq`, never by device clock.

### 8.3 Sync

- `GET /v1/sync/changes?cursor=<opaque>&since_seq=...` returns per-entity field-level patches plus a new cursor.
- Client stores `last_sync_cursor` per entity class: `messages`, `chats`, `profiles`, `posts`, `notifications`, `dating`.
- Reconnect strategy for ~116 ms latency links: exponential backoff with jitter (1 s → 2 s → 4 s → … cap 60 s), plus immediate retry on connectivity-change event; on reconnect, always run a delta sync before trusting local state.

### 8.4 Edit / delete

- Edit: allowed within 15 min, marks `edited_at`, shows "ပြင်ပြီး".
- Delete: `for_me` (local tombstone) vs `for_everyone` (server tombstone + WS `message.deleted` to all members). Dating chat: `for_everyone` is the only mode (no local-only delete of evidence-relevant content); forward and export are disabled (§9.4 R4).

### 8.5 Calls (v1.1, Could-have)

WebRTC with self-hosted coturn (TURN/STUN). Out of scope for 1.0.0 build order but the schema and permission copy exist.

---

## 9. Dating Module

### 9.1 Dating profile (separate entity from social profile)

Fields: `display_name` (may differ from social name), 2–6 photos, `birth_date` → derived age (**18+ hard gate**, never stored as free text age), `gender`, `seeking_gender`, `bio` (≤ 300 chars, counter), `interests[]` tags, `looking_for` (`long_term | friends | chat`), optional `height_cm`, optional `occupation`, optional `prompt_qa` (icebreaker source), `verification_status`, `paused`, `radar_visible`, `show_distance`.

- Selfie verification → `verified` badge; may gate perks (e.g. +1 Super Like/day). Verification photos go to the restricted vault path, not the public media bucket.
- `paused=true` removes the profile from card stacks and radar instantly (≤ 60 s propagation).
- Dating profile is **not** exposed by any social API. Any endpoint that could leak dating existence to a social contact is a P0 security bug.

### 9.2 Card stack & swipe

- Right = Like, Left = Pass, Up = Super Like (daily cap: 1 for unverified, 2 for verified **[PROPOSAL]**).
- Candidate pipeline (server-side, in this order):
  1. hard filters: 18+, gender/seeking match, distance ≤ user filter, not paused, not blocked, not already liked/passed
  2. scoring: `Score = w1*Interest + w2*Completeness + w3*Activity + w4*Proximity` (defaults 0.35/0.20/0.25/0.20 **[PROPOSAL]**, A/B via remote config)
  3. dedupe + shuffle within score bands to avoid deterministic ordering
- Card stack depth 3 (scale .94/.88, y+8/+16). Action bar in thumb zone: Pass 60 · Undo 44 · Super 48 · Like 60.
- Undo: last action only, max 5/day **[PROPOSAL]**.

### 9.3 Match logic & state machine

- Mutual condition: A likes B **and** B likes A. The second like is evaluated inside a DB transaction; `UNIQUE (from_user, to_user)` on `likes` prevents duplicate/race writes; `matches` stores canonical order `user_a < user_b` with `UNIQUE (user_a, user_b)`.
- States: `none → liked_outgoing | liked_incoming → matched → (chatting) → dormant → unmatched | blocked`.
- **No message can be sent in any state other than `matched`** (server-enforced; T12).
- On match: create `matches` row → create `dating` chat → emit WS `match.created` to both → if offline, push "It's a Match!" with **no** name/photo in the payload (lock-screen privacy).
- `Likes You` tab shows incoming likes/super likes before the user decides; revealing identity of a super-liker is allowed only in that tab.

### 9.4 Dating chat policy rules (R1–R8, all server-enforced)

| # | Rule | Spec |
| --- | --- | --- |
| R1 | **Opener limit** | After match, the first sender may send at most **3** messages until the other party replies. On reply, the limit lifts permanently for that chat. Counter stored server-side; client shows "ကျန် ၁ ခု" style hint. HTTP 429 `{code:"opener_limit"}` when exceeded. |
| R2 | **Icebreaker prompt** | On match, show one prompt from the counterpart's profile (e.g. "အကြိုက်ဆုံး ခရီးစဉ်") with a tap-to-reply chip that prefills the composer. Skippable. |
| R3 | **Media blur** | Photos/videos render blurred until the recipient taps to reveal (explicit consent per item). NSFW AI scan runs at upload; `nsfw_score ≥ 0.8` → block upload, `0.5–0.8` → blur + report shortcut. |
| R4 | **No forward, no export** | Forwarding out of a dating chat and exporting dating chats are disabled server-side and hidden in UI. |
| R5 | **Read receipts default off** | User can enable in Settings → Dating. When off, sender never receives `read`. |
| R6 | **Unmatch semantics** | Unmatch closes the chat immediately for both parties (WS `chat.closed` + local cache wipe signal). Evidence retained **30 days** for report handling, then deleted. Stated in the privacy policy. |
| R7 | **Dormant chat** | If nobody replies within **7 days** of the last message, chat becomes read-only; either party can reopen (single tap, restores write access). |
| R8 | **Dating folder** | Matched chats appear in the Chat tab's Dating folder with an unread badge that is never merged into the social badge. |

Chat screen anatomy: header (photo, name, verified badge, safety menu) · safety banner (auto-triggered on money requests, external links, personal-data requests) · message list (text, blurred photo, voice note, icebreaker reply chip) · input bar.

### 9.5 Radar & location privacy

- Store location in PostGIS (authoritative) with Redis GEO as query cache.
- **Never** send raw coordinates to another client. Distance is banded: `< 1 km → "၁ ကီလိုမီတာအတွင်း"`, else rounded to bands (`~3 km`, `~5 km`, `~10 km`).
- Anti-trilateration: snap reported location to a geohash grid with a **200–500 m random offset** applied consistently per user per session; store only the snapped point for discovery.
- `radar_visible=false` toggle removes the user from radar.
- Radar offline behaviour: show last cached result + timestamp (never a blank screen).
- Location permission denied → fall back to "မြို့နယ် ဖြင့် ရှာ" (township-level search from a bundled offline hierarchy).
- Permission purpose strings (iOS) / rationale (Android) must be present and Myanmar-localised.

---

## 10. Profile & Settings

### 10.1 Own profile
Photo header (swipe through photos, optional video avatar) · name · online status · username · bio · birthday (visibility-controlled) · quick actions: `My Posts`, `Friends`, `Groups & Pages`, `Saved Messages`, `❤ Dating` (visible only when dating mode is on).

### 10.2 Other user's profile
Header (photo, name, last seen) · actions Message / Call / Video / Add-Unfriend / Mute · info (username, bio, phone only if privacy allows) · shared media tabs (Photos, Videos, Files, Links, Voice, Groups in common) · Block · Report.
**Dating data must never appear here.**

### 10.3 Settings — 11 sections (all must exist in v1, some rows may be v1.1)

| Section | Rows |
| --- | --- |
| Account | Edit profile (name, photo, bio, username, birthday), **Change device (QR transfer)**, **Email / Linked accounts → Connect Gmail**, **Restore Purchases**, Deactivate, Delete account |
| Privacy & Security | Visibility of phone/last seen/profile photo/bio/birthday (Everybody / Contacts / Nobody), forwarded-message link, calls, group-channel add, friend requests, default post audience, blocked users, two-step verification, passcode/biometric, active sessions + "Sign out from all other devices", auto-delete messages, account self-destruct (inactivity), data download, **dating visibility** |
| Notifications | private chat, group, channel, feed activity, friend request, dating (new match, likes you), **dating chat (separate channel)**; in-app sound, vibrate, preview, reset |
| Data & Storage | storage usage + clear cache, network usage, auto-download (Wi-Fi/mobile/roaming), auto-play, data saver, proxy |
| Chat | text size, wallpaper, bubble colour, chat folders, stickers/emoji, send-by-enter, archived behaviour |
| Appearance | light/dark/**AMOLED**/system, high contrast, accent colour, app icon, animation/reduced motion, **list density (Comfortable 68 / Compact 56)**, Myanmar numerals toggle, legacy Zawgyi display toggle (default off) |
| Dating | dating on/off, pause profile, discovery filters (age, distance, gender), radar visibility, show distance, verification, dating chat notification, read receipt toggle, blocked dating users, reset dating profile |
| Devices | bound devices, transfer, revoke |
| Language | Myanmar / English |
| Premium | plan, status, purchase (blocked for guests → Connect Gmail), Restore Purchases, "no cross-platform portability" note, manage subscription deep link |
| Help | FAQ, contact support, report a problem, privacy policy, terms |

Turning dating **off**: remove from radar immediately, then ask whether to archive active matches.

---

## 11. Offline-First Architecture

### 11.1 Local DB is the source of truth
All UI reads Drift. Network responses are upserted into Drift first, then the UI reacts to the DB stream. Repository pattern: `read local → trigger network → upsert → UI updates`. Feed, chat list, profile, settings must open instantly with no network.

### 11.2 Outbox & idempotency
- Durable SQLite `outbox` table (survives app kill). Every UI mutation writes locally first, then enqueues.
- Client generates entity IDs as UUIDv7 and an `Idempotency-Key`/`client_msg_id` so retries never duplicate.
- Worker: serial per-entity-class queue, exponential backoff + jitter, network-type aware, pauses media uploads on low battery and continues text outbox.

### 11.3 Conflict resolution by data type

| Data | Strategy |
| --- | --- |
| Messages | append-only, no conflict; order by server `seq` |
| Profile & Settings | field-level merge, per-field Hybrid Logical Clock LWW (bio edited on device A + avatar on device B ⇒ both kept) |
| Post edit | field-level LWW |
| Dating swipe | may be queued client-side, but **match decision is server-only** |
| Premium purchase / restore | online only |
| Device change (QR) | online only |
| Account deletion | online only |

No CRDT in v1 (no collaborative editing requirement) — deliberate complexity reduction.

### 11.4 Delta sync & media
- Per-entity `sync_cursor` (server seq or `updated_at`); payload = field-level patches only.
- Media: WebP thumbnail + separate full resolution; chunked **resumable** uploads; large video upload only on Wi-Fi or while charging (user choice).
- Face-aware crop for every thumbnail; `aspect-ratio` hard-coded to prevent layout shift; BlurHash/LQIP placeholder before thumbnail.

### 11.5 Connectivity UX (4 states, all designed)

| State | UI |
| --- | --- |
| Online | nothing |
| Offline | sticky top banner: "အင်တာနက်မရှိပါ။ ပို့ထားသော စာများကို ချိတ်ဆက်သည်နှင့် ပို့ပေးပါမည်" |
| Syncing | small spinner (≤ 2 s) then skeleton/text state |
| Failed | "ပို့မရပါ။ ထပ်ကြိုးစားရန်" button per item |

Per-message status icons: clock (pending) · ✓ (sent) · ✓✓ (delivered/read).
**Online-only actions must be visibly disabled offline**, not silently failing: Premium purchase, dating match creation, QR device transfer, account deletion.

---

## 12. Screen State Matrix (minimum 4 states per screen before design review)

| Screen | Loading | Empty | Error | Offline | Permission denied |
| --- | --- | --- | --- | --- | --- |
| Feed | skeleton 3 cards | "အသိုင်းအဝိုင်းနဲ့ စတင်ပါ" + join-5-groups CTA | retry + show cached | cached + banner | — |
| Chat list | skeleton 6 rows | "စကားပြောမှု မရှိသေး" + "အဆက်အသွယ် ရှာရန်" | retry | cached | — |
| Thread | skeleton 4 bubbles | "မက်ဆေ့ချ် စတင်ပါ" | per-bubble "ပြန်ပို့ရန်" | waiting badge | — |
| Post detail | skeleton | "မတွေ့ပါ / ဖျက်လိုက်ပြီ" | retry | cached | "ဒီပို့စ်ကို ကြည့်ခွင့် မရှိပါ" |
| Dating cards | card skeleton | "ကိုက်ညီသူ မရှိသေး — filter ချဲ့ပါ" | retry | "အင်တာနက် လိုအပ်သည်" | verification pending |
| Radar | radar placeholder | "အနီးတွင် မတွေ့ပါ — အကွာအဝေး တိုးပါ" | retry | **last cached + timestamp** | location denied → township search |
| Profile | skeleton | — | retry | cached | private account |
| Settings | static | — | toast | local only + "ချိန်ညှိမှု သိမ်းမထားပါ" | — |
| Search | recent + suggestions | "ရှာမတွေ့ပါ" + spelling hint | retry | offline search (bundled index) | — |
| Linked accounts / Gmail | spinner on link flow | "မချိတ်ဆက်ရသေး" + Connect CTA | "မအောင်မြင်ပါ။ ပြန်ကြိုးစားပါ (E-…)" | **disabled: online only** | OAuth cancelled → return to sheet |

---

## 13. Data Model (normative DDL — core tables)

```sql
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
  purge_at        timestamptz,              -- deleted_at + 30d
  updated_hlc     bigint NOT NULL DEFAULT 0 -- hybrid logical clock
);

CREATE TABLE identities (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id    uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  provider      text NOT NULL CHECK (provider IN ('guest','google','apple')),
  provider_sub  text NOT NULL,
  email         text,
  email_verified boolean NOT NULL DEFAULT false,
  linked_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, provider_sub)           -- one account per external identity
);

CREATE TABLE device_bindings (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id   uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  device_hash  text NOT NULL,               -- HMAC-SHA256(pepper, raw_id); raw_id never stored
  role         text NOT NULL DEFAULT 'primary' CHECK (role IN ('primary','secondary')),
  platform     text NOT NULL CHECK (platform IN ('android','ios')),
  push_token   text,
  bound_at     timestamptz NOT NULL DEFAULT now(),
  revoked_at   timestamptz,
  UNIQUE (account_id, device_hash)
);
CREATE INDEX idx_device_bindings_hash ON device_bindings(device_hash) WHERE revoked_at IS NULL;

CREATE TABLE sessions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id    uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  device_hash   text NOT NULL,
  refresh_hash  text NOT NULL UNIQUE,        -- only hash stored
  family_id     uuid NOT NULL,               -- reuse detection
  created_at    timestamptz NOT NULL DEFAULT now(),
  expires_at    timestamptz NOT NULL,
  revoked_at    timestamptz
);

CREATE TABLE transfer_tokens (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id     uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  token_hash     text NOT NULL UNIQUE,
  from_device    text NOT NULL,
  to_device      text,
  status         text NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','confirmed','expired','rejected')),
  created_at     timestamptz NOT NULL DEFAULT now(),
  expires_at     timestamptz NOT NULL,       -- created_at + 120s
  used_at        timestamptz
);

CREATE TABLE device_cooldowns (
  device_hash  text PRIMARY KEY,
  reason       text NOT NULL DEFAULT 'account_deleted',
  until        timestamptz NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE abuse_logs (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  device_hash  text NOT NULL,                -- NO account_id, NO raw device id
  event        text NOT NULL CHECK (event IN ('guest_created','account_deleted')),
  occurred_at  timestamptz NOT NULL DEFAULT now()
);                                            -- retention 90d then aggregated
CREATE INDEX idx_abuse_device_window ON abuse_logs(device_hash, occurred_at);

-- ========== SOCIAL ==========
CREATE TABLE profiles (
  user_id      uuid PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
  display_name text NOT NULL,
  bio          text,
  avatar_key   text,
  birth_date   date,
  privacy      jsonb NOT NULL DEFAULT '{}'::jsonb,  -- see §13.1
  updated_hlc  bigint NOT NULL DEFAULT 0
);

CREATE TABLE friendships (
  user_id    uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  friend_id  uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  status     text NOT NULL CHECK (status IN ('pending','accepted','blocked')),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, friend_id),
  CHECK (user_id <> friend_id)
);

CREATE TABLE posts (
  id           uuid PRIMARY KEY,
  author_id    uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  audience     text NOT NULL DEFAULT 'friends'
               CHECK (audience IN ('public','friends','group','page','only_me')),
  container_id uuid,                          -- group/page id when applicable
  body         text,
  media        jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at   timestamptz NOT NULL DEFAULT now(),
  edited_at    timestamptz,
  deleted_at   timestamptz,
  updated_hlc  bigint NOT NULL DEFAULT 0
);
CREATE INDEX idx_posts_feed ON posts(author_id, created_at DESC);

CREATE TABLE reactions (
  post_id    uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  kind       text NOT NULL CHECK (kind IN ('like','love','care','haha','wow','sad')),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (post_id, user_id)
);

CREATE TABLE comments (
  id         uuid PRIMARY KEY,
  post_id    uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  parent_id  uuid REFERENCES comments(id) ON DELETE CASCADE,  -- depth max 2
  user_id    uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  body       text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- ========== CHAT ENGINE ==========
CREATE TABLE chats (
  id           uuid PRIMARY KEY,
  type         text NOT NULL CHECK (type IN ('private','secret','group','channel','saved','dating')),
  title        text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  last_seq     bigint NOT NULL DEFAULT 0,
  policy       text NOT NULL DEFAULT 'social' CHECK (policy IN ('social','dating')),
  closed_at    timestamptz                    -- unmatched/closed
);

CREATE TABLE chat_members (
  chat_id     uuid NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  role        text NOT NULL DEFAULT 'member' CHECK (role IN ('owner','admin','member','subscriber')),
  joined_at   timestamptz NOT NULL DEFAULT now(),
  left_at     timestamptz,
  muted_until timestamptz,
  read_receipts_enabled boolean NOT NULL DEFAULT true,  -- dating default false at insert
  PRIMARY KEY (chat_id, user_id)
);

CREATE TABLE messages (
  id             uuid PRIMARY KEY,            -- client UUIDv7
  chat_id        uuid NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  sender_id      uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  seq            bigint NOT NULL,             -- server-assigned per chat
  client_msg_id  uuid NOT NULL,
  kind           text NOT NULL CHECK (kind IN
                 ('text','photo','video','voice','sticker','file','system','icebreaker')),
  body           text,
  media          jsonb,
  reply_to       uuid,
  status         text NOT NULL DEFAULT 'sent'
                 CHECK (status IN ('sent','delivered','read','failed','deleted')),
  deleted_scope  text CHECK (deleted_scope IN ('me','everyone')),
  edited_at      timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (chat_id, seq),
  UNIQUE (sender_id, client_msg_id)           -- idempotency
);
CREATE INDEX idx_messages_chat_seq ON messages(chat_id, seq DESC);

CREATE TABLE chat_folders (
  user_id  uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  chat_id  uuid NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  folder   text NOT NULL CHECK (folder IN ('all','private','group','channel','dating','unread','pinned','archived')),
  PRIMARY KEY (user_id, chat_id, folder)
);

-- ========== DATING ==========
CREATE TABLE dating_profiles (
  user_id          uuid PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
  display_name     text NOT NULL,
  birth_date       date NOT NULL,             -- age derived; >= 18 enforced in service + CHECK via trigger
  age_verified_18  boolean NOT NULL DEFAULT false,
  gender           text NOT NULL CHECK (gender IN ('male','female','other')),
  seeking_gender   text NOT NULL CHECK (seeking_gender IN ('male','female','everyone')),
  bio              text CHECK (char_length(bio) <= 300),
  interests        text[] NOT NULL DEFAULT '{}',
  looking_for      text CHECK (looking_for IN ('long_term','friends','chat')),
  height_cm        smallint,
  occupation       text,
  prompt_qa        jsonb,
  photos           jsonb NOT NULL DEFAULT '[]'::jsonb,   -- 2..6 enforced in service
  verification     text NOT NULL DEFAULT 'none'
                   CHECK (verification IN ('none','pending','verified','rejected')),
  paused           boolean NOT NULL DEFAULT false,
  radar_visible    boolean NOT NULL DEFAULT true,
  show_distance    boolean NOT NULL DEFAULT true,
  location         geometry(Point,4326),        -- snapped/obfuscated point only
  location_updated_at timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_hlc      bigint NOT NULL DEFAULT 0
);
CREATE INDEX idx_dating_geo ON dating_profiles USING GIST (location) WHERE paused = false;

CREATE TABLE likes (
  from_user  uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  to_user    uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  kind       text NOT NULL CHECK (kind IN ('like','super_like','pass','undo')),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (from_user, to_user),
  CHECK (from_user <> to_user)
);

CREATE TABLE matches (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a       uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  user_b       uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  chat_id      uuid REFERENCES chats(id) ON DELETE SET NULL,
  state        text NOT NULL DEFAULT 'matched'
               CHECK (state IN ('matched','dormant','unmatched','blocked')),
  matched_at   timestamptz NOT NULL DEFAULT now(),
  dormant_at   timestamptz,
  unmatched_at timestamptz,
  retain_until timestamptz,                     -- evidence window: unmatched_at + 30d
  UNIQUE (user_a, user_b),
  CHECK (user_a < user_b)                       -- canonical order
);

CREATE TABLE dating_chat_state (
  chat_id           uuid PRIMARY KEY REFERENCES chats(id) ON DELETE CASCADE,
  opener_owner      uuid REFERENCES accounts(id) ON DELETE CASCADE,  -- who is under limit
  opener_sent       smallint NOT NULL DEFAULT 0,                      -- max 3 until reply
  opener_cleared    boolean NOT NULL DEFAULT false,
  last_reply_at     timestamptz,
  dormant           boolean NOT NULL DEFAULT false
);

CREATE TABLE super_like_quota (
  user_id  uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  day      date NOT NULL,
  used     smallint NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, day)
);

-- ========== BILLING ==========
CREATE TABLE entitlements (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id       uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  store            text NOT NULL CHECK (store IN ('apple','google')),
  product_id       text NOT NULL,
  store_txn_hash   text NOT NULL,
  status           text NOT NULL DEFAULT 'active'
                   CHECK (status IN ('active','expired','revoked','pending','grace')),
  starts_at        timestamptz NOT NULL,
  expires_at       timestamptz,
  last_verified_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store, store_txn_hash)                -- one transaction => one account
);

-- ========== SAFETY / MODERATION ==========
CREATE TABLE reports (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id   uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  target_type   text NOT NULL CHECK (target_type IN ('user','post','comment','photo','message','chat')),
  target_id     text NOT NULL,
  reason        text NOT NULL,
  detail        text,
  severity      text NOT NULL DEFAULT 'normal'
                CHECK (severity IN ('critical','high','normal','low')),  -- critical = child safety, violence, extortion
  status        text NOT NULL DEFAULT 'open'
                CHECK (status IN ('open','in_review','actioned','rejected','closed')),
  created_at    timestamptz NOT NULL DEFAULT now(),
  closed_at     timestamptz,
  sla_due_at    timestamptz                     -- critical: created_at + 24h
);

CREATE TABLE evidence_items (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id     uuid NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
  vault_key     text NOT NULL,                  -- restricted vault, KMS-encrypted
  content_hash  text NOT NULL,
  kind          text NOT NULL,
  legal_hold    boolean NOT NULL DEFAULT false,
  retain_until  timestamptz NOT NULL,           -- closed_at + 30d (+30d if actioned)
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE evidence_access_log (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  evidence_id  uuid NOT NULL REFERENCES evidence_items(id) ON DELETE CASCADE,
  actor_id     uuid NOT NULL,
  actor_role   text NOT NULL,
  accessed_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE blocks (
  blocker_id  uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  blocked_id  uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  scope       text NOT NULL DEFAULT 'all' CHECK (scope IN ('all','social','dating')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (blocker_id, blocked_id, scope)
);

-- ========== SYNC / IDEMPOTENCY ==========
CREATE TABLE idempotency_keys (
  account_id   uuid NOT NULL,
  key          text NOT NULL,
  response_hash text NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz NOT NULL,            -- +7d
  PRIMARY KEY (account_id, key)
);
```

### 13.1 `profiles.privacy` JSONB shape

```json
{
  "phone": "contacts", "last_seen": "everybody", "profile_photo": "everybody",
  "bio": "everybody", "birthday": "nobody",
  "forwarded_link": "nobody", "calls": "contacts", "group_add": "contacts",
  "friend_request": "everybody", "default_post_audience": "friends",
  "dating_visibility": "hidden", "two_step_verification": false,
  "auto_delete_days": null, "inactive_self_destruct_days": null
}
```
Enum values allowed: `everybody | contacts | nobody`. `dating_visibility` allowed: `hidden | entry_only`. **No API may return another user's `dating_visibility` or any dating field.**

### 13.2 Migration rules
Migrations are backward-compatible (expand → migrate → contract) and applied by the migration tool only. No manual DDL in any environment. Every migration has a rollback script.

---

## 14. UI/UX Design System (DS 1.0.0)

Machine-readable tokens: `Hasta_v1_Design_Tokens.json` (companion file). Rule: **components may only reference semantic tokens; hard-coded hex is a CI failure.**

### 14.1 Colour — semantic tokens (light / dark)

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `bg.canvas` | `#F6F8FB` | `#0E1621` | app background |
| `bg.surface` | `#FFFFFF` | `#16202C` | card, list row |
| `bg.surfaceRaised` | `#FFFFFF`+shadow | `#1E2A38` | sheet, sticky bar |
| `bg.sunken` | `#EEF1F6` | `#0A1219` | input, chat bg |
| `bg.overlay` | `#111827` @56% | `#000000` @64% | scrim |
| `bg.brandSubtle` | `#EAF1FE` | `#16243D` | selected, mention |
| `bg.dangerSubtle` | `#FDECEC` | `#2A1518` | destructive bg |
| `bg.datingSubtle` | `#FDECF1` | `#2A1620` | dating mode surface |
| `text.primary` | `#111827` | `#E8EDF4` | body, title |
| `text.secondary` | `#5B6472` | `#9DA9BA` | metadata |
| `text.tertiary` | `#8A93A2` | `#6E7A8B` | placeholder, disabled |
| `text.onBrand` | `#FFFFFF` | `#0B1220` | on filled button |
| `text.link` | `#2F6FED` | `#4C8DFF` | link, @mention |
| `text.danger` | `#E5484D` | `#FF6B70` | error, delete |
| `icon.primary` | `#1B2432` | `#C9D3E0` | default icon |
| `icon.active` | `#2F6FED` | `#4C8DFF` | selected tab |
| `border.subtle` | `#E2E7EF` | `#243141` | divider |
| `border.strong` | `#CBD3DF` | `#33445A` | input border |
| `border.focus` | `#2F6FED` | `#4C8DFF` | 2px focus ring |
| `accent.community` | `#1FA971` | `#2FBF83` | group badge |
| `accent.market` | `#F2A33C` | `#F2A33C` | listing/seller |
| `accent.dating` | `#EF4B7B` | `#FF6B93` | dating, match |
| `state.online` | `#1FA971` | `#2FBF83` | presence dot |
| `state.sending` | `#8A93A2` | `#6E7A8B` | clock icon |
| `state.read` | `#2F6FED` | `#4C8DFF` | ✓✓ |
| `state.waiting` | `#E0A500` | `#E0A500` | offline queue |

Contrast minimums: body/bg 4.5:1, large text 3:1, functional icon 3:1, focus ring vs adjacent 3:1, **Myanmar text 4.5:1 mandatory**. Never encode meaning by colour alone — always icon + text (colour-blind safety).

### 14.2 Typography

Fonts: `Noto Sans Myanmar` (bundled, weights 400/500/600/700) · fallback `Padauk` → system · Latin/numerals `Inter` · **Zawgyi is never bundled**: detect → convert → render Unicode, with a one-time toast "ပြောင်းပြီးပါပြီ". Legacy Zawgyi *display* toggle lives in Settings → Appearance (default off).

| Style | Size / line-height | Weight | Use |
| --- | --- | --- | --- |
| display | 28 / 40 | 700 | onboarding title, match name |
| h1 | 24 / 36 | 700 | screen title |
| h2 | 20 / 32 | 600 | section header |
| subtitle | 17 / 28 | 600 | list primary, post author |
| body | 15 / 26 | 400 | post text, message |
| bodyStrong | 15 / 26 | 600 | unread chat name |
| bodySm | 14 / 24 | 400 | comment, secondary |
| caption | 13 / 22 | 400 | timestamp |
| micro | 11 / 18 | 500 | badge, tab label |
| overline | 12 / 20 (+0.2 ls) | 600 | section label — **never uppercase** |

Myanmar rules: line-height ≥ 1.65× (never less); syllable-segmenter wrapping, not character breaking; `min-height` not fixed height; `ellipsis` never `clip`; Myanmar bold ≤ 600 except large headings; input vertical padding +2 px; Arabic numerals by default with a Myanmar-numerals toggle; `?` glued to the preceding syllable.

Truncation: post body 6 lines → "ဆက်ဖတ်ရန်" · comment 4 → "ပိုကြည့်" · chat-list last message 1 → ellipsis · bubble unlimited · name 1 → ellipsis · dating bio 3 → "ပိုကြည့်".

### 14.3 Layout & spacing
4-pt scale `0·2·4·8·12·16·20·24·32·40·48·64`. Screen horizontal padding 16; card padding 12 (feed) / 16 (settings); list row vertical 12; avatar↔text 12; section gap 24; sticky bar 12 + safe-area.
Breakpoints: Compact <600 (1 col + bottom nav) · Medium 600–904 (nav rail, content max 640) · Expanded ≥905 (rail + list-detail). Line length ≤ 60 Latin chars / ≤ 40 Myanmar syllables.
Density: Comfortable row 68 / Compact row 56 with −1 px type.
Insets: bottom nav `12 + safe-area-bottom`; keyboard pushes input bar via `ime-inset` with auto-scroll or a "နောက်ဆုံးသို့" pill; top bar 56 + status bar.

### 14.4 Shape & elevation
`radius.xs 6 · sm 8 · md 12 · card 16 · sheet 20 (top only) · pill 999 · bubble 16 (tail 6)`; border 1 (subtle) / 1.5 (focus 2).
Elevation `e0 none · e1 0 1 2 rgba(17,24,39,.06) · e2 0 4 12 rgba(17,24,39,.08) · e3 0 8 24 rgba(17,24,39,.12) · e4 0 16 40 rgba(17,24,39,.16)`. On low-end devices cap at e3; blur backdrop allowed on sheets, forbidden on dialogs.

### 14.5 Motion, haptics, sound
`instant 100 · fast 150 · base 200 · slow 320 · celebrate 600 ms`; easings standard `cubic-bezier(.2,0,0,1)`, decelerate `(0,0,.2,1)`, accelerate `(.4,0,1,1)`, spring stiffness 320 damping 30. Max 3 concurrent animated elements; list stagger ≤ 8 items; loading = skeleton (shimmer off on low-end), text state after 3 s. Reduced Motion → fades only, swipe card cross-fades, match reveal becomes a static card.
Haptics on by default; **sound off by default** (Myanmar context). Match = success haptic pattern, sound off.

### 14.6 Components (64 total, 3 tiers)
Tier 1 foundation (22): Button, IconButton, FAB, Chip/FilterChip, SegmentedControl, TabBar, Switch, Checkbox/Radio, Slider, TextField, TextArea, SearchField, OTPInput *(retained in the library but unused in v1 — no OTP flow)*, Select, DatePicker (+age preview for the 18+ gate), Divider, Progress, Skeleton, Avatar (+presence, +dating ring, +verified), Badge, Tooltip, Snackbar (offline variant).
Tier 2 compound (24): TopAppBar, BottomNav, NavigationRail, ListItem, SectionHeader, Card, BottomSheet, Dialog (destructive action on the right), ActionSheet (destructive last + red), PopoverMenu, EmptyState (exactly 1 CTA), ErrorState (hidden error code), OfflineBanner, PullToRefresh, InfiniteScrollFooter, Toast, Stepper, PhotoGrid, MediaViewer, ShareSheet, VerificationBadge (page blue / seller amber / dating pink), PresenceDot, ReactionPill, InfoRow.
Tier 3 domain (18): PostCard (6 variants), PostComposer, StoryRing, StoryViewer, CommentThread, ReactionPicker, MessageBubble (12 content types, max width 78%, tail 6), ReplyPreview, AttachmentTray, VoiceRecorder (waveform 40 bars, slide-to-cancel), StickerPanel, TypingIndicator, DateSeparator, UnreadDivider, **MatchCard** (4:5, gradient overlay, name+age, distance pill, 3 interest chips, action row), **SwipeOverlay** (LIKE right green / NOPE left red / SUPER up blue, 12° rotate), **RadarView** (3 concentric rings, own dot centred, others blurred, tap → mini card), AddressPicker (4-step + landmark + pin, no free-text address, works offline from bundled hierarchy).

Every component's documentation must contain: `anatomy · variants · sizes · states · tokens used · do/don't (2) · a11y label · Myanmar text example · empty/loading/error`.

Minimum states per component: `default, pressed, disabled, loading, focus` (+ `error` for inputs).

### 14.7 Key copy (Myanmar, normative)

| Context | Copy |
| --- | --- |
| Welcome primary button | `စတင်အသုံးပြုရန်` (Continue) |
| Guest explainer | `အီးမေးလ်၊ ဖုန်းနံပါတ် မလိုပါ။ ဤဖုန်းတွင် ချက်ချင်း စတင်နိုင်သည်။` |
| Guest risk notice | `ဖုန်းပျောက်ပါက ဤအကောင့်ကို ပြန်ရနိုင်မည် မဟုတ်ပါ။ Gmail ချိတ်ဆက်ထားရန် အကြံပြုသည်။` |
| Connect Gmail row | `Gmail ချိတ်ဆက်ရန်` / linked: `ချိတ်ဆက်ပြီး — h***@gmail.com` |
| Gmail benefit sheet | `ချိတ်ဆက်ပါက — (၁) ဖုန်းပြောင်းလျှင် အကောင့် ပြန်ရနိုင်သည် (၂) Premium ဝယ်ယူနိုင်သည် (၃) Restore Purchases သုံးနိုင်သည်။` |
| Purchase blocked (guest) | `Premium ဝယ်ယူရန် Gmail ချိတ်ဆက်ထားရပါမည်။` |
| Offline | `အင်တာနက်မရှိပါ။ ပို့ထားသော စာများကို ချိတ်ဆက်သည်နှင့် ပို့ပေးပါမည်။` |
| Opener limit | ` ဤချတ်တွင် နောက်ထပ် မက်ဆေ့ချ် ၁ ခုသာ ပို့နိုင်သေးသည်။ ဖြေကြားမှု ရရှိပါက ကန့်သတ်ချက် ပြေလျော့မည်။` |
| Age < 18 | `Dating ကို အသက် ၁၈ ဈစ်ပြည့်ပြီးမှ အသုံးပြုနိုင်ပါသည်။` |
| Unmatch confirm | title `ဒီတွဲဖက်ကို ဖျက်မလား?` body `နှစ်ဖက်စလုံးအတွက် ချက်ချင်း ပိတ်သွားမည်။ လုံခြုံရေးအတွက် သက်သေ ၃၀ ရက် ထိန်းထားပါမည်။` action `ဖျက်သည်` |
| Generic error | `မအောင်မြင်ပါ။ ခဏနေမှ ပြန်ကြိုးစားပါ။ (E-500)` |

Error formula: `[what happened] + [what to do] + [(hidden) error code]`. Destructive buttons use verbs, never "OK".
Glossary (mandatory): Post=ပို့စ် · Comment=မှတ်ချက် · Share=မျှဝေ · Follow=လိုက်ကြည့် · Friend request=သူငယ်ချင်း တောင်းဆို · Match=တွဲဖက် · Nearby=အနီးအနား · Offline transfer=အင်တာနက်မလိုဘဲ ပို့.
Tone: plain, respectful, encouraging; age-neutral (no ခင်ဗျား/ညီကို/အစ်ကို); light English loanwords allowed.
Time/number formats: 24 h default ("၁၉:၄၅") with 12 h toggle; relative "၅ မိနစ်က / မနေ့က / ၁၂ ရက် / ၁ နှစ်က"; distance banded; file size "၂.၄ MB"; counts "၁,၂၄၅".

### 14.8 Accessibility
Touch targets ≥ 44×44 (iOS) / 48×48 (Android); visual-24 icons get expanded hit areas (WCAG 2.2 SC 2.5.8 floor 24×24). Text scaling to 200% without breakage (hide nav labels, reflow cards). TalkBack/VoiceOver labels for every icon-only control, Myanmar voice-compatible. Focus order matches visual order; focus trap in bottom sheets. Reduce Motion honoured. Status conveyed by icon + text. "Large text" mode sets body 17.

### 14.9 Performance budget (design constraints, measured in CI/QA)
First screen interactive < 2.5 s on mid-range Android over 3G · feed scroll ≥ 55 fps · initial images per screen ≤ 800 KB · concurrent blur/shadow layers ≤ 2 · concurrent animated views ≤ 3 · font files ≤ 3 (subset) · APK < 45 MB · skeleton rows ≤ 6 then static block · app cold start ≤ 2.5 s.

### 14.10 Imagery & media specs
Avatar list 1:1 40 (WebP 40/80/120) · avatar profile 1:1 96/160 · dating photo 4:5 640×800 (WebP+AVIF) · post image 1:1/4:5/16:9 max 1080 (WebP) · feed video preview 16:9 ≤ 8 s muted HLS · sticker 1:1 512 animated WebP · story 9:16 720×1280 · BlurHash/LQIP before thumbnail · Data Saver caps images at 320 px and requires tap for video.

### 14.11 Iconography
24×24 grid, 20 live area, 1.5 px stroke, round cap/join; outline default, filled for active. Sizes 16/20/24/28. Myanmar-specific custom set (≈20): pagoda, market, monastic, bus station, phone call, offline-transfer, QR, radar, etc. No hand-drawn one-off icons — request from the library. Icon-only buttons require tooltip + a11y label.

### 14.12 Themes
Light (default) · Dark · **AMOLED** (`bg.canvas = #000000`) · System · High contrast (text 7:1, thicker borders) · Data saver (imagery overrides).

### 14.13 Design QA gate (every release)
Hard-coded colours 0 · states ≥ 4 per screen · Myanmar clipping 0 and Zawgyi test pass · contrast fails 0 · feed fps ≥ 55 on low-end · glossary compliance 100% · handoff checklist complete (tokens only, 5 states, Myanmar long-string test, text scale 1.3×/2.0×, dark + AMOLED, empty/loading/error/offline, a11y label + focus order, touch ≥ 44, WebP 1x/2x/3x + blurhash export, animation spec).

---

## 15. Security, Privacy & Compliance

| Area | Requirement (concrete) |
| --- | --- |
| Transport | HTTPS only; HSTS; TLS 1.2+; optional certificate pinning (remote-config kill switch) |
| Tokens | JWT access 15 min; refresh rotation + family reuse detection; stored in Keychain/Keystore; never logged |
| Device id | raw device id never persisted; only `HMAC-SHA256(HASTA_DEVICE_PEPPER, raw_id)`; pepper in Secrets Manager, rotatable with re-hash job |
| Authorisation | ownership + role checks on every endpoint; IDOR protection (UUIDs, no sequential ids in responses); deny-by-default |
| Validation | DTO validation (class-validator) + zod boundary parsing; strict MIME/extension/size checks on uploads; max file 20 MB (copy: "ဖိုင် ကြီးလွန်းပါသည် (အများဆုံး ၂၀ MB)") |
| Rate limits | per-account and per-device on auth, transfer (≤2/3 min), message send, swipe, report; 429 with `Retry-After` |
| Secrets | no secret in code or repo; `.env` locally, AWS Secrets Manager in deployed envs; pre-commit secret scanning (lefthook/husky) |
| Logs | structured JSON; redact tokens, emails, phone-like strings, message bodies; keep `request_id`, `account_id`, route, duration, status |
| Dating privacy | no dating field leaks to social APIs; push payloads carry no name/photo; distance banded; coordinates obfuscated (200–500 m) |
| Moderation | AI scan on image upload and message patterns (money requests, external links, personal-data harvesting, scam/spam); report queue priority; **critical cases (child safety, violence, extortion) handled by a human moderator within 24 h** |
| Minors | 18+ hard gate for dating; derived from birth_date; store age rating 17+/18+ as required |
| Data retention | location, dating chat, verification photos: documented retention + deletion windows in the privacy policy; device-hash abuse log 90 days; evidence 30 (+30 / legal hold) |
| Backups | client-side encrypted Drive/iCloud backup; key in device Keychain/Keystore, **never** sent to server; server cannot read it (T35) |
| Store compliance | privacy policy URL, ToS, Google Data safety form, Apple privacy nutrition labels, account-deletion path, UGC moderation (report/block/filter), location purpose strings |
| Legal | Data-protection, dating-app regulation, payments/tax review by qualified counsel **before launch**; retention windows (§5.7, §5.8) require legal sign-off |

---

## 16. Test Matrix & QA Gates

### 16.1 Tests carried over from Identity Guide (T21–T35) plus new v1 auth tests (T36–T45)

| # | Test | Expected | Type |
| --- | --- | --- | --- |
| 20 | Static check: no OTP/SMS route exists | pass (route absent) | Static/CI |
| 21 | Guest attempts Premium purchase | blocked, "Connect Gmail" prompt | Unit |
| 22 | Restore Purchases on a new device with linked Gmail | entitlement restored | Integration (store sandbox) |
| 23 | Same subscription restored on a second account | second rejected (409) | Integration |
| 24 | Apple/Google refund notification | status → revoked | Integration |
| 25 | QR token expired (>120 s) | reject | Unit |
| 26 | QR token redeemed twice | second rejected | Concurrency |
| 27 | Transfer without old-device confirm | not transferred | Integration |
| 28 | After successful transfer, open old device | welcome screen, no session | E2E |
| 29 | Transfer while target device has a guest account | reject 409 | Integration |
| 30 | Old device lost + Gmail linked → sign in on new device | access granted, new binding created | E2E |
| 31 | Delete account with Drive backup permission granted | Drive file deleted, purge job scheduled | Integration |
| 32 | Report closed + 30 days | evidence purged from vault | Scheduled job |
| 33 | Report under legal hold | retention job does not delete | Integration |
| 34 | Non-moderator accesses evidence vault | 403, no access-log leak | Security |
| 35 | Server attempts to read user Drive backup | impossible (client-side encryption, key never leaves device) | Security |
| 36 | `release`/`production` build contains the quick-test-account panel | **fail build** | Static/CI |
| 37 | Any Google *sign-in* endpoint exists (`/auth/google/signin`, token-only login) | **fail build** | Static/CI |
| 38 | Linking a Gmail already bound to another account | 409 `identity_in_use`, no second account created | Integration |
| 39 | Client submits a forged/unverified Google ID token | rejected (server-side verification) | Security |
| 40 | Guest one-tap on a fresh device | account created, `is_guest=true`, session issued | E2E |
| 41 | Guest one-tap on a device with an existing active binding | resumes the same account (no duplicate) | Integration |
| 42 | Guest creation during device cooldown | 429 `device_cooldown` with remaining days | Unit |
| 43 | Connect Gmail while offline | action visibly disabled with reason copy | UI/E2E |
| 44 | After Connect Gmail, purchase flow | entitlement attachable, `is_guest=false` | Integration |
| 45 | Word "nexus" anywhere in build artefacts/source | 0 matches | Static/CI |

### 16.2 Core product tests (T1–T19)

| # | Test | Expected | Type |
| --- | --- | --- | --- |
| 1 | Mutual like → match | `matches` row (canonical order), `dating` chat created, `match.created` to both, push without name/photo | Integration |
| 2 | Concurrent duplicate likes (A→B twice, B→A) | exactly one match, no duplicate row | Concurrency |
| 3 | Send message in `liked` (not matched) state | 403, no message stored | Unit/Security |
| 4 | Opener limit: 4th unreplied message | 429 `opener_limit`; 3rd allowed | Unit |
| 5 | Opener limit cleared after reply | unlimited both ways | Unit |
| 6 | Dormant after 7 days without reply | chat read-only; reopen restores write | Scheduled job |
| 7 | Unmatch | both sides closed immediately, local cache wipe signal, `retain_until = +30d` | Integration |
| 8 | Forward/export attempt in dating chat | blocked server-side, hidden in UI | Security |
| 9 | Read receipts off (dating default) | sender never sees `read` | Unit |
| 10 | Media blur + NSFW scan ≥0.8 | upload rejected; 0.5–0.8 blurred with report shortcut | Integration |
| 11 | Age < 18 attempts to enable dating | blocked with Myanmar copy | Unit |
| 12 | Radar response payload | contains banded distance only, no coordinates | Security |
| 13 | Location obfuscation | stored point differs from reported by 200–500 m | Unit |
| 14 | Pause profile | absent from card stack and radar within 60 s | Integration |
| 15 | Feed ranking determinism | same inputs + weights → same order; weights from remote config | Unit |
| 16 | Message lifecycle states | pending→sent→delivered→read transitions correct, ordering by `seq` | Integration |
| 17 | Offline send then reconnect | outbox drains, no duplicates (idempotency), status updates | E2E |
| 18 | Multi-device field-level merge (bio on A, avatar on B) | both changes survive (HLC LWW per field) | Integration |
| 19 | Privacy: social user fetches another user's profile | no dating field present in response | Security |

### 16.3 Test strategy
- **Pyramid:** unit (business logic: match rule, ranking score, privacy check, distance banding, opener counter, HLC merge) > integration (Testcontainers: PostgreSQL+PostGIS, Redis, Socket.IO) > E2E/UAT.
- **E2E:** Patrol or `integration_test` over 10 critical flows — guest login, connect Gmail, create post, send chat message, dating swipe, match, dating chat with opener limit, block/report, QR transfer, delete account. Device matrix ≥ 3 Android + 3 iOS models, including one 2–3 GB RAM device.
- **Performance:** k6 to 10,000 concurrent users on feed API + WS. Targets: feed p95 ≤ 300 ms, message delivery ≤ 500 ms (online), cold start ≤ 2.5 s.
- **UAT:** staging, 30–50 beta testers via TestFlight and Google Play internal/closed tracks. Bug severity Critical/Major/Minor/Cosmetic; **zero Critical and zero Major** before release; sign-off by PO + business owner.
- **Security:** SAST (Semgrep/SonarQube) in CI · `npm audit` + Dependabot/Snyk · GitHub secret scanning · DAST (OWASP ZAP) against staging only · OWASP Mobile Top 10 + API Security Top 10 checklists · external penetration test before launch (budgeted).
- **Coverage DoD:** ≥ 70% on business logic; every P0 rule (R1–R8, match, 18+ gate, privacy boundary) has at least one automated test.
- **Prototype test before implementing dating chat rules:** 5 users on a Figma prototype measuring confidence sending the first message, acceptance of the opener limit, and report-button discoverability. Results may adjust numbers (opener 3 or 5; dormant 7 or 14 days) before code freeze.

---

## 17. Delivery Plan

### 17.1 Process
Scrum, 2-week sprints. Sprint Planning → daily 15-min standup → Sprint Review (demo) → Retrospective. User stories as "As a [user], I want [feature], so that [benefit]" with acceptance criteria.

**DoR:** design finished · acceptance criteria written · API contract defined · dependencies clear.
**DoD:** code reviewed (≥1 approver) · unit coverage ≥ 70% on business logic · CI green · QA pass on staging · docs updated (API spec, README) · relevant test-matrix items pass · no hard-coded token/hex/secret · i18n keys present for `my` and `en`.

### 17.2 Sprint plan (19 weeks ≈ 5 months + buffer) — **[CONFLICT-RESOLVED]**

Source docs had two different sprint maps. Resolution: merge into one plan; **OTP is removed from Sprint 1** and replaced by guest + Gmail-link.

| Sprint | Weeks | Content | Exit criteria |
| --- | --- | --- | --- |
| 0 | 1 | Monorepo setup, CI skeleton, Terraform baseline, DS foundations (tokens), DB schema v1, i18n scaffolding, ADR log | CI green on empty app; T45 passes |
| 1 | 2 | **Guest auth (one-tap), device hash/binding, sessions, JWT rotation, cooldown, abuse log**, profile basics, Settings shell, test-mode panel | T36, T40–T43, T20 pass |
| 2 | 2 | **Connect Gmail (link/unlink, recovery path)**, QR device transfer + Settings → Security/Devices, friend system | T25–T30, T37–T39, T44 pass |
| 3 | 2 | Posts, feed ranking (weighted, remote-config weights), reactions, comments | T15, feed states complete |
| 4 | 2 | Groups, pages, notifications, search (Meilisearch) | notification badge separation verified |
| 5 | 2 | Chat engine 1:1 + WS + delivery states + outbox + delta sync + push | T16, T17 pass |
| 6 | 2 | Group chat, channels, saved, folders, media pipeline (thumbnail, resumable upload, transcode worker) | T18 pass |
| 7 | 2 | Dating profile (18+ gate), swipe, likes, match state machine, Likes You, Matches | T1–T3, T11, T14 pass |
| 8 | 2 | Radar/nearby + location privacy, dating chat R1–R8, safety banner, block/report, moderation queue | T4–T10, T12, T13 pass |
| 9 | 2 | Premium entitlements + store verification + restore + refund webhooks; full Settings; Drive encrypted backup; purge job; evidence vault + retention job | T21–T24, T31–T35 pass |
| 10 | 2 | Hardening: perf budget, a11y pass, security testing, pen-test fixes, store submission assets, launch checklist | zero Critical/Major bugs; UAT sign-off |

### 17.3 Git & code standards
Trunk-based with short-lived branches (`feature/HAS-123-dating-swipe`, `bugfix/HAS-456-chat-scroll`, `hotfix/1.0.1-login-crash`); branch lifetime ≤ 2 days; no direct push to `main`/`develop`; PR ≤ 400 lines; review response ≤ 2 h; Conventional Commits with mandatory scope (`feat(chat): …`, `fix(dating): …`, `chore(ci): …`).
Lint/format: ESLint + Prettier + strict TS (backend); `flutter analyze` + `dart format` (mobile). Feature-first folder structure. Pre-commit: lint + secret scan.

### 17.4 Repository layout

```
hasta-app/
├─ apps/
│  ├─ mobile/                     # Flutter
│  │  ├─ lib/
│  │  │  ├─ core/                 # tokens, theme, network, db, sync, security, l10n
│  │  │  │  ├─ design/tokens.dart        (generated from DS JSON — do not hand-edit)
│  │  │  │  ├─ db/drift/                 (schema, DAOs, migrations)
│  │  │  │  ├─ sync/outbox_worker.dart, sync_engine.dart, hlc.dart
│  │  │  │  └─ network/api_client.dart, ws_client.dart, interceptors/
│  │  │  ├─ features/
│  │  │  │  ├─ auth/         (data|domain|presentation)   # guest, gmail link, QR transfer
│  │  │  │  ├─ feed/  ├─ chat/  ├─ dating/  ├─ profile/
│  │  │  │  ├─ settings/  ├─ notifications/  ├─ search/  ├─ billing/
│  │  │  └─ shared/widgets/       # DS components (tier 1/2/3)
│  │  └─ test/ , integration_test/
│  └─ server/                     # NestJS modular monolith
│     ├─ src/modules/{auth,identity,user,social,chat,dating,media,notification,moderation,billing,sync,admin}/
│     ├─ src/common/{guards,interceptors,filters,pipes,decorators}/
│     ├─ src/workers/             # BullMQ processors + cron jobs
│     ├─ prisma/ (or migrations/) , test/
├─ infra/terraform/               # vpc, ecs, rds, elasticache, s3, cloudfront, iam, secrets
├─ .github/workflows/             # ci.yml, deploy-staging.yml, release.yml, mobile.yml
├─ docs/                          # this spec, ADR/, api/openapi.yaml, enums.md, i18n/
├─ design/                        # DS JSON, figma exports, icon set
└─ tools/scripts/                 # token generator, seeders, test-account seeder
```

---

## 18. Deployment, CI/CD, Operations

### 18.1 Environments
`development` (local Docker Compose per developer) · `staging` (production-like infra, QA/UAT) · `production`. Separate DB, secrets, and domain per environment; config drift minimised; **staging must be able to run the full test matrix including store sandbox** (Apple StoreKit testing, Google Play licence testing).

### 18.2 CI pipeline (per PR)
lint → unit tests → integration tests (Testcontainers) → SAST + dependency scan + secret scan → static gates (**T20, T36, T37, T45**) → build (Docker image tagged with commit SHA; APK/IPA debug) → DS token check (generated file matches JSON; zero hard-coded hex).
Merge to `develop` → auto-deploy staging. Tag `v1.0.0` on `main` → production pipeline with a **manual approval gate**.

### 18.3 Mobile release (Fastlane)
Version + build number derived from the git tag. Android: AAB → Play Internal → Closed → Production, staged rollout 5% → 20% → 100%. iOS: IPA → TestFlight → App Store review (allow 1–3 days in the schedule). Signing keys/certificates only in the CI secret store.

### 18.4 Infrastructure as Code
VPC, subnets, ECS cluster, RDS (PostgreSQL+PostGIS), ElastiCache (Redis), S3, CloudFront, IAM roles, Secrets Manager — all Terraform; state in S3 + DynamoDB lock; manual production changes forbidden.

### 18.5 Monitoring & alerting
Alerts: API error rate > 1% · p95 latency > 500 ms · DB CPU > 80% · crash-free rate < 99.5% · WS reconnect rate spike · outbox backlog > 5 min · BullMQ queue age > 5 min · push delivery failure > 5%. Routing to Slack/PagerDuty with an on-call rotation. Dashboards: Grafana (ops), Firebase/Mixpanel (product).

### 18.6 Backup & DR
RDS automated backups ≥ 7 days with PITR; S3 versioning; **RTO ≤ 4 h, RPO ≤ 1 h**; annual restore drill; purge-window constraint: backups expire ≤ 35 days after a deletion request (or the documented legal equivalent).

### 18.7 Maintenance
Support tiers: L1 in-app feedback/email/FAQ · L2 reproduce + triage · L3 developer fix. Response: Critical 4 h, Major 24 h, Minor 7 d. Release cadence: minor monthly, patch as needed; SemVer; minimum-supported-version via remote config; API versioned with ≥ 3-month deprecation; release notes in Myanmar + English. Feedback aggregated in one place with tags (`chat`, `dating`, `performance`) and closed-loop replies. Technical debt ≈ 20% of sprint capacity; dependency updates monthly; security patches within 7 days. Calendar: weekly bug triage + dependency check + on-call review; monthly release + KPI review + 5 user interviews + backup/restore drill; quarterly pen test/security review + DR test; yearly Apple Developer renewal, privacy-policy review, architecture review.

### 18.8 Budget envelope (planning estimates — **[PROPOSAL]**, verify before commitment)
Infra (cloud, CDN, DB, Redis) USD 300–600/month · developer accounts: Apple USD 99/year, Google USD 25 once · tooling (domain, SSL, Figma, GitHub, Sentry, analytics) ≈ USD 100/month · team (7 people × 4 months: 2 mobile, 2 backend, 1 UI/UX, 1 QA, 1 DevOps) · contingency 15% · **legal review line item is mandatory**. SMS/OTP cost is removed (no SMS provider in v1) — the source Build Guide's USD 100–500/month SMS line is void. **[CONFLICT-RESOLVED]**

---

## 19. Test-Mode Build Configuration (required for this phase)

Purpose: let the team and the AI agent enter an account instantly during development/QA, then exercise the real Gmail-connect flow afterwards.

| Flag | dev | test/qa | beta | release/prod |
| --- | --- | --- | --- | --- |
| `HASTA_AUTH_GUEST_ENABLED` | true | true | true | true |
| `HASTA_AUTH_GOOGLE_SIGNIN_ENABLED` | **false** | **false** | **false** | **false** |
| `HASTA_AUTH_GOOGLE_LINK_ENABLED` | true | true | true | true |
| `HASTA_AUTH_APPLE_LINK_ENABLED` | false | false | false | false |
| `HASTA_QUICK_TEST_ACCOUNTS_ENABLED` | true | true | true | **false** |
| `HASTA_DEVICE_COOLDOWN_ENABLED` | false | false | true | true |
| `HASTA_NSFW_SCAN_ENABLED` | mock | mock | true | true |
| `HASTA_STORE_VERIFICATION_MODE` | mock | sandbox | sandbox | production |

**Seeded test accounts** (`tools/scripts/seed-test-accounts.ts`, idempotent, runs on `test`/`beta` backend only):

| Handle | Purpose | Notes |
| --- | --- | --- |
| `tester.a` / `tester.b` | dating match pair | both 18+, verified, interest overlap, same geohash band |
| `tester.social` | feed/group/page flows | 12 friends, 2 groups, 1 page |
| `tester.premium` | entitlement + restore | mock-store active subscription |
| `tester.minor` | 18+ gate | birth_date < 18 → dating blocked |
| `tester.fresh` | clean guest | no data, no linked identity |

Access in test builds: welcome screen → long-press logo 3 s → `Quick test accounts` sheet → tap a handle → immediate session (no OTP, no email, no password). The sheet also offers `Reset this account's data` and `Connect Gmail (test)` which runs the real linking flow against the test OAuth client.

**Guards:** the panel is compiled out of release builds (T36); seeding endpoints return 404 unless `HASTA_ENV in (dev,test,beta)`; seeded accounts cannot be created in production; the Gmail link flow used from the panel is the *same* production code path (so linking is genuinely tested).

**Gmail connectivity test procedure (the phase goal):**
1. Build `beta` (or `dev`) with a Google OAuth client of type iOS/Android + a web client for the token exchange; set `HASTA_GOOGLE_CLIENT_ID`, `HASTA_GOOGLE_CLIENT_SECRET`, `HASTA_GOOGLE_REDIRECT_URI`.
2. Launch app → one-tap `Continue` → guest session (verify `is_guest=true` in `/v1/me`).
3. `Settings → Account → Linked accounts → Connect Gmail` → consent → verify `is_guest=false`, masked email shown, `identities` row created.
4. Verify Premium purchase becomes available (T21 → T44).
5. Sign out, wipe app data, re-install → `Recover with Gmail` path → verify same account, new device binding, old sessions revoked (T30).
6. Unlink → verify Premium purchase blocked again but existing entitlement survives to expiry.
7. Negative: link the same Gmail to a second account → expect 409 (T38); offline attempt → disabled state (T43).

---

## 20. Open Decisions & Assumptions

| # | Item | Status | Needed from |
| --- | --- | --- | --- |
| 20.1 | Undo/restore during the 30-day grace period | **Open** — decide before Sprint 9; if yes, re-check cooldown interaction | PO + Legal |
| 20.2 | Purge window 30 d and backup expiry 35 d | **Proposal** — must be confirmed against store account-deletion policy and local law | Legal + Store policy |
| 20.3 | Evidence retention 30 d (+30 d appeal, legal hold) | **Proposal** — re-review against child-safety and lawful-request obligations | Legal |
| 20.4 | Drive backup inclusion (Google restricted-scope verification cost/time; CloudKit container cost) | **Open** — if deferred, Settings → Data download ships as export-to-file only | PO + DevOps |
| 20.5 | Cooldown model (device-only vs +provider-sub vs +IP/Play Integrity) | **Deferred** to after 1 month of abuse-log data | PO + Security |
| 20.6 | Super Like daily cap (1/2), Undo cap (5/day), opener limit (3), dormant window (7 d) | **Proposals** — validate in the 5-user prototype test, then freeze | PO + Design |
| 20.7 | Feed and dating score weights | **Proposals** — remote-config tunable, A/B before launch | PO + Data |
| 20.8 | Apple identity link UI | **Deferred to v1.1** (schema and endpoints ready, flag off) | PO |
| 20.9 | Voice/video call | **v1.1** | PO |
| 20.10 | Myanmar numerals default | Assumed off (Arabic default) per DS | Design |

**Assumptions the agent must not silently change:** no phone/OTP anywhere; no Google *sign-in* in v1; guest is a first-class production path (not only a dev hack); dating data is never visible to social surfaces; all retention numbers above are proposals pending legal sign-off, not legal advice.

---

## 21. Execution Instructions for the AI Agent

Build order (strict): **Sprint 0 → 1 → 2 → …** as in §17.2. Do not implement dating before the chat engine passes T16/T17. Do not implement premium before identity linking passes T38–T44.

For every feature deliver:
1. DDL migration (backward-compatible) + rollback.
2. NestJS module (controller/service/DTO/guard) with OpenAPI annotations.
3. Flutter feature folder (`data|domain|presentation`) reading from Drift first (§11.1).
4. i18n keys for `my` and `en` (no hard-coded strings).
5. Semantic tokens only (generated from `Hasta_v1_Design_Tokens.json`).
6. Tests: unit for rules, integration for the endpoint, E2E if it is a critical flow; mapped to a test-matrix ID.
7. All 5 UI states (loading/empty/error/offline/permission-denied) where applicable.
8. ADR entry if any decision deviates from this document.

**Hard prohibitions:**
- No dependency outside §4 without an ADR.
- No manual DDL; migrations only.
- No renaming `.env` variables.
- No skipping authorisation checks defined here.
- No hard-coded passwords, keys, tokens, or hex colours.
- No logging of tokens, emails, message bodies, or raw device ids.
- No new Google/Apple **sign-in** path; linking only (§5.4).
- No phone/OTP/SMS code, endpoint, dependency, or copy.
- No dating data in any social-facing response or notification payload.
- No client-side entitlement decisions; server verification only.
- Idempotency is mandatory on every state-changing write endpoint.
- Time types (`timestamptz`), PK types (UUIDv7), and enum casing are globally uniform — never mixed.
- Async ORM: no lazy loading; declare eager-loading explicitly.
- Test isolation: separate database and separate Redis DB index for tests; cleanup fixtures ordered by FK reverse.
- Docker services connect by service name, never `localhost`.
- Before writing the first feature, prove the framework combination with a minimal async end-to-end smoke test.

**Definition of Production-Ready for v1.0.0:** all Must-have features pass DoD · test matrix T1–T45 green · zero Critical/Major bugs · UAT signed off · SAST/DAST/dependency/secret scans clean · pen-test findings closed or risk-accepted in writing · perf budget met on a 2–3 GB RAM Android device · privacy policy, ToS, data-safety form, nutrition labels, account-deletion path published · monitoring, alerting, backup, DR and rollback runbooks live · legal review complete for retention windows (§20.1–20.3).

---

_End of Hasta v1.0.0 Master PRD (SPEC 1.0.0)._


<!-- ===== END Hasta_v1_Master_PRD.md ===== -->


---

<!-- ===== BEGIN Hasta_v1_API_Contract.md ===== -->

# Hasta v1.0.0 — API & Realtime Contract

Companion to `Hasta_v1_Master_PRD.md`. All paths are prefixed `/v1`. All request/response bodies are JSON. All timestamps are ISO-8601 UTC (`2026-11-23T09:30:00Z`). All ids are UUIDv7 strings. Enum literals are `snake_case` and identical in DB, API, and Dart.

## 0. Conventions

| Item | Rule |
| --- | --- |
| Auth | `Authorization: Bearer <access_token>` (JWT, 15 min). Refresh via `POST /v1/auth/refresh`. |
| Idempotency | Every state-changing POST/PATCH/DELETE accepts `Idempotency-Key: <uuidv7>`. Replay returns the stored body + `Idempotent-Replayed: true`. Keys retained 7 days. |
| Correlation | `X-Request-Id` echoed in every response and present in all logs. |
| Pagination | Cursor-based: `?cursor=<opaque>&limit=20` → response contains `next_cursor` (null when exhausted). |
| Rate limits | `429` + `Retry-After: <seconds>` + body `{code:"rate_limited"}`. |
| Errors | Uniform envelope (below). Never leak stack traces or internal ids. |
| Localisation | `Accept-Language: my | en` (default `my`). All server-provided user-facing copy is a key resolved client-side; only error codes come from the API. |

**Error envelope**

```json
{
  "error": {
    "code": "opener_limit",
    "message_key": "dating.openerLimit",
    "status": 429,
    "request_id": "018f6c2a-7b41-7a2e-9c31-2f6c1d5b9a11",
    "details": { "remaining": 0, "cleared_when": "counterparty_replies" },
    "retry_after_seconds": null
  }
}
```

Standard codes: `unauthenticated` · `forbidden` · `not_found` · `validation_failed` · `rate_limited` · `idempotency_conflict` · `device_cooldown` · `guest_exists_on_target` · `token_expired` · `token_used` · `identity_in_use` · `google_email_unverified` · `identity_required` · `opener_limit` · `chat_closed` · `chat_dormant` · `under_18` · `upload_too_large` · `nsfw_blocked` · `store_receipt_invalid` · `subscription_other_account` · `offline_only_online_action`.

---

## 1. Auth & Identity

### 1.1 `POST /v1/auth/device/register` — public
Registers the device and returns the hash. The raw id crosses the wire once, over TLS, and is **never persisted**.

Request
```json
{ "raw_device_id": "android-id-or-idfv", "platform": "android", "app_version": "1.0.0", "os_version": "14" }
```
Response `200`
```json
{ "device_hash": "9f2c…", "device_token": "dt_…", "platform": "android", "registered_at": "2026-11-23T09:30:00Z" }
```

### 1.2 `POST /v1/auth/guest` — public, rate limited (3 / device / hour)
Creates or resumes the guest account for this device.

Request
```json
{ "device_token": "dt_…", "locale": "my" }
```
Response `200`
```json
{
  "access_token": "eyJ…", "refresh_token": "rt_…", "expires_in": 900,
  "account": { "id": "018f…", "status": "active", "is_guest": true, "display_name": null, "username": null, "created_at": "2026-11-23T09:30:00Z" },
  "device_binding": { "id": "018f…", "role": "primary", "device_hash": "9f2c…", "bound_at": "2026-11-23T09:30:00Z" },
  "is_new_account": true
}
```
Errors: `429 device_cooldown` (`details.retry_after_days`), `403 validation_failed`, `429 rate_limited`.

### 1.3 `POST /v1/auth/refresh` — public
Request `{ "refresh_token": "rt_…", "device_token": "dt_…" }` → `200` new pair (old refresh invalidated). Reuse of a rotated token ⇒ `401 unauthenticated` and the whole token family is revoked.

### 1.4 `POST /v1/auth/logout` — auth
`{ "device_token": "dt_…", "everywhere": false }` → `204`.

### 1.5 `GET /v1/me` — auth
```json
{
  "account": { "id": "018f…", "status": "active", "is_guest": true, "created_at": "…" },
  "profile": { "display_name": "…", "username": "…", "bio": "…", "avatar_url": "…", "birth_date": "1998-04-02" },
  "identities": [ { "provider": "google", "email_masked": "h***@gmail.com", "linked_at": "…" } ],
  "entitlements": [ { "store": "google", "product_id": "hasta.premium.monthly", "status": "active", "expires_at": "…" } ],
  "flags": { "dating_enabled": false, "dating_paused": false, "premium": false, "test_mode_panel": false }
}
```

### 1.6 Gmail linking

`POST /v1/auth/identities/google/link:start` — auth
→ `200 { "state": "…", "nonce": "…", "scopes": ["openid","email","profile"], "auth_url": "https://accounts.google.com/o/oauth2/v2/auth?…", "expires_in": 300 }`

`POST /v1/auth/identities/google/link:complete` — auth
Request `{ "state": "…", "code": "…", "id_token": "…", "device_token": "dt_…" }`
→ `200 { "identity": { "provider": "google", "email_masked": "h***@gmail.com", "linked_at": "…" }, "account": { "id": "018f…", "is_guest": false }, "unlocked": ["premium_purchase","restore_purchases","device_recovery"] }`
Errors: `409 identity_in_use`, `422 google_email_unverified`, `401 token_expired` (state), `403 store_receipt_invalid`→n/a, `400 validation_failed`.

`DELETE /v1/auth/identities/google` — auth
→ `204`, or `409 {code:"recovery_required"}` when it is the only recovery method. Unlinking sets `is_guest=true`; existing paid entitlement survives to expiry (no refund).

> **Not implemented in v1:** `POST /v1/auth/google/signin`, `POST /v1/auth/apple/signin`, any `id_token`-only login, any OTP/SMS route. CI gate T37 fails the build if any appears.

### 1.7 Recovery (old device lost)

`POST /v1/auth/recover:start` — public → `{ "state":"…","nonce":"…","auth_url":"…" }` (Google only in v1)
`POST /v1/auth/recover:complete` — public → same shape as guest response, plus `"revoked_other_sessions": 3`. If no account matches the identity ⇒ `404 not_found` with copy guiding to guest creation.

### 1.8 QR device transfer

| Endpoint | Auth | Body | Result |
| --- | --- | --- | --- |
| `POST /v1/auth/transfer/start` | auth (old device) | `{}` | `200 { "transfer_id":"…", "qr_payload":"{\"v\":1,\"token\":\"tt_…\"}", "expires_at":"…(+120s)" }` — rate limit 2 / 3 min |
| `POST /v1/auth/transfer/redeem` | auth (new device) | `{ "token":"tt_…", "device_token":"dt_…" }` | `200 { "status":"awaiting_confirmation", "expires_at":"…" }` |
| `POST /v1/auth/transfer/confirm` | auth (old device) | `{ "transfer_id":"…", "biometric_verified": true }` | `200 { "status":"confirmed", "new_device_bound_at":"…", "revoked_sessions": 4 }` |
| `POST /v1/auth/transfer/reject` | auth (old device) | `{ "transfer_id":"…" }` | `200 { "status":"rejected" }` |
| `GET /v1/auth/transfer/:id` | auth | — | `200 { "status":"pending|awaiting_confirmation|confirmed|rejected|expired" }` |

Errors: `410 token_expired`, `409 token_used`, `409 guest_exists_on_target`, `403 biometric_required`.

### 1.9 Sessions & devices
`GET /v1/auth/sessions` → list `{id, device_hash_short, platform, created_at, last_seen_at, current}`.
`DELETE /v1/auth/sessions/:id` · `DELETE /v1/auth/sessions?others=true` → `204`.

### 1.10 Account lifecycle
`POST /v1/account/deactivate` — auth, online only → `200 { "status":"paused", "reactivate_by":"…" }`
`DELETE /v1/account` — auth, online only, requires `Confirm-Deletion: <typed phrase hash>` → `202 { "status":"deleted", "purge_at":"…(+30d)", "cooldown_until":"…(+30d)", "store_subscription_notice_key":"billing.cancelInStore", "drive_backup_action":"deleted|user_action_required" }`

---

## 2. Social

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| GET/PATCH | `/v1/profile` | self | read/update own profile (field-level HLC merge) |
| GET | `/v1/users/:id/profile` | any | public view — **never contains dating fields** |
| POST | `/v1/friends/requests` | auth | `{ "to_user_id":"…" }` → `201` |
| PATCH | `/v1/friends/requests/:id` | auth | `{ "action":"accept|decline" }` |
| GET | `/v1/friends?cursor=&limit=` | auth | list |
| DELETE | `/v1/friends/:userId` | auth | unfriend |
| POST | `/v1/posts` | auth | create (idempotent) |
| GET | `/v1/feed?cursor=&filter=all|friends|groups|pages` | auth | ranked feed, page size 20 |
| GET | `/v1/posts/:id` | auth | detail (audience-checked) |
| PATCH/DELETE | `/v1/posts/:id` | author | edit within 15 min / delete (`scope=me|everyone`) |
| PUT/DELETE | `/v1/posts/:id/reactions` | auth | `{ "kind":"like|love|care|haha|wow|sad" }` |
| GET/POST | `/v1/posts/:id/comments` | auth | depth ≤ 2 |
| GET/POST | `/v1/groups`, `/v1/groups/:id/members` | auth | groups |
| GET/POST | `/v1/pages`, `/v1/pages/:id/posts` | auth | pages |
| GET | `/v1/search?q=&type=users|posts|groups|pages&cursor=` | auth | Meilisearch-backed; offline falls back to a bundled index |
| GET/PATCH | `/v1/notifications`, `/v1/notifications/read` | auth | **social actions only** |
| POST/DELETE | `/v1/blocks` | auth | `{ "user_id":"…", "scope":"all|social|dating" }` |
| POST | `/v1/reports` | auth | see §6 |

**`POST /v1/posts` request**
```json
{
  "audience": "friends",
  "container_id": null,
  "body": "မင်္ဂလာပါ",
  "media": [ { "key": "media/018f….webp", "kind": "photo", "width": 1080, "height": 1350, "blurhash": "LKO2?l%2…" } ]
}
```
**Feed item response (abridged)**
```json
{
  "id": "018f…", "author": { "id":"018f…", "display_name":"မိုး", "avatar_url":"…", "is_page": false },
  "audience": "friends", "body": "…", "media": [ { "url":"…", "thumb_url":"…", "aspect":"4:5", "blurhash":"…" } ],
  "counts": { "reactions": 12, "comments": 3, "shares": 1 },
  "my_reaction": "like", "created_at": "…", "edited_at": null,
  "ranking_debug": null
}
```
`ranking_debug` is populated **only** in `dev`/`test` builds.

---

## 3. Chat engine

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/v1/chats?folder=all|private|group|channel|dating|unread|pinned|archived&cursor=` | auth | chat list; dating folder only when dating is on |
| POST | `/v1/chats` | auth | `{ "type":"private|group|channel", "member_ids":[…] }` (dating chats are created **only** by the match flow) |
| GET | `/v1/chats/:id/messages?before_seq=&limit=50` | member | history |
| POST | `/v1/chats/:id/messages` | member | send (idempotent) |
| PATCH | `/v1/chats/:id/messages/:msgId` | author | edit ≤ 15 min |
| DELETE | `/v1/chats/:id/messages/:msgId?scope=me|everyone` | author | delete; dating chat accepts `everyone` only |
| POST | `/v1/chats/:id/read` | member | `{ "up_to_seq": 128 }` → emits read receipts if enabled |
| PATCH | `/v1/chats/:id/settings` | member | mute, pin, folder, read-receipt toggle |
| POST | `/v1/media/uploads:init` | auth | `{ "kind":"photo|video|voice|file", "size":1234, "mime":"image/webp", "checksum_sha256":"…" }` → `{ "upload_id":"…", "parts":[{ "index":1, "url":"…" }], "max_size":20971520 }` |
| POST | `/v1/media/uploads/:id/complete` | auth | `{ "etags":[…] }` → `{ "key":"…", "thumb_url":"…", "blurhash":"…", "nsfw": { "score":0.02, "action":"pass" } }` |

**Send message request**
```json
{ "client_msg_id": "018f…", "kind": "text", "body": "မင်္ဂလာပါ", "reply_to": null }
```
**Send message response**
```json
{ "id":"018f…", "chat_id":"018f…", "seq":129, "status":"sent", "created_at":"…" }
```
Dating-chat failures: `429 opener_limit` (`details.remaining`), `403 chat_closed` (unmatched), `423 chat_dormant` (reopen required), `403 forbidden` (not matched).

---

## 4. Sync

`GET /v1/sync/changes?cursor=<opaque>&entities=messages,chats,profiles,posts,notifications,dating&limit=500`

```json
{
  "cursor": "eyJzZXEiOjEyOX0",
  "has_more": false,
  "server_time": "2026-11-23T09:30:00Z",
  "changes": {
    "messages": [ { "op":"upsert", "data": { "id":"…", "chat_id":"…", "seq":129, "kind":"text", "body":"…", "status":"delivered" } } ],
    "chats":    [ { "op":"patch",  "id":"018f…", "fields": { "last_seq":129, "unread":2 } } ],
    "profiles": [ { "op":"patch",  "id":"018f…", "fields": { "bio":"…" }, "hlc": 1732353000123 } ],
    "dating":   [ { "op":"upsert", "data": { "match_id":"…", "state":"matched" } } ],
    "deletions":[ { "entity":"messages", "id":"018f…", "scope":"everyone" } ]
  }
}
```
Rules: field-level patches only; `hlc` present on every mergeable entity; clients must apply changes inside a Drift transaction and persist `cursor` atomically with the data.

`POST /v1/sync/push` (outbox drain) — accepts a batch (≤ 50 ops) of `{ entity, op, idempotency_key, payload, hlc }`, returns per-op results `{ key, status:"applied|duplicate|rejected", server_hlc }`.

---

## 5. Dating

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| GET/PUT | `/v1/dating/profile` | self | separate entity; PUT is field-level HLC merge |
| POST | `/v1/dating/enable` | self | requires age ≥ 18 → else `403 under_18` |
| POST | `/v1/dating/pause` | self | `{ "paused": true }`; propagates ≤ 60 s |
| POST | `/v1/dating/verification` | self | selfie upload → `verification: pending|verified|rejected`; images stored on the restricted path |
| GET | `/v1/dating/cards?limit=10` | self | candidate stack (filters + scoring applied server-side) |
| POST | `/v1/dating/swipes` | self | `{ "to_user_id":"…", "kind":"like|pass|super_like|undo" }` (idempotent) |
| GET | `/v1/dating/likes/incoming?cursor=` | self | Likes You |
| GET | `/v1/dating/matches?cursor=` | self | Matches |
| POST | `/v1/dating/matches/:id/unmatch` | self | closes chat both sides, sets `retain_until = now()+30d` |
| POST | `/v1/dating/matches/:id/reopen` | self | reopen a dormant chat |
| GET | `/v1/dating/radar?radius_km=5` | self | **banded distance only** |
| PATCH | `/v1/dating/settings` | self | filters, radar visibility, show distance, read receipts, notifications |
| POST | `/v1/dating/profile/reset` | self | destructive, confirm required |

**`GET /v1/dating/cards` response**
```json
{
  "cards": [
    {
      "user_id": "018f…", "display_name": "…", "age": 26,
      "photos": [ { "url":"…", "aspect":"4:5", "blurhash":"…" } ],
      "bio": "…", "interests": ["ခရီးသွား", "ကော်ဖီ"], "occupation": null,
      "verified": true, "distance_band": "within_1km", "prompt": { "q":"အကြိုက်ဆုံး ခရီးစဉ်", "a":"…" }
    }
  ],
  "quota": { "super_like_remaining": 1, "undo_remaining": 5 },
  "next_cursor": null
}
```
`distance_band ∈ { "within_1km", "~3km", "~5km", "~10km", "hidden" }`. **No `lat`, `lon`, or metre-precision distance may appear in any response** (test T12).

**`POST /v1/dating/swipes` response**
```json
{ "result":"like_recorded", "matched": true, "match": { "id":"018f…", "chat_id":"018f…", "matched_at":"…" } }
```
On match the server also emits `match.created` (WS) and a privacy-safe push.

**`GET /v1/dating/radar` response**
```json
{ "updated_at":"…", "radius_km":5, "people":[ { "token":"p_…", "distance_band":"~3km", "avatar_blurred_url":"…", "verified":true } ], "cached": false }
```
Offline: `200` with the last cached payload and `"cached": true, "cached_at": "…"`.

---

## 6. Safety & moderation

`POST /v1/reports`
```json
{ "target_type":"message", "target_id":"018f…", "reason":"money_request", "detail":"…", "context": { "chat_id":"018f…" } }
```
→ `201 { "report_id":"…", "severity":"high", "status":"open", "sla_due_at":"…" }`

`reason ∈ { harassment, spam, scam, money_request, nudity, child_safety, violence, extortion, fake_profile, other }`. `child_safety | violence | extortion` ⇒ `severity=critical`, human moderator within 24 h. Evidence snapshot is written to the vault automatically.

Moderator/legal endpoints (`/v1/admin/**`) require role `moderator` or `legal`; every vault read writes an access-log entry; non-authorized access ⇒ `403` (T34).

---

## 7. Billing

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/v1/billing/products` | auth | catalogue with localised prices |
| POST | `/v1/billing/purchase:intent` | auth | `{ "product_id":"…", "store":"google|apple" }` → `{ "client_account_token":"<account uuid>" }` (use as `obfuscatedAccountId` / `appAccountToken`). Guests ⇒ `403 identity_required` (T21). Online only. |
| POST | `/v1/billing/purchase:verify` | auth | `{ "store":"…", "receipt":"…|purchase_token":"…", "product_id":"…" }` → server verifies with the store API → `{ "entitlement": { "status":"active", "expires_at":"…" } }` |
| POST | `/v1/billing/restore` | auth | online only → `{ "restored": 1, "entitlements":[…], "rejected":[{ "reason":"subscription_other_account" }] }` |
| POST | `/v1/billing/webhooks/apple` · `/google` | signed | notifications → update `status`, `last_verified_at`; refunds ⇒ `revoked` (T24) |

State machine: `pending → active → (grace → active|expired) | revoked`. Direct `pending → revoked` transitions are forbidden except on a verified refund/fraud signal.

---

## 8. WebSocket (Socket.IO) contract

Namespace `/rt`. Auth: `auth: { token: "<access_token>", device_token: "dt_…" }`. Rooms: `user:{accountId}`, `chat:{chatId}`, `device:{deviceHash}`. Reconnect: exponential backoff with jitter (1 s → 60 s cap) + immediate retry on connectivity change; after reconnect the client **must** run `GET /v1/sync/changes` before trusting local state. Heartbeat 25 s ping / 60 s pong timeout.

| Event (server → client) | Payload | Notes |
| --- | --- | --- |
| `message.new` | `{ chat_id, id, seq, sender_id, kind, body?, media?, created_at, chat_type }` | `chat_type` drives badge channel |
| `message.status` | `{ chat_id, id, status: "sent|delivered|read" }` | `read` only if the recipient's read receipts are on |
| `message.deleted` | `{ chat_id, id, scope: "me|everyone" }` | |
| `message.edited` | `{ chat_id, id, body, edited_at }` | |
| `chat.typing` | `{ chat_id, user_id, typing: true|false }` | 4 s TTL |
| `chat.updated` | `{ chat_id, fields: {…} }` | |
| `chat.closed` | `{ chat_id, reason: "unmatched|blocked" }` | client must drop the subscription **and** purge local cache |
| `chat.dormant` | `{ chat_id, dormant: true, reopen_allowed: true }` | |
| `match.created` | `{ match_id, chat_id, peer: { display_name_first_initial:"M", verified:true }, prompt? }` | **no full name, no photo** |
| `dating.profile_paused` | `{ paused: true }` | |
| `notification.new` | `{ id, kind, payload }` | social kinds only; dating kinds go to `dating.notification.new` |
| `dating.notification.new` | `{ id, kind: "match|likes_you|message", chat_id? }` | separate channel, separate badge |
| `session.revoked` | `{ reason: "transfer|password_change|admin|reuse_detected" }` | client must sign out immediately |
| `transfer.confirm_required` | `{ transfer_id, target_device_label, expires_at }` | old device |
| `sync.cursor_invalid` | `{}` | client must full-resync that entity class |
| `moderation.action` | `{ target_type, target_id, action }` | content removed by moderators |

Client → server: `chat.join {chat_id}` · `chat.leave {chat_id}` · `message.ack {chat_id, up_to_seq}` · `typing {chat_id, typing}` · `presence {state}`.

**Presence:** `online` written to Redis with 60 s TTL; last-seen is bucketed (`just_now | minutes | hours | day | days | week_plus`) before being exposed, per privacy settings.

Push (FCM/APNs) payload is privacy-safe: `{ "title": "Hasta", "body_key": "push.match.generic", "data": { "type": "match", "chat_id": "…" } }` — no name, no photo, no message text. Dating push uses a separate notification channel with its own sound/vibration settings.

---

## 9. OpenAPI

`docs/api/openapi.yaml` must be generated from the NestJS decorators and validated in CI (`spectral lint` + breaking-change detection against the previous tag). Any breaking change to `/v1` fails the build; ship `/v2` instead with ≥ 3-month deprecation.


<!-- ===== END Hasta_v1_API_Contract.md ===== -->


---

<!-- ===== BEGIN Hasta_v1_Design_Tokens.json ===== -->

{
  "$schema": "https://design-tokens.org/schema.json",
  "meta": {
    "product": "Hasta",
    "version": "1.0.0",
    "designSystem": "DS 1.0.0",
    "renamedFrom": "Nexus",
    "themes": ["light", "dark", "amoled", "highContrast", "dataSaver"],
    "defaultTheme": "light",
    "rule": "Components MUST reference semantic tokens only. Hard-coded hex in component code is a CI failure."
  },
  "tier1_raw": {
    "color": {
      "blue.50": "#EAF1FE",
      "blue.400": "#4C8DFF",
      "blue.500": "#2F6FED",
      "blue.600": "#2558C4",
      "pink.400": "#FF6B93",
      "pink.500": "#EF4B7B",
      "green.500": "#1FA971",
      "amber.400": "#F2A33C",
      "amber.500": "#E0A500",
      "red.500": "#E5484D",
      "neutral.0": "#FFFFFF",
      "neutral.50": "#F6F8FB",
      "neutral.100": "#EEF1F6",
      "neutral.200": "#E2E7EF",
      "neutral.400": "#8A93A2",
      "neutral.600": "#5B6472",
      "neutral.800": "#1B2432",
      "neutral.900": "#111827"
    }
  },
  "tier2_semantic": {
    "color": {
      "bg.canvas":          { "light": "#F6F8FB", "dark": "#0E1621", "amoled": "#000000", "use": "app background" },
      "bg.surface":         { "light": "#FFFFFF", "dark": "#16202C", "amoled": "#0B0B0B", "use": "card, list row" },
      "bg.surfaceRaised":   { "light": "#FFFFFF", "dark": "#1E2A38", "amoled": "#111111", "use": "sheet, sticky bar" },
      "bg.sunken":          { "light": "#EEF1F6", "dark": "#0A1219", "amoled": "#000000", "use": "input field, chat bg" },
      "bg.overlay":         { "light": "#1118278F", "dark": "#000000A3", "use": "modal scrim 56%/64%" },
      "bg.brandSubtle":     { "light": "#EAF1FE", "dark": "#16243D", "use": "selected row, mention" },
      "bg.dangerSubtle":    { "light": "#FDECEC", "dark": "#2A1518", "use": "destructive background" },
      "bg.datingSubtle":    { "light": "#FDECF1", "dark": "#2A1620", "use": "dating mode surface" },
      "text.primary":       { "light": "#111827", "dark": "#E8EDF4", "use": "body, title" },
      "text.secondary":     { "light": "#5B6472", "dark": "#9DA9BA", "use": "metadata, timestamp" },
      "text.tertiary":      { "light": "#8A93A2", "dark": "#6E7A8B", "use": "placeholder, disabled" },
      "text.onBrand":       { "light": "#FFFFFF", "dark": "#0B1220", "use": "on filled brand button" },
      "text.link":          { "light": "#2F6FED", "dark": "#4C8DFF", "use": "link, @mention" },
      "text.danger":        { "light": "#E5484D", "dark": "#FF6B70", "use": "error, delete" },
      "icon.primary":       { "light": "#1B2432", "dark": "#C9D3E0", "use": "default icon" },
      "icon.active":        { "light": "#2F6FED", "dark": "#4C8DFF", "use": "selected tab" },
      "border.subtle":      { "light": "#E2E7EF", "dark": "#243141", "use": "divider" },
      "border.strong":      { "light": "#CBD3DF", "dark": "#33445A", "use": "input border" },
      "border.focus":       { "light": "#2F6FED", "dark": "#4C8DFF", "use": "2px focus ring" },
      "accent.community":   { "light": "#1FA971", "dark": "#2FBF83", "use": "group badge" },
      "accent.market":      { "light": "#F2A33C", "dark": "#F2A33C", "use": "listing / seller" },
      "accent.dating":      { "light": "#EF4B7B", "dark": "#FF6B93", "use": "dating, match — dating module MUST use this token" },
      "state.online":       { "light": "#1FA971", "dark": "#2FBF83", "use": "presence dot" },
      "state.sending":      { "light": "#8A93A2", "dark": "#6E7A8B", "use": "clock icon (pending)" },
      "state.read":         { "light": "#2F6FED", "dark": "#4C8DFF", "use": "double check read" },
      "state.waiting":      { "light": "#E0A500", "dark": "#E0A500", "use": "offline queue" }
    },
    "contrast": {
      "bodyOnBg": 4.5,
      "largeTextOnBg": 3.0,
      "functionalIconOnBg": 3.0,
      "focusRingAdjacent": 3.0,
      "myanmarTextOnBg": { "min": 4.5, "note": "MANDATORY — thin diacritics make 3:1 insufficient" },
      "highContrastThemeText": 7.0,
      "rule": "Never encode meaning by colour alone: icon + text always (colour-blind safety)."
    }
  },
  "typography": {
    "fontStack": {
      "myanmar": "Noto Sans Myanmar (bundled; weights 400/500/600/700)",
      "myanmarFallback": "Padauk (bundled, off by default) -> system",
      "latin": "Inter (bundled)",
      "zawgyi": "NEVER bundled — detect -> convert -> render Unicode; one-time toast; legacy display toggle in Settings > Appearance (default off)"
    },
    "scale": {
      "display":    { "size": 28, "lineHeight": 40, "weight": 700, "letterSpacing": 0, "use": "onboarding title, match name" },
      "h1":         { "size": 24, "lineHeight": 36, "weight": 700, "letterSpacing": 0, "use": "screen title" },
      "h2":         { "size": 20, "lineHeight": 32, "weight": 600, "letterSpacing": 0, "use": "section header" },
      "subtitle":   { "size": 17, "lineHeight": 28, "weight": 600, "letterSpacing": 0, "use": "list primary, post author" },
      "body":       { "size": 15, "lineHeight": 26, "weight": 400, "letterSpacing": 0, "use": "post text, message" },
      "bodyStrong": { "size": 15, "lineHeight": 26, "weight": 600, "letterSpacing": 0, "use": "unread chat name" },
      "bodySm":     { "size": 14, "lineHeight": 24, "weight": 400, "letterSpacing": 0, "use": "comment, secondary" },
      "caption":    { "size": 13, "lineHeight": 22, "weight": 400, "letterSpacing": 0, "use": "timestamp, metadata" },
      "micro":      { "size": 11, "lineHeight": 18, "weight": 500, "letterSpacing": 0, "use": "badge count, tab label" },
      "overline":   { "size": 12, "lineHeight": 20, "weight": 600, "letterSpacing": 0.2, "use": "section label — NEVER uppercase" },
      "largeTextModeBody": { "size": 17, "note": "accessibility large-text mode" }
    },
    "myanmarRules": {
      "minLineHeightRatio": 1.65,
      "latinOnlyUiMinLineHeightRatio": 1.35,
      "wordBreak": "syllable segmenter, never per-character",
      "containerHeight": "min-height only, never fixed height",
      "overflow": "ellipsis only, never clip",
      "boldMaxWeight": 600,
      "headingBoldMaxWeight": 700,
      "inputVerticalPaddingExtra": 2,
      "questionMark": "glue to preceding syllable",
      "numerals": { "default": "arabic", "toggle": "myanmar (၁၂၃) in Settings > Appearance" }
    },
    "truncation": {
      "postBody": { "maxLines": 6, "affordance": "ဆက်ဖတ်ရန်" },
      "comment": { "maxLines": 4, "affordance": "ပိုကြည့်" },
      "chatListLastMessage": { "maxLines": 1, "affordance": "ellipsis" },
      "bubbleText": { "maxLines": null },
      "name": { "maxLines": 1, "affordance": "ellipsis" },
      "datingBio": { "maxLines": 3, "affordance": "ပိုကြည့်" }
    }
  },
  "spacing": {
    "base": 4,
    "scale": [0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64],
    "usage": {
      "screenHorizontalPadding": 16,
      "cardInnerPaddingFeed": 12,
      "cardInnerPaddingSettings": 16,
      "listRowVerticalPadding": 12,
      "avatarToText": 12,
      "sectionGap": 24,
      "stickyBarPadding": "12 + safe-area"
    }
  },
  "layout": {
    "breakpoints": {
      "compact": { "max": 599, "layout": "1 column + bottom nav" },
      "medium": { "min": 600, "max": 904, "layout": "navigation rail + 1.3 column feed, content max 640" },
      "expanded": { "min": 905, "layout": "rail + list-detail" }
    },
    "contentMaxWidth": 640,
    "lineLength": { "latinChars": 60, "myanmarSyllables": 40 },
    "density": {
      "comfortable": { "rowHeight": 68, "fontDelta": 0, "default": true },
      "compact": { "rowHeight": 56, "fontDelta": -1 }
    },
    "safeAreas": {
      "bottomNav": "12 + safe-area-bottom, must not touch gesture bar",
      "topBar": "56 + status bar",
      "keyboard": "ime-inset pushes input bar; auto-scroll or show 'နောက်ဆုံးသို့' pill"
    }
  },
  "shape": {
    "radius": { "xs": 6, "sm": 8, "md": 12, "card": 16, "sheet": 20, "pill": 999, "bubble": 16, "bubbleTail": 6 },
    "borderWidth": { "subtle": 1, "focus": 2 }
  },
  "elevation": {
    "e0": { "shadow": "none", "use": "flat list" },
    "e1": { "shadow": "0 1 2 rgba(17,24,39,.06)", "use": "card" },
    "e2": { "shadow": "0 4 12 rgba(17,24,39,.08)", "use": "sticky bar, FAB" },
    "e3": { "shadow": "0 8 24 rgba(17,24,39,.12)", "use": "sheet, dialog" },
    "e4": { "shadow": "0 16 40 rgba(17,24,39,.16)", "use": "popover menu" },
    "lowEndCap": "e3",
    "blurBackdrop": { "sheet": true, "dialog": false }
  },
  "motion": {
    "duration": { "instant": 100, "fast": 150, "base": 200, "slow": 320, "celebrate": 600 },
    "easing": {
      "standard": "cubic-bezier(0.2, 0, 0, 1)",
      "decelerate": "cubic-bezier(0, 0, 0.2, 1)",
      "accelerate": "cubic-bezier(0.4, 0, 1, 1)",
      "spring": { "stiffness": 320, "damping": 30, "use": "swipe card, sheet dismiss" }
    },
    "limits": { "concurrentAnimatedElements": 3, "listStaggerMax": 8, "indeterminateProgressMaxMs": 2000 },
    "reducedMotion": { "transitions": "fade only", "swipeCard": "cross-fade", "matchReveal": "static card" },
    "loading": { "pattern": "skeleton", "shimmerOnLowEnd": false, "textStateAfterMs": 3000, "skeletonRowsMax": 6 }
  },
  "hapticsSound": {
    "defaultSound": "off",
    "defaultHaptics": "on",
    "events": {
      "buttonPress": { "haptic": "light" },
      "reaction": { "haptic": "light", "sound": "subtle-off-default" },
      "messageSend": { "haptic": "light" },
      "messageReceiveInChat": { "haptic": "light-user-toggle", "sound": "off" },
      "swipeDecision": { "haptic": "medium" },
      "match": { "haptic": "success", "sound": "off-default" },
      "destructiveConfirm": { "haptic": "warning" },
      "error": { "haptic": "error" },
      "callRing": { "sound": "ringtone-system-like" }
    }
  },
  "iconography": {
    "grid": 24, "liveArea": 20, "stroke": 1.5, "capJoin": "round",
    "style": { "default": "outline", "active": "filled" },
    "sizes": [16, 20, 24, 28],
    "colors": ["icon.primary", "icon.active"],
    "customMyanmarSet": ["pagoda", "market", "monastic", "bus-station", "phone-call", "offline-transfer", "qr", "radar"],
    "rule": "icon-only buttons require tooltip + accessibility label; no ad-hoc hand-drawn icons"
  },
  "media": {
    "avatarList": { "aspect": "1:1", "size": 40, "format": "WebP", "variants": [40, 80, 120] },
    "avatarProfile": { "aspect": "1:1", "sizes": [96, 160], "format": "WebP" },
    "datingPhoto": { "aspect": "4:5", "size": "640x800", "format": ["WebP", "AVIF"] },
    "postImage": { "aspect": ["1:1", "4:5", "16:9"], "maxEdge": 1080, "format": "WebP" },
    "feedVideoPreview": { "aspect": "16:9", "maxSeconds": 8, "muted": true, "autoplay": false, "format": "HLS" },
    "sticker": { "aspect": "1:1", "size": 512, "format": "WebP-animated" },
    "story": { "aspect": "9:16", "size": "720x1280" },
    "placeholder": "BlurHash / LQIP before thumbnail",
    "crop": "face-aware, aspect-ratio hard-coded to prevent layout shift",
    "dataSaver": { "imageMaxPx": 320, "videoRequiresTap": true }
  },
  "performanceBudget": {
    "firstScreenInteractiveMs": 2500,
    "feedScrollFpsMin": 55,
    "initialImagesPerScreenKbMax": 800,
    "concurrentBlurShadowLayersMax": 2,
    "concurrentAnimatedViewsMax": 3,
    "fontFilesMax": 3,
    "apkSizeMbMax": 45,
    "coldStartMsMax": 2500,
    "skeletonRowsMax": 6,
    "targetDevice": "mid-range Android, 2-3GB RAM, 3G"
  },
  "navigation": {
    "bottomNavItems": [
      { "index": 1, "labelMy": "ပင်မ", "labelEn": "Home", "icon": "home", "badge": null },
      { "index": 2, "labelMy": "ရှာဖွေ", "labelEn": "Discover", "icon": "compass", "badge": null },
      { "index": 3, "labelMy": "ချတ်", "labelEn": "Chat", "icon": "chat", "badge": "unread count" },
      { "index": 4, "labelMy": "အသိပေး", "labelEn": "Notifications", "icon": "bell", "badge": "social actions only" },
      { "index": 5, "labelMy": "ပရိုဖိုင်", "labelEn": "Profile", "icon": "user", "badge": "friend request dot" }
    ],
    "maxItems": 5,
    "datingEntry": "Profile -> ❤ Dating only (never a tab)",
    "chatFolders": ["all", "private", "group", "channel", "dating", "unread"],
    "labelHideAboveTextScale": 1.3,
    "retapActiveTab": "scroll to top",
    "preserveTabScrollState": true
  },
  "components": {
    "total": 64,
    "tier1_foundation": ["Button", "IconButton", "FAB", "Chip/FilterChip", "SegmentedControl", "TabBar", "Switch", "Checkbox/Radio", "Slider", "TextField", "TextArea", "SearchField", "OTPInput (library only, unused in v1)", "Select/Dropdown", "DatePicker (+age preview)", "Divider", "Progress", "Skeleton", "Avatar (+presence, +dating ring, +verified)", "Badge", "Tooltip", "Snackbar (+offline variant)"],
    "tier2_compound": ["TopAppBar", "BottomNav", "NavigationRail", "ListItem", "SectionHeader", "Card", "BottomSheet", "Dialog", "ActionSheet", "PopoverMenu", "EmptyState", "ErrorState", "OfflineBanner", "PullToRefresh", "InfiniteScrollFooter", "Toast", "Stepper", "PhotoGrid", "MediaViewer", "ShareSheet", "VerificationBadge", "PresenceDot", "ReactionPill", "InfoRow"],
    "tier3_domain": ["PostCard", "PostComposer", "StoryRing", "StoryViewer", "CommentThread", "ReactionPicker", "MessageBubble", "ReplyPreview", "AttachmentTray", "VoiceRecorder", "StickerPanel", "TypingIndicator", "DateSeparator", "UnreadDivider", "MatchCard", "SwipeOverlay", "RadarView", "AddressPicker"],
    "buttonSizes": { "sm": 36, "md": 44, "lg": 52 },
    "buttonVariants": ["primary", "secondary", "ghost", "danger", "link"],
    "requiredStates": ["default", "pressed", "disabled", "loading", "focus"],
    "touchTarget": { "ios": 44, "android": 48, "visualMinPerWcag22": 24 },
    "documentationStandard": "anatomy, variants, sizes, states, tokens used, do/don't x2, a11y label, Myanmar text example, empty/loading/error",
    "matchCard": { "aspect": "4:5", "stackDepth": 3, "stackScale": [1, 0.94, 0.88], "stackOffsetY": [0, 8, 16], "actionBar": { "pass": 60, "undo": 44, "super": 48, "like": 60 } },
    "swipeOverlay": { "like": { "direction": "right", "color": "accent.community" }, "nope": { "direction": "left", "color": "text.danger" }, "super": { "direction": "up", "color": "icon.active" }, "rotateDeg": 12 },
    "messageBubble": { "maxWidthPct": 78, "tailPx": 6, "contentTypes": 12 },
    "radarView": { "rings": 3, "ownDot": "center", "others": "blurred avatar dot", "tap": "mini card" }
  },
  "stateMatrix": {
    "requiredStatesPerScreen": 4,
    "screens": {
      "feed": { "loading": "skeleton 3 cards", "empty": "အသိုင်းအဝိုင်းနဲ့ စတင်ပါ + join 5 groups CTA", "error": "retry + show cached", "offline": "cached + top banner" },
      "chatList": { "loading": "skeleton 6 rows", "empty": "စကားပြောမှု မရှိသေး + အဆက်အသွယ် ရှာရန်", "error": "retry", "offline": "cached" },
      "thread": { "loading": "skeleton 4 bubbles", "empty": "မက်ဆေ့ချ် စတင်ပါ", "error": "per-bubble ပြန်ပို့ရန်", "offline": "waiting badge" },
      "postDetail": { "loading": "skeleton", "empty": "မတွေ့ပါ / ဖျက်လိုက်ပြီ", "error": "retry", "offline": "cached", "permissionDenied": "ဒီပို့စ်ကို ကြည့်ခွင့် မရှိပါ" },
      "datingCards": { "loading": "card skeleton", "empty": "ကိုက်ညီသူ မရှိသေး — filter ချဲ့ပါ", "error": "retry", "offline": "အင်တာနက် လိုအပ်သည်", "permissionDenied": "verification pending" },
      "radar": { "loading": "radar placeholder", "empty": "အနီးတွင် မတွေ့ပါ — အကွာအဝေး တိုးပါ", "error": "retry", "offline": "last cached + timestamp", "permissionDenied": "township-level search" },
      "profile": { "loading": "skeleton", "error": "retry", "offline": "cached", "permissionDenied": "private account" },
      "settings": { "loading": "static", "error": "toast", "offline": "local only + ချိန်ညှိမှု သိမ်းမထားပါ" },
      "search": { "loading": "recent + suggestions", "empty": "ရှာမတွေ့ပါ + spelling hint", "error": "retry", "offline": "bundled offline index" },
      "linkedAccountsGmail": { "loading": "spinner during link flow", "empty": "မချိတ်ဆက်ရသေး + Connect CTA", "error": "မအောင်မြင်ပါ။ ပြန်ကြိုးစားပါ (E-…)", "offline": "disabled — online only", "permissionDenied": "OAuth cancelled -> return to sheet" }
    }
  },
  "copy": {
    "tone": "plain, respectful, encouraging; age-neutral (no ခင်ဗျား/ညီကို/အစ်ကို); formal-lite; light English loanwords allowed",
    "errorFormula": "[what happened] + [what to do] + [(hidden) error code]",
    "destructiveButtonRule": "verb only, never 'OK'; destructive action placed on the right in dialogs, last + red in action sheets",
    "glossary": {
      "Post": "ပို့စ်", "Comment": "မှတ်ချက်", "Share": "မျှဝေ", "Follow": "လိုက်ကြည့်",
      "Friend request": "သူငယ်ချင်း တောင်းဆို", "Match": "တွဲဖက်", "Nearby": "အနီးအနား",
      "Offline transfer": "အင်တာနက်မလိုဘဲ ပို့"
    },
    "forbidden": ["အပ်တင်", "ကွန်မန့်", "ရှဲ", "ဖော်လိုး", "ဖရန့်ရီကွက်", "မက်ချ်", "နီးဘိုင်း"],
    "formats": {
      "time": { "default": "24h (၁၉:၄၅)", "toggle": "12h" },
      "relative": ["၅ မိနစ်က", "မနေ့က", "၁၂ ရက်", "၁ နှစ်က"],
      "distance": ["၁ ကီလိုမီတာအတွင်း (<1km)", "~၃ ကီလိုမီတာ (band)"],
      "fileSize": "၂.၄ MB",
      "count": "၁,၂၄၅"
    },
    "keyStrings": {
      "welcome.primary": "စတင်အသုံးပြုရန်",
      "welcome.guestExplainer": "အီးမေးလ်၊ ဖုန်းနံပါတ် မလိုပါ။ ဤဖုန်းတွင် ချက်ချင်း စတင်နိုင်သည်။",
      "welcome.guestRisk": "ဖုန်းပျောက်ပါက ဤအကောင့်ကို ပြန်ရနိုင်မည် မဟုတ်ပါ။ Gmail ချိတ်ဆက်ထားရန် အကြံပြုသည်။",
      "settings.connectGmail": "Gmail ချိတ်ဆက်ရန်",
      "settings.gmailLinked": "ချိတ်ဆက်ပြီး — h***@gmail.com",
      "premium.guestBlocked": "Premium ဝယ်ယူရန် Gmail ချိတ်ဆက်ထားရပါမည်။",
      "offline.banner": "အင်တာနက်မရှိပါ။ ပို့ထားသော စာများကို ချိတ်ဆက်သည်နှင့် ပို့ပေးပါမည်။",
      "dating.openerLimit": "ဤချတ်တွင် နောက်ထပ် မက်ဆေ့ချ် ၁ ခုသာ ပို့နိုင်သေးသည်။ ဖြေကြားမှု ရရှိပါက ကန့်သတ်ချက် ပြေလျော့မည်။",
      "dating.under18": "Dating ကို အသက် ၁၈ နှစ်ပြည့်ပြီးမှ အသုံးပြုနိုင်ပါသည်။",
      "dating.unmatchTitle": "ဒီတွဲဖက်ကို ဖျက်မလား?",
      "dating.unmatchBody": "နှစ်ဖက်စလုံးအတွက် ချက်ချင်း ပိတ်သွားမည်။ လုံခြုံရေးအတွက် သက်သေ ၃၀ ရက် ထိန်းထားပါမည်။",
      "dating.unmatchAction": "ဖျက်သည်",
      "error.generic": "မအောင်မြင်ပါ။ ခဏနေမှ ပြန်ကြိုးစားပါ။ (E-500)",
      "error.uploadTooLarge": "ဖိုင် ကြီးလွန်းပါသည် (အများဆုံး ၂၀ MB)။ ဖိုင် သေးငယ်အောင် လုပ်ပါ။"
    }
  },
  "handoffChecklist": [
    "semantic tokens only (no hex in components)",
    "5 states per component",
    "Myanmar long-string test (2-stack / 3-stack glyphs)",
    "text scale 1.3x and 2.0x tested",
    "dark + AMOLED tested",
    "empty / loading / error / offline present",
    "a11y label + focus order defined",
    "touch target >= 44",
    "asset export WebP 1x/2x/3x + blurhash",
    "animation spec uses duration/easing tokens"
  ],
  "qaGate": {
    "hardCodedColors": 0,
    "screenStateCoverageMin": 4,
    "myanmarClipping": 0,
    "zawgyiTest": "pass",
    "contrastFails": 0,
    "lowEndFeedFpsMin": 55,
    "glossaryCompliancePct": 100
  },
  "governance": {
    "versioning": "MAJOR.MINOR.PATCH — token break = MAJOR",
    "changeRequest": "Figma comment + DS ticket, must list affected screens",
    "review": "2 designers + 1 engineer + 1 PM, weekly 30 min",
    "deprecation": "announced 1 release cycle ahead with migration note",
    "ownership": "DS Lead has final say on tokens",
    "documentation": "Storybook / Zeroheight, one page per component",
    "figmaNaming": { "component": "Component/Variant/Size/State e.g. Button/Primary/MD/Pressed", "page": "[Module] Screen Name — State e.g. Chat/Thread — Offline" },
    "figmaProperties": ["variant", "size", "state", "hasIcon", "iconPosition", "label", "leadingAvatar", "trailingBadge", "density", "isRTLsafe"]
  },
  "deliverables": [
    "Figma Foundations file (colour/type/space/motion variables)",
    "Component library 64 (all variants)",
    "Screen templates 12 (feed, thread, chat list, profile, settings, dating x5, geo x1)",
    "State matrix sheet",
    "Icon set (standard 120 + Myanmar-specific 20)",
    "Motion prototypes 8 (sheet, swipe, match, send, page transition)",
    "Handoff checklist + QA gate document"
  ],
  "screenCount": 68
}


<!-- ===== END Hasta_v1_Design_Tokens.json ===== -->
