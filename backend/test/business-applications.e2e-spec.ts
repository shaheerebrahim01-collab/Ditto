import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { cleanupUsers, createAdmin, createCustomer, createTailor } from './utils/factories';
import { authHeader, createTestApp } from './utils/test-app';

describe('BusinessApplications (e2e)', () => {
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
    await request(app.getHttpServer()).post('/business-applications').send({ businessType: 'tailor' }).expect(401);
  });

  it('creates a PENDING application for a valid business type', async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    const res = await request(app.getHttpServer())
      .post('/business-applications')
      .set(header, token)
      .send({ businessType: 'rental_shop' })
      .expect(201);
    expect(res.body.status).toBe('PENDING');
    expect(res.body.businessType).toBe('rental_shop');
  });

  it('rejects an unrecognized businessType', async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    await request(app.getHttpServer())
      .post('/business-applications')
      .set(header, token)
      .send({ businessType: 'astronaut' })
      .expect(400);
  });

  it('rejects applying for a business type the applicant already holds', async () => {
    const { user: tailorUser } = await createTailor(prisma);
    userIds.push(tailorUser.id);
    const [header, token] = authHeader(tailorUser.id, 'TAILOR');

    const res = await request(app.getHttpServer())
      .post('/business-applications')
      .set(header, token)
      .send({ businessType: 'tailor' })
      .expect(400);
    expect(res.body.message).toMatch(/already have a tailor account/);
  });

  it('rejects a second application while one is already pending, regardless of type', async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    await request(app.getHttpServer())
      .post('/business-applications')
      .set(header, token)
      .send({ businessType: 'tailor' })
      .expect(201);

    const res = await request(app.getHttpServer())
      .post('/business-applications')
      .set(header, token)
      .send({ businessType: 'designer' })
      .expect(400);
    expect(res.body.message).toMatch(/already have a pending business application/);
  });

  it('rejects a non-admin trying to review applications', async () => {
    const customer = await createCustomer(prisma);
    userIds.push(customer.id);
    const [header, token] = authHeader(customer.id, 'CUSTOMER');

    const created = await request(app.getHttpServer())
      .post('/business-applications')
      .set(header, token)
      .send({ businessType: 'tailor' })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/admin/business-applications/${created.body.id}/approve`)
      .set(header, token)
      .send({})
      .expect(403);
    await request(app.getHttpServer())
      .post(`/admin/business-applications/${created.body.id}/approve`)
      .expect(401);
  });

  it('approving a tailor application bumps the role, provisions an APPROVED TailorProfile, and notifies the applicant', async () => {
    const customer = await createCustomer(prisma);
    const admin = await createAdmin(prisma);
    userIds.push(customer.id, admin.id);
    const [custHeader, custToken] = authHeader(customer.id, 'CUSTOMER');
    const [adminHeader, adminToken] = authHeader(admin.id, 'ADMIN');

    const created = await request(app.getHttpServer())
      .post('/business-applications')
      .set(custHeader, custToken)
      .send({ businessType: 'tailor' })
      .expect(201);

    const approved = await request(app.getHttpServer())
      .post(`/admin/business-applications/${created.body.id}/approve`)
      .set(adminHeader, adminToken)
      .send({ reviewNotes: 'Looks good' })
      .expect(201);
    expect(approved.body.status).toBe('APPROVED');
    expect(approved.body.reviewNotes).toBe('Looks good');

    const updatedUser = await prisma.user.findUnique({ where: { id: customer.id } });
    expect(updatedUser?.role).toBe('TAILOR');

    const profile = await prisma.tailorProfile.findUnique({ where: { userId: customer.id } });
    expect(profile?.status).toBe('APPROVED');

    const notifications = await request(app.getHttpServer())
      .get('/notifications')
      .set(custHeader, custToken)
      .expect(200);
    expect(notifications.body.data.some((n: { type: string }) => n.type === 'application_approved')).toBe(true);
  });

  it('approving a rental_shop application provisions an APPROVED RentalShopProfile', async () => {
    const customer = await createCustomer(prisma);
    const admin = await createAdmin(prisma);
    userIds.push(customer.id, admin.id);
    const [custHeader, custToken] = authHeader(customer.id, 'CUSTOMER');
    const [adminHeader, adminToken] = authHeader(admin.id, 'ADMIN');

    const created = await request(app.getHttpServer())
      .post('/business-applications')
      .set(custHeader, custToken)
      .send({ businessType: 'rental_shop' })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/admin/business-applications/${created.body.id}/approve`)
      .set(adminHeader, adminToken)
      .send({})
      .expect(201);

    const updatedUser = await prisma.user.findUnique({ where: { id: customer.id } });
    expect(updatedUser?.role).toBe('RENTAL_SHOP');

    const profile = await prisma.rentalShopProfile.findUnique({ where: { userId: customer.id } });
    expect(profile?.status).toBe('APPROVED');
  });

  it('approving a designer application bumps the role but provisions no profile model', async () => {
    const customer = await createCustomer(prisma);
    const admin = await createAdmin(prisma);
    userIds.push(customer.id, admin.id);
    const [custHeader, custToken] = authHeader(customer.id, 'CUSTOMER');
    const [adminHeader, adminToken] = authHeader(admin.id, 'ADMIN');

    const created = await request(app.getHttpServer())
      .post('/business-applications')
      .set(custHeader, custToken)
      .send({ businessType: 'designer' })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/admin/business-applications/${created.body.id}/approve`)
      .set(adminHeader, adminToken)
      .send({})
      .expect(201);

    const updatedUser = await prisma.user.findUnique({ where: { id: customer.id } });
    expect(updatedUser?.role).toBe('DESIGNER');
    const tailorProfile = await prisma.tailorProfile.findUnique({ where: { userId: customer.id } });
    expect(tailorProfile).toBeNull();
  });

  it('rejecting an application leaves the role untouched and notifies with the review notes', async () => {
    const customer = await createCustomer(prisma);
    const admin = await createAdmin(prisma);
    userIds.push(customer.id, admin.id);
    const [custHeader, custToken] = authHeader(customer.id, 'CUSTOMER');
    const [adminHeader, adminToken] = authHeader(admin.id, 'ADMIN');

    const created = await request(app.getHttpServer())
      .post('/business-applications')
      .set(custHeader, custToken)
      .send({ businessType: 'tailor' })
      .expect(201);

    const rejected = await request(app.getHttpServer())
      .post(`/admin/business-applications/${created.body.id}/reject`)
      .set(adminHeader, adminToken)
      .send({ reviewNotes: 'Missing certification' })
      .expect(201);
    expect(rejected.body.status).toBe('REJECTED');

    const updatedUser = await prisma.user.findUnique({ where: { id: customer.id } });
    expect(updatedUser?.role).toBe('CUSTOMER');
    const profile = await prisma.tailorProfile.findUnique({ where: { userId: customer.id } });
    expect(profile).toBeNull();

    const notifications = await request(app.getHttpServer())
      .get('/notifications')
      .set(custHeader, custToken)
      .expect(200);
    const notif = notifications.body.data.find((n: { type: string }) => n.type === 'application_rejected');
    expect(notif.body).toMatch(/Missing certification/);
  });

  it('404s reviewing a nonexistent application and 400s reviewing one already decided', async () => {
    const customer = await createCustomer(prisma);
    const admin = await createAdmin(prisma);
    userIds.push(customer.id, admin.id);
    const [custHeader, custToken] = authHeader(customer.id, 'CUSTOMER');
    const [adminHeader, adminToken] = authHeader(admin.id, 'ADMIN');

    await request(app.getHttpServer())
      .post('/admin/business-applications/does-not-exist/approve')
      .set(adminHeader, adminToken)
      .send({})
      .expect(404);

    const created = await request(app.getHttpServer())
      .post('/business-applications')
      .set(custHeader, custToken)
      .send({ businessType: 'tailor' })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/admin/business-applications/${created.body.id}/approve`)
      .set(adminHeader, adminToken)
      .send({})
      .expect(201);

    const res = await request(app.getHttpServer())
      .post(`/admin/business-applications/${created.body.id}/reject`)
      .set(adminHeader, adminToken)
      .send({})
      .expect(400);
    expect(res.body.message).toMatch(/already approved/);
  });

  it('lists applications filterable by status', async () => {
    const customer = await createCustomer(prisma);
    const admin = await createAdmin(prisma);
    userIds.push(customer.id, admin.id);
    const [custHeader, custToken] = authHeader(customer.id, 'CUSTOMER');
    const [adminHeader, adminToken] = authHeader(admin.id, 'ADMIN');

    const created = await request(app.getHttpServer())
      .post('/business-applications')
      .set(custHeader, custToken)
      .send({ businessType: 'embroidery' })
      .expect(201);

    const pending = await request(app.getHttpServer())
      .get('/admin/business-applications')
      .set(adminHeader, adminToken)
      .query({ status: 'PENDING' })
      .expect(200);
    expect(pending.body.some((a: { id: string }) => a.id === created.body.id)).toBe(true);
    expect(pending.body.every((a: { status: string }) => a.status === 'PENDING')).toBe(true);
    const withApplicant = pending.body.find((a: { id: string }) => a.id === created.body.id);
    expect(withApplicant.applicant.id).toBe(customer.id);

    await request(app.getHttpServer())
      .post(`/admin/business-applications/${created.body.id}/approve`)
      .set(adminHeader, adminToken)
      .send({})
      .expect(201);

    const stillPending = await request(app.getHttpServer())
      .get('/admin/business-applications')
      .set(adminHeader, adminToken)
      .query({ status: 'PENDING' })
      .expect(200);
    expect(stillPending.body.some((a: { id: string }) => a.id === created.body.id)).toBe(false);
  });
});
