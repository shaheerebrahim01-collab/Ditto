import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { RentalStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateRentalBookingDto } from './dto/create-rental-booking.dto';

const ACTIVE_STATUSES: RentalStatus[] = [RentalStatus.RESERVED, RentalStatus.PICKED_UP];
const MS_PER_DAY = 24 * 60 * 60 * 1000;

const bookingInclude = {
  item: { include: { shop: { select: { businessName: true } } } },
} as const;

@Injectable()
export class RentalsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async createBooking(renterId: string, dto: CreateRentalBookingDto) {
    const pickupDate = new Date(dto.pickupDate);
    const returnDate = new Date(dto.returnDate);
    if (pickupDate >= returnDate) {
      throw new BadRequestException('returnDate must be after pickupDate');
    }
    const startOfToday = new Date();
    startOfToday.setUTCHours(0, 0, 0, 0);
    if (pickupDate < startOfToday) {
      throw new BadRequestException('pickupDate cannot be in the past');
    }

    const item = await this.prisma.rentalItem.findUnique({
      where: { id: dto.itemId },
      include: { shop: { select: { userId: true } } },
    });
    if (!item) throw new NotFoundException('Rental item not found');

    // Overlap: an existing active booking's range intersects the requested
    // one — [pickupDate, returnDate) treated as half-open so a same-day
    // return/pickup handoff isn't flagged as a conflict.
    const overlapping = await this.prisma.rentalBooking.findFirst({
      where: {
        itemId: item.id,
        status: { in: ACTIVE_STATUSES },
        pickupDate: { lt: returnDate },
        returnDate: { gt: pickupDate },
      },
    });
    if (overlapping) {
      throw new BadRequestException('This item is already booked for part of that date range');
    }

    const booking = await this.prisma.rentalBooking.create({
      data: { itemId: item.id, renterId, pickupDate, returnDate },
      include: bookingInclude,
    });
    await this.notificationsService.create(
      item.shop.userId,
      'booking_created',
      'New rental booking',
      `${booking.item.name} was just booked.`,
    );
    return booking;
  }

  async listMyBookings(renterId: string) {
    return this.prisma.rentalBooking.findMany({
      where: { renterId },
      orderBy: { pickupDate: 'desc' },
      include: bookingInclude,
    });
  }

  async cancelBooking(renterId: string, id: string) {
    const booking = await this.prisma.rentalBooking.findUnique({ where: { id } });
    if (!booking || booking.renterId !== renterId) throw new NotFoundException('Booking not found');
    if (booking.status !== RentalStatus.RESERVED) {
      throw new BadRequestException(
        `Cannot cancel a booking that's already ${booking.status.toLowerCase()}`,
      );
    }
    return this.prisma.rentalBooking.update({
      where: { id },
      data: { status: RentalStatus.CANCELLED },
    });
  }

  async listShopBookings(shopUserId: string, status?: RentalStatus) {
    const shop = await this.getShopOrThrow(shopUserId);
    const bookings = await this.prisma.rentalBooking.findMany({
      where: { item: { shopId: shop.id }, ...(status ? { status } : {}) },
      orderBy: { pickupDate: 'desc' },
      include: { item: true, renter: { select: { fullName: true, email: true, phone: true } } },
    });
    // No scheduled job flips bookings to RentalStatus.LATE (that needs
    // Phase 11's infra), so "overdue" is computed here instead of stored.
    const now = new Date();
    return bookings.map((b) => ({
      ...b,
      overdue: b.status === RentalStatus.PICKED_UP && b.returnDate < now,
    }));
  }

  async markPickedUp(shopUserId: string, id: string) {
    const booking = await this.getOwnedBooking(shopUserId, id);
    if (booking.status !== RentalStatus.RESERVED) {
      throw new BadRequestException(`Cannot mark ${booking.status.toLowerCase()} as picked up`);
    }
    return this.prisma.rentalBooking.update({
      where: { id },
      data: { status: RentalStatus.PICKED_UP },
    });
  }

  async markReturned(shopUserId: string, id: string) {
    const booking = await this.getOwnedBooking(shopUserId, id);
    if (booking.status !== RentalStatus.PICKED_UP) {
      throw new BadRequestException(`Cannot mark ${booking.status.toLowerCase()} as returned`);
    }
    const now = new Date();
    let lateFee = 0;
    if (now > booking.returnDate) {
      const daysLate = Math.ceil((now.getTime() - booking.returnDate.getTime()) / MS_PER_DAY);
      lateFee = daysLate * booking.item.pricePerDay;
    }
    const updated = await this.prisma.rentalBooking.update({
      where: { id },
      data: { status: RentalStatus.RETURNED, lateFee },
    });
    await this.notificationsService.create(
      booking.renterId,
      'booking_returned',
      'Rental return confirmed',
      lateFee > 0
        ? `Your return was confirmed with a late fee of $${lateFee.toFixed(2)}.`
        : 'Your rental return was confirmed — thanks for returning it on time.',
    );
    return updated;
  }

  private async getShopOrThrow(userId: string) {
    const shop = await this.prisma.rentalShopProfile.findUnique({ where: { userId } });
    if (!shop) throw new NotFoundException('No rental shop profile for this account');
    return shop;
  }

  private async getOwnedBooking(shopUserId: string, id: string) {
    const shop = await this.getShopOrThrow(shopUserId);
    const booking = await this.prisma.rentalBooking.findUnique({ where: { id }, include: { item: true } });
    if (!booking || booking.item.shopId !== shop.id) throw new NotFoundException('Booking not found');
    return booking;
  }
}
