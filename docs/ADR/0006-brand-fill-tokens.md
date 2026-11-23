# ADR-0006 — Primary button uses the DS 1.0.1 brand fill tokens

Status: accepted and closed (PR #2, ruling in SPEC 1.0.2). Supersedes ADR-0005.

## Decision
SPEC 1.0.1 §14.1 adds `bg.brand`, `bg.brandPressed` and `bg.brandDisabled`. `HastaButton` (primary) now resolves default → `bg.brand`, pressed → `bg.brandPressed`, disabled → `bg.brandDisabled`, with `text.onBrand` as the label. The `actionPrimary` alias to `text.link` is removed. `tokens.dart` is regenerated from `design/hasta-ds-1.0.2.json`; the generator turns a token-level `opacity` into the alpha channel.

## Notes
- Closed (SPEC 1.0.2): `bg.brandDisabled` is 40% opacity in both themes. The DS JSON is the single source of truth for token values; the PRD prose (dark @30%) was corrected to mirror it.
- Measured contrast (DS `contrast.measured`): white on `bg.brand` is 4.95:1, white on `bg.brandPressed` is 6.24:1.
