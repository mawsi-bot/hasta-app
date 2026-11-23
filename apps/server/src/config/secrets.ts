import { GetSecretValueCommand, SecretsManagerClient } from '@aws-sdk/client-secrets-manager';
import { z } from 'zod';
import type { Env } from './env';

/** Secret material. Never logged, never returned, never persisted. */
export interface Secrets {
  devicePepper: string;
  jwtAccessSecret: string;
  deviceTokenSecret: string;
}

const bundle = z.object({
  HASTA_DEVICE_PEPPER: z.string().min(32),
  HASTA_JWT_ACCESS_SECRET: z.string().min(32),
  HASTA_DEVICE_TOKEN_SECRET: z.string().min(32),
});

export type SecretFetcher = (secretId: string, region: string) => Promise<string>;

export const awsSecretFetcher: SecretFetcher = async (secretId, region) => {
  const client = new SecretsManagerClient({ region });
  const out = await client.send(new GetSecretValueCommand({ SecretId: secretId }));
  if (!out.SecretString) throw new Error('Secrets bundle is empty');
  return out.SecretString;
};

/**
 * Loads the pepper + signing keys. Deployed envs read AWS Secrets Manager (SPEC §15 "pepper in
 * Secrets Manager"); dev/test may fall back to local env placeholders from `.env`.
 */
export async function loadSecrets(env: Env, fetcher: SecretFetcher = awsSecretFetcher): Promise<Secrets> {
  let raw: Record<string, unknown>;
  if (env.HASTA_SECRETS_ARN) {
    raw = JSON.parse(await fetcher(env.HASTA_SECRETS_ARN, env.HASTA_AWS_REGION)) as Record<string, unknown>;
  } else {
    raw = {
      HASTA_DEVICE_PEPPER: env.HASTA_DEVICE_PEPPER,
      HASTA_JWT_ACCESS_SECRET: env.HASTA_JWT_ACCESS_SECRET,
      HASTA_DEVICE_TOKEN_SECRET: env.HASTA_DEVICE_TOKEN_SECRET,
    };
  }
  const parsed = bundle.safeParse(raw);
  if (!parsed.success) {
    throw new Error(`Secret bundle invalid: missing/short keys ${parsed.error.issues.map((i) => i.path.join('.')).join(', ')}`);
  }
  return {
    devicePepper: parsed.data.HASTA_DEVICE_PEPPER,
    jwtAccessSecret: parsed.data.HASTA_JWT_ACCESS_SECRET,
    deviceTokenSecret: parsed.data.HASTA_DEVICE_TOKEN_SECRET,
  };
}
