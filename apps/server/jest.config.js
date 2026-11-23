/** @type {import('jest').Config} */
const base = { preset: 'ts-jest', testEnvironment: 'node', rootDir: '.', setupFiles: ['<rootDir>/test/setup-env.ts'] };
module.exports = {
  testTimeout: 30000,
  projects: [
    { ...base, displayName: 'unit', testMatch: ['<rootDir>/test/unit/**/*.spec.ts'] },
    { ...base, displayName: 'static', testMatch: ['<rootDir>/test/static/**/*.spec.ts'] },
    {
      ...base,
      displayName: 'integration',
      testMatch: ['<rootDir>/test/integration/**/*.spec.ts'],
      globalSetup: '<rootDir>/test/global-setup.ts',
    },
  ],
  collectCoverageFrom: ['src/**/*.ts', '!src/main.ts', '!src/**/*.dto.ts', '!src/**/dto/*.ts'],
  coverageThreshold: { global: { lines: 70, branches: 60, functions: 70, statements: 70 } },
};
