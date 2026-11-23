import { MiddlewareConsumer, Module, NestModule, type DynamicModule } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ConfigModule } from './config/config.module';
import type { Env } from './config/env';
import type { Secrets } from './config/secrets';
import { InfraModule } from './infra/infra.module';
import { ErrorEnvelopeFilter } from './common/errors/error-envelope.filter';
import { IdempotencyInterceptor } from './common/idempotency/idempotency.interceptor';
import { RequestIdMiddleware } from './common/http/request-id.middleware';
import { SessionGuard } from './common/auth/session.guard';
import { AuthModule } from './modules/auth/auth.module';
import { UserModule } from './modules/user/user.module';
import { TestModeModule } from './modules/test-mode/test-mode.module';
import { HealthController } from './modules/health/health.controller';

@Module({})
export class AppModule implements NestModule {
  static forRoot(env: Env, secrets: Secrets): DynamicModule {
    return {
      module: AppModule,
      imports: [ConfigModule.forRoot(env, secrets), InfraModule, AuthModule, UserModule, TestModeModule],
      controllers: [HealthController],
      providers: [
        { provide: APP_FILTER, useClass: ErrorEnvelopeFilter },
        { provide: APP_GUARD, useClass: SessionGuard },
        { provide: APP_INTERCEPTOR, useClass: IdempotencyInterceptor },
      ],
    };
  }

  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(RequestIdMiddleware).forRoutes('*');
  }
}
