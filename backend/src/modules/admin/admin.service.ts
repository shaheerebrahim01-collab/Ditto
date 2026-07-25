import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { BusinessStatus, Role } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async getStats() {
    const [userCount, tailorCount, pendingApprovals, revenueAgg] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.tailorProfile.count(),
      this.prisma.businessApplication.count({ where: { status: BusinessStatus.PENDING } }),
      this.prisma.payment.aggregate({
        where: { status: 'succeeded' },
        _sum: { amount: true },
      }),
    ]);

    return {
      userCount,
      tailorCount,
      pendingApprovals,
      totalRevenue: revenueAgg._sum.amount ?? 0,
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

  async listTailors() {
    return this.prisma.tailorProfile.findMany({
      include: { user: { select: { fullName: true, email: true, phone: true } } },
      orderBy: { businessName: 'asc' },
    });
  }
}
