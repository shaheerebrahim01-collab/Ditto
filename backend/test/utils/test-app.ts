import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as jwt from 'jsonwebtoken';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/prisma/prisma.service';

// Boots the real app (real Prisma, real Postgres, every real module/guard/
// pipe) exactly the way main.ts does — the same "real DB/HTTP calls, not
// mocks" bar this project's manual curl verification has always used,
// just automated. One instance is shared across a whole spec file's tests
// (see beforeAll/afterAll in each *.e2e-spec.ts) rather than per-test,
// since booting the full module graph isn't free.
export async function createTestApp(): Promise<{ app: INestApplication; prisma: PrismaService }> {
  const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
  // rawBody: true mirrors main.ts exactly — POST /payments/webhook reads
  // req.rawBody to verify Stripe's signature, and won't see it otherwise.
  const app = moduleRef.createNestApplication({ rawBody: true });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  await app.init();
  const prisma = app.get(PrismaService);
  return { app, prisma };
}

// Mirrors AuthService.signAccessToken exactly (sub/role claims, same
// secret resolution) — lets tests act as an arbitrary user without going
// through a real Firebase sign-in.
export function signTestToken(userId: string, role: string): string {
  const secret = process.env.JWT_SECRET ?? 'dev-secret-change-me';
  return jwt.sign({ sub: userId, role }, secret, { expiresIn: '1h' });
}

export function authHeader(userId: string, role: string): [string, string] {
  return ['Authorization', `Bearer ${signTestToken(userId, role)}`];
}
