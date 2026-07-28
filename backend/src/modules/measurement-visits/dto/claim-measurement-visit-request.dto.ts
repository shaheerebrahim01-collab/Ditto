import { IsOptional, IsString } from 'class-validator';

// assistantId is optional on purpose — a tailor can claim a request under
// their own business without naming a specific TailorAssistant yet (there's
// no assistant-roster endpoint for the app to pick one from today; the
// field exists on the model so that's a drop-in addition later, not a
// schema change).
export class ClaimMeasurementVisitRequestDto {
  @IsString()
  @IsOptional()
  assistantId?: string;
}
