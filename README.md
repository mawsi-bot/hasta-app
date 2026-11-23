# Hasta v1.0.0

Myanmar-first social feed, chat and dating app. Flutter client and NestJS API. The spec lives in `Hasta_v1_Master_PRD.md` and `Hasta_v1_API_Contract.md`; build rules are in `skills/hasta-build/SKILL.md`.

## Layout
| Path | What |
|---|---|
| `apps/server` | NestJS 10 + Prisma 5 API (PostgreSQL 16 + PostGIS 3.4, Redis 7) |
| `apps/mobile` | Flutter 3.24 app (Riverpod, Drift, Dio) |
| `design/hasta-ds-1.0.2.json` | Design tokens; `tools/scripts/generate-tokens.mjs` generates `apps/mobile/lib/core/design/tokens.dart` |
| `infra/terraform` | AWS baseline (VPC, ECS Fargate, RDS, ElastiCache, S3, Secrets Manager) |
| `docs/` | ADRs, enum registry, OpenAPI, Myanmar copy-review queue |
| `tools/ci` | Static gates (T20/T37/T45/hex), T36 release-build check |

## Local development
```bash
cp apps/server/.env.example apps/server/.env   # placeholders only; fill in dev values
docker compose up -d postgres redis
docker compose up server                        # runs prisma migrate deploy, then the API on :3000
```

Seed the six QA accounts with `npm run seed:test-accounts` in `apps/server` (it refuses to run outside dev/test/beta).

Server tests need an isolated DB and Redis index: set `HASTA_TEST_DATABASE_URL` and `HASTA_TEST_REDIS_URL`, then run `npm run test:cov` in `apps/server`.

For mobile, run these in `apps/mobile`:
```bash
flutter pub get && dart run build_runner build
flutter run --dart-define-from-file=dart_defines/dev.json
```

Regenerate tokens after any DS change with `node tools/scripts/generate-tokens.mjs`. Never edit `tokens.dart` by hand.
