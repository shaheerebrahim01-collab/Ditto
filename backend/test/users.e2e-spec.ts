import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupUsers, createCustomer } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

describe('Users (e2e)', () => {
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

  it('rejects an unauthenticated caller', async () => {
    await request(app.getHttpServer()).get('/users/me').expect(401);
  });

  it("returns the caller's own profile, matching the real User row", async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    const res = await request(app.getHttpServer()).get('/users/me').set(header, token).expect(200);
    expect(res.body.id).toBe(customer.id);
    expect(res.body.fullName).toBe(customer.fullName);
    expect(res.body.email).toBe(customer.email);
    expect(res.body.role).toBe('CUSTOMER');
    expect(res.body.suspended).toBe(false);
  });

  it("scopes strictly off the caller's own JWT — two different users each get only their own profile", async () => {
    const userA = await createCustomer(prisma);
    const userB = await createCustomer(prisma);
    userIds.push(userA.id, userB.id);
    const [headerA, tokenA] = authHeader(userA.id, 'CUSTOMER');
    const [headerB, tokenB] = authHeader(userB.id, 'CUSTOMER');

    const resA = await request(app.getHttpServer()).get('/users/me').set(headerA, tokenA).expect(200);
    const resB = await request(app.getHttpServer()).get('/users/me').set(headerB, tokenB).expect(200);

    expect(resA.body.id).toBe(userA.id);
    expect(resB.body.id).toBe(userB.id);
    expect(resA.body.id).not.toBe(resB.body.id);
  });
});
