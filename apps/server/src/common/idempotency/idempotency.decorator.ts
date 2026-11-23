import { SetMetadata } from '@nestjs/common';

export const IDEMPOTENCY_META = 'hasta:idempotency';

export type IdempotencyMode =
  | { mode: 'replay' }
  | { mode: 'by_design'; reason: string };

/**
 * Stores the response under (scope, Idempotency-Key) for 7 days and replays it with
 * `Idempotent-Replayed: true`. Required header. Use for writes whose response carries no secrets.
 */
export const Idempotent = () => SetMetadata(IDEMPOTENCY_META, { mode: 'replay' } satisfies IdempotencyMode);

/**
 * The operation is idempotent by construction (e.g. guest resume, logout) and its response must
 * NOT be persisted because it carries credentials. The header is accepted and validated only.
 * The static gate (test/static/write-endpoints.spec.ts) requires one of the two decorators on
 * every POST/PATCH/PUT/DELETE handler.
 */
export const IdempotentByDesign = (reason: string) =>
  SetMetadata(IDEMPOTENCY_META, { mode: 'by_design', reason } satisfies IdempotencyMode);
