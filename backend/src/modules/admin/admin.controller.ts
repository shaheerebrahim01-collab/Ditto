import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { BusinessStatus, Role } from '@prisma/client';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { AdminService } from './admin.service';
import { ReviewApplicationDto } from './dto/review-application.dto';

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
  listUsers(@Query('role') role?: Role) {
    return this.adminService.listUsers(role);
  }

  @Get('tailors')
  listTailors() {
    return this.adminService.listTailors();
  }
}
