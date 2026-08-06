import { Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { NotificationsService } from './notifications.service';

// Same bounded-parse pagination convention as RentalShopsController /
// AdminController — copied rather than shared, no module both already
// depend on.
function parsePage(value: string | undefined, fallback: number, max: number): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 1) return fallback;
  return Math.min(Math.floor(n), max);
}

@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  list(
    @CurrentUser() user: { userId: string },
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
    @Query('unreadOnly') unreadOnly?: string,
  ) {
    return this.notificationsService.list(
      user.userId,
      parsePage(page, 1, Infinity),
      parsePage(pageSize, 20, 100),
      unreadOnly === 'true',
    );
  }

  @Get('unread-count')
  unreadCount(@CurrentUser() user: { userId: string }) {
    return this.notificationsService.unreadCount(user.userId);
  }

  @Post(':id/read')
  markRead(@CurrentUser() user: { userId: string }, @Param('id') id: string) {
    return this.notificationsService.markRead(user.userId, id);
  }

  @Post('read-all')
  markAllRead(@CurrentUser() user: { userId: string }) {
    return this.notificationsService.markAllRead(user.userId);
  }
}
