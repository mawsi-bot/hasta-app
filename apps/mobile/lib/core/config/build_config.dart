/// Compile-time build configuration (`--dart-define` / `--dart-define-from-file`).
///
/// Values are `const` so the Dart compiler can tree-shake code behind them. In
/// particular the quick-test panel is unreachable — and therefore absent from
/// the binary — unless BOTH the flag is set AND the environment is dev/test/beta
/// (SPEC §19, CI gate T36).
abstract final class BuildConfig {
  /// dev | test | beta | staging | production
  static const String env = String.fromEnvironment('HASTA_ENV', defaultValue: 'dev');

  /// API origin, e.g. https://api.staging.hasta.app (no trailing slash).
  static const String apiBaseUrl = String.fromEnvironment('HASTA_API_BASE_URL');

  static const String appVersion = String.fromEnvironment('HASTA_APP_VERSION', defaultValue: '1.0.0');

  static const bool _quickTestFlag = bool.fromEnvironment('HASTA_QUICK_TEST_ACCOUNTS_ENABLED');

  static const bool isQaEnvironment = env == 'dev' || env == 'test' || env == 'beta';

  /// Quick test accounts panel (long-press logo 3 s on Welcome).
  static const bool quickTestAccountsEnabled = _quickTestFlag && isQaEnvironment;
}
