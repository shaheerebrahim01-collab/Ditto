import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupUsers, createCustomer, createRentalShop } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

describe('Rentals (e2e)', () => {
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

  it('rejects a booking that overlaps an existing active one for the same item', async () => {
    const customer = await createCustomer(prisma);
    const { user: shopUser, profile: shop } = await createRentalShop(prisma);
    userIds.push(customer.id, shopUser.id);
    const item = await prisma.rentalItem.create({
      data: { shopId: shop.id, name: 'E2E Tux', category: 'suit', pricePerDay: 10, depositAmount: 50 },
    });

    const [header, token] = authHeader(customer.id, 'CUSTOMER');
    await request(app.getHttpServer())
      .post('/rentals')
      .set(header, token)
      .send({ itemId: item.id, pickupDate: '2027-01-10', returnDate: '2027-01-15' })
      .expect(201);

    // overlaps the first booking's range
    const res = await request(app.getHttpServer())
      .post('/rentals')
      .set(header, token)
      .send({ itemId: item.id, pickupDate: '2027-01-12', returnDate: '2027-01-18' })
      .expect(400);
    expect(res.body.message).toMatch(/already booked/);
  });

  it('only allows cancelling from RESERVED', async () => {
    const customer = await createCustomer(prisma);
    const { user: shopUser, profile: shop } = await createRentalShop(prisma);
    userIds.push(customer.id, shopUser.id);
    const item = await prisma.rentalItem.create({
      data: { shopId: shop.id, name: 'E2E Suit', category: 'suit', pricePerDay: 10, depositAmount: 50 },
    });

    const [custHeader, custToken] = authHeader(customer.id, 'CUSTOMER');
    const booking = await request(app.getHttpServer())
      .post('/rentals')
      .set(custHeader, custToken)
      .send({ itemId: item.id, pickupDate: '2027-02-01', returnDate: '2027-02-05' })
      .expect(201);

    const [shopHeader, shopToken] = authHeader(shopUser.id, 'RENTAL_SHOP');
    await request(app.getHttpServer())
      .post(`/rentals/${booking.body.id}/pickup`)
      .set(shopHeader, shopToken)
      .expect(200);

    await request(app.getHttpServer())
      .post(`/rentals/${booking.body.id}/cancel`)
      .set(custHeader, custToken)
      .expect(400);
  });

  it('flips an overdue PICKED_UP booking to LATE via the cron query, still returnable with a late fee', async () => {
    const customer = await createCustomer(prisma);
    const { user: shopUser, profile: shop } = await createRentalShop(prisma);
    userIds.push(customer.id, shopUser.id);
    const item = await prisma.rentalItem.create({
      data: { shopId: shop.id, name: 'E2E Overdue Item', category: 'suit', pricePerDay: 10, depositAmount: 50 },
    });
    const booking = await prisma.rentalBooking.create({
      data: {
        itemId: item.id,
        renterId: customer.id,
        pickupDate: new Date(Date.now() - 5 * 86400000),
        returnDate: new Date(Date.now() - 2 * 86400000),
        status: 'PICKED_UP',
      },
    });

    // same query RentalStatusCron.flagOverdueBookings runs hourly
    const { count } = await prisma.rentalBooking.updateMany({
      where: { status: 'PICKED_UP', returnDate: { lt: new Date() } },
      data: { status: 'LATE' },
    });
    expect(count).toBeGreaterThanOrEqual(1);

    const [shopHeader, shopToken] = authHeader(shopUser.id, 'RENTAL_SHOP');
    const listed = await request(app.getHttpServer()).get('/rentals/shop').set(shopHeader, shopToken).expect(200);
    const found = listed.body.find((b: { id: string }) => b.id === booking.id);
    expect(found.status).toBe('LATE');
    expect(found.overdue).toBe(true);

    const returned = await request(app.getHttpServer())
      .post(`/rentals/${booking.id}/return`)
      .set(shopHeader, shopToken)
      .expect(200);
    expect(returned.body.status).toBe('RETURNED');
    expect(returned.body.lateFee).toBeGreaterThan(0);
  });

  it('notifies the shop owner when a booking is created', async () => {
    const customer = await createCustomer(prisma);
    const { user: shopUser, profile: shop } = await createRentalShop(prisma);
    userIds.push(customer.id, shopUser.id);
    const item = await prisma.rentalItem.create({
      data: { shopId: shop.id, name: 'E2E Notif Item', category: 'suit', pricePerDay: 10, depositAmount: 50 },
    });

    const [custHeader, custToken] = authHeader(customer.id, 'CUSTOMER');
    await request(app.getHttpServer())
      .post('/rentals')
      .set(custHeader, custToken)
      .send({ itemId: item.id, pickupDate: '2027-03-01', returnDate: '2027-03-05' })
      .expect(201);

    const [shopHeader, shopToken] = authHeader(shopUser.id, 'RENTAL_SHOP');
    const notifications = await request(app.getHttpServer())
      .get('/notifications')
      .set(shopHeader, shopToken)
      .expect(200);
    expect(notifications.body.data.some((n: { type: string }) => n.type === 'booking_created')).toBe(true);
  });
});
