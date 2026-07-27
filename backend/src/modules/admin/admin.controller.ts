import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { BusinessStatus, Role } from '@prisma/client';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { AdminService } from './admin.service';
import { CreateTailorDto } from './dto/create-tailor.dto';
import { CreateUserDto } from './dto/create-user.dto';
import { ReviewApplicationDto } from './dto/review-application.dto';

// `?page=`/`?pageSize=` arrive as strings (or not at all); this is the one
// place that turns them into a valid, bounded page/pageSize pair rather
// than trusting the query string.
function parsePage(value: string | undefined, fallback: number, max: number): number {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 1) return fallback;
  return Math.min(Math.floor(n), max);
}

// Everything here is restricted to Role.ADMIN — the customer/tailor apps
// never call these.
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('stats')
  getStats() {
    return this.adminService.getStats();
  }

  @Get('business-applications')
  listBusinessApplications(@Query('status') status?: BusinessStatus) {
    return this.adminService.listBusinessApplications(status);
  }

  @Post('business-applications/:id/approve')
  approve(@Param('id') id: string, @Body() dto: ReviewApplicationDto) {
    return this.adminService.approveApplication(id, dto.reviewNotes);
  }

  @Post('business-applications/:id/reject')
  reject(@Param('id') id: string, @Body() dto: ReviewApplicationDto) {
    return this.adminService.rejectApplication(id, dto.reviewNotes);
  }

  @Get('users')
  listUsers(
    @Query('role') role?: Role,
    @Query('q') q?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.adminService.listUsers(role, q, parsePage(page, 1, Infinity), parsePage(pageSize, 20, 100));
  }

  @Post('users')
  createUser(@Body() dto: CreateUserDto) {
    return this.adminService.createUser(dto);
  }

  @Post('users/:id/suspend')
  suspendUser(@Param('id') id: string) {
    return this.adminService.suspendUser(id);
  }

  @Post('users/:id/reactivate')
  reactivateUser(@Param('id') id: string) {
    return this.adminService.reactivateUser(id);
  }

  @Get('tailors')
  listTailors(
    @Query('q') q?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.adminService.listTailors(q, parsePage(page, 1, Infinity), parsePage(pageSize, 20, 100));
  }

  @Post('tailors')
  createTailor(@Body() dto: CreateTailorDto) {
    return this.adminService.createTailor(dto);
  }

  @Post('tailors/:id/suspend')
  suspendTailor(@Param('id') id: string) {
    return this.adminService.suspendTailor(id);
  }

  @Post('tailors/:id/reactivate')
  reactivateTailor(@Param('id') id: string) {
    return this.adminService.reactivateTailor(id);
  }

  @Get('rental-shops')
  listRentalShops(
    @Query('q') q?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.adminService.listRentalShops(q, parsePage(page, 1, Infinity), parsePage(pageSize, 20, 100));
  }

  @Post('rental-shops/:id/suspend')
  suspendRentalShop(@Param('id') id: string) {
    return this.adminService.suspendRentalShop(id);
  }

  @Post('rental-shops/:id/reactivate')
  reactivateRentalShop(@Param('id') id: string) {
    return this.adminService.reactivateRentalShop(id);
  }
}
