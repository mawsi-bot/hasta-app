import { Injectable } from '@nestjs/common';
import type { Prisma } from '@prisma/client';
import { PrismaService } from '../../infra/prisma.service';

export type AbuseEvent = 'guest_created' | 'account_deleted';

/**
 * SPEC §5.10: keyed by device hash ONLY. The signature deliberately has no account parameter so
 * an account id cannot be logged here by accident. Retention 90 d [PROPOSAL] → aggregation job (Sprint 9).
 */
@Injectable()
export class AbuseLogService {
  constructor(private readonly prisma: PrismaService) {}

  async record(deviceHash: string, event: AbuseEvent, tx: Prisma.TransactionClient = this.prisma): Promise<void> {
    await tx.abuseLog.create({ data: { deviceHash, event } });
  }
}
