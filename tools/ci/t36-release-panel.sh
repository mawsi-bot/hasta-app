#!/usr/bin/env bash
# T36 — a release/production build must NOT contain the quick-test-account panel.
#
# Compiles the app twice with the panel flag forced ON:
#   1. HASTA_ENV=production  → marker must be ABSENT (env guard + tree shaking)
#   2. HASTA_ENV=beta        → marker must be PRESENT (positive control: proves
#                              the grep would catch a leak)
# Uses a throw-away web target (dart2js keeps string literals verbatim) so the
# check runs on any CI runner; mobile.yml repeats the check on the release APK.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MARKER="hasta-qa-quick-test-panel"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

rsync -a --exclude build --exclude .dart_tool "$ROOT/apps/mobile/" "$WORK/app/"
cd "$WORK/app"
flutter create --platforms web --project-name hasta --org app.hasta . >/dev/null
flutter pub get >/dev/null

build() {
  flutter build web --release --no-tree-shake-icons \
    --dart-define=HASTA_ENV="$1" \
    --dart-define=HASTA_QUICK_TEST_ACCOUNTS_ENABLED=true \
    --dart-define=HASTA_API_BASE_URL=https://api.example.invalid >/dev/null
  grep -c "$MARKER" build/web/main.dart.js || true
}

prod=$(build production)
beta=$(build beta)
echo "T36 marker hits — production: ${prod}, beta (control): ${beta}"
if [ "${prod}" != "0" ]; then echo "T36 FAIL: quick-test panel present in production build"; exit 1; fi
if [ "${beta}" = "0" ]; then echo "T36 FAIL: positive control did not find the marker (check is blind)"; exit 1; fi
echo "T36 PASS"
