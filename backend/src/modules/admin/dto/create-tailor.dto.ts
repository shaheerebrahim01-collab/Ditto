import { IsArray, IsEmail, IsNumber, IsOptional, IsString, MinLength } from 'class-validator';

// Creates a User (role TAILOR) and its TailorProfile together — there's no
// other code path that creates a TailorProfile (approving a
// BusinessApplication only flips its status, see admin.service.ts), so this
// is the one place an admin can onboard a tailor directly, ahead of the
// applicant ever signing in.
export class CreateTailorDto {
  @IsString()
  @MinLength(1)
  fullName!: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsString()
  @MinLength(1)
  businessName!: string;

  @IsOptional()
  @IsString()
  bio?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  specialties?: string[];

  @IsOptional()
  @IsNumber()
  deliveryRadiusKm?: number;
}
