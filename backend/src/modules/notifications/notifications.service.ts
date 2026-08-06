import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  // Called from other modules' services (measurement-visits, rentals,
  // admin, messaging) via NotificationsModule's export — never called
  // directly from a controller, there's no "create a notification for
  // someone else" endpoint.
  async create(userId: string, type: string, title: string, body: string) {
    return this.prisma.notification.create({ data: { userId, type, title, body } });
  }

  async list(userId: string, page: number, pageSize: number, unreadOnly: boolean) {
    const where = { userId, ...(unreadOnly ? { read: false } : {}) };
    const [data, total] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.notification.count({ where }),
    ]);
    return { data, total, page, pageSize };
  }

  async unreadCount(userId: string) {
    const count = await this.prisma.notification.count({ where: { userId, read: false } });
    return { count };
  }

  async markRead(userId: string, id: string) {
    const notification = await this.prisma.notification.findUnique({ where: { id } });
    if (!notification || notification.userId !== userId) {
      throw new NotFoundException('Notification not found');
    }
    if (notification.read) return notification;
    return this.prisma.notification.update({ where: { id }, data: { read: true } });
  }

  async markAllRead(userId: string) {
    const { count } = await this.prisma.notification.updateMany({
      where: { userId, read: false },
      data: { read: true },
    });
    return { updated: count };
  }
}
