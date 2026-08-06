import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SendMessageDto } from './dto/send-message.dto';

const otherUserSelect = { id: true, fullName: true, avatarUrl: true, role: true } as const;

@Injectable()
export class MessagingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // userAId/userBId are canonicalized (lower id first) so starting a
  // conversation from either direction lands on the same row — upsert on
  // the compound unique key rather than a separate find-then-create to
  // avoid a race between the two.
  async startConversation(callerId: string, otherUserId: string) {
    if (callerId === otherUserId) {
      throw new BadRequestException("Can't start a conversation with yourself");
    }
    const otherUser = await this.prisma.user.findUnique({
      where: { id: otherUserId },
      select: otherUserSelect,
    });
    if (!otherUser) throw new NotFoundException('User not found');

    const [userAId, userBId] = [callerId, otherUserId].sort();
    const conversation = await this.prisma.conversation.upsert({
      where: { userAId_userBId: { userAId, userBId } },
      create: { userAId, userBId },
      update: {},
    });
    return { ...conversation, otherUser };
  }

  async listConversations(callerId: string) {
    const conversations = await this.prisma.conversation.findMany({
      where: { OR: [{ userAId: callerId }, { userBId: callerId }] },
      orderBy: { updatedAt: 'desc' },
      include: {
        userA: { select: otherUserSelect },
        userB: { select: otherUserSelect },
        messages: { orderBy: { createdAt: 'desc' }, take: 1 },
      },
    });

    const unreadCounts = await this.prisma.message.groupBy({
      by: ['conversationId'],
      where: {
        conversationId: { in: conversations.map((c) => c.id) },
        senderId: { not: callerId },
        readAt: null,
      },
      _count: { id: true },
    });
    const unreadByConversation = new Map(unreadCounts.map((u) => [u.conversationId, u._count.id]));

    return conversations.map(({ userA, userB, messages, userAId, userBId, ...rest }) => ({
      ...rest,
      otherUser: userAId === callerId ? userB : userA,
      lastMessage: messages[0] ?? null,
      unreadCount: unreadByConversation.get(rest.id) ?? 0,
    }));
  }

  async listMessages(callerId: string, conversationId: string, page: number, pageSize: number) {
    const conversation = await this.getOwnedConversation(callerId, conversationId);
    const [data, total] = await Promise.all([
      this.prisma.message.findMany({
        where: { conversationId: conversation.id },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.message.count({ where: { conversationId: conversation.id } }),
    ]);
    return { data, total, page, pageSize };
  }

  async sendMessage(callerId: string, conversationId: string, dto: SendMessageDto) {
    if (!dto.body && !dto.attachmentUrl) {
      throw new BadRequestException('Provide a message body or an attachment');
    }
    const conversation = await this.getOwnedConversation(callerId, conversationId);
    const recipientId = conversation.userAId === callerId ? conversation.userBId : conversation.userAId;

    const [message] = await this.prisma.$transaction([
      this.prisma.message.create({
        data: {
          conversationId: conversation.id,
          senderId: callerId,
          body: dto.body,
          attachmentUrl: dto.attachmentUrl,
          attachmentType: dto.attachmentType,
        },
      }),
      // an empty `data: {}` update does *not* touch @updatedAt on its own
      // (confirmed against this Prisma version) — set it explicitly so
      // listConversations' `orderBy: updatedAt desc` actually reflects the
      // most recently active thread.
      this.prisma.conversation.update({ where: { id: conversation.id }, data: { updatedAt: new Date() } }),
    ]);

    const sender = await this.prisma.user.findUnique({ where: { id: callerId }, select: { fullName: true } });
    await this.notificationsService.create(
      recipientId,
      'message',
      'New message',
      `${sender?.fullName ?? 'Someone'} sent you a message`,
    );

    return message;
  }

  async markRead(callerId: string, conversationId: string) {
    const conversation = await this.getOwnedConversation(callerId, conversationId);
    const { count } = await this.prisma.message.updateMany({
      where: { conversationId: conversation.id, senderId: { not: callerId }, readAt: null },
      data: { readAt: new Date() },
    });
    return { updated: count };
  }

  private async getOwnedConversation(callerId: string, id: string) {
    const conversation = await this.prisma.conversation.findUnique({ where: { id } });
    if (!conversation || (conversation.userAId !== callerId && conversation.userBId !== callerId)) {
      throw new NotFoundException('Conversation not found');
    }
    return conversation;
  }
}
