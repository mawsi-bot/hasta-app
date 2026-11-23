import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { AuthContext } from './auth-context';
import { ApiError } from '../errors/api-error';

export const CurrentAuth = createParamDecorator((_: unknown, ctx: ExecutionContext): AuthContext => {
  const req = ctx.switchToHttp().getRequest<{ auth?: AuthContext }>();
  if (!req.auth) throw ApiError.unauthenticated();
  return req.auth;
});
