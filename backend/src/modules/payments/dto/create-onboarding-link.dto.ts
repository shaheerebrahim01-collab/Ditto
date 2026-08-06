import { IsOptional, IsUrl } from 'class-validator';

// Where Stripe should send the connected account back to once onboarding
// finishes (or needs to be resumed). Defaults are placeholders — the real
// app deep links land here once the mobile onboarding screens exist.
export class CreateOnboardingLinkDto {
  @IsUrl({ require_tld: false })
  @IsOptional()
  refreshUrl?: string;

  @IsUrl({ require_tld: false })
  @IsOptional()
  returnUrl?: string;
}
