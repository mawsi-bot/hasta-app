#!/usr/bin/env bash
# T47 — docs/api/openapi.json must lint clean (spectral, errors fail) and carry no breaking change
# versus the previous release tag (oasdiff). JSON is the accepted format (SPEC 1.0.1).
# Env: OASDIFF (binary path, default oasdiff), T47_SPEC (spec under test), T47_BASE_REF (override base).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
SPEC="${T47_SPEC:-docs/api/openapi.json}"
OASDIFF="${OASDIFF:-oasdiff}"

npx -y @stoplight/spectral-cli@6.17.1 lint "$SPEC" --ruleset .spectral.json --fail-severity error

BASE="${T47_BASE_REF:-$(git describe --tags --abbrev=0 --match 'v[0-9]*' HEAD 2>/dev/null || true)}"
if [ -z "$BASE" ]; then echo "T47 FAIL: no previous release tag (v*) to diff against"; exit 1; fi
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
git show "$BASE:docs/api/openapi.json" > "$TMP/base.json"
if "$OASDIFF" breaking "$TMP/base.json" "$SPEC" --fail-on ERR; then
  echo "T47 PASS (no breaking change vs $BASE)"
else
  echo "T47 FAIL: breaking change vs $BASE"; exit 1
fi
