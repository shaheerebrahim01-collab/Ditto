import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { BusinessStatus, OrderStage, Prisma, Role } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTailorDto } from './dto/create-tailor.dto';
import { CreateUserDto } from './dto/create-user.dto';

// A user created straight from the admin dashboard hasn't signed in via
// Firebase yet — auth.service.ts's find-or-create still matches them by
// email/phone the first time they do, so this is just a marker that the
// row didn't originate from a real sign-in provider.
const ADMIN_PROVISIONED = 'admin';

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

  async listUsers(role: Role | undefined, q: string | undefined, page: number, pageSize: number) {
    const where: Prisma.UserWhereInput = {
      ...(role ? { role } : {}),
      ...(q
        ? {
            OR: [
              { fullName: { contains: q, mode: 'insensitive' } },
              { email: { contains: q, mode: 'insensitive' } },
              { phone: { contains: q, mode: 'insensitive' } },
            ],
          }
        : {}),
    };
    const [data, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.user.count({ where }),
    ]);
    return { data, total, page, pageSize };
  }

  async createUser(dto: CreateUserDto) {
    if (!dto.email && !dto.phone) {
      throw new BadRequestException('Provide at least an email or a phone number');
    }
    try {
      return await this.prisma.user.create({
        data: {
          fullName: dto.fullName,
          email: dto.email ?? null,
          phone: dto.phone ?? null,
          role: dto.role ?? Role.CUSTOMER,
          authProvider: ADMIN_PROVISIONED,
        },
      });
    } catch (err) {
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
        throw new ConflictException('A user with that email or phone already exists');
      }
      throw err;
    }
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

  async listTailors(q: string | undefined, page: number, pageSize: number) {
    const where: Prisma.TailorProfileWhereInput = q
      ? {
          OR: [
            { businessName: { contains: q, mode: 'insensitive' } },
            { user: { fullName: { contains: q, mode: 'insensitive' } } },
          ],
        }
      : {};
    const [tailors, total] = await Promise.all([
      this.prisma.tailorProfile.findMany({
        where,
        include: this.tailorInclude,
        orderBy: { businessName: 'asc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.tailorProfile.count({ where }),
    ]);
    return { data: tailors.map((t) => this.shapeTailor(t)), total, page, pageSize };
  }

  async createTailor(dto: CreateTailorDto) {
    if (!dto.email && !dto.phone) {
      throw new BadRequestException('Provide at least an email or a phone number');
    }
    try {
      const tailor = await this.prisma.$transaction(async (tx) => {
        const user = await tx.user.create({
          data: {
            fullName: dto.fullName,
            email: dto.email ?? null,
            phone: dto.phone ?? null,
            role: Role.TAILOR,
            authProvider: ADMIN_PROVISIONED,
          },
        });
        return tx.tailorProfile.create({
          data: {
            userId: user.id,
            businessName: dto.businessName,
            bio: dto.bio ?? null,
            specialties: dto.specialties ?? [],
            deliveryRadiusKm: dto.deliveryRadiusKm ?? null,
            // Admin-onboarded directly, bypassing the pending-application
            // queue — the admin is vetting it out of band.
            status: BusinessStatus.APPROVED,
          },
          include: this.tailorInclude,
        });
      });
      return this.shapeTailor(tailor);
    } catch (err) {
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
        throw new ConflictException('A user with that email or phone already exists');
      }
      throw err;
    }
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
