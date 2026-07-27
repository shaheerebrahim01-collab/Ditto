import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { BusinessApplicationsController } from './business-applications.controller';
import { BusinessApplicationsService } from './business-applications.service';

@Module({
  imports: [AuthModule], // needed so JwtAuthGuard has something to check against
  controllers: [BusinessApplicationsController],
  providers: [BusinessApplicationsService],
})
export class BusinessApplicationsModule {}
