import { ApiProperty } from '@nestjs/swagger';
import { IsString, Length } from 'class-validator';

/** No `id_token` field: the server obtains it from Google itself (SPEC 1.0.2 §5.4 ruling; unknown fields → 400). */
export class LinkCompleteDto {
  @ApiProperty() @IsString() @Length(16, 256) state!: string;
  @ApiProperty() @IsString() @Length(1, 2048) code!: string;
}

export class LinkStartResponse {
  @ApiProperty() state!: string;
  @ApiProperty() nonce!: string;
  @ApiProperty({ type: [String] }) scopes!: string[];
  @ApiProperty() auth_url!: string;
  @ApiProperty({ example: 300 }) expires_in!: number;
}

export class LinkedIdentityView {
  @ApiProperty({ enum: ['google'] }) provider!: 'google';
  @ApiProperty({ nullable: true, type: String, example: 'h***@gmail.com' }) email_masked!: string | null;
  @ApiProperty() linked_at!: string;
}

export class LinkedAccountView {
  @ApiProperty() id!: string;
  @ApiProperty() is_guest!: boolean;
}

export class LinkCompleteResponse {
  @ApiProperty({ type: LinkedIdentityView }) identity!: LinkedIdentityView;
  @ApiProperty({ type: LinkedAccountView }) account!: LinkedAccountView;
  @ApiProperty({ type: [String], example: ['premium_purchase', 'restore_purchases', 'device_recovery'] }) unlocked!: string[];
}
