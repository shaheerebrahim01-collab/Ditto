import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupUsers, createCustomer, createRentalShop } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

describe('RentalShops (e2e)', () => {
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

  it('lists only APPROVED shops, filterable by business name', async () => {
    const { user: approvedUser, profile: approved } = await createRentalShop(prisma);
    const { user: pendingUser } = await createRentalShop(prisma, { status: 'PENDING' });
    userIds.push(approvedUser.id, pendingUser.id);
    await prisma.rentalShopProfile.update({
      where: { id: approved.id },
      data: { businessName: 'Unique Tux Emporium' },
    });

    const all = await request(app.getHttpServer()).get('/rental-shops').expect(200);
    expect(all.body.data.some((s: { id: string }) => s.id === approved.id)).toBe(true);
    expect(all.body.data.some((s: { userId: string }) => s.userId === pendingUser.id)).toBe(false);

    const filtered = await request(app.getHttpServer()).get('/rental-shops').query({ q: 'tux emporium' }).expect(200);
    expect(filtered.body.data.every((s: { id: string }) => s.id === approved.id)).toBe(true);

    const noMatch = await request(app.getHttpServer()).get('/rental-shops').query({ q: 'no such shop' }).expect(200);
    expect(noMatch.body.data.some((s: { id: string }) => s.id === approved.id)).toBe(false);
  });

  it('404s a PENDING shop by id — not publicly visible yet', async () => {
    const { user, profile } = await createRentalShop(prisma, { status: 'PENDING' });
    userIds.push(user.id);

    await request(app.getHttpServer()).get(`/rental-shops/${profile.id}`).expect(404);
  });

  it('200s an APPROVED shop by id, including its items', async () => {
    const { user, profile } = await createRentalShop(prisma);
    userIds.push(user.id);
    await prisma.rentalItem.create({
      data: { shopId: profile.id, name: 'E2E Detail Item', category: 'suit', pricePerDay: 15, depositAmount: 75 },
    });

    const res = await request(app.getHttpServer()).get(`/rental-shops/${profile.id}`).expect(200);
    expect(res.body.id).toBe(profile.id);
    expect(res.body.items).toHaveLength(1);
  });

  it('rejects /rental-shops/me for an unauthenticated caller and for a non-rental-shop role', async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);

    await request(app.getHttpServer()).get('/rental-shops/me').expect(401);

    const [header, token] = authHeader(customer.id, 'CUSTOMER');
    await request(app.getHttpServer()).get('/rental-shops/me').set(header, token).expect(403);
  });

  it("lets a rental shop read and update their own profile, but not another shop's", async () => {
    const { user: shopUser, profile } = await createRentalShop(prisma);
    const { user: otherShopUser } = await createRentalShop(prisma);
    userIds.push(shopUser.id, otherShopUser.id);
    const [header, token] = authHeader(shopUser.id, 'RENTAL_SHOP');

    const mine = await request(app.getHttpServer()).get('/rental-shops/me').set(header, token).expect(200);
    expect(mine.body.id).toBe(profile.id);

    const updated = await request(app.getHttpServer())
      .patch('/rental-shops/me')
      .set(header, token)
      .send({ businessName: 'Updated Tux Co.' })
      .expect(200);
    expect(updated.body.businessName).toBe('Updated Tux Co.');

    // the other shop's own PATCH only ever touches their own row (scoped off the JWT, no "whose" param)
    const [otherHeader, otherToken] = authHeader(otherShopUser.id, 'RENTAL_SHOP');
    const otherUpdate = await request(app.getHttpServer())
      .patch('/rental-shops/me')
      .set(otherHeader, otherToken)
      .send({ businessName: 'Should Not Touch The First Shop' })
      .expect(200);
    expect(otherUpdate.body.id).not.toBe(profile.id);

    const stillMine = await request(app.getHttpServer()).get('/rental-shops/me').set(header, token).expect(200);
    expect(stillMine.body.businessName).toBe('Updated Tux Co.');
  });

  it('strips unknown fields from the update body rather than persisting or erroring on them (whitelist validation)', async () => {
    const { user, profile } = await createRentalShop(prisma);
    userIds.push(user.id);
    const [header, token] = authHeader(user.id, 'RENTAL_SHOP');

    const res = await request(app.getHttpServer())
      .patch('/rental-shops/me')
      .set(header, token)
      .send({ businessName: 'Whitelist Check', status: 'PENDING', ratingAvg: 5 })
      .expect(200);

    expect(res.body.businessName).toBe('Whitelist Check');
    expect(res.body.status).toBe(profile.status); // untouched — status isn't in UpdateRentalShopDto
    expect(res.body.ratingAvg).toBe(0); // untouched — ratingAvg isn't in UpdateRentalShopDto either
  });

  it('lets a rental shop create, list, update, and delete their own items', async () => {
    const { user, profile } = await createRentalShop(prisma);
    userIds.push(user.id);
    const [header, token] = authHeader(user.id, 'RENTAL_SHOP');

    const created = await request(app.getHttpServer())
      .post('/rental-shops/me/items')
      .set(header, token)
      .send({ name: 'E2E Tuxedo', category: 'suit', pricePerDay: 25, depositAmount: 100 })
      .expect(201);
    expect(created.body.shopId).toBe(profile.id);

    const listed = await request(app.getHttpServer()).get('/rental-shops/me/items').set(header, token).expect(200);
    expect(listed.body.some((i: { id: string }) => i.id === created.body.id)).toBe(true);

    const updated = await request(app.getHttpServer())
      .patch(`/rental-shops/me/items/${created.body.id}`)
      .set(header, token)
      .send({ pricePerDay: 30 })
      .expect(200);
    expect(updated.body.pricePerDay).toBe(30);

    await request(app.getHttpServer())
      .delete(`/rental-shops/me/items/${created.body.id}`)
      .set(header, token)
      .expect(200);

    const listedAfter = await request(app.getHttpServer()).get('/rental-shops/me/items').set(header, token).expect(200);
    expect(listedAfter.body.some((i: { id: string }) => i.id === created.body.id)).toBe(false);
  });

  it("404s when a rental shop tries to update or delete another shop's item", async () => {
    const { user: ownerUser, profile: owner } = await createRentalShop(prisma);
    const { user: otherUser } = await createRentalShop(prisma);
    userIds.push(ownerUser.id, otherUser.id);
    const item = await prisma.rentalItem.create({
      data: { shopId: owner.id, name: 'E2E Owned Item', category: 'suit', pricePerDay: 10, depositAmount: 50 },
    });

    const [otherHeader, otherToken] = authHeader(otherUser.id, 'RENTAL_SHOP');
    await request(app.getHttpServer())
      .patch(`/rental-shops/me/items/${item.id}`)
      .set(otherHeader, otherToken)
      .send({ pricePerDay: 999 })
      .expect(404);

    await request(app.getHttpServer())
      .delete(`/rental-shops/me/items/${item.id}`)
      .set(otherHeader, otherToken)
      .expect(404);

    const stillThere = await prisma.rentalItem.findUnique({ where: { id: item.id } });
    expect(stillThere?.pricePerDay).toBe(10);
  });

  it('rejects deleting an item that has bookings against it (409, not a raw FK 500)', async () => {
    const customer = await createCustomer(prisma);
    const { user: shopUser, profile: shop } = await createRentalShop(prisma);
    userIds.push(customer.id, shopUser.id);
    const item = await prisma.rentalItem.create({
      data: { shopId: shop.id, name: 'E2E Booked Item', category: 'suit', pricePerDay: 10, depositAmount: 50 },
    });
    await prisma.rentalBooking.create({
      data: {
        itemId: item.id,
        renterId: customer.id,
        pickupDate: new Date(Date.now() + 86400000),
        returnDate: new Date(Date.now() + 5 * 86400000),
      },
    });

    const [header, token] = authHeader(shopUser.id, 'RENTAL_SHOP');
    const res = await request(app.getHttpServer())
      .delete(`/rental-shops/me/items/${item.id}`)
      .set(header, token)
      .expect(409);
    expect(res.body.message).toMatch(/bookings/);

    const stillThere = await prisma.rentalItem.findUnique({ where: { id: item.id } });
    expect(stillThere).not.toBeNull();
  });
});
