import { Injectable, NotFoundException } from '@nestjs/common';
import { BusinessStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdateTailorProfileDto } from './dto/update-tailor-profile.dto';

@Injectable()
export class TailorsService {
  constructor(private readonly prisma: PrismaService) {}

  // Public browse — approved tailors only, same scope
  // RentalShopsService.listShops uses. Optional `specialty` filters on the
  // specialties array (mirrors HomeScreen's category-chip UI, even though
  // that screen still renders from mock data — this is the real endpoint
  // waiting for it).
  async listTailors(q: string | undefined, specialty: string | undefined, page: number, pageSize: number) {
    const where: Prisma.TailorProfileWhereInput = {
      status: BusinessStatus.APPROVED,
      ...(q ? { businessName: { contains: q, mode: 'insensitive' } } : {}),
      ...(specialty ? { specialties: { has: specialty } } : {}),
    };
    const [tailors, total] = await Promise.all([
      this.prisma.tailorProfile.findMany({
        where,
        orderBy: { businessName: 'asc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.tailorProfile.count({ where }),
    ]);
    return { data: tailors, total, page, pageSize };
  }

  async getTailor(id: string) {
    const tailor = await this.prisma.tailorProfile.findFirst({
      where: { id, status: BusinessStatus.APPROVED },
      include: { portfolio: { orderBy: { createdAt: 'desc' } } },
    });
    if (!tailor) throw new NotFoundException('Tailor not found');
    return tailor;
  }

  async getMyProfile(userId: string) {
    const tailor = await this.prisma.tailorProfile.findUnique({ where: { userId } });
    if (!tailor) throw new NotFoundException('No tailor profile for this account');
    return tailor;
  }

  async updateMyProfile(userId: string, dto: UpdateTailorProfileDto) {
    await this.getMyProfile(userId);
    return this.prisma.tailorProfile.update({
      where: { userId },
      data: { ...dto, workingHours: dto.workingHours as Prisma.InputJsonValue | undefined },
    });
  }
}
