import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/auth/public.decorator';
import { PrismaService } from '../../infra/prisma.service';
import { RedisService } from '../../infra/redis.service';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  /** Async end-to-end smoke path: HTTP → Nest → Prisma(Postgres) + ioredis (Sprint 0 gate). */
  @Public()
  @Get()
  async health() {
    const [db] = await this.prisma.$queryRaw<{ ok: number }[]>`SELECT 1 AS ok`;
    const redis = await this.redis.client.ping();
    return { status: 'ok', db: db?.ok === 1, redis: redis === 'PONG', version: '1.0.0' };
  }
}
