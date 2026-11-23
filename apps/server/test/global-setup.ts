import { execSync } from 'node:child_process';
import './setup-env';

export default async function globalSetup(): Promise<void> {
  if (!/hasta_test/.test(process.env.HASTA_DATABASE_URL ?? '')) {
    throw new Error('Integration tests must run against the isolated hasta_test database');
  }
  execSync('npx prisma migrate reset --force --skip-generate --skip-seed', { stdio: 'ignore', env: process.env });
}
