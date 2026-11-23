# ADR-0006 — Primary button uses the DS 1.0.1 brand fill tokens

Status: accepted (PR #2). Supersedes ADR-0005.

## Decision
SPEC 1.0.1 §14.1 adds `bg.brand`, `bg.brandPressed` and `bg.brandDisabled`. `HastaButton` (primary) now resolves default → `bg.brand`, pressed → `bg.brandPressed`, disabled → `bg.brandDisabled`, with `text.onBrand` as the label. The `actionPrimary` alias to `text.link` is removed. `tokens.dart` is regenerated from `design/hasta-ds-1.0.1.json`; the generator turns a token-level `opacity` into the alpha channel.

## Notes
- The DS JSON gives `bg.brandDisabled` one `opacity: 0.4` for both themes, but PRD §14.1 says dark is @30%. The generator follows the JSON (the token source of truth). Open for the design owner.
- Measured contrast (DS `contrast.measured`): white on `bg.brand` is 4.95:1, white on `bg.brandPressed` is 6.24:1.
