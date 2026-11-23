#!/usr/bin/env bash
# Repo-wide static gates. T20 (no OTP/SMS), T37 (no Google/Apple sign-in), T45 (legacy brand name), hex gate.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
fail=0
SCAN=(apps infra tools .github design docs)
EXCL=(--glob '!**/node_modules/**' --glob '!**/build/**' --glob '!**/.dart_tool/**' --glob '!**/dist/**' --glob '!**/coverage/**' --glob '!**/*.lock' --glob '!**/package-lock.json' --glob '!tools/ci/static-gates.sh' --glob '!docs/Hasta_v1_*.md')

# T45 — the legacy product name must not appear in shipped code/assets. Pattern built by concatenation so
# this script does not match itself. Root spec docs and skills/ are historical inputs and are excluded.
LEGACY="nex""us"
if rg -n -i "${EXCL[@]}" "$LEGACY" "${SCAN[@]}"; then echo "T45 FAIL: legacy name found"; fail=1; else echo "T45 PASS"; fi

# T20 — no OTP/SMS dependency in either app manifest.
if rg -n -i 'twilio|nexmo|vonage|messagebird|sms_autofill|sms_otp|otp_|pin_code_fields|firebase_auth' apps/mobile/pubspec.yaml apps/server/package.json; then
  echo "T20 FAIL: OTP/SMS dependency"; fail=1; else echo "T20 PASS (manifests)"; fi

# T48 — local compose DB must be postgres:16 (pinned), matching CI. Prevents local PG 18 vs CI 16 drift.
COMPOSE="${T48_COMPOSE:-docker-compose.yml}"
db_image=$(awk '/^  postgres:/{f=1;next} f&&/^  [a-z]/{f=0} f&&/image:/{print $2; exit}' "$COMPOSE")
if [[ "$db_image" =~ ^postgres:16(\.[0-9]+)*(@sha256:[0-9a-f]{64})?$ ]]; then echo "T48 PASS ($db_image)"; else echo "T48 FAIL: compose postgres image is '${db_image:-missing}', must be postgres:16"; fail=1; fi

# Hex gate — no hard-coded colours in app code outside the generated token file.
if rg -n "${EXCL[@]}" --glob '!apps/mobile/lib/core/design/tokens.dart' --glob '!**/*.g.dart' \
     -e 'Color\(0x[0-9A-Fa-f]{6,8}\)' -e "['\"]#[0-9A-Fa-f]{3,8}['\"]" apps/mobile/lib; then
  echo "HEX FAIL"; fail=1; else echo "HEX PASS"; fi

exit $fail
