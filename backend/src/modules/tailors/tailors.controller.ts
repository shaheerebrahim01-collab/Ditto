import { Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { UpdateTailorProfileDto } from './dto/update-tailor-profile.dto';
import { TailorsService } from './tailors.service';

// Same bounded-parse pagination copied across every public-browse
// controller in this codebase (Admin, RentalShops, Notifications) — no
// shared module ties them together yet.
function parsePage(value: string | undefined, fallback: number, max: number): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 1) return fallback;
  return Math.min(Math.floor(n), max);
}

@Controller('tailors')
export class TailorsController {
  constructor(private readonly tailorsService: TailorsService) {}

  @Get()
  list(
    @Query('q') q?: string,
    @Query('specialty') specialty?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.tailorsService.listTailors(q, specialty, parsePage(page, 1, Infinity), parsePage(pageSize, 20, 100));
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.TAILOR)
  @Get('me')
  getMine(@CurrentUser() user: { userId: string }) {
    return this.tailorsService.getMyProfile(user.userId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.TAILOR)
  @Patch('me')
  updateMine(@CurrentUser() user: { userId: string }, @Body() dto: UpdateTailorProfileDto) {
    return this.tailorsService.updateMyProfile(user.userId, dto);
  }

  // Dynamic :id route last so it doesn't swallow the literal `me` route above.
  @Get(':id')
  getOne(@Param('id') id: string) {
    return this.tailorsService.getTailor(id);
  }
}
