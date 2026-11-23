import { Inject, Injectable } from '@nestjs/common';
import { SECRETS } from '../../config/config.module';
import type { Secrets } from '../../config/secrets';
import { RemoteConfigService } from '../../config/remote-config';
import { deviceHash } from '../../common/crypto/crypto';
import { RateLimiterService } from '../../common/rate-limit/rate-limiter.service';
import { TokenService } from './token.service';
import type { Platform } from './dto/register-device.dto';

/**
 * SPEC §5.3 step 2: raw device id crosses the wire once over TLS; only the HMAC is kept.
 * The raw id is never persisted, logged, cached, or returned.
 */
@Injectable()
export class DeviceService {
  constructor(
    @Inject(SECRETS) private readonly secrets: Secrets,
    private readonly tokens: TokenService,
    private readonly limiter: RateLimiterService,
    private readonly rc: RemoteConfigService,
  ) {}

  async register(rawDeviceId: string, platform: Platform) {
    const hash = deviceHash(this.secrets.devicePepper, rawDeviceId);
    await this.limiter.consume('device_register', hash, this.rc.get('device_register_rate_limit_per_hour'), 3600);
    return {
      device_hash: hash,
      device_token: this.tokens.signDevice(hash, platform),
      platform,
      registered_at: new Date().toISOString(),
    };
  }
}
