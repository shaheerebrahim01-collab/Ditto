import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupUsers, createCustomer, createTailor } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

describe('Measurements (e2e)', () => {
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
    await request(app.getHttpServer()).get('/measurements').expect(401);
    await request(app.getHttpServer()).post('/measurements').send({ chest: 40 }).expect(401);
  });

  it('creates a measurement and lists only the caller\'s own', async () => {
    const mine = await createCustomer(prisma);
    const someoneElse = await createCustomer(prisma);
    userIds.push(mine.id, someoneElse.id);
    const [header, token] = authHeader(mine.id, 'CUSTOMER');
    const [otherHeader, otherToken] = authHeader(someoneElse.id, 'CUSTOMER');

    const created = await request(app.getHttpServer())
      .post('/measurements')
      .set(header, token)
      .send({ label: 'E2E Suit', chest: 40, waist: 34, notes: 'Standard fit' })
      .expect(201);
    expect(created.body.label).toBe('E2E Suit');
    expect(created.body.chest).toBe(40);

    await request(app.getHttpServer())
      .post('/measurements')
      .set(otherHeader, otherToken)
      .send({ label: 'Not Mine', chest: 99 })
      .expect(201);

    const list = await request(app.getHttpServer()).get('/measurements').set(header, token).expect(200);
    expect(list.body).toHaveLength(1);
    expect(list.body[0].id).toBe(created.body.id);
  });

  it('lets the owner update their own measurement, but 404s another user\'s', async () => {
    const owner = await createCustomer(prisma);
    const stranger = await createCustomer(prisma);
    userIds.push(owner.id, stranger.id);
    const [header, token] = authHeader(owner.id, 'CUSTOMER');
    const [strangerHeader, strangerToken] = authHeader(stranger.id, 'CUSTOMER');

    const created = await request(app.getHttpServer())
      .post('/measurements')
      .set(header, token)
      .send({ label: 'E2E Update Target', chest: 38 })
      .expect(201);

    const updated = await request(app.getHttpServer())
      .patch(`/measurements/${created.body.id}`)
      .set(header, token)
      .send({ chest: 41 })
      .expect(200);
    expect(updated.body.chest).toBe(41);

    await request(app.getHttpServer())
      .patch(`/measurements/${created.body.id}`)
      .set(strangerHeader, strangerToken)
      .send({ chest: 999 })
      .expect(404);

    const stillMine = await prisma.measurement.findUnique({ where: { id: created.body.id } });
    expect(stillMine?.chest).toBe(41);
  });

  it('lets the owner delete their own measurement, but 404s another user\'s', async () => {
    const owner = await createCustomer(prisma);
    const stranger = await createCustomer(prisma);
    userIds.push(owner.id, stranger.id);
    const [header, token] = authHeader(owner.id, 'CUSTOMER');
    const [strangerHeader, strangerToken] = authHeader(stranger.id, 'CUSTOMER');

    const created = await request(app.getHttpServer())
      .post('/measurements')
      .set(header, token)
      .send({ label: 'E2E Delete Target' })
      .expect(201);

    await request(app.getHttpServer())
      .delete(`/measurements/${created.body.id}`)
      .set(strangerHeader, strangerToken)
      .expect(404);

    await request(app.getHttpServer())
      .delete(`/measurements/${created.body.id}`)
      .set(header, token)
      .expect(200);

    const gone = await prisma.measurement.findUnique({ where: { id: created.body.id } });
    expect(gone).toBeNull();
  });

  it('rejects deleting a measurement that a CustomOrder references (409, not a raw FK 500)', async () => {
    const customer = await createCustomer(prisma);
    const { user: tailorUser, profile: tailor } = await createTailor(prisma);
    userIds.push(customer.id, tailorUser.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    const measurement = await request(app.getHttpServer())
      .post('/measurements')
      .set(header, token)
      .send({ label: 'E2E Referenced' })
      .expect(201);

    await prisma.customOrder.create({
      data: {
        customerId: customer.id,
        tailorId: tailor.id,
        garmentType: 'shirt',
        fabric: 'charcoal_wool',
        price: 50,
        measurementId: measurement.body.id,
      },
    });

    const res = await request(app.getHttpServer())
      .delete(`/measurements/${measurement.body.id}`)
      .set(header, token)
      .expect(409);
    expect(res.body.message).toMatch(/order references/);

    const stillThere = await prisma.measurement.findUnique({ where: { id: measurement.body.id } });
    expect(stillThere).not.toBeNull();
  });
});
