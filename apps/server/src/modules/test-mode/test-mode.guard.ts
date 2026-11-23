import { CanActivate, Inject, Injectable } from '@nestjs/common';
import { ENV } from '../../config/config.module';
import { TEST_MODE_ENVS, type Env } from '../../config/env';
import { ApiError } from '../../common/errors/api-error';

/** Seeding/test endpoints answer 404 (not 403) outside dev/test/beta so they are undiscoverable. */
@Injectable()
export class TestModeGuard implements CanActivate {
  constructor(@Inject(ENV) private readonly env: Env) {}

  canActivate(): boolean {
    if (!this.env.HASTA_QUICK_TEST_ACCOUNTS_ENABLED || !TEST_MODE_ENVS.includes(this.env.HASTA_ENV)) {
      throw ApiError.notFound();
    }
    return true;
  }
}
