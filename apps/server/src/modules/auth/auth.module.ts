import { Module } from '@nestjs/common';
import { RateLimiterService } from '../../common/rate-limit/rate-limiter.service';
import { AbuseLogService } from './abuse-log.service';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { CooldownService } from './cooldown.service';
import { DeviceService } from './device.service';
import { SessionIssuer } from './session-issuer.service';
import { TokenService } from './token.service';

@Module({
  controllers: [AuthController],
  providers: [AuthService, DeviceService, TokenService, SessionIssuer, CooldownService, AbuseLogService, RateLimiterService],
  exports: [TokenService, SessionIssuer, AbuseLogService, CooldownService, RateLimiterService],
})
export class AuthModule {}
