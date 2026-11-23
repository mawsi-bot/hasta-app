# ADR-0005 — Primary action fill uses the `text.link` token alias

Status: superseded by ADR-0006 (DS 1.0.1 adds bg.brand)

## Context
`design-tokens.json` 1.0.0 has no `bg.brand`/`action.primary` colour. Hard-coded hex is forbidden.

## Decision
`HastaTheme` exposes `actionPrimary` as an alias of `text.link`, with `text.onBrand` for the label. The alias lives in hand-written theme code, while `tokens.dart` stays generated. When the DS adds a dedicated token, only the alias changes.
