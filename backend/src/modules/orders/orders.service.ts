import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { BusinessStatus, OrderStage } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { computeOrderPrice } from './garment-pricing';

// The sequence a real order actually moves through — updateStage only
// allows moving forward one or more steps at a time, never sideways or
// backward, so a tailor can't accidentally (or maliciously) un-confirm a
// paid order.
const STAGE_ORDER: OrderStage[] = [
  OrderStage.ORDER_CONFIRMED,
  OrderStage.FABRIC_SELECTED,
  OrderStage.CUTTING,
  OrderStage.STITCHING,
  OrderStage.EMBROIDERY,
  OrderStage.QUALITY_CHECK,
  OrderStage.PACKED,
  OrderStage.OUT_FOR_DELIVERY,
  OrderStage.DELIVERED,
];

const tailorViewInclude = {
  customer: { select: { fullName: true, email: true, phone: true } },
} as const;

const customerViewInclude = {
  tailor: { select: { businessName: true } },
} as const;

@Injectable()
export class OrdersService {
  constructor(private readonly prisma: PrismaService) {}

  async create(customerId: string, dto: CreateOrderDto) {
    const tailor = await this.prisma.tailorProfile.findUnique({ where: { id: dto.tailorId } });
    if (!tailor || tailor.status !== BusinessStatus.APPROVED) {
      throw new NotFoundException('Tailor not found');
    }

    if (dto.measurementId) {
      const measurement = await this.prisma.measurement.findUnique({ where: { id: dto.measurementId } });
      if (!measurement || measurement.userId !== customerId) {
        throw new NotFoundException('Measurement not found');
      }
    }

    const price = computeOrderPrice(dto);

    return this.prisma.customOrder.create({
      data: {
        customerId,
        tailorId: dto.tailorId,
        garmentType: dto.garmentTypeId,
        fabric: dto.fabricId,
        measurementId: dto.measurementId,
        price,
        detailsJson: {
          lapelStyle: dto.lapelStyle ?? 'Notch',
          buttonStyle: dto.buttonStyle ?? '2-Button',
          monogram: dto.monogram ?? null,
        },
      },
      include: customerViewInclude,
    });
  }

  async listMine(customerId: string) {
    return this.prisma.customOrder.findMany({
      where: { customerId },
      orderBy: { createdAt: 'desc' },
      include: customerViewInclude,
    });
  }

  async listForTailor(tailorUserId: string) {
    const tailor = await this.getTailorOrThrow(tailorUserId);
    return this.prisma.customOrder.findMany({
      where: { tailorId: tailor.id },
      orderBy: { createdAt: 'desc' },
      include: tailorViewInclude,
    });
  }

  async getOne(userId: string, id: string) {
    const order = await this.prisma.customOrder.findUnique({
      where: { id },
      include: { ...customerViewInclude, ...tailorViewInclude },
    });
    if (!order) throw new NotFoundException('Order not found');

    const tailor = await this.prisma.tailorProfile.findUnique({ where: { id: order.tailorId } });
    const isOwnCustomer = order.customerId === userId;
    const isOwnTailor = tailor?.userId === userId;
    if (!isOwnCustomer && !isOwnTailor) throw new NotFoundException('Order not found');

    return order;
  }

  async updateStage(tailorUserId: string, id: string, stage: OrderStage) {
    const tailor = await this.getTailorOrThrow(tailorUserId);
    const order = await this.prisma.customOrder.findUnique({ where: { id } });
    if (!order || order.tailorId !== tailor.id) throw new NotFoundException('Order not found');

    const currentIndex = STAGE_ORDER.indexOf(order.stage);
    const nextIndex = STAGE_ORDER.indexOf(stage);
    if (nextIndex <= currentIndex) {
      throw new BadRequestException(
        `Cannot move from ${order.stage} to ${stage} — stage can only move forward`,
      );
    }

    return this.prisma.customOrder.update({ where: { id }, data: { stage } });
  }

  private async getTailorOrThrow(userId: string) {
    const tailor = await this.prisma.tailorProfile.findUnique({ where: { userId } });
    if (!tailor) throw new NotFoundException('No tailor profile for this account');
    return tailor;
  }
}
