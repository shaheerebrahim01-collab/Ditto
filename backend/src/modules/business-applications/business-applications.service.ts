import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { BusinessStatus, Role } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateBusinessApplicationDto } from './dto/create-business-application.dto';

// The applicant-facing counterpart to admin.service.ts's PROFILE_ROLE map —
// used here to reject an application for a business type the applicant
// already holds, before it ever reaches the review queue.
const BUSINESS_TYPE_ROLE: Record<string, Role> = {
  tailor: Role.TAILOR,
  rental_shop: Role.RENTAL_SHOP,
  designer: Role.DESIGNER,
  embroidery: Role.EMBROIDERY_SPECIALIST,
};

@Injectable()
export class BusinessApplicationsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(applicantId: string, dto: CreateBusinessApplicationDto) {
    const applicant = await this.prisma.user.findUnique({ where: { id: applicantId } });
    if (!applicant) throw new NotFoundException('Applicant not found');

    if (applicant.role === BUSINESS_TYPE_ROLE[dto.businessType]) {
      throw new BadRequestException(
        `You already have a ${dto.businessType.replace('_', ' ')} account`,
      );
    }

    // One in-flight application at a time, regardless of type — simpler
    // than tracking per-type pending state, and applying for a second
    // business type can wait until the first is decided.
    const existingPending = await this.prisma.businessApplication.findFirst({
      where: { applicantId, status: BusinessStatus.PENDING },
    });
    if (existingPending) {
      throw new BadRequestException('You already have a pending business application');
    }

    return this.prisma.businessApplication.create({
      data: { applicantId, businessType: dto.businessType },
    });
  }
}
