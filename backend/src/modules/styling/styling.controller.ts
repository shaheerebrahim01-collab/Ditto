import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RecommendStylingDto } from './dto/recommend-styling.dto';
import { StylingService } from './styling.service';

@UseGuards(JwtAuthGuard)
@Controller('styling')
export class StylingController {
  constructor(private readonly stylingService: StylingService) {}

  // Tighter than the app-wide default — once ANTHROPIC_API_KEY is live,
  // every call is a real, billed Claude request.
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('recommend')
  recommend(@Body() dto: RecommendStylingDto) {
    return this.stylingService.recommend(dto);
  }
}
