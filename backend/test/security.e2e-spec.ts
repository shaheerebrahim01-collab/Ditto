import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { createTestApp } from './utils/test-app';

// Cross-cutting hardening from Phase 13 — not owned by any one domain
// module, so it gets its own spec file rather than living inside e.g.
// auth.e2e-spec.ts or styling.e2e-spec.ts. No test data of its own, so no
// afterAll cleanup like every other spec file has.
describe('Security hardening (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    ({ app } = await createTestApp());
  });

  afterAll(async () => {
    await app.close();
  });

  it('sets helmet security headers on every response', async () => {
    const res = await request(app.getHttpServer()).get('/health').expect(200);
    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.headers['x-frame-options']).toBe('SAMEORIGIN');
    expect(res.headers['content-security-policy']).toBeDefined();
    expect(res.headers['strict-transport-security']).toBeDefined();
  });

  it('allows any origin when CORS_ORIGIN is unset (this test env), the way local dev and the mobile apps need', async () => {
    const res = await request(app.getHttpServer())
      .get('/health')
      .set('Origin', 'http://example.com')
      .expect(200);
    expect(res.headers['access-control-allow-origin']).toBe('*');
  });

  it('rejects a JSON body over the 1mb limit with 413, not a hang or a 500', async () => {
    await request(app.getHttpServer())
      .post('/auth/firebase')
      .set('Content-Type', 'application/json')
      .send({ idToken: 'a'.repeat(2 * 1024 * 1024) })
      .expect(413);
  });

  it('rate-limits POST /auth/firebase to 10/min per caller, 429 past that', async () => {
    // Sequential, not Promise.all — the throttler's counter increment isn't
    // guaranteed atomic across truly concurrent requests, so firing these
    // in parallel could let more than 10 slip through before any of them
    // observe the updated count. One at a time is what actually proves the
    // 11th request is the one that gets throttled.
    const statuses: number[] = [];
    for (let i = 0; i < 11; i++) {
      const res = await request(app.getHttpServer())
        .post('/auth/firebase')
        .send({ idToken: 'not-a-real-firebase-token' });
      statuses.push(res.status);
    }
    // Every one of the first 10 fails Firebase verification (401), never
    // 429 — rate limiting only kicks in once the 10/min budget is spent.
    expect(statuses.slice(0, 10)).toEqual(Array(10).fill(401));
    expect(statuses[10]).toBe(429);
  });
});
