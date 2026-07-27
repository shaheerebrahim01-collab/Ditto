import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { BusinessStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateRentalItemDto } from './dto/create-rental-item.dto';
import { UpdateRentalItemDto } from './dto/update-rental-item.dto';
import { UpdateRentalShopDto } from './dto/update-rental-shop.dto';

@Injectable()
export class RentalShopsService {
  constructor(private readonly prisma: PrismaService) {}

  // Public browse — approved shops only, same scope every other
  // customer-facing listing in this codebase uses.
  async listShops(q: string | undefined, page: number, pageSize: number) {
    const where: Prisma.RentalShopProfileWhereInput = {
      status: BusinessStatus.APPROVED,
      ...(q ? { businessName: { contains: q, mode: 'insensitive' } } : {}),
    };
    const [shops, total] = await Promise.all([
      this.prisma.rentalShopProfile.findMany({
        where,
        orderBy: { businessName: 'asc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
        include: { _count: { select: { items: true } } },
      }),
      this.prisma.rentalShopProfile.count({ where }),
    ]);
    return {
      data: shops.map(({ _count, ...shop }) => ({ ...shop, itemCount: _count.items })),
      total,
      page,
      pageSize,
    };
  }

  async getShop(id: string) {
    const shop = await this.prisma.rentalShopProfile.findFirst({
      where: { id, status: BusinessStatus.APPROVED },
      include: { items: true },
    });
    if (!shop) throw new NotFoundException('Rental shop not found');
    return shop;
  }

  async getMyShop(userId: string) {
    const shop = await this.prisma.rentalShopProfile.findUnique({ where: { userId } });
    if (!shop) throw new NotFoundException('No rental shop profile for this account');
    return shop;
  }

  async updateMyShop(userId: string, dto: UpdateRentalShopDto) {
    await this.getMyShop(userId);
    return this.prisma.rentalShopProfile.update({ where: { userId }, data: dto });
  }

  async listMyItems(userId: string) {
    const shop = await this.getMyShop(userId);
    return this.prisma.rentalItem.findMany({ where: { shopId: shop.id }, orderBy: { name: 'asc' } });
  }

  async createItem(userId: string, dto: CreateRentalItemDto) {
    const shop = await this.getMyShop(userId);
    return this.prisma.rentalItem.create({ data: { ...dto, shopId: shop.id } });
  }

  async updateItem(userId: string, itemId: string, dto: UpdateRentalItemDto) {
    const item = await this.getOwnedItem(userId, itemId);
    return this.prisma.rentalItem.update({ where: { id: item.id }, data: dto });
  }

  async deleteItem(userId: string, itemId: string) {
    const item = await this.getOwnedItem(userId, itemId);
    try {
      await this.prisma.rentalItem.delete({ where: { id: item.id } });
    } catch (err) {
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2003') {
        throw new ConflictException('Cannot delete an item that has bookings against it');
      }
      throw err;
    }
    return { deleted: true };
  }

  // Same NotFoundException whether the item doesn't exist at all or just
  // belongs to a different shop — the caller can't tell which from the
  // outside, and doesn't need to.
  private async getOwnedItem(userId: string, itemId: string) {
    const shop = await this.getMyShop(userId);
    const item = await this.prisma.rentalItem.findUnique({ where: { id: itemId } });
    if (!item || item.shopId !== shop.id) throw new NotFoundException('Rental item not found');
    return item;
  }
}
