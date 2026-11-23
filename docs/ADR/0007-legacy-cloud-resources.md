# ADR-0007 — Legacy-named cloud resources stay out of T45 scope

Status: accepted (PR #2). T45 scans code and build artefacts, not cloud resource names; the paused Supabase project carrying the legacy name is left paused, unused, and must be renamed `hasta-legacy-archive` (or deleted) by the owner in the Supabase dashboard so no future export reintroduces the string.

Addendum (2026-11-23, PR #3 approval): the root `Hasta_v1_*.md` input copies and `skills/` are also out of T45 scope for now and are left as-is; T45 scans only the paths in `tools/ci/t45-allowlist.txt`.
