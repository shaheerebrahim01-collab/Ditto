import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { BusinessApplicationsService } from './business-applications.service';
import { CreateBusinessApplicationDto } from './dto/create-business-application.dto';

// Any authenticated user can apply to become a business — deliberately
// not behind Role.ADMIN like everything under /admin/*. This is the
// applicant-facing counterpart to AdminController's approve/reject.
@UseGuards(JwtAuthGuard)
@Controller('business-applications')
export class BusinessApplicationsController {
  constructor(private readonly businessApplicationsService: BusinessApplicationsService) {}

  @Post()
  create(@CurrentUser() user: { userId: string }, @Body() dto: CreateBusinessApplicationDto) {
    return this.businessApplicationsService.create(user.userId, dto);
  }
}
