import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { VisitRequestStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { ClaimMeasurementVisitRequestDto } from './dto/claim-measurement-visit-request.dto';
import { CreateMeasurementVisitRequestDto } from './dto/create-measurement-visit-request.dto';

const CANCELLABLE_STATUSES: VisitRequestStatus[] = [VisitRequestStatus.PENDING, VisitRequestStatus.ASSIGNED];

const tailorViewInclude = {
  customer: { select: { fullName: true, email: true, phone: true } },
} as const;

@Injectable()
export class MeasurementVisitsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(customerId: string, dto: CreateMeasurementVisitRequestDto) {
    const preferredAt = new Date(dto.preferredAt);
    if (preferredAt < new Date()) {
      throw new BadRequestException('preferredAt cannot be in the past');
    }
    return this.prisma.measurementVisitRequest.create({
      data: {
        customerId,
        location: dto.location,
        preferredAt,
        notes: dto.notes,
      },
    });
  }

  async listMine(customerId: string) {
    return this.prisma.measurementVisitRequest.findMany({
      where: { customerId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async cancel(customerId: string, id: string) {
    const request = await this.prisma.measurementVisitRequest.findUnique({ where: { id } });
    if (!request || request.customerId !== customerId) {
      throw new NotFoundException('Visit request not found');
    }
    if (!CANCELLABLE_STATUSES.includes(request.status)) {
      throw new BadRequestException(`Cannot cancel a request that's already ${request.status.toLowerCase()}`);
    }
    return this.prisma.measurementVisitRequest.update({
      where: { id },
      data: { status: VisitRequestStatus.CANCELLED },
    });
  }

  // Open pool — every tailor sees the same unclaimed requests, first to
  // claim gets it. Unlike CustomOrder, nothing here starts pointed at a
  // specific tailor.
  async listAvailable() {
    return this.prisma.measurementVisitRequest.findMany({
      where: { status: VisitRequestStatus.PENDING },
      orderBy: { preferredAt: 'asc' },
      include: tailorViewInclude,
    });
  }

  async listAssigned(tailorUserId: string, status?: VisitRequestStatus) {
    const tailor = await this.getTailorOrThrow(tailorUserId);
    return this.prisma.measurementVisitRequest.findMany({
      where: { tailorId: tailor.id, ...(status ? { status } : {}) },
      orderBy: { preferredAt: 'asc' },
      include: tailorViewInclude,
    });
  }

  async claim(tailorUserId: string, id: string, dto: ClaimMeasurementVisitRequestDto) {
    const tailor = await this.getTailorOrThrow(tailorUserId);
    const request = await this.prisma.measurementVisitRequest.findUnique({ where: { id } });
    if (!request) throw new NotFoundException('Visit request not found');
    if (request.status !== VisitRequestStatus.PENDING) {
      throw new BadRequestException(`Cannot claim a request that's already ${request.status.toLowerCase()}`);
    }

    if (dto.assistantId) {
      const assistant = await this.prisma.tailorAssistant.findUnique({ where: { id: dto.assistantId } });
      if (!assistant || assistant.tailorId !== tailor.id) {
        throw new NotFoundException('Assistant not found on your roster');
      }
    }

    return this.prisma.measurementVisitRequest.update({
      where: { id },
      data: {
        tailorId: tailor.id,
        assistantId: dto.assistantId,
        status: VisitRequestStatus.ASSIGNED,
      },
    });
  }

  async complete(tailorUserId: string, id: string) {
    const request = await this.getOwnedByTailor(tailorUserId, id);
    if (request.status !== VisitRequestStatus.ASSIGNED) {
      throw new BadRequestException(`Cannot complete a request that's ${request.status.toLowerCase()}`);
    }
    return this.prisma.measurementVisitRequest.update({
      where: { id },
      data: { status: VisitRequestStatus.COMPLETED },
    });
  }

  private async getTailorOrThrow(userId: string) {
    const tailor = await this.prisma.tailorProfile.findUnique({ where: { userId } });
    if (!tailor) throw new NotFoundException('No tailor profile for this account');
    return tailor;
  }

  private async getOwnedByTailor(tailorUserId: string, id: string) {
    const tailor = await this.getTailorOrThrow(tailorUserId);
    const request = await this.prisma.measurementVisitRequest.findUnique({ where: { id } });
    if (!request || request.tailorId !== tailor.id) {
      throw new NotFoundException('Visit request not found');
    }
    return request;
  }
}
