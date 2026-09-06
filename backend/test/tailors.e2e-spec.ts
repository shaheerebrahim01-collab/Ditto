import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupUsers, createCustomer, createTailor } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

describe('Tailors (e2e)', () => {
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

  it('lists only APPROVED tailors, filterable by specialty', async () => {
    const { user: approvedUser, profile: approved } = await createTailor(prisma);
    const { user: pendingUser } = await createTailor(prisma, { status: 'PENDING' });
    userIds.push(approvedUser.id, pendingUser.id);
    await prisma.tailorProfile.update({
      where: { id: approved.id },
      data: { specialties: ['sherwani', 'bandhgala'] },
    });

    const all = await request(app.getHttpServer()).get('/tailors').expect(200);
    expect(all.body.data.some((t: { id: string }) => t.id === approved.id)).toBe(true);
    expect(all.body.data.some((t: { userId: string }) => t.userId === pendingUser.id)).toBe(false);

    const filtered = await request(app.getHttpServer()).get('/tailors').query({ specialty: 'bandhgala' }).expect(200);
    expect(filtered.body.data.every((t: { specialties: string[] }) => t.specialties.includes('bandhgala'))).toBe(true);

    const noMatch = await request(app.getHttpServer()).get('/tailors').query({ specialty: 'origami' }).expect(200);
    expect(noMatch.body.data.some((t: { id: string }) => t.id === approved.id)).toBe(false);
  });

  it('404s a PENDING tailor by id — not publicly visible yet', async () => {
    const { user, profile } = await createTailor(prisma, { status: 'PENDING' });
    userIds.push(user.id);

    await request(app.getHttpServer()).get(`/tailors/${profile.id}`).expect(404);
  });

  it('200s an APPROVED tailor by id, including their portfolio', async () => {
    const { user, profile } = await createTailor(prisma);
    userIds.push(user.id);

    const res = await request(app.getHttpServer()).get(`/tailors/${profile.id}`).expect(200);
    expect(res.body.id).toBe(profile.id);
    expect(Array.isArray(res.body.portfolio)).toBe(true);
  });

  it('rejects /tailors/me for an unauthenticated caller and for a non-tailor role', async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);

    await request(app.getHttpServer()).get('/tailors/me').expect(401);

    const [header, token] = authHeader(customer.id, 'CUSTOMER');
    await request(app.getHttpServer()).get('/tailors/me').set(header, token).expect(403);
  });

  it("lets a tailor read and update their own profile, but not another tailor's", async () => {
    const { user: tailorUser, profile } = await createTailor(prisma);
    const { user: otherTailorUser } = await createTailor(prisma);
    userIds.push(tailorUser.id, otherTailorUser.id);
    const [header, token] = authHeader(tailorUser.id, 'TAILOR');

    const mine = await request(app.getHttpServer()).get('/tailors/me').set(header, token).expect(200);
    expect(mine.body.id).toBe(profile.id);

    const updated = await request(app.getHttpServer())
      .patch('/tailors/me')
      .set(header, token)
      .send({ businessName: 'Updated Bespoke Co.', deliveryRadiusKm: 15 })
      .expect(200);
    expect(updated.body.businessName).toBe('Updated Bespoke Co.');
    expect(updated.body.deliveryRadiusKm).toBe(15);

    // the other tailor's own PATCH only ever touches their own row (scoped off the JWT, no "whose" param)
    const [otherHeader, otherToken] = authHeader(otherTailorUser.id, 'TAILOR');
    const otherUpdate = await request(app.getHttpServer())
      .patch('/tailors/me')
      .set(otherHeader, otherToken)
      .send({ businessName: 'Should Not Touch The First Tailor' })
      .expect(200);
    expect(otherUpdate.body.id).not.toBe(profile.id);

    const stillMine = await request(app.getHttpServer()).get('/tailors/me').set(header, token).expect(200);
    expect(stillMine.body.businessName).toBe('Updated Bespoke Co.');
  });

  it('strips unknown fields from the update body rather than persisting or erroring on them (whitelist validation)', async () => {
    const { user: tailorUser, profile } = await createTailor(prisma);
    userIds.push(tailorUser.id);
    const [header, token] = authHeader(tailorUser.id, 'TAILOR');

    const res = await request(app.getHttpServer())
      .patch('/tailors/me')
      .set(header, token)
      .send({ businessName: 'Whitelist Check', status: 'PENDING', ratingAvg: 5 })
      .expect(200);

    expect(res.body.businessName).toBe('Whitelist Check');
    expect(res.body.status).toBe(profile.status); // untouched — status isn't in UpdateTailorProfileDto
    expect(res.body.ratingAvg).toBe(0); // untouched — ratingAvg isn't in UpdateTailorProfileDto either
  });
});
