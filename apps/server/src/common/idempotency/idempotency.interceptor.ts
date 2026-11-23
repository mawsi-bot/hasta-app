import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Prisma } from '@prisma/client';
import type { Request, Response } from 'express';
import { Observable, from, of } from 'rxjs';
import { catchError, mergeMap } from 'rxjs/operators';
import { RemoteConfigService } from '../../config/remote-config';
import { PrismaService } from '../../infra/prisma.service';
import { sha256Hex } from '../crypto/crypto';
import { ApiError } from '../errors/api-error';
import { isUuidV7 } from '../ids/uuidv7';
import type { AuthContext } from '../auth/auth-context';
import { IDEMPOTENCY_META, IdempotencyMode } from './idempotency.decorator';

const IN_FLIGHT = 0;

@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
    private readonly rc: RemoteConfigService,
  ) {}

  intercept(ctx: ExecutionContext, next: CallHandler): Observable<unknown> {
    const meta = this.reflector.get<IdempotencyMode | undefined>(IDEMPOTENCY_META, ctx.getHandler());
    if (!meta) return next.handle();
    const req = ctx.switchToHttp().getRequest<Request & { auth?: AuthContext }>();
    const res = ctx.switchToHttp().getResponse<Response>();
    const header = req.headers['idempotency-key'];
    const key = typeof header === 'string' ? header : undefined;

    if (key !== undefined && !isUuidV7(key)) {
      throw ApiError.validation({ header: 'Idempotency-Key must be a UUIDv7' });
    }
    if (meta.mode === 'by_design') return next.handle();
    if (!key) throw ApiError.validation({ header: 'Idempotency-Key is required' });
    if (!req.auth) throw ApiError.unauthenticated();

    const scope = `acct:${req.auth.accountId}`;
    const requestHash = sha256Hex(`${req.method} ${req.route?.path ?? req.path} ${JSON.stringify(req.body ?? {})}`);
    const expiresAt = new Date(Date.now() + this.rc.get('idempotency_retention_days') * 86_400_000);

    return from(this.claim(scope, key, requestHash, expiresAt)).pipe(
      mergeMap((existing) => {
        if (existing) {
          res.setHeader('Idempotent-Replayed', 'true');
          res.status(existing.statusCode);
          return of(existing.responseBody);
        }
        return next.handle().pipe(
          mergeMap((body) =>
            from(this.complete(scope, key, res.statusCode, body)).pipe(mergeMap(() => of(body))),
          ),
          catchError((err: unknown) => from(this.release(scope, key)).pipe(mergeMap(() => { throw err; }))),
        );
      }),
    );
  }

  /** Inserts an in-flight marker; returns the stored response when this is a replay. */
  private async claim(scope: string, key: string, requestHash: string, expiresAt: Date) {
    await this.prisma.idempotencyKey.deleteMany({ where: { scope, key, expiresAt: { lt: new Date() } } });
    try {
      await this.prisma.idempotencyKey.create({
        data: { scope, key, requestHash, responseHash: '', statusCode: IN_FLIGHT, expiresAt },
      });
      return null;
    } catch (e) {
      if (!(e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002')) throw e;
    }
    const row = await this.prisma.idempotencyKey.findUnique({ where: { scope_key: { scope, key } } });
    if (!row) throw new ApiError(409, 'idempotency_conflict', 'error.idempotencyConflict');
    if (row.requestHash !== requestHash) {
      throw new ApiError(422, 'idempotency_conflict', 'error.idempotencyConflict', { reason: 'payload_mismatch' });
    }
    if (row.statusCode === IN_FLIGHT) {
      throw new ApiError(409, 'idempotency_conflict', 'error.idempotencyConflict', { reason: 'in_progress' });
    }
    return row;
  }

  private async complete(scope: string, key: string, statusCode: number, body: unknown) {
    const json = (body ?? null) as Prisma.InputJsonValue;
    await this.prisma.idempotencyKey.update({
      where: { scope_key: { scope, key } },
      data: { statusCode, responseBody: json ?? Prisma.JsonNull, responseHash: sha256Hex(JSON.stringify(body ?? null)) },
    });
  }

  private async release(scope: string, key: string) {
    await this.prisma.idempotencyKey.deleteMany({ where: { scope, key, statusCode: IN_FLIGHT } });
  }
}
