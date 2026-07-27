import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { RentalStatus, Role } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CreateRentalBookingDto } from './dto/create-rental-booking.dto';
import { RentalsService } from './rentals.service';

// Everything here needs a logged-in user; the shop-side routes additionally
// need Role.RENTAL_SHOP, applied per-route below.
@UseGuards(JwtAuthGuard)
@Controller('rentals')
export class RentalsController {
  constructor(private readonly rentalsService: RentalsService) {}

  @Post()
  create(@CurrentUser() user: { userId: string }, @Body() dto: CreateRentalBookingDto) {
    return this.rentalsService.createBooking(user.userId, dto);
  }

  @Get('me')
  mine(@CurrentUser() user: { userId: string }) {
    return this.rentalsService.listMyBookings(user.userId);
  }

  @Post(':id/cancel')
  cancel(@CurrentUser() user: { userId: string }, @Param('id') id: string) {
    return this.rentalsService.cancelBooking(user.userId, id);
  }

  @UseGuards(RolesGuard)
  @Roles(Role.RENTAL_SHOP)
  @Get('shop')
  shopBookings(@CurrentUser() user: { userId: string }, @Query('status') status?: RentalStatus) {
    return this.rentalsService.listShopBookings(user.userId, status);
  }

  @UseGuards(RolesGuard)
  @Roles(Role.RENTAL_SHOP)
  @Post(':id/pickup')
  pickup(@CurrentUser() user: { userId: string }, @Param('id') id: string) {
    return this.rentalsService.markPickedUp(user.userId, id);
  }

  @UseGuards(RolesGuard)
  @Roles(Role.RENTAL_SHOP)
  @Post(':id/return')
  returnItem(@CurrentUser() user: { userId: string }, @Param('id') id: string) {
    return this.rentalsService.markReturned(user.userId, id);
  }
}
