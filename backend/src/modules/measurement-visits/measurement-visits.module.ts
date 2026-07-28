import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { MeasurementVisitsController } from './measurement-visits.controller';
import { MeasurementVisitsService } from './measurement-visits.service';

@Module({
  imports: [AuthModule], // needed so JwtAuthGuard has something to check against
  controllers: [MeasurementVisitsController],
  providers: [MeasurementVisitsService],
})
export class MeasurementVisitsModule {}
