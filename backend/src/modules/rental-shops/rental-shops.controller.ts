import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CreateRentalItemDto } from './dto/create-rental-item.dto';
import { UpdateRentalItemDto } from './dto/update-rental-item.dto';
import { UpdateRentalShopDto } from './dto/update-rental-shop.dto';
import { RentalShopsService } from './rental-shops.service';

// `?page=`/`?pageSize=` handling copied from AdminController — same
// bounded-parse, no shared helper yet since there's no shared module
// between admin and customer-facing controllers.
function parsePage(value: string | undefined, fallback: number, max: number): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 1) return fallback;
  return Math.min(Math.floor(n), max);
}

@Controller('rental-shops')
export class RentalShopsController {
  constructor(private readonly rentalShopsService: RentalShopsService) {}

  @Get()
  list(@Query('q') q?: string, @Query('page') page?: string, @Query('pageSize') pageSize?: string) {
    return this.rentalShopsService.listShops(q, parsePage(page, 1, Infinity), parsePage(pageSize, 20, 100));
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.RENTAL_SHOP)
  @Get('me')
  getMine(@CurrentUser() user: { userId: string }) {
    return this.rentalShopsService.getMyShop(user.userId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.RENTAL_SHOP)
  @Patch('me')
  updateMine(@CurrentUser() user: { userId: string }, @Body() dto: UpdateRentalShopDto) {
    return this.rentalShopsService.updateMyShop(user.userId, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.RENTAL_SHOP)
  @Get('me/items')
  listMyItems(@CurrentUser() user: { userId: string }) {
    return this.rentalShopsService.listMyItems(user.userId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.RENTAL_SHOP)
  @Post('me/items')
  createItem(@CurrentUser() user: { userId: string }, @Body() dto: CreateRentalItemDto) {
    return this.rentalShopsService.createItem(user.userId, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.RENTAL_SHOP)
  @Patch('me/items/:id')
  updateItem(
    @CurrentUser() user: { userId: string },
    @Param('id') id: string,
    @Body() dto: UpdateRentalItemDto,
  ) {
    return this.rentalShopsService.updateItem(user.userId, id, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.RENTAL_SHOP)
  @Delete('me/items/:id')
  deleteItem(@CurrentUser() user: { userId: string }, @Param('id') id: string) {
    return this.rentalShopsService.deleteItem(user.userId, id);
  }

  // Dynamic :id route last so it doesn't swallow the literal `me` routes
  // above.
  @Get(':id')
  getOne(@Param('id') id: string) {
    return this.rentalShopsService.getShop(id);
  }
}
