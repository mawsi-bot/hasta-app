# Hasta mobile

Flutter 3.24.5. Build flavours are selected with `--dart-define-from-file=dart_defines/{dev,beta,production}.json`.
The quick-test account panel only compiles in when `HASTA_ENV` is dev/test/beta and `HASTA_QUICK_TEST_ACCOUNTS_ENABLED=true` (T36; see `tools/ci/t36-release-panel.sh`).
