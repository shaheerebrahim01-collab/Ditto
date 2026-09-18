import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { OrderStage, RentalStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateRentalReviewDto } from './dto/create-rental-review.dto';
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
    return this.listReviews({ order: { tailorId } }, page, pageSize);
  }

  // One review per booking, and only once the item's actually come back —
  // mirrors create()'s DELIVERED gate, RETURNED being RentalStatus's
  // equivalent "done" state (LATE means still out, not reviewable yet).
  async createForRentalBooking(renterId: string, dto: CreateRentalReviewDto) {
    const booking = await this.prisma.rentalBooking.findUnique({
      where: { id: dto.bookingId },
      include: { item: { include: { shop: true } } },
    });
    if (!booking || booking.renterId !== renterId) throw new NotFoundException('Booking not found');
    if (booking.status !== RentalStatus.RETURNED) {
      throw new BadRequestException('Booking must be returned before it can be reviewed');
    }

    const existing = await this.prisma.review.findUnique({ where: { rentalBookingId: dto.bookingId } });
    if (existing) throw new BadRequestException('This booking has already been reviewed');

    const shop = booking.item.shop;
    const newCount = shop.ratingCount + 1;
    const newAvg = (shop.ratingAvg * shop.ratingCount + dto.rating) / newCount;

    const [review] = await this.prisma.$transaction([
      this.prisma.review.create({
        data: { rentalBookingId: dto.bookingId, authorId: renterId, rating: dto.rating, comment: dto.comment },
        include: reviewInclude,
      }),
      this.prisma.rentalShopProfile.update({
        where: { id: shop.id },
        data: { ratingAvg: newAvg, ratingCount: newCount },
      }),
    ]);

    await this.notificationsService.create(
      shop.userId,
      'review_received',
      'New review',
      `You received a ${dto.rating}-star review.`,
    );

    return review;
  }

  async listForRentalShop(rentalShopId: string, page: number, pageSize: number) {
    return this.listReviews({ rentalBooking: { item: { shopId: rentalShopId } } }, page, pageSize);
  }

  private async listReviews(where: Record<string, unknown>, page: number, pageSize: number) {
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
