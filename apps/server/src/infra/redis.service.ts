import { Injectable, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';

/** Redis 7 client. Tests use a separate DB index via HASTA_REDIS_URL (…/1). */
@Injectable()
export class RedisService implements OnModuleDestroy {
  readonly client: Redis;

  constructor(url: string) {
    this.client = new Redis(url, { lazyConnect: true, maxRetriesPerRequest: 2, enableOfflineQueue: true });
  }

  async onModuleDestroy(): Promise<void> {
    if (this.client.status === 'ready') await this.client.quit().catch(() => undefined);
    else this.client.disconnect();
  }
}
