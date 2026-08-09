import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { RentalStatusCron } from './rental-status.cron';
import { RentalsController } from './rentals.controller';
import { RentalsService } from './rentals.service';

@Module({
  imports: [AuthModule, NotificationsModule], // AuthModule for JwtAuthGuard, NotificationsModule for booking notifications
  controllers: [RentalsController],
  providers: [RentalsService, RentalStatusCron],
})
export class RentalsModule {}
