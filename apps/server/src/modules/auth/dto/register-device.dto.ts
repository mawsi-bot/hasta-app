import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, Length, Matches } from 'class-validator';

export const PLATFORMS = ['android', 'ios'] as const;
export type Platform = (typeof PLATFORMS)[number];

export class RegisterDeviceDto {
  @ApiProperty({ description: 'Android ID / iOS identifierForVendor. Sent once over TLS, never persisted.', example: 'a1b2c3d4e5f60718' })
  @IsString()
  @Length(8, 128)
  @Matches(/^[A-Za-z0-9-]+$/)
  raw_device_id!: string;

  @ApiProperty({ enum: PLATFORMS })
  @IsIn(PLATFORMS)
  platform!: Platform;

  @ApiProperty({ example: '1.0.0' })
  @IsString()
  @Matches(/^\d+\.\d+\.\d+(\+\d+)?$/)
  app_version!: string;

  @ApiProperty({ example: '14', required: false })
  @IsOptional()
  @IsString()
  @Length(1, 32)
  os_version?: string;
}

export class RegisterDeviceResponse {
  @ApiProperty() device_hash!: string;
  @ApiProperty() device_token!: string;
  @ApiProperty({ enum: PLATFORMS }) platform!: Platform;
  @ApiProperty() registered_at!: string;
}
