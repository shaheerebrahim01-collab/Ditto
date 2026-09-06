import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupUsers, createCustomer, createTailor } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

describe('MeasurementVisits (e2e)', () => {
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

  function futureDate(daysAhead: number): string {
    return new Date(Date.now() + daysAhead * 86400000).toISOString();
  }

  it('rejects a request whose preferredAt is in the past', async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    const res = await request(app.getHttpServer())
      .post('/measurement-visits')
      .set(header, token)
      .send({ location: '123 E2E St', preferredAt: new Date(Date.now() - 86400000).toISOString() })
      .expect(400);
    expect(res.body.message).toMatch(/cannot be in the past/);
  });

  it('creates a request and lists it under /me, scoped to the caller', async () => {
    const customer = await createCustomer(prisma);
    const otherCustomer = await createCustomer(prisma);
    userIds.push(customer.id, otherCustomer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');
    const [otherHeader, otherToken] = authHeader(otherCustomer.id, 'CUSTOMER');

    const created = await request(app.getHttpServer())
      .post('/measurement-visits')
      .set(header, token)
      .send({ location: '456 E2E Ave', preferredAt: futureDate(3), notes: 'Ring the bell' })
      .expect(201);
    expect(created.body.status).toBe('PENDING');

    const mine = await request(app.getHttpServer()).get('/measurement-visits/me').set(header, token).expect(200);
    expect(mine.body.some((r: { id: string }) => r.id === created.body.id)).toBe(true);

    const theirs = await request(app.getHttpServer())
      .get('/measurement-visits/me')
      .set(otherHeader, otherToken)
      .expect(200);
    expect(theirs.body.some((r: { id: string }) => r.id === created.body.id)).toBe(false);
  });

  it('cancels a PENDING request, 404s cancelling a stranger\'s, and rejects cancelling an already-cancelled one', async () => {
    const customer = await createCustomer(prisma);
    const stranger = await createCustomer(prisma);
    userIds.push(customer.id, stranger.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');
    const [strangerHeader, strangerToken] = authHeader(stranger.id, 'CUSTOMER');

    const created = await request(app.getHttpServer())
      .post('/measurement-visits')
      .set(header, token)
      .send({ location: '789 E2E Blvd', preferredAt: futureDate(2) })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/measurement-visits/${created.body.id}/cancel`)
      .set(strangerHeader, strangerToken)
      .expect(404);

    const cancelled = await request(app.getHttpServer())
      .post(`/measurement-visits/${created.body.id}/cancel`)
      .set(header, token)
      .expect(201);
    expect(cancelled.body.status).toBe('CANCELLED');

    const res = await request(app.getHttpServer())
      .post(`/measurement-visits/${created.body.id}/cancel`)
      .set(header, token)
      .expect(400);
    expect(res.body.message).toMatch(/already cancelled/);
  });

  it('rejects the tailor-only routes for an unauthenticated caller and for a non-tailor role', async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    await request(app.getHttpServer()).get('/measurement-visits/available').expect(401);
    await request(app.getHttpServer()).get('/measurement-visits/available').set(header, token).expect(403);
  });

  it('lists PENDING requests as available, lets a tailor claim one, and notifies the customer', async () => {
    const customer = await createCustomer(prisma);
    const { user: tailorUser } = await createTailor(prisma);
    userIds.push(customer.id, tailorUser.id);
    const [custHeader, custToken] = authHeader(customer.id, 'CUSTOMER');
    const [tailorHeader, tailorToken] = authHeader(tailorUser.id, 'TAILOR');

    const created = await request(app.getHttpServer())
      .post('/measurement-visits')
      .set(custHeader, custToken)
      .send({ location: '1 E2E Claim Way', preferredAt: futureDate(4) })
      .expect(201);

    const available = await request(app.getHttpServer())
      .get('/measurement-visits/available')
      .set(tailorHeader, tailorToken)
      .expect(200);
    expect(available.body.some((r: { id: string }) => r.id === created.body.id)).toBe(true);

    const claimed = await request(app.getHttpServer())
      .post(`/measurement-visits/${created.body.id}/claim`)
      .set(tailorHeader, tailorToken)
      .send({})
      .expect(201);
    expect(claimed.body.status).toBe('ASSIGNED');

    const notifications = await request(app.getHttpServer())
      .get('/notifications')
      .set(custHeader, custToken)
      .expect(200);
    expect(notifications.body.data.some((n: { type: string }) => n.type === 'visit_assigned')).toBe(true);

    // no longer in the available pool once claimed
    const availableAfter = await request(app.getHttpServer())
      .get('/measurement-visits/available')
      .set(tailorHeader, tailorToken)
      .expect(200);
    expect(availableAfter.body.some((r: { id: string }) => r.id === created.body.id)).toBe(false);
  });

  it('rejects claiming an already-ASSIGNED request and rejects an assistantId not on the claiming tailor\'s own roster', async () => {
    const customer = await createCustomer(prisma);
    const { user: tailorAUser } = await createTailor(prisma);
    const { user: tailorBUser, profile: tailorB } = await createTailor(prisma);
    userIds.push(customer.id, tailorAUser.id, tailorBUser.id);
    const [custHeader, custToken] = authHeader(customer.id, 'CUSTOMER');
    const [tailorAHeader, tailorAToken] = authHeader(tailorAUser.id, 'TAILOR');
    const [tailorBHeader, tailorBToken] = authHeader(tailorBUser.id, 'TAILOR');

    const created = await request(app.getHttpServer())
      .post('/measurement-visits')
      .set(custHeader, custToken)
      .send({ location: '2 E2E Double Claim Rd', preferredAt: futureDate(5) })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/measurement-visits/${created.body.id}/claim`)
      .set(tailorAHeader, tailorAToken)
      .send({})
      .expect(201);

    const res = await request(app.getHttpServer())
      .post(`/measurement-visits/${created.body.id}/claim`)
      .set(tailorBHeader, tailorBToken)
      .send({})
      .expect(400);
    expect(res.body.message).toMatch(/already assigned/);

    const secondRequest = await request(app.getHttpServer())
      .post('/measurement-visits')
      .set(custHeader, custToken)
      .send({ location: '3 E2E Foreign Assistant Ln', preferredAt: futureDate(6) })
      .expect(201);
    const foreignAssistant = await prisma.tailorAssistant.create({
      data: { tailorId: tailorB.id, fullName: 'E2E Foreign Assistant' },
    });
    const claimRes = await request(app.getHttpServer())
      .post(`/measurement-visits/${secondRequest.body.id}/claim`)
      .set(tailorAHeader, tailorAToken)
      .send({ assistantId: foreignAssistant.id })
      .expect(404);
    expect(claimRes.body.message).toMatch(/roster/);
  });

  it("lets a tailor claim with their own assistant, complete an ASSIGNED request, and 404s completing another tailor's", async () => {
    const customer = await createCustomer(prisma);
    const { user: tailorUser, profile: tailor } = await createTailor(prisma);
    const { user: otherTailorUser } = await createTailor(prisma);
    userIds.push(customer.id, tailorUser.id, otherTailorUser.id);
    const [custHeader, custToken] = authHeader(customer.id, 'CUSTOMER');
    const [tailorHeader, tailorToken] = authHeader(tailorUser.id, 'TAILOR');
    const [otherHeader, otherToken] = authHeader(otherTailorUser.id, 'TAILOR');

    const assistant = await prisma.tailorAssistant.create({
      data: { tailorId: tailor.id, fullName: 'E2E Own Assistant' },
    });

    const created = await request(app.getHttpServer())
      .post('/measurement-visits')
      .set(custHeader, custToken)
      .send({ location: '4 E2E Complete Ct', preferredAt: futureDate(7) })
      .expect(201);

    const claimed = await request(app.getHttpServer())
      .post(`/measurement-visits/${created.body.id}/claim`)
      .set(tailorHeader, tailorToken)
      .send({ assistantId: assistant.id })
      .expect(201);
    expect(claimed.body.assistantId).toBe(assistant.id);

    const assigned = await request(app.getHttpServer())
      .get('/measurement-visits/assigned')
      .set(tailorHeader, tailorToken)
      .query({ status: 'ASSIGNED' })
      .expect(200);
    expect(assigned.body.some((r: { id: string }) => r.id === created.body.id)).toBe(true);

    await request(app.getHttpServer())
      .post(`/measurement-visits/${created.body.id}/complete`)
      .set(otherHeader, otherToken)
      .expect(404);

    const completed = await request(app.getHttpServer())
      .post(`/measurement-visits/${created.body.id}/complete`)
      .set(tailorHeader, tailorToken)
      .expect(201);
    expect(completed.body.status).toBe('COMPLETED');

    const notifications = await request(app.getHttpServer())
      .get('/notifications')
      .set(custHeader, custToken)
      .expect(200);
    expect(notifications.body.data.some((n: { type: string }) => n.type === 'visit_completed')).toBe(true);

    // completing again is rejected — no longer ASSIGNED
    await request(app.getHttpServer())
      .post(`/measurement-visits/${created.body.id}/complete`)
      .set(tailorHeader, tailorToken)
      .expect(400);
  });
});
