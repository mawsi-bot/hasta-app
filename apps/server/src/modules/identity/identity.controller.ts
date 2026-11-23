import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOkResponse, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CurrentAuth } from '../../common/auth/current-auth.decorator';
import type { AuthContext } from '../../common/auth/auth-context';
import { Idempotent, IdempotentByDesign } from '../../common/idempotency/idempotency.decorator';
import { IdentityService } from './identity.service';
import { LinkCompleteDto, LinkCompleteResponse, LinkStartResponse } from './dto/link.dto';

/**
 * Gmail LINKING after guest login (SPEC 1.0.2 §5.4). This is not a sign-in: every route needs an
 * existing session. `\\:` escapes the AIP-136 custom-method colon for Express.
 */
@ApiTags('identity')
@ApiBearerAuth()
@Controller('auth/identities/google')
export class IdentityController {
  constructor(private readonly identities: IdentityService) {}

  @Post('link\\:start')
  @HttpCode(200)
  @IdempotentByDesign('each call issues a fresh single-use state; nothing is linked until link:complete')
  @ApiOperation({ summary: 'Begin Gmail linking: PKCE auth_url + single-use state (300 s)' })
  @ApiOkResponse({ type: LinkStartResponse })
  @ApiResponse({ status: 403, description: 'feature_disabled' })
  start(@CurrentAuth() auth: AuthContext): Promise<LinkStartResponse> {
    return this.identities.start(auth);
  }

  @Post('link\\:complete')
  @HttpCode(200)
  @Idempotent()
  @ApiHeader({ name: 'Idempotency-Key', required: true, description: 'UUIDv7' })
  @ApiOperation({ summary: 'Finish linking: server exchanges the code and verifies the id_token itself' })
  @ApiOkResponse({ type: LinkCompleteResponse })
  @ApiResponse({ status: 401, description: 'unauthenticated (bad code/token) or token_expired (state)' })
  @ApiResponse({ status: 409, description: 'identity_in_use' })
  @ApiResponse({ status: 422, description: 'google_email_unverified' })
  complete(@CurrentAuth() auth: AuthContext, @Body() dto: LinkCompleteDto): Promise<LinkCompleteResponse> {
    return this.identities.complete(auth, dto.state, dto.code);
  }
}
