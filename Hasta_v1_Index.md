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
