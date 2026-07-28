import { IsNumber, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateMeasurementDto {
  @IsString()
  @MinLength(1)
  @IsOptional()
  label?: string;

  @IsNumber()
  @IsOptional()
  chest?: number;

  @IsNumber()
  @IsOptional()
  waist?: number;

  @IsNumber()
  @IsOptional()
  hip?: number;

  @IsNumber()
  @IsOptional()
  shoulder?: number;

  @IsNumber()
  @IsOptional()
  sleeve?: number;

  @IsNumber()
  @IsOptional()
  neck?: number;

  @IsNumber()
  @IsOptional()
  inseam?: number;

  @IsString()
  @IsOptional()
  notes?: string;
}
