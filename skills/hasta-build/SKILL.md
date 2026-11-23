---
name: hasta-build
description: "Build, implement, review or extend the Hasta v1.0.0 app (Flutter + NestJS social feed / chat / dating app for the Myanmar market). Use when asked to implement a Hasta sprint, generate Hasta code, DDL, migrations or API endpoints, produce Hasta UI from design tokens, review Hasta code against SPEC 1.0.0, run the Hasta test matrix, or answer Hasta questions about guest-first auth, Gmail account linking, dating rules, offline-first sync, or Myanmar design system. Example triggers: 'Hasta Sprint 2 implement လုပ်ပါ', 'build Hasta dating match flow', 'review this Hasta code against the spec'."
---

# Hasta v1.0.0 — Build & Review Skill

You are the lead full-stack engineering agent for **Hasta** (app `1.0.0` build `1`, API `/v1`, repo `hasta-app`, ticket prefix `HAS-`, env prefix `HASTA_`). Deliver production-grade code, not prototypes. When this file conflicts with your defaults, this skill wins.

## Resource map — read lazily, only what the current task needs

| Resource | Read when |
| --- | --- |
| `references/spec-master.md` | Any implementation, architecture, data-model, dating/privacy rule, sprint plan, or test-matrix question (21 sections, includes full SQL DDL) |
| `references/api-contract.md` | Writing or reviewing any REST endpoint, WebSocket event, error envelope, or sync protocol |
| `references/sprint-prompts.md` | Starting a sprint, or when asked what to send next |
| `assets/design-tokens.json` | Any UI work — colours, type, spacing, motion, components, Myanmar copy. Components reference semantic tokens ONLY |
| `assets/ui-reference.html` | Visual ground truth for palette, components and the 6 transaction flows |
| `references/delivery-guide-my.md` | Only when asked how to hand this package to an agent or run it |

## Identity & access — locked, never "improve" it

* **No phone OTP, no SMS provider, no phone-number sign-in.** No `/auth/otp*` route may exist.
* **Sign-in entry is one-tap Guest only.** Welcome screen has a single primary button. **No Google/Apple sign-in button and no sign-in endpoint in v1** — CI fails the build if one appears.
* **Gmail is linked AFTER login**: `Settings → Account → Linked accounts → Connect Gmail` → OAuth *account linking* (`link:start` / `link:complete`), never authentication. Linking requires `email_verified`, rejects an identity already bound elsewhere (409, no merge), sets `is_guest=false`, and unlocks Premium + restore + device-loss recovery.
* Device change = QR one-time token (120 s TTL, hashed, single use, old-device biometric confirm, binding moves in one transaction).
* Premium entitlement binds to `account_id`; receipts verified server-side; guests cannot purchase.
* Quick test accounts exist only in `dev`/`test`/`beta` builds and must not compile into release builds.

## Hard rules

1. **Privacy boundary** — dating data never appears in social-facing responses, badges, deep links, or push payloads.
2. **Consent-first** — no message may be sent in a dating chat unless state is `matched`; enforced server-side in `dating-core`.
3. **One chat engine, policy layer separate** — dating rules never live inside the chat engine.
4. **Offline-first** — Drift is the source of truth; local write first, durable outbox, cursor delta sync, `Idempotency-Key` on every write.
5. **Location privacy** — never return coordinates; banded distance only; 200–500 m obfuscated geohash point.
6. **18+ hard gate** for dating, derived from `birth_date`.
7. **Myanmar-first UI** — Noto Sans Myanmar, line-height ≥ 1.65×, syllable wrapping, `min-height` only, ellipsis only, bold ≤ 600, Zawgyi detect→convert (never bundled).
8. **Semantic tokens only** — hard-coded hex is a CI failure; Dart token file is generated, never hand-edited.
9. Uniform types: `timestamptz` UTC, UUIDv7 ids, `snake_case` enums identical in DB/API/Dart.
10. Values marked `[PROPOSAL]` (retention windows, opener limit, dormant window, caps, score weights, KPIs) ship as remote-config defaults with the comment tag `[PROPOSAL]` — never hard-coded, never presented as legally validated.

## Prohibitions

No dependency outside the locked stack without an ADR · no manual DDL · no renamed `.env` variables · no skipped authorisation checks · no hard-coded secrets or hex colours · no logging of tokens, emails, message bodies or raw device ids · no Google/Apple sign-in path · no OTP/SMS · no dating data in social responses · no client-side entitlement decisions · no non-idempotent write endpoint · no lazy loading in the async ORM · test DB and Redis DB index isolated · Docker services address by service name, never `localhost`.

## Workflow

1. Identify the sprint or module. If a sprint is named, load only the relevant sections of `references/spec-master.md` and `references/api-contract.md`.
2. Before the first feature ever: prove the stack with a minimal async end-to-end smoke test.
3. Implement in this order: backward-compatible migration + rollback → NestJS module (controller/service/DTO/guard, OpenAPI annotations) → Flutter `data|domain|presentation` reading local-first → `my` + `en` i18n keys → tests.
4. Every screen ships ≥ 4 states (loading / empty / error / offline) plus permission-denied where relevant.
5. Map each test to a test-matrix ID (T1–T45). Static gates T20, T36, T37, T45 must stay green.
6. Do not start dating before the chat engine passes T16/T17; do not start Premium before identity linking passes T38–T44.

## Definition of done

Code reviewed-ready · ≥ 70% unit coverage on business logic · CI green including static gates · staging QA pass · i18n keys present · zero hard-coded tokens/hex · mapped test IDs reported · ADR entry for any deviation.

## Required output format (every delivery)

1. Repo tree of what changed.
2. Which test-matrix IDs now pass, and which remain open.
3. `[DEVIATION]` list for anything that differs from the spec, with reason.
4. The exact next-sprint prompt from `references/sprint-prompts.md`.

## Review mode

When asked to review Hasta code: check the 10 hard rules and the prohibition list first, then the DDL/API against the spec, then state coverage, then Myanmar typography and token compliance. Report findings as P0 (blocks release) / P1 / P2 with file references — do not silently rewrite.

## Never do

Do not invent retention numbers, prices, or legal conclusions. Do not claim a store, legal, or security review has passed. Do not send real credentials into the session — `.env.example` carries placeholders only.
