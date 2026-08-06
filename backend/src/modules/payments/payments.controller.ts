import { BadRequestException, Body, Controller, Headers, Param, Post, Req, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import type { RawBodyRequest } from '@nestjs/common';
import type { Request } from 'express';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CreateOnboardingLinkDto } from './dto/create-onboarding-link.dto';
import { PaymentsService } from './payments.service';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @UseGuards(JwtAuthGuard)
  @Post('orders/:orderId/intent')
  createOrderIntent(@CurrentUser() user: { userId: string }, @Param('orderId') orderId: string) {
    return this.paymentsService.createOrderPaymentIntent(user.userId, orderId);
  }

  @UseGuards(JwtAuthGuard)
  @Post('rentals/:bookingId/deposit-intent')
  createRentalDepositIntent(@CurrentUser() user: { userId: string }, @Param('bookingId') bookingId: string) {
    return this.paymentsService.createRentalDepositIntent(user.userId, bookingId);
  }

  // Either a tailor or a rental-shop owner can onboard for payouts —
  // RolesGuard's `includes` check makes this an "either role" gate.
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.TAILOR, Role.RENTAL_SHOP)
  @Post('connect/onboarding-link')
  createOnboardingLink(@CurrentUser() user: { userId: string; role: Role }, @Body() dto: CreateOnboardingLinkDto) {
    return this.paymentsService.createOnboardingLink(user.userId, user.role, dto);
  }

  // Stripe calls this directly with its own signature, not a user JWT — no
  // JwtAuthGuard here. Needs the exact raw request bytes to verify that
  // signature, which is why main.ts enables `rawBody: true` and this reads
  // req.rawBody instead of the parsed body.
  @Post('webhook')
  handleWebhook(@Req() req: RawBodyRequest<Request>, @Headers('stripe-signature') signature?: string) {
    if (!req.rawBody || !signature) {
      throw new BadRequestException('Missing raw body or stripe-signature header');
    }
    return this.paymentsService.handleWebhookEvent(req.rawBody, signature);
  }
}
