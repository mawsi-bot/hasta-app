import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

/**
 * Prisma has no lazy loading: relations are only returned when explicitly `include`d/`select`ed.
 * That is the "declare eager loading explicitly" rule — never rely on implicit relation fetches.
 */
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleDestroy {
  constructor(url: string) {
    super({ datasources: { db: { url } }, log: [] });
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
