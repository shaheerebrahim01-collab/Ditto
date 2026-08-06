import { IsIn, IsOptional, IsString } from 'class-validator';
import { BUTTON_STYLES, FABRIC_IDS, GARMENT_TYPE_IDS, LAPEL_STYLES } from '../../styling/garment-vocabulary';

// No `price` field — computeOrderPrice (garment-pricing.ts) derives it
// server-side from these ids. Never trust a client-sent amount for
// anything that becomes a real charge.
export class CreateOrderDto {
  @IsString()
  tailorId!: string;

  @IsIn(GARMENT_TYPE_IDS)
  garmentTypeId!: string;

  @IsIn(FABRIC_IDS)
  fabricId!: string;

  @IsIn(LAPEL_STYLES)
  @IsOptional()
  lapelStyle?: string;

  @IsIn(BUTTON_STYLES)
  @IsOptional()
  buttonStyle?: string;

  @IsString()
  @IsOptional()
  monogram?: string;

  @IsString()
  @IsOptional()
  measurementId?: string;
}
