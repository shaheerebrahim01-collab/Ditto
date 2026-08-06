import { IsIn, IsOptional, IsString, MinLength } from 'class-validator';

// At least one of body/attachmentUrl is required — checked in
// MessagingService rather than here, same approach AdminService's
// createUser/createTailor use for "at least one of email/phone" (a
// cross-field rule class-validator can't express as cleanly as a plain
// service-level check).
export class SendMessageDto {
  @IsString()
  @MinLength(1)
  @IsOptional()
  body?: string;

  @IsString()
  @IsOptional()
  attachmentUrl?: string;

  @IsIn(['image', 'voice', 'video'])
  @IsOptional()
  attachmentType?: string;
}
