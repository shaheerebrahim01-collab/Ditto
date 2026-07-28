import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateMeasurementDto } from './dto/create-measurement.dto';
import { UpdateMeasurementDto } from './dto/update-measurement.dto';

@Injectable()
export class MeasurementsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string) {
    return this.prisma.measurement.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(userId: string, dto: CreateMeasurementDto) {
    return this.prisma.measurement.create({
      data: { userId, ...dto },
    });
  }

  async update(userId: string, id: string, dto: UpdateMeasurementDto) {
    await this.getOwnedOrThrow(userId, id);
    return this.prisma.measurement.update({
      where: { id },
      data: dto,
    });
  }

  async remove(userId: string, id: string) {
    await this.getOwnedOrThrow(userId, id);
    try {
      await this.prisma.measurement.delete({ where: { id } });
    } catch (err) {
      // A CustomOrder can reference a Measurement (measurementId) — same
      // FK-on-delete situation RentalShopsService already handles for
      // RentalItem, turned into a 409 instead of a raw 500.
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2003') {
        throw new ConflictException('Cannot delete a measurement that an order references');
      }
      throw err;
    }
  }

  private async getOwnedOrThrow(userId: string, id: string) {
    const measurement = await this.prisma.measurement.findUnique({ where: { id } });
    if (!measurement || measurement.userId !== userId) {
      throw new NotFoundException('Measurement not found');
    }
    return measurement;
  }
}
