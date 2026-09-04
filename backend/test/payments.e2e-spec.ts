import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupUsers, createCustomer, createTailor } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

// STRIPE_SECRET_KEY is genuinely unset in this test environment (same as
// local dev and CI) — these assert the real fallback behaviour documented
// in docs/ROADMAP.md Phase 10, not a mocked-away credential.
describe('Payments — unconfigured Stripe (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const userIds: string[] = [];

  beforeAll(async () => {
    expect(process.env.STRIPE_SECRET_KEY).toBeFalsy();
    ({ app, prisma } = await createTestApp());
  });

  afterAll(async () => {
    await cleanupUsers(prisma, userIds);
    await app.close();
  });

  it('rejects an unauthenticated payment-intent request before any Stripe logic runs', async () => {
    await request(app.getHttpServer()).post('/payments/orders/nonexistent/intent').expect(401);
  });

  it('503s an order payment-intent request cleanly, not a raw crash', async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    const res = await request(app.getHttpServer())
      .post('/payments/orders/nonexistent-order-id/intent')
      .set(header, token)
      .expect(503);
    expect(res.body.message).toMatch(/STRIPE_SECRET_KEY/);
  });

  it('403s a customer (not tailor/rental-shop) on the Connect onboarding-link route', async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    await request(app.getHttpServer()).post('/payments/connect/onboarding-link').set(header, token).send({}).expect(403);
  });

  it('503s a real tailor on the onboarding-link route (role check passes, Stripe check fails)', async () => {
    const { user: tailorUser } = await createTailor(prisma);
    userIds.push(tailorUser.id);
    const [header, token] = authHeader(tailorUser.id, 'TAILOR');

    await request(app.getHttpServer()).post('/payments/connect/onboarding-link').set(header, token).send({}).expect(503);
  });

  it('tells apart "no signature header" (400) from "signature present but webhook secret missing" (503)', async () => {
    await request(app.getHttpServer())
      .post('/payments/webhook')
      .send({ type: 'payment_intent.succeeded' })
      .expect(400);

    await request(app.getHttpServer())
      .post('/payments/webhook')
      .set('stripe-signature', 't=1,v1=fake')
      .send({ type: 'payment_intent.succeeded' })
      .expect(503);
  });
});
