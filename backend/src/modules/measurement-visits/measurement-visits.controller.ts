import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { Role, VisitRequestStatus } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ClaimMeasurementVisitRequestDto } from './dto/claim-measurement-visit-request.dto';
import { CreateMeasurementVisitRequestDto } from './dto/create-measurement-visit-request.dto';
import { MeasurementVisitsService } from './measurement-visits.service';

// Everything here needs a logged-in user; the tailor-side routes
// additionally need Role.TAILOR, applied per-route below — same split
// RentalsController uses for its shop-side routes.
@UseGuards(JwtAuthGuard)
@Controller('measurement-visits')
export class MeasurementVisitsController {
  constructor(private readonly measurementVisitsService: MeasurementVisitsService) {}

  @Post()
  create(@CurrentUser() user: { userId: string }, @Body() dto: CreateMeasurementVisitRequestDto) {
    return this.measurementVisitsService.create(user.userId, dto);
  }

  @Get('me')
  mine(@CurrentUser() user: { userId: string }) {
    return this.measurementVisitsService.listMine(user.userId);
  }

  @Post(':id/cancel')
  cancel(@CurrentUser() user: { userId: string }, @Param('id') id: string) {
    return this.measurementVisitsService.cancel(user.userId, id);
  }

  @UseGuards(RolesGuard)
  @Roles(Role.TAILOR)
  @Get('available')
  available() {
    return this.measurementVisitsService.listAvailable();
  }

  @UseGuards(RolesGuard)
  @Roles(Role.TAILOR)
  @Get('assigned')
  assigned(@CurrentUser() user: { userId: string }, @Query('status') status?: VisitRequestStatus) {
    return this.measurementVisitsService.listAssigned(user.userId, status);
  }

  @UseGuards(RolesGuard)
  @Roles(Role.TAILOR)
  @Post(':id/claim')
  claim(
    @CurrentUser() user: { userId: string },
    @Param('id') id: string,
    @Body() dto: ClaimMeasurementVisitRequestDto,
  ) {
    return this.measurementVisitsService.claim(user.userId, id, dto);
  }

  @UseGuards(RolesGuard)
  @Roles(Role.TAILOR)
  @Post(':id/complete')
  complete(@CurrentUser() user: { userId: string }, @Param('id') id: string) {
    return this.measurementVisitsService.complete(user.userId, id);
  }
}
