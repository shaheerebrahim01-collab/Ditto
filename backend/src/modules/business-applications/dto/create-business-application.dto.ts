import { IsIn } from 'class-validator';

// Kept in sync by hand with admin.service.ts's PROFILE_ROLE map — both
// read the same four values off BusinessApplication.businessType (schema
// comment: "tailor | rental_shop | designer | embroidery").
export const BUSINESS_APPLICATION_TYPES = ['tailor', 'rental_shop', 'designer', 'embroidery'] as const;

export class CreateBusinessApplicationDto {
  @IsIn(BUSINESS_APPLICATION_TYPES)
  businessType!: (typeof BUSINESS_APPLICATION_TYPES)[number];
}
