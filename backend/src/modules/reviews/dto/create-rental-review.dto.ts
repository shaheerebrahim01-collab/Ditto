import { IsInt, IsOptional, IsString, Max, Min, MinLength } from 'class-validator';

export class CreateRentalReviewDto {
  @IsString()
  @MinLength(1)
  bookingId!: string;

  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsString()
  @IsOptional()
  comment?: string;
}
