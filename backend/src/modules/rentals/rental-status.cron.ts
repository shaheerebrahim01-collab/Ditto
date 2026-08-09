import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { RentalStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

// Flips PICKED_UP bookings to LATE once their returnDate has passed.
// RentalStatus.LATE existed in the schema since Phase 2 but nothing ever
// wrote it — listShopBookings computed an `overdue` boolean on the fly
// instead, with a comment noting the real fix needed "a scheduled job,
// which is Phase 11 infrastructure." This is that job.
@Injectable()
export class RentalStatusCron {
  private readonly logger = new Logger(RentalStatusCron.name);

  constructor(private readonly prisma: PrismaService) {}

  @Cron(CronExpression.EVERY_HOUR)
  async flagOverdueBookings() {
    const { count } = await this.prisma.rentalBooking.updateMany({
      where: { status: RentalStatus.PICKED_UP, returnDate: { lt: new Date() } },
      data: { status: RentalStatus.LATE },
    });
    if (count > 0) {
      this.logger.log(`Flagged ${count} booking(s) as LATE`);
    }
  }
}
