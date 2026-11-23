import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsISO8601, IsOptional, IsString, Length, Matches } from 'class-validator';

export class PatchProfileDto {
  @ApiPropertyOptional({ maxLength: 64 }) @IsOptional() @IsString() @Length(1, 64) display_name?: string;
  @ApiPropertyOptional({ pattern: '^[a-z0-9._]{3,32}$' }) @IsOptional() @Matches(/^[a-z0-9._]{3,32}$/) username?: string;
  @ApiPropertyOptional({ maxLength: 300 }) @IsOptional() @IsString() @Length(0, 300) bio?: string;
  @ApiPropertyOptional({ example: '1998-04-02' }) @IsOptional() @IsISO8601({ strict: true }) @Matches(/^\d{4}-\d{2}-\d{2}$/) birth_date?: string;
  @ApiProperty({ description: 'Client HLC (decimal string, (ms<<16)|counter) for field-level LWW' })
  @Matches(/^\d{1,20}$/)
  hlc!: string;
}

export class ProfileView {
  @ApiProperty({ nullable: true, type: String }) display_name!: string | null;
  @ApiProperty({ nullable: true, type: String }) username!: string | null;
  @ApiProperty({ nullable: true, type: String }) bio!: string | null;
  @ApiProperty({ nullable: true, type: String }) avatar_url!: string | null;
  @ApiProperty({ nullable: true, type: String }) birth_date!: string | null;
  @ApiProperty() updated_hlc!: string;
}

export class PatchProfileResponse {
  @ApiProperty({ type: ProfileView }) profile!: ProfileView;
  @ApiProperty({ type: [String] }) applied!: string[];
  @ApiProperty({ type: [String] }) ignored!: string[];
}

export class IdentityView {
  @ApiProperty({ enum: ['google', 'apple'] }) provider!: string;
  @ApiProperty({ nullable: true, type: String }) email_masked!: string | null;
  @ApiProperty() linked_at!: string;
}

export class EntitlementView {
  @ApiProperty({ enum: ['apple', 'google'] }) store!: string;
  @ApiProperty() product_id!: string;
  @ApiProperty({ enum: ['active', 'expired', 'revoked', 'pending', 'grace'] }) status!: string;
  @ApiProperty({ nullable: true, type: String }) expires_at!: string | null;
}

export class MeFlags {
  @ApiProperty() dating_enabled!: boolean;
  @ApiProperty() dating_paused!: boolean;
  @ApiProperty() premium!: boolean;
  @ApiProperty() test_mode_panel!: boolean;
}

export class MeAccount {
  @ApiProperty() id!: string;
  @ApiProperty() status!: string;
  @ApiProperty() is_guest!: boolean;
  @ApiProperty() created_at!: string;
}

export class MeResponse {
  @ApiProperty({ type: MeAccount }) account!: MeAccount;
  @ApiProperty({ type: ProfileView, nullable: true }) profile!: ProfileView | null;
  @ApiProperty({ type: [IdentityView] }) identities!: IdentityView[];
  @ApiProperty({ type: [EntitlementView] }) entitlements!: EntitlementView[];
  @ApiProperty({ type: MeFlags }) flags!: MeFlags;
}
