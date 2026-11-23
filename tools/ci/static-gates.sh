#!/usr/bin/env bash
# Repo-wide static gates: T20 (no OTP/SMS), hex gate, plus tools/ci/gates.mjs (T45, T48, T37 mobile boundary).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
fail=0
EXCL=(--glob '!**/node_modules/**' --glob '!**/build/**' --glob '!**/.dart_tool/**' --glob '!**/dist/**' --glob '!**/coverage/**' --glob '!**/*.lock' --glob '!**/package-lock.json' --glob '!tools/ci/static-gates.sh')

# T45 (allowlist), T48 (Postgres major 16), T37 mobile boundary: see tools/ci/gates.mjs.
node tools/ci/gates.mjs all || fail=1

# T20 — no OTP/SMS dependency in either app manifest.
if rg -n -i 'twilio|nexmo|vonage|messagebird|sms_autofill|sms_otp|otp_|pin_code_fields|firebase_auth' apps/mobile/pubspec.yaml apps/server/package.json; then
  echo "T20 FAIL: OTP/SMS dependency"; fail=1; else echo "T20 PASS (manifests)"; fi

# Hex gate — no hard-coded colours in app code outside the generated token file.
if rg -n "${EXCL[@]}" --glob '!apps/mobile/lib/core/design/tokens.dart' --glob '!**/*.g.dart' \
     -e 'Color\(0x[0-9A-Fa-f]{6,8}\)' -e "['\"]#[0-9A-Fa-f]{3,8}['\"]" apps/mobile/lib; then
  echo "HEX FAIL"; fail=1; else echo "HEX PASS"; fi

exit $fail
