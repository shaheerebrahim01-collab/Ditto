import Stripe from 'stripe';

// Same shape as ../auth/firebase-admin.provider.ts and
// ../styling/anthropic-client.provider.ts: lazily created from an env var
// the first time it's actually used, so importing this file never has side
// effects on its own. STRIPE_SECRET_KEY doesn't exist in this environment
// yet (see docs/ROADMAP.md Phase 10) — PaymentsService checks
// isStripeConfigured() before ever calling getStripeClient().
let client: Stripe | undefined;

export function isStripeConfigured(): boolean {
  return Boolean(process.env.STRIPE_SECRET_KEY);
}

export function getStripeClient(): Stripe {
  if (!client) {
    client = new Stripe(process.env.STRIPE_SECRET_KEY as string);
  }
  return client;
}

export function isWebhookConfigured(): boolean {
  return Boolean(process.env.STRIPE_WEBHOOK_SECRET);
}
