import { Global, Module } from '@nestjs/common';
import { ENV } from '../config/config.module';
import type { Env } from '../config/env';
import { PrismaService } from './prisma.service';
import { RedisService } from './redis.service';

@Global()
@Module({
  providers: [
    { provide: PrismaService, inject: [ENV], useFactory: (env: Env) => new PrismaService(env.HASTA_DATABASE_URL) },
    { provide: RedisService, inject: [ENV], useFactory: (env: Env) => new RedisService(env.HASTA_REDIS_URL) },
  ],
  exports: [PrismaService, RedisService],
})
export class InfraModule {}
