import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';

@Module({
  imports: [AuthModule], // needed so JwtAuthGuard has something to check against
  controllers: [OrdersController],
  providers: [OrdersService],
})
export class OrdersModule {}
