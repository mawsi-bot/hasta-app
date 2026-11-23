import { z } from 'zod';

/**
 * Environment contract. Variable names are part of the public deploy contract —
 * never rename them (SPEC §21 prohibitions). Secrets are placeholders in `.env.example` only.
 */
const bool = z
  .enum(['true', 'false'])
  .transform((v) => v === 'true');

export const HASTA_ENVS = ['dev', 'test', 'beta', 'staging', 'production'] as const;
export type HastaEnv = (typeof HASTA_ENVS)[number];
/** Environments where the quick-test panel + seeding endpoints may exist (SPEC §19). */
export const TEST_MODE_ENVS: readonly HastaEnv[] = ['dev', 'test', 'beta'];

const schema = z
  .object({
    HASTA_ENV: z.enum(HASTA_ENVS),
    HASTA_PORT: z.coerce.number().int().positive().default(3000),
    HASTA_DATABASE_URL: z.string().url(),
    HASTA_REDIS_URL: z.string().url(),
    /** AWS Secrets Manager secret id/ARN holding the JSON secret bundle. Required outside dev/test. */
    HASTA_SECRETS_ARN: z.string().optional(),
    HASTA_AWS_REGION: z.string().default('ap-southeast-1'),
    HASTA_DEVICE_PEPPER: z.string().min(32).optional(),
    HASTA_JWT_ACCESS_SECRET: z.string().min(32).optional(),
    HASTA_DEVICE_TOKEN_SECRET: z.string().min(32).optional(),
    /** Google OAuth web client (SPEC §19). The client secret lives in the Secrets bundle in deployed envs. */
    HASTA_GOOGLE_CLIENT_ID: z.string().min(1).optional(),
    HASTA_GOOGLE_CLIENT_SECRET: z.string().min(1).optional(),
    HASTA_GOOGLE_REDIRECT_URI: z.string().url().optional(),
    HASTA_AUTH_GUEST_ENABLED: bool.default('true'),
    HASTA_AUTH_GOOGLE_SIGNIN_ENABLED: bool.default('false'),
    HASTA_AUTH_GOOGLE_LINK_ENABLED: bool.default('true'),
    HASTA_AUTH_APPLE_LINK_ENABLED: bool.default('false'),
    HASTA_QUICK_TEST_ACCOUNTS_ENABLED: bool.default('false'),
    HASTA_DEVICE_COOLDOWN_ENABLED: bool.default('true'),
  })
  .superRefine((env, ctx) => {
    if (env.HASTA_AUTH_GOOGLE_SIGNIN_ENABLED) {
      ctx.addIssue({ code: 'custom', message: 'Google sign-in does not exist in v1 (SPEC D2). Must be false.' });
    }
    if (env.HASTA_AUTH_APPLE_LINK_ENABLED) {
      ctx.addIssue({ code: 'custom', message: 'Apple linking is deferred to v1.1 (SPEC D4). Must be false.' });
    }
    if (env.HASTA_QUICK_TEST_ACCOUNTS_ENABLED && !TEST_MODE_ENVS.includes(env.HASTA_ENV)) {
      ctx.addIssue({ code: 'custom', message: 'Quick test accounts are forbidden outside dev/test/beta (T36).' });
    }
    if ((env.HASTA_ENV === 'staging' || env.HASTA_ENV === 'production') && !env.HASTA_SECRETS_ARN) {
      ctx.addIssue({ code: 'custom', message: 'HASTA_SECRETS_ARN is required in staging/production (pepper lives in Secrets Manager).' });
    }
  });

export type Env = z.infer<typeof schema>;

export function parseEnv(source: NodeJS.ProcessEnv = process.env): Env {
  const result = schema.safeParse(source);
  if (!result.success) {
    // Only variable names + messages are printed — never values.
    const issues = result.error.issues.map((i) => `${i.path.join('.') || 'env'}: ${i.message}`).join('; ');
    throw new Error(`Invalid environment: ${issues}`);
  }
  return result.data;
}
