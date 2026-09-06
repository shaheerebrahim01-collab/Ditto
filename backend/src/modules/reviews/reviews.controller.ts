import { BadRequestException, Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
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

  // Public — every Review is against a CustomOrder, so tailorId is the only
  // scope that makes sense today (no rental-booking reviews in the schema yet).
  @Get()
  list(@Query('tailorId') tailorId: string, @Query('page') page?: string, @Query('pageSize') pageSize?: string) {
    if (!tailorId) throw new BadRequestException('tailorId is required');
    return this.reviewsService.listForTailor(tailorId, parsePage(page, 1, Infinity), parsePage(pageSize, 20, 100));
  }
}
