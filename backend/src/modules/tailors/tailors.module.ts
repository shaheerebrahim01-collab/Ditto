import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { TailorsController } from './tailors.controller';
import { TailorsService } from './tailors.service';

@Module({
  imports: [AuthModule], // needed so JwtAuthGuard has something to check against
  controllers: [TailorsController],
  providers: [TailorsService],
})
export class TailorsModule {}
