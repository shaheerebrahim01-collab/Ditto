import { IsNumber, IsOptional, IsString, Min, MinLength } from 'class-validator';

export class UpdateRentalItemDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  name?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  category?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  pricePerDay?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  depositAmount?: number;

  @IsOptional()
  @IsString()
  imageUrl?: string;
}
