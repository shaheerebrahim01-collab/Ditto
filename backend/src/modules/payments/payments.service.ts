import { BadRequestException, Injectable, Logger, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { Role } from '@prisma/client';
import type Stripe from 'stripe';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateOnboardingLinkDto } from './dto/create-onboarding-link.dto';
import { getStripeClient, isStripeConfigured, isWebhookConfigured } from './stripe-client.provider';

// Ditto's cut of every destination charge, taken via application_fee_amount
// on the PaymentIntent. A real number needs a real business decision — this
// is a placeholder until that happens, kept as one named constant so it's
// easy to find and change in one place.
const PLATFORM_FEE_RATE = 0.1;

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(private readonly prisma: PrismaService) {}

  async createOrderPaymentIntent(customerId: string, orderId: string) {
    this.requireStripeConfigured();

    const order = await this.prisma.customOrder.findUnique({ where: { id: orderId } });
    if (!order || order.customerId !== customerId) throw new NotFoundException('Order not found');

    const existingPayment = await this.prisma.payment.findUnique({ where: { orderId } });
    if (existingPayment?.status === 'succeeded') {
      throw new BadRequestException('This order has already been paid');
    }

    const tailor = await this.prisma.tailorProfile.findUnique({ where: { id: order.tailorId } });
    if (!tailor?.stripeAccountId) {
      throw new ServiceUnavailableException('This tailor has not finished payout setup yet');
    }

    const intent = await this.createDestinationChargeIntent(order.price, tailor.stripeAccountId, {
      orderId: order.id,
    });

    await this.prisma.payment.upsert({
      where: { orderId },
      create: { orderId, amount: order.price, provider: 'stripe', providerRef: intent.id, status: 'pending' },
      update: { providerRef: intent.id, status: 'pending' },
    });

    return { clientSecret: intent.client_secret };
  }

  async createRentalDepositIntent(renterId: string, bookingId: string) {
    this.requireStripeConfigured();

    const booking = await this.prisma.rentalBooking.findUnique({
      where: { id: bookingId },
      include: { item: { include: { shop: true } } },
    });
    if (!booking || booking.renterId !== renterId) throw new NotFoundException('Booking not found');

    const existingPayment = await this.prisma.payment.findUnique({ where: { rentalBookingId: bookingId } });
    if (existingPayment?.status === 'succeeded') {
      throw new BadRequestException('This booking has already been paid');
    }

    const shop = booking.item.shop;
    if (!shop.stripeAccountId) {
      throw new ServiceUnavailableException('This rental shop has not finished payout setup yet');
    }

    const intent = await this.createDestinationChargeIntent(booking.item.depositAmount, shop.stripeAccountId, {
      rentalBookingId: booking.id,
    });

    await this.prisma.payment.upsert({
      where: { rentalBookingId: bookingId },
      create: {
        rentalBookingId: bookingId,
        amount: booking.item.depositAmount,
        provider: 'stripe',
        providerRef: intent.id,
        status: 'pending',
      },
      update: { providerRef: intent.id, status: 'pending' },
    });

    return { clientSecret: intent.client_secret };
  }

  private async createDestinationChargeIntent(
    amount: number,
    destinationAccountId: string,
    metadata: Record<string, string>,
  ): Promise<Stripe.PaymentIntent> {
    const stripe = getStripeClient();
    const amountCents = Math.round(amount * 100);
    try {
      return await stripe.paymentIntents.create({
        amount: amountCents,
        currency: 'usd',
        transfer_data: { destination: destinationAccountId },
        application_fee_amount: Math.round(amountCents * PLATFORM_FEE_RATE),
        metadata,
      });
    } catch (err) {
      this.logger.error('Stripe PaymentIntent creation failed', err instanceof Error ? err.stack : err);
      throw new ServiceUnavailableException('Payment provider request failed');
    }
  }

  // Creates (once) and reuses a Stripe Express connected account for the
  // caller's own business profile, then returns a fresh onboarding link —
  // Account Links are short-lived and single-use, so a new one is minted
  // every call rather than cached.
  async createOnboardingLink(userId: string, role: Role, dto: CreateOnboardingLinkDto) {
    this.requireStripeConfigured();
    const stripe = getStripeClient();

    const accountId =
      role === Role.TAILOR
        ? await this.getOrCreateTailorStripeAccount(userId)
        : await this.getOrCreateRentalShopStripeAccount(userId);

    let link: Stripe.AccountLink;
    try {
      link = await stripe.accountLinks.create({
        account: accountId,
        type: 'account_onboarding',
        refresh_url: dto.refreshUrl ?? 'https://ditto.app/onboarding/refresh',
        return_url: dto.returnUrl ?? 'https://ditto.app/onboarding/complete',
      });
    } catch (err) {
      this.logger.error('Stripe AccountLink creation failed', err instanceof Error ? err.stack : err);
      throw new ServiceUnavailableException('Payment provider request failed');
    }

    return { url: link.url };
  }

  private async getOrCreateTailorStripeAccount(userId: string): Promise<string> {
    const tailor = await this.prisma.tailorProfile.findUnique({ where: { userId }, include: { user: true } });
    if (!tailor) throw new NotFoundException('No tailor profile for this account');
    if (tailor.stripeAccountId) return tailor.stripeAccountId;

    const accountId = await this.createExpressAccount(tailor.user.email, tailor.businessName);
    await this.prisma.tailorProfile.update({ where: { id: tailor.id }, data: { stripeAccountId: accountId } });
    return accountId;
  }

  private async getOrCreateRentalShopStripeAccount(userId: string): Promise<string> {
    const shop = await this.prisma.rentalShopProfile.findUnique({ where: { userId }, include: { user: true } });
    if (!shop) throw new NotFoundException('No rental shop profile for this account');
    if (shop.stripeAccountId) return shop.stripeAccountId;

    const accountId = await this.createExpressAccount(shop.user.email, shop.businessName);
    await this.prisma.rentalShopProfile.update({ where: { id: shop.id }, data: { stripeAccountId: accountId } });
    return accountId;
  }

  private async createExpressAccount(email: string | null, businessName: string): Promise<string> {
    const stripe = getStripeClient();
    try {
      const account = await stripe.accounts.create({
        type: 'express',
        email: email ?? undefined,
        business_profile: { name: businessName },
        capabilities: { transfers: { requested: true }, card_payments: { requested: true } },
      });
      return account.id;
    } catch (err) {
      this.logger.error('Stripe Account creation failed', err instanceof Error ? err.stack : err);
      throw new ServiceUnavailableException('Payment provider request failed');
    }
  }

  // Raw body + the `stripe-signature` header are required to verify the
  // event actually came from Stripe (main.ts's `rawBody: true` option is
  // what makes req.rawBody available to the controller). Never trust an
  // unverified webhook body to update a Payment's status.
  async handleWebhookEvent(rawBody: Buffer, signature: string) {
    if (!isStripeConfigured() || !isWebhookConfigured()) {
      throw new ServiceUnavailableException('Webhook handling is not configured yet');
    }
    const stripe = getStripeClient();

    let event: Stripe.Event;
    try {
      event = stripe.webhooks.constructEvent(rawBody, signature, process.env.STRIPE_WEBHOOK_SECRET as string);
    } catch (err) {
      this.logger.warn(`Webhook signature verification failed: ${err instanceof Error ? err.message : err}`);
      throw new BadRequestException('Invalid webhook signature');
    }

    if (event.type === 'payment_intent.succeeded' || event.type === 'payment_intent.payment_failed') {
      const intent = event.data.object as Stripe.PaymentIntent;
      const status = event.type === 'payment_intent.succeeded' ? 'succeeded' : 'failed';
      await this.prisma.payment.updateMany({ where: { providerRef: intent.id }, data: { status } });
    }

    return { received: true };
  }

  private requireStripeConfigured() {
    if (!isStripeConfigured()) {
      throw new ServiceUnavailableException(
        'Payments are not configured yet — STRIPE_SECRET_KEY is missing. See docs/ROADMAP.md Phase 10.',
      );
    }
  }
}
