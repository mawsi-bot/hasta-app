#!/usr/bin/env node
// Applies prisma/migrations/<name>/rollback.sql through Prisma (no psql/manual DDL).
// Usage: npm run migrate:rollback -- <migration_name>
import { execFileSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join } from 'node:path';

const name = process.argv[2];
if (!name) {
  console.error('usage: migrate:rollback <migration_name>');
  process.exit(2);
}
const file = join('prisma', 'migrations', name, 'rollback.sql');
if (!existsSync(file)) {
  console.error(`no rollback script at ${file}`);
  process.exit(2);
}
if (process.env.HASTA_ENV === 'production' && process.env.HASTA_ROLLBACK_APPROVED !== 'true') {
  console.error('production rollback requires HASTA_ROLLBACK_APPROVED=true (manual approval gate)');
  process.exit(3);
}
execFileSync('npx', ['prisma', 'db', 'execute', '--file', file, '--schema', 'prisma/schema.prisma'], { stdio: 'inherit' });
console.log(`rolled back ${name}`);
