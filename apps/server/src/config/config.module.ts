import { Global, Module } from '@nestjs/common';
import type { Env } from './env';
import type { Secrets } from './secrets';
import { RemoteConfigService } from './remote-config';

export const ENV = Symbol('HASTA_ENV');
export const SECRETS = Symbol('HASTA_SECRETS');

@Global()
@Module({})
export class ConfigModule {
  static forRoot(env: Env, secrets: Secrets) {
    return {
      module: ConfigModule,
      providers: [
        { provide: ENV, useValue: env },
        { provide: SECRETS, useValue: secrets },
        RemoteConfigService,
      ],
      exports: [ENV, SECRETS, RemoteConfigService],
    };
  }
}
