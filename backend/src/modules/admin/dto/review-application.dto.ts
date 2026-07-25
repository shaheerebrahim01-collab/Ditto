import { IsOptional, IsString } from 'class-validator';

export class ReviewApplicationDto {
  @IsOptional()
  @IsString()
  reviewNotes?: string;
}
