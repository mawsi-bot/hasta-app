import { Module } from '@nestjs/common';
import { IdentityController } from './identity.controller';
import { IdentityService } from './identity.service';
import { GoogleIdTokenVerifier } from './google-id-token.verifier';
import { GoogleOAuthHttp, GoogleOAuthPort } from './google-oauth.port';

@Module({
  controllers: [IdentityController],
  providers: [IdentityService, GoogleIdTokenVerifier, { provide: GoogleOAuthPort, useClass: GoogleOAuthHttp }],
})
export class IdentityModule {}
