import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupUsers, createCustomer, createTailor } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

describe('Reviews (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const userIds: string[] = [];

  beforeAll(async () => {
    ({ app, prisma } = await createTestApp());
  });

  afterAll(async () => {
    await cleanupUsers(prisma, userIds);
    await app.close();
  });

  async function makeOrder(customerId: string, tailorId: string, stage: 'ORDER_CONFIRMED' | 'DELIVERED' = 'DELIVERED') {
    return prisma.customOrder.create({
      data: { customerId, tailorId, garmentType: 'shirt', fabric: 'charcoal_wool', price: 50, stage },
    });
  }

  it('rejects reviewing an order that has not been DELIVERED yet', async () => {
    const customer = await createCustomer(prisma);
    const { user: tailorUser, profile: tailor } = await createTailor(prisma);
    userIds.push(customer.id, tailorUser.id);
    const order = await makeOrder(customer.id, tailor.id, 'ORDER_CONFIRMED');

    const [header, token] = authHeader(customer.id, 'CUSTOMER');
    const res = await request(app.getHttpServer())
      .post('/reviews')
      .set(header, token)
      .send({ orderId: order.id, rating: 5 })
      .expect(400);
    expect(res.body.message).toMatch(/must be delivered/);
  });

  it("404s a stranger trying to review someone else's order", async () => {
    const customer = await createCustomer(prisma);
    const stranger = await createCustomer(prisma);
    const { user: tailorUser, profile: tailor } = await createTailor(prisma);
    userIds.push(customer.id, stranger.id, tailorUser.id);
    const order = await makeOrder(customer.id, tailor.id);

    const [strangerHeader, strangerToken] = authHeader(stranger.id, 'CUSTOMER');
    await request(app.getHttpServer())
      .post('/reviews')
      .set(strangerHeader, strangerToken)
      .send({ orderId: order.id, rating: 1 })
      .expect(404);
  });

  it('creates a review for a delivered order, updates the tailor rating aggregate, and rejects a second review on the same order', async () => {
    const customer = await createCustomer(prisma);
    const { user: tailorUser, profile: tailor } = await createTailor(prisma);
    userIds.push(customer.id, tailorUser.id);
    const order = await makeOrder(customer.id, tailor.id);

    const [header, token] = authHeader(customer.id, 'CUSTOMER');
    const res = await request(app.getHttpServer())
      .post('/reviews')
      .set(header, token)
      .send({ orderId: order.id, rating: 4, comment: 'Great fit, a little slow.' })
      .expect(201);
    expect(res.body.rating).toBe(4);
    expect(res.body.author.fullName).toBe('E2E Customer');

    const updatedTailor = await prisma.tailorProfile.findUnique({ where: { id: tailor.id } });
    expect(updatedTailor?.ratingAvg).toBe(4);
    expect(updatedTailor?.ratingCount).toBe(1);

    await request(app.getHttpServer())
      .post('/reviews')
      .set(header, token)
      .send({ orderId: order.id, rating: 2 })
      .expect(400);

    // rating aggregate wasn't touched by the rejected duplicate
    const stillOne = await prisma.tailorProfile.findUnique({ where: { id: tailor.id } });
    expect(stillOne?.ratingCount).toBe(1);
  });

  it('averages ratingAvg correctly across multiple reviews for the same tailor, and lists them newest-first', async () => {
    const customerA = await createCustomer(prisma);
    const customerB = await createCustomer(prisma);
    const { user: tailorUser, profile: tailor } = await createTailor(prisma);
    userIds.push(customerA.id, customerB.id, tailorUser.id);

    const orderA = await makeOrder(customerA.id, tailor.id);
    const orderB = await makeOrder(customerB.id, tailor.id);

    const [headerA, tokenA] = authHeader(customerA.id, 'CUSTOMER');
    const [headerB, tokenB] = authHeader(customerB.id, 'CUSTOMER');

    await request(app.getHttpServer())
      .post('/reviews')
      .set(headerA, tokenA)
      .send({ orderId: orderA.id, rating: 5 })
      .expect(201);
    await request(app.getHttpServer())
      .post('/reviews')
      .set(headerB, tokenB)
      .send({ orderId: orderB.id, rating: 3 })
      .expect(201);

    const updatedTailor = await prisma.tailorProfile.findUnique({ where: { id: tailor.id } });
    expect(updatedTailor?.ratingCount).toBe(2);
    expect(updatedTailor?.ratingAvg).toBe(4);

    const list = await request(app.getHttpServer()).get('/reviews').query({ tailorId: tailor.id }).expect(200);
    expect(list.body.total).toBe(2);
    expect(list.body.data.map((r: { rating: number }) => r.rating)).toEqual([3, 5]); // newest (orderB) first
  });

  it('rejects listing reviews with no tailorId', async () => {
    await request(app.getHttpServer()).get('/reviews').expect(400);
  });
});
