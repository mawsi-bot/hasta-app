# ADR-0003 — Field-level HLC on profiles

Status: accepted (Sprint 1)

## Decision
Offline edits merge per field using a hybrid logical clock. `profiles.field_hlc jsonb` maps field name → HLC string; `PATCH /v1/profile` accepts `hlc` and applies only fields whose incoming HLC is newer (last-writer-wins per field). Drift mirrors this in `LocalProfiles.fieldHlc`. This is a schema addition not listed in PRD §13.
