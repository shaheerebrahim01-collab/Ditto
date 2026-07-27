import { IsOptional, IsString, MinLength } from 'class-validator';

export class UpdateRentalShopDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  businessName?: string;
}
