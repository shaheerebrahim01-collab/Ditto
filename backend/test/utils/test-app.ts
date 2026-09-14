import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { NestExpressApplication } from '@nestjs/platform-express';
import * as jwt from 'jsonwebtoken';
import helmet from 'helmet';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/prisma/prisma.service';
import { getJwtSecret } from '../../src/modules/auth/jwt-secret';
import { getCorsOptions } from '../../src/cors-options';

// Boots the real app (real Prisma, real Postgres, every real module/guard/
// pipe) exactly the way main.ts does — the same "real DB/HTTP calls, not
// mocks" bar this project's manual curl verification has always used,
// just automated. One instance is shared across a whole spec file's tests
// (see beforeAll/afterAll in each *.e2e-spec.ts) rather than per-test,
// since booting the full module graph isn't free.
export async function createTestApp(): Promise<{ app: INestApplication; prisma: PrismaService }> {
  const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
  // Same rawBody/bodyParser/helmet/CORS setup as main.ts's bootstrap() —
  // kept in sync by hand since tests build the app via Nest's testing
  // module rather than importing main.ts itself.
  const app = moduleRef.createNestApplication<NestExpressApplication>({ rawBody: true, bodyParser: false });
  app.useBodyParser('json', { limit: '1mb' });
  app.useBodyParser('urlencoded', { extended: true, limit: '1mb' });
  app.use(helmet());
  app.enableCors(getCorsOptions());
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  await app.init();
  const prisma = app.get(PrismaService);
  return { app, prisma };
}

// Mirrors AuthService.signAccessToken exactly (sub/role claims, same
// secret resolution) — lets tests act as an arbitrary user without going
// through a real Firebase sign-in.
export function signTestToken(userId: string, role: string): string {
  return jwt.sign({ sub: userId, role }, getJwtSecret(), { expiresIn: '1h' });
}

export function authHeader(userId: string, role: string): [string, string] {
  return ['Authorization', `Bearer ${signTestToken(userId, role)}`];
}
