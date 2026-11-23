import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, Length } from 'class-validator';

export class GuestDto {
  @ApiProperty() @IsString() @Length(10, 2048) device_token!: string;
  @ApiProperty({ enum: ['my', 'en'], required: false }) @IsOptional() @IsIn(['my', 'en']) locale?: 'my' | 'en';
}

export class RefreshDto {
  @ApiProperty() @IsString() @Length(10, 256) refresh_token!: string;
  @ApiProperty() @IsString() @Length(10, 2048) device_token!: string;
}

export class LogoutDto {
  @ApiProperty() @IsString() @Length(10, 2048) device_token!: string;
  @ApiProperty({ default: false, required: false }) @IsOptional() everywhere?: boolean;
}

export class AccountView {
  @ApiProperty() id!: string;
  @ApiProperty({ enum: ['active', 'paused', 'deleted', 'banned'] }) status!: string;
  @ApiProperty() is_guest!: boolean;
  @ApiProperty({ nullable: true, type: String }) display_name!: string | null;
  @ApiProperty({ nullable: true, type: String }) username!: string | null;
  @ApiProperty() created_at!: string;
}

export class DeviceBindingView {
  @ApiProperty() id!: string;
  @ApiProperty({ enum: ['primary', 'secondary'] }) role!: string;
  @ApiProperty() device_hash!: string;
  @ApiProperty() bound_at!: string;
}

export class SessionResponse {
  @ApiProperty() access_token!: string;
  @ApiProperty() refresh_token!: string;
  @ApiProperty({ example: 900 }) expires_in!: number;
  @ApiProperty({ type: AccountView }) account!: AccountView;
  @ApiProperty({ type: DeviceBindingView, nullable: true }) device_binding!: DeviceBindingView | null;
  @ApiProperty() is_new_account!: boolean;
}

export class TokenPairResponse {
  @ApiProperty() access_token!: string;
  @ApiProperty() refresh_token!: string;
  @ApiProperty({ example: 900 }) expires_in!: number;
}
