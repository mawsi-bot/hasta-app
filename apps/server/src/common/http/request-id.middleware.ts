import { Injectable, NestMiddleware } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';
import { uuidv7 } from '../ids/uuidv7';
import { log } from '../logging/logger';

const SAFE_ID = /^[A-Za-z0-9-]{8,64}$/;

/** X-Request-Id propagation + one structured access-log line per request (no bodies). */
@Injectable()
export class RequestIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction): void {
    const incoming = req.headers['x-request-id'];
    const id = typeof incoming === 'string' && SAFE_ID.test(incoming) ? incoming : uuidv7();
    req.headers['x-request-id'] = id;
    res.setHeader('X-Request-Id', id);
    const started = process.hrtime.bigint();
    res.on('finish', () => {
      log.info('http', {
        request_id: id,
        account_id: (req as Request & { auth?: { accountId: string } }).auth?.accountId ?? null,
        method: req.method,
        route: req.route?.path ?? req.baseUrl ?? req.path,
        status: res.statusCode,
        duration_ms: Number(process.hrtime.bigint() - started) / 1e6,
      });
    });
    next();
  }
}
