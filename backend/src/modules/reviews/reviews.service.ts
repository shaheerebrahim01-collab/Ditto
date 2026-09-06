import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { OrderStage } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateReviewDto } from './dto/create-review.dto';

const reviewInclude = {
  author: { select: { fullName: true } },
} as const;

@Injectable()
export class ReviewsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // One review per order, and only once it's actually DELIVERED — mirrors
  // OrdersService.updateStage's forward-only STAGE_ORDER, DELIVERED being
  // its final step.
  async create(customerId: string, dto: CreateReviewDto) {
    const order = await this.prisma.customOrder.findUnique({ where: { id: dto.orderId } });
    if (!order || order.customerId !== customerId) throw new NotFoundException('Order not found');
    if (order.stage !== OrderStage.DELIVERED) {
      throw new BadRequestException('Order must be delivered before it can be reviewed');
    }

    const existing = await this.prisma.review.findUnique({ where: { orderId: dto.orderId } });
    if (existing) throw new BadRequestException('This order has already been reviewed');

    const tailor = await this.prisma.tailorProfile.findUniqueOrThrow({ where: { id: order.tailorId } });
    const newCount = tailor.ratingCount + 1;
    const newAvg = (tailor.ratingAvg * tailor.ratingCount + dto.rating) / newCount;

    const [review] = await this.prisma.$transaction([
      this.prisma.review.create({
        data: { orderId: dto.orderId, authorId: customerId, rating: dto.rating, comment: dto.comment },
        include: reviewInclude,
      }),
      this.prisma.tailorProfile.update({
        where: { id: tailor.id },
        data: { ratingAvg: newAvg, ratingCount: newCount },
      }),
    ]);

    await this.notificationsService.create(
      tailor.userId,
      'review_received',
      'New review',
      `You received a ${dto.rating}-star review.`,
    );

    return review;
  }

  async listForTailor(tailorId: string, page: number, pageSize: number) {
    const where = { order: { tailorId } };
    const [data, total] = await Promise.all([
      this.prisma.review.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
        include: reviewInclude,
      }),
      this.prisma.review.count({ where }),
    ]);
    return { data, total, page, pageSize };
  }
}
