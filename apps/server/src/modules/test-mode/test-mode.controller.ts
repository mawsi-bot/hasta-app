import { Body, Controller, Get, HttpCode, Param, ParseEnumPipe, Post, UseGuards } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import { IsString, Length } from 'class-validator';
import { Public } from '../../common/auth/public.decorator';
import { IdempotentByDesign } from '../../common/idempotency/idempotency.decorator';
import { TestModeGuard } from './test-mode.guard';
import { TestModeService } from './test-mode.service';
import { SEED_HANDLES, type SeedHandle } from './seed-accounts';

class TestSessionDto {
  @IsString() @Length(10, 2048) device_token!: string;
}

const HANDLE_ENUM = Object.fromEntries(SEED_HANDLES.map((h) => [h, h]));

/**
 * QA-only quick-access endpoints (SPEC §19). 404 outside dev/test/beta; excluded from the
 * published OpenAPI document. The Gmail link flow used from the panel is the production path.
 */
@ApiExcludeController()
@Public()
@UseGuards(TestModeGuard)
@Controller('test/accounts')
export class TestModeController {
  constructor(private readonly svc: TestModeService) {}

  @Get()
  list() {
    return this.svc.list().then((accounts) => ({ accounts }));
  }

  @Post(':handle/session')
  @HttpCode(200)
  @IdempotentByDesign('issues a fresh test session; no persistent side effect beyond a session row')
  session(@Param('handle', new ParseEnumPipe(HANDLE_ENUM)) handle: SeedHandle, @Body() dto: TestSessionDto) {
    return this.svc.session(handle, dto.device_token);
  }

  @Post(':handle/reset')
  @HttpCode(200)
  @IdempotentByDesign('resetting to the seed state twice yields the same state')
  reset(@Param('handle', new ParseEnumPipe(HANDLE_ENUM)) handle: SeedHandle) {
    return this.svc.reset(handle);
  }
}
