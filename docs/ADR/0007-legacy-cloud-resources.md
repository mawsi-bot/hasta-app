# ADR-0007 — Legacy-named cloud resources stay out of T45 scope

Status: accepted (PR #2). T45 scans code and build artefacts, not cloud resource names; the paused Supabase project carrying the legacy name is left paused, unused, and must be renamed `hasta-legacy-archive` (or deleted) by the owner in the Supabase dashboard so no future export reintroduces the string.
