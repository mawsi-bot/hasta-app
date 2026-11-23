import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { TestModeController } from './test-mode.controller';
import { TestModeGuard } from './test-mode.guard';
import { TestModeService } from './test-mode.service';

@Module({ imports: [AuthModule], controllers: [TestModeController], providers: [TestModeService, TestModeGuard] })
export class TestModeModule {}
