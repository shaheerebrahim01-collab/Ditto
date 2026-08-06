import { IsArray, IsNumber, IsObject, IsOptional, IsString, Min } from 'class-validator';

// Mirrors UpdateRentalShopDto's shape for the same "only what's actually
// editable" reasoning — businessName plus the fields this model actually
// has beyond what RentalShopProfile does (bio, specialties, radius, hours).
export class UpdateTailorProfileDto {
  @IsString()
  @IsOptional()
  businessName?: string;

  @IsString()
  @IsOptional()
  bio?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  specialties?: string[];

  @IsNumber()
  @Min(0)
  @IsOptional()
  deliveryRadiusKm?: number;

  @IsObject()
  @IsOptional()
  workingHours?: Record<string, unknown>;
}
