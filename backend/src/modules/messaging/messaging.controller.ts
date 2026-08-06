import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SendMessageDto } from './dto/send-message.dto';
import { StartConversationDto } from './dto/start-conversation.dto';
import { MessagingService } from './messaging.service';

function parsePage(value: string | undefined, fallback: number, max: number): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 1) return fallback;
  return Math.min(Math.floor(n), max);
}

// No @Roles anywhere here — any two authenticated users can message each
// other (customer<->tailor, customer<->rental shop, etc.), so the only
// access control is "are you a participant in this conversation".
@UseGuards(JwtAuthGuard)
@Controller('conversations')
export class MessagingController {
  constructor(private readonly messagingService: MessagingService) {}

  @Post()
  start(@CurrentUser() user: { userId: string }, @Body() dto: StartConversationDto) {
    return this.messagingService.startConversation(user.userId, dto.otherUserId);
  }

  @Get()
  list(@CurrentUser() user: { userId: string }) {
    return this.messagingService.listConversations(user.userId);
  }

  @Get(':id/messages')
  messages(
    @CurrentUser() user: { userId: string },
    @Param('id') id: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.messagingService.listMessages(user.userId, id, parsePage(page, 1, Infinity), parsePage(pageSize, 30, 100));
  }

  @Post(':id/messages')
  send(@CurrentUser() user: { userId: string }, @Param('id') id: string, @Body() dto: SendMessageDto) {
    return this.messagingService.sendMessage(user.userId, id, dto);
  }

  @Post(':id/read')
  markRead(@CurrentUser() user: { userId: string }, @Param('id') id: string) {
    return this.messagingService.markRead(user.userId, id);
  }
}
