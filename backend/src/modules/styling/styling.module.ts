import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { StylingController } from './styling.controller';
import { StylingService } from './styling.service';

@Module({
  imports: [AuthModule], // needed so JwtAuthGuard has something to check against
  controllers: [StylingController],
  providers: [StylingService],
})
export class StylingModule {}
