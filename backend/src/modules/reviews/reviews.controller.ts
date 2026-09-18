import { BadRequestException, Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateRentalReviewDto } from './dto/create-rental-review.dto';
import { CreateReviewDto } from './dto/create-review.dto';
import { ReviewsService } from './reviews.service';

// Same bounded-parse pagination copied across every public-browse
// controller in this codebase (Admin, Tailors, RentalShops, Notifications).
function parsePage(value: string | undefined, fallback: number, max: number): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 1) return fallback;
  return Math.min(Math.floor(n), max);
}

@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@CurrentUser() user: { userId: string }, @Body() dto: CreateReviewDto) {
    return this.reviewsService.create(user.userId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post('rentals')
  createRentalReview(@CurrentUser() user: { userId: string }, @Body() dto: CreateRentalReviewDto) {
    return this.reviewsService.createForRentalBooking(user.userId, dto);
  }

  // Public — pass exactly one of tailorId/rentalShopId depending on which
  // kind of review list you want; a Review is always against exactly one.
  @Get()
  list(
    @Query('tailorId') tailorId: string | undefined,
    @Query('rentalShopId') rentalShopId: string | undefined,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    if (!tailorId && !rentalShopId) throw new BadRequestException('tailorId or rentalShopId is required');
    if (tailorId && rentalShopId) throw new BadRequestException('Pass only one of tailorId or rentalShopId');
    const p = parsePage(page, 1, Infinity);
    const ps = parsePage(pageSize, 20, 100);
    return tailorId ? this.reviewsService.listForTailor(tailorId, p, ps) : this.reviewsService.listForRentalShop(rentalShopId!, p, ps);
  }
}
