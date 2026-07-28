import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RecommendStylingDto } from './dto/recommend-styling.dto';
import { StylingService } from './styling.service';

@UseGuards(JwtAuthGuard)
@Controller('styling')
export class StylingController {
  constructor(private readonly stylingService: StylingService) {}

  @Post('recommend')
  recommend(@Body() dto: RecommendStylingDto) {
    return this.stylingService.recommend(dto);
  }
}
