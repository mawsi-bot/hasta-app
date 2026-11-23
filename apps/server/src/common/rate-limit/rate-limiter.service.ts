import { Injectable } from '@nestjs/common';
import { RedisService } from '../../infra/redis.service';
import { ApiError } from '../errors/api-error';

/** Fixed-window counter in Redis. Keys never contain raw device ids (hash only). */
@Injectable()
export class RateLimiterService {
  constructor(private readonly redis: RedisService) {}

  async consume(bucket: string, subject: string, limit: number, windowSeconds: number): Promise<void> {
    const key = `rl:${bucket}:${subject}`;
    const results = await this.redis.client.multi().incr(key).expire(key, windowSeconds, 'NX').ttl(key).exec();
    const count = Number(results?.[0]?.[1] ?? 0);
    const ttl = Number(results?.[2]?.[1] ?? windowSeconds);
    if (count > limit) throw ApiError.rateLimited(ttl > 0 ? ttl : windowSeconds);
  }
}
