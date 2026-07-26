import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { BusinessStatus, OrderStage, Role } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async getStats() {
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const [userCount, tailorCount, pendingApprovals, revenueAgg, ordersThisMonth] =
      await Promise.all([
        this.prisma.user.count(),
        this.prisma.tailorProfile.count(),
        this.prisma.businessApplication.count({ where: { status: BusinessStatus.PENDING } }),
        this.prisma.payment.aggregate({
          where: { status: 'succeeded' },
          _sum: { amount: true },
        }),
        this.prisma.customOrder.count({ where: { createdAt: { gte: startOfMonth } } }),
      ]);

    return {
      userCount,
      tailorCount,
      pendingApprovals,
      totalRevenue: revenueAgg._sum.amount ?? 0,
      ordersThisMonth,
    };
  }

  // BusinessApplication.applicantId has no Prisma relation to User (schema
  // only stores the raw id), so the applicant's name/email is joined here
  // in application code rather than via `include`.
  async listBusinessApplications(status?: BusinessStatus) {
    const applications = await this.prisma.businessApplication.findMany({
      where: status ? { status } : undefined,
      orderBy: { submittedAt: 'desc' },
    });

    const applicantIds = [...new Set(applications.map((a) => a.applicantId))];
    const applicants = await this.prisma.user.findMany({
      where: { id: { in: applicantIds } },
      select: { id: true, fullName: true, email: true, phone: true },
    });
    const applicantById = new Map(applicants.map((u) => [u.id, u]));

    return applications.map((application) => ({
      ...application,
      applicant: applicantById.get(application.applicantId) ?? null,
    }));
  }

  async approveApplication(id: string, reviewNotes?: string) {
    return this.reviewApplication(id, BusinessStatus.APPROVED, reviewNotes);
  }

  async rejectApplication(id: string, reviewNotes?: string) {
    return this.reviewApplication(id, BusinessStatus.REJECTED, reviewNotes);
  }

  private async reviewApplication(id: string, status: BusinessStatus, reviewNotes?: string) {
    const application = await this.prisma.businessApplication.findUnique({ where: { id } });
    if (!application) throw new NotFoundException('Business application not found');
    if (application.status !== BusinessStatus.PENDING) {
      throw new BadRequestException(`Application already ${application.status.toLowerCase()}`);
    }
    return this.prisma.businessApplication.update({
      where: { id },
      data: { status, reviewedAt: new Date(), reviewNotes },
    });
  }

  async listUsers(role?: Role) {
    return this.prisma.user.findMany({
      where: role ? { role } : undefined,
      orderBy: { createdAt: 'desc' },
    });
  }

  async suspendUser(id: string) {
    return this.setUserSuspended(id, true);
  }

  async reactivateUser(id: string) {
    return this.setUserSuspended(id, false);
  }

  private async setUserSuspended(id: string, suspended: boolean) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('User not found');
    if (user.suspended === suspended) {
      throw new BadRequestException(`User is already ${suspended ? 'suspended' : 'active'}`);
    }
    return this.prisma.user.update({ where: { id }, data: { suspended } });
  }

  // Only the order count is needed here, not the orders themselves —
  // selecting just `id` keeps the query from pulling full rows.
  private tailorInclude = {
    user: { select: { fullName: true, email: true, phone: true } },
    orders: { where: { stage: OrderStage.DELIVERED }, select: { id: true } },
  } as const;

  private shapeTailor<T extends { orders: { id: string }[] }>(tailor: T) {
    const { orders, ...rest } = tailor;
    return { ...rest, completedOrders: orders.length };
  }

  async listTailors() {
    const tailors = await this.prisma.tailorProfile.findMany({
      include: this.tailorInclude,
      orderBy: { businessName: 'asc' },
    });
    return tailors.map((t) => this.shapeTailor(t));
  }

  async suspendTailor(id: string) {
    return this.setTailorStatus(id, BusinessStatus.APPROVED, BusinessStatus.SUSPENDED);
  }

  async reactivateTailor(id: string) {
    return this.setTailorStatus(id, BusinessStatus.SUSPENDED, BusinessStatus.APPROVED);
  }

  // Only APPROVED <-> SUSPENDED is a valid transition here — PENDING and
  // REJECTED go through reviewApplication instead.
  private async setTailorStatus(id: string, from: BusinessStatus, to: BusinessStatus) {
    const tailor = await this.prisma.tailorProfile.findUnique({ where: { id } });
    if (!tailor) throw new NotFoundException('Tailor not found');
    if (tailor.status !== from) {
      throw new BadRequestException(
        `Cannot move tailor from ${tailor.status.toLowerCase()} to ${to.toLowerCase()}`,
      );
    }
    const updated = await this.prisma.tailorProfile.update({
      where: { id },
      data: { status: to },
      include: this.tailorInclude,
    });
    return this.shapeTailor(updated);
  }
}
