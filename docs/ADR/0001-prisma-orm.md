# ADR-0001 — Prisma as the server ORM and migration tool

Status: accepted (Sprint 1)

## Context
The locked stack says "NestJS + Postgres 16" but leaves the ORM open. Hard rule: no manual DDL; every schema change ships as a migration with a rollback.

## Decision
Use Prisma 5.22 repo-wide. `prisma/schema.prisma` is the model of record; migrations live in `prisma/migrations/<ts>_<name>/migration.sql` with a sibling `down.sql` applied by `npm run migrate:rollback`. CHECK constraints and partial indexes that Prisma cannot express are added inside the generated migration SQL, and CI runs `prisma migrate diff --exit-code` so the schema and migrations cannot drift.

## Consequences
- Advisory locks and row-level locking use `$queryRaw` with tagged templates (parameterised, no string concatenation).
- No lazy loading: every relation is fetched with explicit `select`/`include`.
