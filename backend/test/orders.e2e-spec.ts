import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupUsers, createCustomer, createTailor } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

describe('Orders (e2e)', () => {
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

  it('rejects an unrecognized garmentTypeId with the valid values listed', async () => {
    const customer = await createCustomer(prisma);
    const { profile: tailor } = await createTailor(prisma);
    userIds.push(customer.id, tailor.userId);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    const res = await request(app.getHttpServer())
      .post('/orders')
      .set(header, token)
      .send({ tailorId: tailor.id, garmentTypeId: 'spacesuit', fabricId: 'charcoal_wool' })
      .expect(400);
    expect(res.body.message.join(' ')).toMatch(/garmentTypeId must be one of/);
  });

  it('computes price server-side and ignores a client-sent price entirely', async () => {
    const customer = await createCustomer(prisma);
    const { profile: tailor } = await createTailor(prisma);
    userIds.push(customer.id, tailor.userId);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    // suit(250) + burgundy_silk(+60) + Peak(+15) + Double-Breasted(+20) + monogram(+10) = 355
    const res = await request(app.getHttpServer())
      .post('/orders')
      .set(header, token)
      .send({
        tailorId: tailor.id,
        garmentTypeId: 'suit',
        fabricId: 'burgundy_silk',
        lapelStyle: 'Peak',
        buttonStyle: 'Double-Breasted',
        monogram: 'A.K.',
        price: 1, // attempted override — CreateOrderDto has no price field, whitelist strips it
      })
      .expect(201);

    expect(res.body.price).toBe(355);
  });

  it("404s a stranger who isn't the order's customer or assigned tailor", async () => {
    const customer = await createCustomer(prisma);
    const { profile: tailor } = await createTailor(prisma);
    const stranger = await createCustomer(prisma);
    userIds.push(customer.id, tailor.userId, stranger.id);

    const [custHeader, custToken] = authHeader(customer.id, 'CUSTOMER');
    const order = await request(app.getHttpServer())
      .post('/orders')
      .set(custHeader, custToken)
      .send({ tailorId: tailor.id, garmentTypeId: 'shirt', fabricId: 'charcoal_wool' })
      .expect(201);

    const [strangerHeader, strangerToken] = authHeader(stranger.id, 'CUSTOMER');
    await request(app.getHttpServer())
      .get(`/orders/${order.body.id}`)
      .set(strangerHeader, strangerToken)
      .expect(404);
  });

  it('only allows the stage to move forward, never sideways or backward', async () => {
    const customer = await createCustomer(prisma);
    const { user: tailorUser, profile: tailor } = await createTailor(prisma);
    userIds.push(customer.id, tailorUser.id);

    const [custHeader, custToken] = authHeader(customer.id, 'CUSTOMER');
    const order = await request(app.getHttpServer())
      .post('/orders')
      .set(custHeader, custToken)
      .send({ tailorId: tailor.id, garmentTypeId: 'kurta', fabricId: 'ivory_linen' })
      .expect(201);

    const [tailorHeader, tailorToken] = authHeader(tailorUser.id, 'TAILOR');

    // same-stage re-send rejected
    await request(app.getHttpServer())
      .patch(`/orders/${order.body.id}/stage`)
      .set(tailorHeader, tailorToken)
      .send({ stage: 'ORDER_CONFIRMED' })
      .expect(400);

    // forward move succeeds
    await request(app.getHttpServer())
      .patch(`/orders/${order.body.id}/stage`)
      .set(tailorHeader, tailorToken)
      .send({ stage: 'CUTTING' })
      .expect(200);

    // backward move rejected
    await request(app.getHttpServer())
      .patch(`/orders/${order.body.id}/stage`)
      .set(tailorHeader, tailorToken)
      .send({ stage: 'FABRIC_SELECTED' })
      .expect(400);

    // a customer (wrong role) can't advance it at all
    await request(app.getHttpServer())
      .patch(`/orders/${order.body.id}/stage`)
      .set(custHeader, custToken)
      .send({ stage: 'STITCHING' })
      .expect(403);
  });
});
