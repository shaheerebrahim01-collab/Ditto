import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupUsers, createCustomer } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

// ANTHROPIC_API_KEY isn't set in this dev environment (see docs/ROADMAP.md
// Phase 8) — so unlike every other spec file here, the real happy path
// (an actual Claude tool-use call) isn't exercisable yet. What's real and
// testable today is StylingService's clean-503-not-a-crash fallback and
// the DTO validation in front of it.
describe('Styling (e2e)', () => {
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
    await request(app.getHttpServer())
      .post('/styling/recommend')
      .send({ occasion: 'wedding' })
      .expect(401);
  });

  it('rejects a request missing the required occasion field', async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    await request(app.getHttpServer()).post('/styling/recommend').set(header, token).send({}).expect(400);
  });

  it('returns a clean 503, not a raw SDK crash, while ANTHROPIC_API_KEY is unconfigured', async () => {
    expect(process.env.ANTHROPIC_API_KEY).toBeUndefined();

    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    const res = await request(app.getHttpServer())
      .post('/styling/recommend')
      .set(header, token)
      .send({ occasion: 'black-tie wedding', preferences: 'slim fit, navy', budget: 800 })
      .expect(503);
    expect(res.body.message).toMatch(/ANTHROPIC_API_KEY is missing/);
  });
});
