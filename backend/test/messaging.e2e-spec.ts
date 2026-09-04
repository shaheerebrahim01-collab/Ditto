import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupUsers, createCustomer } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

describe('Messaging (e2e)', () => {
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

  it("rejects starting a conversation with yourself", async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    await request(app.getHttpServer())
      .post('/conversations')
      .set(header, token)
      .send({ otherUserId: customer.id })
      .expect(400);
  });

  it('canonicalizes a conversation regardless of which side starts it', async () => {
    const a = await createCustomer(prisma);
    const b = await createCustomer(prisma);
    userIds.push(a.id, b.id);
    const [aHeader, aToken] = authHeader(a.id, 'CUSTOMER');
    const [bHeader, bToken] = authHeader(b.id, 'CUSTOMER');

    const fromA = await request(app.getHttpServer())
      .post('/conversations')
      .set(aHeader, aToken)
      .send({ otherUserId: b.id })
      .expect(201);
    const fromB = await request(app.getHttpServer())
      .post('/conversations')
      .set(bHeader, bToken)
      .send({ otherUserId: a.id })
      .expect(201);

    expect(fromA.body.id).toBe(fromB.body.id);
  });

  it("404s a non-participant trying to read a conversation's messages", async () => {
    const a = await createCustomer(prisma);
    const b = await createCustomer(prisma);
    const stranger = await createCustomer(prisma);
    userIds.push(a.id, b.id, stranger.id);
    const [aHeader, aToken] = authHeader(a.id, 'CUSTOMER');

    const conv = await request(app.getHttpServer())
      .post('/conversations')
      .set(aHeader, aToken)
      .send({ otherUserId: b.id })
      .expect(201);

    const [strangerHeader, strangerToken] = authHeader(stranger.id, 'CUSTOMER');
    await request(app.getHttpServer())
      .get(`/conversations/${conv.body.id}/messages`)
      .set(strangerHeader, strangerToken)
      .expect(404);
  });

  it('sending a message notifies the other participant', async () => {
    const a = await createCustomer(prisma);
    const b = await createCustomer(prisma);
    userIds.push(a.id, b.id);
    const [aHeader, aToken] = authHeader(a.id, 'CUSTOMER');
    const [bHeader, bToken] = authHeader(b.id, 'CUSTOMER');

    const conv = await request(app.getHttpServer())
      .post('/conversations')
      .set(aHeader, aToken)
      .send({ otherUserId: b.id })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/conversations/${conv.body.id}/messages`)
      .set(aHeader, aToken)
      .send({ body: 'hello from e2e' })
      .expect(201);

    const notifications = await request(app.getHttpServer())
      .get('/notifications')
      .set(bHeader, bToken)
      .expect(200);
    expect(notifications.body.data.some((n: { type: string }) => n.type === 'message')).toBe(true);
  });
});
