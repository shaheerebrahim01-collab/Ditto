import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { MeasurementVisitsController } from './measurement-visits.controller';
import { MeasurementVisitsService } from './measurement-visits.service';

@Module({
  imports: [AuthModule, NotificationsModule], // AuthModule for JwtAuthGuard, NotificationsModule for claim/complete notifications
  controllers: [MeasurementVisitsController],
  providers: [MeasurementVisitsService],
})
export class MeasurementVisitsModule {}
