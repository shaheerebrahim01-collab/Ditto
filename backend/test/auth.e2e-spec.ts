import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { createAdmin, createCustomer, cleanupUsers } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

// Real HTTP calls against a real running app + real Postgres — the same
// bar this project's manual curl verification has always used, now
// codified as regression tests instead of one-off session notes.
describe('Auth & self-scoping (e2e)', () => {
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

  it('rejects an unauthenticated request to a protected route', async () => {
    await request(app.getHttpServer()).get('/users/me').expect(401);
  });

  it("rejects a suspended user's still-valid token immediately (JwtStrategy checks the DB fresh)", async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);

    const [header, value] = authHeader(customer.id, 'CUSTOMER');
    await request(app.getHttpServer()).get('/users/me').set(header, value).expect(200);

    await prisma.user.update({ where: { id: customer.id }, data: { suspended: true } });

    const res = await request(app.getHttpServer()).get('/users/me').set(header, value).expect(401);
    expect(res.body.message).toMatch(/suspended/i);
  });

  it('rejects a non-admin on an admin-only route', async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, value] = authHeader(customer.id, 'CUSTOMER');

    await request(app.getHttpServer()).get('/admin/stats').set(header, value).expect(403);
  });

  it('allows a real admin on an admin-only route', async () => {
    const admin = await createAdmin(prisma);
    userIds.push(admin.id);
    const [header, value] = authHeader(admin.id, 'ADMIN');

    const res = await request(app.getHttpServer()).get('/admin/stats').set(header, value).expect(200);
    expect(res.body).toHaveProperty('userCount');
    expect(res.body).toHaveProperty('totalRevenue');
  });

  it("404s (not 403s) on another user's self-scoped resource, so its existence can't be probed", async () => {
    const owner = await createCustomer(prisma);
    const stranger = await createCustomer(prisma);
    userIds.push(owner.id, stranger.id);

    const [ownerHeader, ownerToken] = authHeader(owner.id, 'CUSTOMER');
    const created = await request(app.getHttpServer())
      .post('/measurements')
      .set(ownerHeader, ownerToken)
      .send({ label: 'E2E', chest: 40 })
      .expect(201);

    const [strangerHeader, strangerToken] = authHeader(stranger.id, 'CUSTOMER');
    await request(app.getHttpServer())
      .patch(`/measurements/${created.body.id}`)
      .set(strangerHeader, strangerToken)
      .send({ chest: 41 })
      .expect(404);
  });
});
