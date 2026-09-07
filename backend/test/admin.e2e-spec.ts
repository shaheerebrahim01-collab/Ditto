import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupUsers, createAdmin, createCustomer, createRentalShop, createTailor } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

describe('Admin (e2e)', () => {
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

  it('rejects every /admin/* route for an unauthenticated caller and for a non-admin role', async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    await request(app.getHttpServer()).get('/admin/stats').expect(401);
    await request(app.getHttpServer()).get('/admin/stats').set(header, token).expect(403);
    await request(app.getHttpServer()).get('/admin/users').set(header, token).expect(403);
    await request(app.getHttpServer())
      .post('/admin/users/does-not-matter/suspend')
      .set(header, token)
      .expect(403);
  });

  it('reflects real counts in /admin/stats', async () => {
    const admin = await createAdmin(prisma);
    userIds.push(admin.id);
    const [header, token] = authHeader(admin.id, 'ADMIN');

    const before = await request(app.getHttpServer()).get('/admin/stats').set(header, token).expect(200);

    const customer = await createCustomer(prisma);
    const { user: tailorUser, profile: tailor } = await createTailor(prisma);
    userIds.push(customer.id, tailorUser.id);
    await prisma.businessApplication.create({ data: { applicantId: customer.id, businessType: 'designer' } });
    const order = await prisma.customOrder.create({
      data: { customerId: customer.id, tailorId: tailor.id, garmentType: 'shirt', fabric: 'charcoal_wool', price: 120 },
    });
    await prisma.payment.create({
      data: { orderId: order.id, amount: 120, provider: 'stripe', status: 'succeeded' },
    });

    const after = await request(app.getHttpServer()).get('/admin/stats').set(header, token).expect(200);

    // 2 new users (customer + tailor); tailorCount +1; one new PENDING
    // application; one new order this month; revenue up by the payment amount
    expect(after.body.userCount).toBe(before.body.userCount + 2);
    expect(after.body.tailorCount).toBe(before.body.tailorCount + 1);
    expect(after.body.pendingApprovals).toBe(before.body.pendingApprovals + 1);
    expect(after.body.ordersThisMonth).toBe(before.body.ordersThisMonth + 1);
    expect(after.body.totalRevenue).toBe(before.body.totalRevenue + 120);
  });

  it('creates a user, requiring at least an email or phone and rejecting a duplicate', async () => {
    const admin = await createAdmin(prisma);
    userIds.push(admin.id);
    const [header, token] = authHeader(admin.id, 'ADMIN');

    await request(app.getHttpServer())
      .post('/admin/users')
      .set(header, token)
      .send({ fullName: 'No Contact Info' })
      .expect(400);

    const email = `e2e-admin-created-${Date.now()}@test.dev`;
    const created = await request(app.getHttpServer())
      .post('/admin/users')
      .set(header, token)
      .send({ fullName: 'E2E Admin-Created User', email, role: 'CUSTOMER' })
      .expect(201);
    userIds.push(created.body.id);
    expect(created.body.email).toBe(email);

    await request(app.getHttpServer())
      .post('/admin/users')
      .set(header, token)
      .send({ fullName: 'Duplicate Email', email })
      .expect(409);
  });

  it('lists and filters users by role and by search text', async () => {
    const admin = await createAdmin(prisma);
    const customer = await createCustomer(prisma);
    userIds.push(admin.id, customer.id);
    await prisma.user.update({ where: { id: customer.id }, data: { fullName: 'Zzyzx Unique Searchable Name' } });
    const [header, token] = authHeader(admin.id, 'ADMIN');

    const byRole = await request(app.getHttpServer())
      .get('/admin/users')
      .set(header, token)
      .query({ role: 'CUSTOMER' })
      .expect(200);
    expect(byRole.body.data.every((u: { role: string }) => u.role === 'CUSTOMER')).toBe(true);
    expect(byRole.body.data.some((u: { id: string }) => u.id === customer.id)).toBe(true);

    const bySearch = await request(app.getHttpServer())
      .get('/admin/users')
      .set(header, token)
      .query({ q: 'Zzyzx Unique Searchable' })
      .expect(200);
    expect(bySearch.body.data).toHaveLength(1);
    expect(bySearch.body.data[0].id).toBe(customer.id);
  });

  it('suspends and reactivates a user, notifying them, and rejects a no-op transition', async () => {
    const admin = await createAdmin(prisma);
    const customer = await createCustomer(prisma);
    userIds.push(admin.id, customer.id);
    const [adminHeader, adminToken] = authHeader(admin.id, 'ADMIN');
    const [custHeader, custToken] = authHeader(customer.id, 'CUSTOMER');

    const suspended = await request(app.getHttpServer())
      .post(`/admin/users/${customer.id}/suspend`)
      .set(adminHeader, adminToken)
      .expect(201);
    expect(suspended.body.suspended).toBe(true);

    await request(app.getHttpServer())
      .post(`/admin/users/${customer.id}/suspend`)
      .set(adminHeader, adminToken)
      .expect(400);

    // the suspended user's own still-valid token is rejected immediately
    await request(app.getHttpServer()).get('/measurements').set(custHeader, custToken).expect(401);

    const reactivated = await request(app.getHttpServer())
      .post(`/admin/users/${customer.id}/reactivate`)
      .set(adminHeader, adminToken)
      .expect(201);
    expect(reactivated.body.suspended).toBe(false);

    await request(app.getHttpServer()).get('/measurements').set(custHeader, custToken).expect(200);

    const notifications = await request(app.getHttpServer())
      .get('/notifications')
      .set(custHeader, custToken)
      .expect(200);
    const types = notifications.body.data.map((n: { type: string }) => n.type);
    expect(types).toEqual(expect.arrayContaining(['account_suspended', 'account_reactivated']));
  });

  it('404s suspending a nonexistent user', async () => {
    const admin = await createAdmin(prisma);
    userIds.push(admin.id);
    const [header, token] = authHeader(admin.id, 'ADMIN');

    await request(app.getHttpServer()).post('/admin/users/does-not-exist/suspend').set(header, token).expect(404);
  });

  it('creates a tailor directly, bypassing the application queue with status APPROVED', async () => {
    const admin = await createAdmin(prisma);
    userIds.push(admin.id);
    const [header, token] = authHeader(admin.id, 'ADMIN');

    await request(app.getHttpServer())
      .post('/admin/tailors')
      .set(header, token)
      .send({ fullName: 'No Contact', businessName: 'E2E Admin Tailor Co.' })
      .expect(400);

    const email = `e2e-admin-tailor-${Date.now()}@test.dev`;
    const created = await request(app.getHttpServer())
      .post('/admin/tailors')
      .set(header, token)
      .send({ fullName: 'E2E Onboarded Tailor', email, businessName: 'E2E Admin Tailor Co.' })
      .expect(201);
    expect(created.body.status).toBe('APPROVED');
    expect(created.body.completedOrders).toBe(0);

    const provisionedUser = await prisma.user.findUnique({ where: { email } });
    expect(provisionedUser?.role).toBe('TAILOR');
    userIds.push(provisionedUser!.id);

    await request(app.getHttpServer())
      .post('/admin/tailors')
      .set(header, token)
      .send({ fullName: 'Duplicate', email, businessName: 'Should Conflict' })
      .expect(409);
  });

  it('lists/filters tailors by business or owner name, with completedOrders counting only DELIVERED orders', async () => {
    const admin = await createAdmin(prisma);
    const customer = await createCustomer(prisma);
    const { user: tailorUser, profile: tailor } = await createTailor(prisma);
    userIds.push(admin.id, customer.id, tailorUser.id);
    await prisma.tailorProfile.update({ where: { id: tailor.id }, data: { businessName: 'Unique Stitch Studio' } });
    await prisma.customOrder.create({
      data: { customerId: customer.id, tailorId: tailor.id, garmentType: 'shirt', fabric: 'wool', price: 90, stage: 'DELIVERED' },
    });
    await prisma.customOrder.create({
      data: { customerId: customer.id, tailorId: tailor.id, garmentType: 'suit', fabric: 'linen', price: 200, stage: 'ORDER_CONFIRMED' },
    });
    const [header, token] = authHeader(admin.id, 'ADMIN');

    const filtered = await request(app.getHttpServer())
      .get('/admin/tailors')
      .set(header, token)
      .query({ q: 'Unique Stitch' })
      .expect(200);
    expect(filtered.body.data).toHaveLength(1);
    expect(filtered.body.data[0].id).toBe(tailor.id);
    expect(filtered.body.data[0].completedOrders).toBe(1);
  });

  it('suspends and reactivates a tailor, rejects an invalid transition, and 404s a nonexistent one', async () => {
    const admin = await createAdmin(prisma);
    const { user: tailorUser, profile: tailor } = await createTailor(prisma);
    const { user: pendingTailorUser, profile: pendingTailor } = await createTailor(prisma, { status: 'PENDING' });
    userIds.push(admin.id, tailorUser.id, pendingTailorUser.id);
    const [header, token] = authHeader(admin.id, 'ADMIN');

    // PENDING isn't APPROVED, so suspend (which requires APPROVED) is rejected
    const invalid = await request(app.getHttpServer())
      .post(`/admin/tailors/${pendingTailor.id}/suspend`)
      .set(header, token)
      .expect(400);
    expect(invalid.body.message).toMatch(/Cannot move tailor from pending to suspended/);

    const suspended = await request(app.getHttpServer())
      .post(`/admin/tailors/${tailor.id}/suspend`)
      .set(header, token)
      .expect(201);
    expect(suspended.body.status).toBe('SUSPENDED');

    const reactivated = await request(app.getHttpServer())
      .post(`/admin/tailors/${tailor.id}/reactivate`)
      .set(header, token)
      .expect(201);
    expect(reactivated.body.status).toBe('APPROVED');

    await request(app.getHttpServer()).post('/admin/tailors/does-not-exist/suspend').set(header, token).expect(404);

    const [tailorHeader, tailorToken] = authHeader(tailorUser.id, 'TAILOR');
    const notifications = await request(app.getHttpServer())
      .get('/notifications')
      .set(tailorHeader, tailorToken)
      .expect(200);
    const types = notifications.body.data.map((n: { type: string }) => n.type);
    expect(types).toEqual(expect.arrayContaining(['account_suspended', 'account_reactivated']));
  });

  it('lists/filters rental shops by business name, with itemCount reflecting real RentalItem rows', async () => {
    const admin = await createAdmin(prisma);
    const { user: shopUser, profile: shop } = await createRentalShop(prisma);
    userIds.push(admin.id, shopUser.id);
    await prisma.rentalShopProfile.update({ where: { id: shop.id }, data: { businessName: 'Unique Tux Rental Co.' } });
    await prisma.rentalItem.create({
      data: { shopId: shop.id, name: 'E2E Admin Item', category: 'suit', pricePerDay: 20, depositAmount: 100 },
    });
    const [header, token] = authHeader(admin.id, 'ADMIN');

    const filtered = await request(app.getHttpServer())
      .get('/admin/rental-shops')
      .set(header, token)
      .query({ q: 'Unique Tux Rental' })
      .expect(200);
    expect(filtered.body.data).toHaveLength(1);
    expect(filtered.body.data[0].id).toBe(shop.id);
    expect(filtered.body.data[0].itemCount).toBe(1);
  });

  it('suspends and reactivates a rental shop, rejects an invalid transition, and 404s a nonexistent one', async () => {
    const admin = await createAdmin(prisma);
    const { user: shopUser, profile: shop } = await createRentalShop(prisma);
    const { user: pendingShopUser, profile: pendingShop } = await createRentalShop(prisma, { status: 'PENDING' });
    userIds.push(admin.id, shopUser.id, pendingShopUser.id);
    const [header, token] = authHeader(admin.id, 'ADMIN');

    await request(app.getHttpServer())
      .post(`/admin/rental-shops/${pendingShop.id}/suspend`)
      .set(header, token)
      .expect(400);

    const suspended = await request(app.getHttpServer())
      .post(`/admin/rental-shops/${shop.id}/suspend`)
      .set(header, token)
      .expect(201);
    expect(suspended.body.status).toBe('SUSPENDED');

    const reactivated = await request(app.getHttpServer())
      .post(`/admin/rental-shops/${shop.id}/reactivate`)
      .set(header, token)
      .expect(201);
    expect(reactivated.body.status).toBe('APPROVED');

    await request(app.getHttpServer())
      .post('/admin/rental-shops/does-not-exist/suspend')
      .set(header, token)
      .expect(404);
  });
});
