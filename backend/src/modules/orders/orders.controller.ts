import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderStageDto } from './dto/update-order-stage.dto';
import { OrdersService } from './orders.service';

// Everything here needs a logged-in user; the tailor-side routes
// additionally need Role.TAILOR, same split MeasurementVisitsController
// and RentalsController already use.
@UseGuards(JwtAuthGuard)
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  create(@CurrentUser() user: { userId: string }, @Body() dto: CreateOrderDto) {
    return this.ordersService.create(user.userId, dto);
  }

  @Get('me')
  mine(@CurrentUser() user: { userId: string }) {
    return this.ordersService.listMine(user.userId);
  }

  @UseGuards(RolesGuard)
  @Roles(Role.TAILOR)
  @Get('tailor')
  forTailor(@CurrentUser() user: { userId: string }) {
    return this.ordersService.listForTailor(user.userId);
  }

  @UseGuards(RolesGuard)
  @Roles(Role.TAILOR)
  @Patch(':id/stage')
  updateStage(
    @CurrentUser() user: { userId: string },
    @Param('id') id: string,
    @Body() dto: UpdateOrderStageDto,
  ) {
    return this.ordersService.updateStage(user.userId, id, dto.stage);
  }

  // Dynamic :id route last so it doesn't swallow the literal routes above.
  @Get(':id')
  getOne(@CurrentUser() user: { userId: string }, @Param('id') id: string) {
    return this.ordersService.getOne(user.userId, id);
  }
}
