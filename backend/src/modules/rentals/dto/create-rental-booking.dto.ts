import { IsDateString, IsString, MinLength } from 'class-validator';

export class CreateRentalBookingDto {
  @IsString()
  @MinLength(1)
  itemId!: string;

  @IsDateString()
  pickupDate!: string;

  @IsDateString()
  returnDate!: string;
}
