import 'reflect-metadata';
import { SwaggerModule } from '@nestjs/swagger';
import { parseEnv } from './config/env';
import { loadSecrets } from './config/secrets';
import { buildOpenApi, createApp } from './bootstrap';
import { log } from './common/logging/logger';

async function main(): Promise<void> {
  const env = parseEnv();
  const secrets = await loadSecrets(env);
  const app = await createApp(env, secrets);
  app.enableShutdownHooks();
  if (env.HASTA_ENV !== 'production') SwaggerModule.setup('v1/docs', app, buildOpenApi(app));
  await app.listen(env.HASTA_PORT, '0.0.0.0');
  log.info('server_started', { env: env.HASTA_ENV, port: env.HASTA_PORT });
}

main().catch((e: unknown) => {
  log.error('server_boot_failed', { error: e instanceof Error ? e.message : 'unknown' });
  process.exit(1);
});
