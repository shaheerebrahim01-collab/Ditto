import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';

@Module({
  imports: [AuthModule, NotificationsModule], // AuthModule for JwtAuthGuard, NotificationsModule for status-change notifications
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
