import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus } from '@nestjs/common';
import type { Request, Response } from 'express';
import { ApiError } from './api-error';
import { log } from '../logging/logger';

interface Envelope {
  error: {
    code: string;
    message_key: string;
    status: number;
    request_id: string | null;
    details: Record<string, unknown> | null;
    retry_after_seconds: number | null;
  };
}

/** Uniform error envelope (API contract §0). Never leaks stack traces or internal ids. */
@Catch()
export class ErrorEnvelopeFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const req = ctx.getRequest<Request>();
    const res = ctx.getResponse<Response>();
    const requestId = (req.headers['x-request-id'] as string | undefined) ?? null;
    const err = toApiError(exception);
    if (err.status >= 500) {
      log.error('unhandled_error', { request_id: requestId, route: req.route?.path ?? req.path, error: describe(exception) });
    }
    if (err.retryAfterSeconds !== null) res.setHeader('Retry-After', String(err.retryAfterSeconds));
    const body: Envelope = {
      error: {
        code: err.code,
        message_key: err.messageKey,
        status: err.status,
        request_id: requestId,
        details: err.details,
        retry_after_seconds: err.retryAfterSeconds,
      },
    };
    res.status(err.status).json(body);
  }
}

function toApiError(e: unknown): ApiError {
  if (e instanceof ApiError) return e;
  if (e instanceof HttpException) {
    const status = e.getStatus();
    const resp = e.getResponse() as { message?: unknown } | string;
    if (status === HttpStatus.BAD_REQUEST || status === HttpStatus.UNPROCESSABLE_ENTITY) {
      const msg = typeof resp === 'object' && resp && Array.isArray(resp.message) ? resp.message : [];
      return ApiError.validation({ fields: msg });
    }
    if (status === HttpStatus.NOT_FOUND) return ApiError.notFound();
    if (status === HttpStatus.UNAUTHORIZED) return ApiError.unauthenticated();
    if (status === HttpStatus.FORBIDDEN) return ApiError.forbidden();
    if (status === HttpStatus.PAYLOAD_TOO_LARGE) return new ApiError(413, 'validation_failed', 'error.payloadTooLarge');
    return new ApiError(status, status >= 500 ? 'internal_error' : 'validation_failed', 'error.generic');
  }
  return new ApiError(500, 'internal_error', 'error.generic');
}

function describe(e: unknown): string {
  if (e instanceof Error) return `${e.name}: ${e.message}`.slice(0, 500);
  return 'non-error thrown';
}
