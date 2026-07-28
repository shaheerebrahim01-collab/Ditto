import { IsNumber, IsOptional, IsString, MinLength } from 'class-validator';

// Same shape as CreateMeasurementDto — every field is independently
// optional on the model, so a partial update needs no different rules,
// just no required fields at all (a PATCH with an empty body is a no-op,
// not an error).
export class UpdateMeasurementDto {
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
