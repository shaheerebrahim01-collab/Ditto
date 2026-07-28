import { IsDateString, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateMeasurementVisitRequestDto {
  @IsString()
  @MinLength(1)
  location!: string;

  @IsDateString()
  preferredAt!: string;

  @IsString()
  @IsOptional()
  notes?: string;
}
