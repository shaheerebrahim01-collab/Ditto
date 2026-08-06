import { IsEnum } from 'class-validator';
import { OrderStage } from '@prisma/client';

export class UpdateOrderStageDto {
  @IsEnum(OrderStage)
  stage!: OrderStage;
}
