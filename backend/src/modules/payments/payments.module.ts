import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';

@Module({
  imports: [AuthModule], // needed so JwtAuthGuard has something to check against
  controllers: [PaymentsController],
  providers: [PaymentsService],
})
export class PaymentsModule {}
