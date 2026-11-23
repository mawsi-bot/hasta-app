import { Body, Controller, Get, Patch } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOkResponse, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CurrentAuth } from '../../common/auth/current-auth.decorator';
import type { AuthContext } from '../../common/auth/auth-context';
import { Idempotent } from '../../common/idempotency/idempotency.decorator';
import { ProfileService } from './profile.service';
import { MeResponse, PatchProfileDto, PatchProfileResponse, ProfileView } from './dto/profile.dto';

@ApiTags('me')
@ApiBearerAuth()
@Controller()
export class MeController {
  constructor(private readonly profiles: ProfileService) {}

  @Get('me')
  @ApiOperation({ summary: 'Own account, profile, linked identities (masked), entitlements, flags' })
  @ApiOkResponse({ type: MeResponse })
  me(@CurrentAuth() a: AuthContext): Promise<MeResponse> {
    return this.profiles.me(a.accountId);
  }

  @Get('profile')
  @ApiOperation({ summary: 'Own profile' })
  @ApiOkResponse({ type: ProfileView })
  getProfile(@CurrentAuth() a: AuthContext): Promise<ProfileView> {
    return this.profiles.get(a.accountId);
  }

  @Patch('profile')
  @Idempotent()
  @ApiHeader({ name: 'Idempotency-Key', required: true, description: 'UUIDv7' })
  @ApiOperation({ summary: 'Update own profile (field-level HLC LWW merge)' })
  @ApiOkResponse({ type: PatchProfileResponse })
  @ApiResponse({ status: 409, description: 'username_taken' })
  patchProfile(@CurrentAuth() a: AuthContext, @Body() dto: PatchProfileDto): Promise<PatchProfileResponse> {
    return this.profiles.patch(a.accountId, dto);
  }
}
