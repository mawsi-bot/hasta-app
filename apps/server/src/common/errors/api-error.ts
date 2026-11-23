/** Standard error codes from the API contract §0 (+ `internal_error`, `feature_disabled`). */
export type ApiErrorCode =
  | 'unauthenticated'
  | 'forbidden'
  | 'not_found'
  | 'validation_failed'
  | 'rate_limited'
  | 'idempotency_conflict'
  | 'device_cooldown'
  | 'token_expired'
  | 'feature_disabled'
  | 'username_taken'
  | 'identity_in_use'
  | 'google_email_unverified'
  | 'recovery_required'
  | 'internal_error';

export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: ApiErrorCode,
    readonly messageKey: string,
    readonly details: Record<string, unknown> | null = null,
    readonly retryAfterSeconds: number | null = null,
  ) {
    super(code);
  }

  static unauthenticated(details: Record<string, unknown> | null = null) {
    return new ApiError(401, 'unauthenticated', 'error.unauthenticated', details);
  }
  static forbidden(messageKey = 'error.forbidden') {
    return new ApiError(403, 'forbidden', messageKey);
  }
  static notFound() {
    return new ApiError(404, 'not_found', 'error.notFound');
  }
  static validation(details: Record<string, unknown>) {
    return new ApiError(400, 'validation_failed', 'error.validation', details);
  }
  static rateLimited(retryAfterSeconds: number) {
    return new ApiError(429, 'rate_limited', 'error.rateLimited', null, retryAfterSeconds);
  }
}
