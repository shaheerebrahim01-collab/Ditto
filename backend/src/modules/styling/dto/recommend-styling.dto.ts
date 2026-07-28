import { IsNumber, IsOptional, IsString, MinLength } from 'class-validator';

export class RecommendStylingDto {
  @IsString()
  @MinLength(1)
  occasion!: string;

  @IsString()
  @IsOptional()
  preferences?: string;

  @IsNumber()
  @IsOptional()
  budget?: number;
}
