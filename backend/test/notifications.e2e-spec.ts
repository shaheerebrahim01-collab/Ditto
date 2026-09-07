import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupUsers, createCustomer } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

describe('Notifications (e2e)', () => {
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

  it('rejects every route for an unauthenticated caller', async () => {
    await request(app.getHttpServer()).get('/notifications').expect(401);
    await request(app.getHttpServer()).get('/notifications/unread-count').expect(401);
    await request(app.getHttpServer()).post('/notifications/does-not-matter/read').expect(401);
    await request(app.getHttpServer()).post('/notifications/read-all').expect(401);
  });

  it('lists only the caller\'s own notifications, newest first', async () => {
    const mine = await createCustomer(prisma);
    const someoneElse = await createCustomer(prisma);
    userIds.push(mine.id, someoneElse.id);
    const [header, token] = authHeader(mine.id, 'CUSTOMER');

    const older = await prisma.notification.create({
      data: { userId: mine.id, type: 'e2e_test', title: 'Older', body: 'First' },
    });
    await new Promise((r) => setTimeout(r, 5));
    const newer = await prisma.notification.create({
      data: { userId: mine.id, type: 'e2e_test', title: 'Newer', body: 'Second' },
    });
    await prisma.notification.create({
      data: { userId: someoneElse.id, type: 'e2e_test', title: 'Not Mine', body: 'Nope' },
    });

    const res = await request(app.getHttpServer()).get('/notifications').set(header, token).expect(200);
    expect(res.body.total).toBe(2);
    expect(res.body.data.map((n: { id: string }) => n.id)).toEqual([newer.id, older.id]);
  });

  it('filters to unreadOnly and reports an accurate unread count', async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    const unread = await prisma.notification.create({
      data: { userId: customer.id, type: 'e2e_test', title: 'Unread', body: 'Still unread' },
    });
    await prisma.notification.create({
      data: { userId: customer.id, type: 'e2e_test', title: 'Already Read', body: 'Read', read: true },
    });

    const countBefore = await request(app.getHttpServer())
      .get('/notifications/unread-count')
      .set(header, token)
      .expect(200);
    expect(countBefore.body.count).toBe(1);

    const unreadOnly = await request(app.getHttpServer())
      .get('/notifications')
      .set(header, token)
      .query({ unreadOnly: 'true' })
      .expect(200);
    expect(unreadOnly.body.total).toBe(1);
    expect(unreadOnly.body.data[0].id).toBe(unread.id);
  });

  it('marks a single notification read, is idempotent, and 404s another user\'s', async () => {
    const owner = await createCustomer(prisma);
    const stranger = await createCustomer(prisma);
    userIds.push(owner.id, stranger.id);
    const [header, token] = authHeader(owner.id, 'CUSTOMER');
    const [strangerHeader, strangerToken] = authHeader(stranger.id, 'CUSTOMER');

    const notification = await prisma.notification.create({
      data: { userId: owner.id, type: 'e2e_test', title: 'Mark Me', body: 'Read target' },
    });

    await request(app.getHttpServer())
      .post(`/notifications/${notification.id}/read`)
      .set(strangerHeader, strangerToken)
      .expect(404);

    const marked = await request(app.getHttpServer())
      .post(`/notifications/${notification.id}/read`)
      .set(header, token)
      .expect(201);
    expect(marked.body.read).toBe(true);

    // idempotent — reading an already-read notification doesn't error or change it
    const markedAgain = await request(app.getHttpServer())
      .post(`/notifications/${notification.id}/read`)
      .set(header, token)
      .expect(201);
    expect(markedAgain.body.read).toBe(true);

    await request(app.getHttpServer())
      .post('/notifications/does-not-exist/read')
      .set(header, token)
      .expect(404);
  });

  it('marks only the caller\'s own unread notifications as read via read-all', async () => {
    const owner = await createCustomer(prisma);
    const someoneElse = await createCustomer(prisma);
    userIds.push(owner.id, someoneElse.id);
    const [header, token] = authHeader(owner.id, 'CUSTOMER');

    await prisma.notification.create({
      data: { userId: owner.id, type: 'e2e_test', title: 'A', body: 'A' },
    });
    await prisma.notification.create({
      data: { userId: owner.id, type: 'e2e_test', title: 'B', body: 'B' },
    });
    const othersUnread = await prisma.notification.create({
      data: { userId: someoneElse.id, type: 'e2e_test', title: 'Not Mine', body: 'Untouched' },
    });

    const res = await request(app.getHttpServer()).post('/notifications/read-all').set(header, token).expect(201);
    expect(res.body.updated).toBe(2);

    const remainingUnread = await prisma.notification.count({ where: { userId: owner.id, read: false } });
    expect(remainingUnread).toBe(0);

    const untouched = await prisma.notification.findUnique({ where: { id: othersUnread.id } });
    expect(untouched?.read).toBe(false);
  });
});
