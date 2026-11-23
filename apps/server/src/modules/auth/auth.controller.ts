import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOkResponse, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/auth/public.decorator';
import { CurrentAuth } from '../../common/auth/current-auth.decorator';
import type { AuthContext } from '../../common/auth/auth-context';
import { IdempotentByDesign } from '../../common/idempotency/idempotency.decorator';
import { AuthService } from './auth.service';
import { DeviceService } from './device.service';
import { RegisterDeviceDto, RegisterDeviceResponse } from './dto/register-device.dto';
import { GuestDto, LogoutDto, RefreshDto, SessionResponse, TokenPairResponse } from './dto/guest.dto';

const IDEM_HEADER = { name: 'Idempotency-Key', required: false, description: 'UUIDv7' };

/**
 * Guest-first auth (SPEC §5.3). There is intentionally NO sign-in endpoint for Google/Apple and
 * NO OTP/SMS route in v1 — static gates T20/T37 fail the build if one appears.
 */
@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly devices: DeviceService,
    private readonly auth: AuthService,
  ) {}

  @Public()
  @Post('device/register')
  @HttpCode(200)
  @IdempotentByDesign('deterministic HMAC of the device id; re-registering returns the same hash')
  @ApiHeader(IDEM_HEADER)
  @ApiOperation({ summary: 'Register device; returns HMAC device hash + device token (raw id never stored)' })
  @ApiOkResponse({ type: RegisterDeviceResponse })
  @ApiResponse({ status: 429, description: 'rate_limited' })
  register(@Body() dto: RegisterDeviceDto): Promise<RegisterDeviceResponse> {
    return this.devices.register(dto.raw_device_id, dto.platform);
  }

  @Public()
  @Post('guest')
  @HttpCode(200)
  @IdempotentByDesign('resumes the account already bound to this device; never creates a duplicate (T41)')
  @ApiHeader(IDEM_HEADER)
  @ApiOperation({ summary: 'One-tap guest: create or resume the account bound to this device' })
  @ApiOkResponse({ type: SessionResponse })
  @ApiResponse({ status: 429, description: 'device_cooldown (details.retry_after_days) or rate_limited' })
  guest(@Body() dto: GuestDto): Promise<SessionResponse> {
    return this.auth.guest(dto.device_token);
  }

  @Public()
  @Post('refresh')
  @HttpCode(200)
  @IdempotentByDesign('rotation: a replay is treated as token reuse and revokes the family (SPEC §5.3)')
  @ApiHeader(IDEM_HEADER)
  @ApiOperation({ summary: 'Rotate refresh token (reuse ⇒ family revoked)' })
  @ApiOkResponse({ type: TokenPairResponse })
  @ApiResponse({ status: 401, description: 'unauthenticated (details.reason=reuse_detected on reuse)' })
  refresh(@Body() dto: RefreshDto): Promise<TokenPairResponse> {
    return this.auth.refresh(dto.refresh_token, dto.device_token);
  }

  @Post('logout')
  @HttpCode(204)
  @ApiBearerAuth()
  @IdempotentByDesign('revoking an already-revoked session is a no-op')
  @ApiHeader(IDEM_HEADER)
  @ApiOperation({ summary: 'Sign out this device (or everywhere). Guest binding is kept, so Continue resumes.' })
  @ApiResponse({ status: 204 })
  async logout(@CurrentAuth() a: AuthContext, @Body() dto: LogoutDto): Promise<void> {
    await this.auth.logout(a.sessionId, a.accountId, a.deviceHash, dto.device_token, dto.everywhere === true);
  }
}
