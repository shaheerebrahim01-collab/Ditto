import { IsNumber, IsOptional, IsString, Min, MinLength } from 'class-validator';

export class CreateRentalItemDto {
  @IsString()
  @MinLength(1)
  name!: string;

  @IsString()
  @MinLength(1)
  category!: string;

  @IsNumber()
  @Min(0)
  pricePerDay!: number;

  @IsNumber()
  @Min(0)
  depositAmount!: number;

  @IsOptional()
  @IsString()
  imageUrl?: string;
}
