// Test isolation: dedicated database (hasta_test) and Redis DB index 1 (SPEC §21).
// CI overrides host names with service names via env.
process.env.HASTA_ENV = process.env.HASTA_ENV ?? 'test';
process.env.HASTA_DATABASE_URL =
  process.env.HASTA_TEST_DATABASE_URL ?? 'postgresql://hasta:hasta@127.0.0.1:5432/hasta_test?schema=public';
process.env.HASTA_REDIS_URL = process.env.HASTA_TEST_REDIS_URL ?? 'redis://127.0.0.1:6379/1';
process.env.HASTA_DEVICE_PEPPER = 'test-pepper-0123456789abcdef0123456789abcdef';
process.env.HASTA_JWT_ACCESS_SECRET = 'test-access-0123456789abcdef0123456789abcdef';
process.env.HASTA_DEVICE_TOKEN_SECRET = 'test-device-0123456789abcdef0123456789abcdef';
process.env.HASTA_QUICK_TEST_ACCOUNTS_ENABLED = process.env.HASTA_QUICK_TEST_ACCOUNTS_ENABLED ?? 'true';
process.env.HASTA_DEVICE_COOLDOWN_ENABLED = 'true';
