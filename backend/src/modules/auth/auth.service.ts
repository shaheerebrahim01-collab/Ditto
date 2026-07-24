import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../prisma/prisma.service';
import { getFirebaseAdmin } from './firebase-admin.provider';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  // Called by POST /auth/firebase. This is the one place Firebase and our
  // own database meet: Firebase proves who the person is, we decide what
  // that means for our User table, then we hand back a session token that's
  // ours — every other endpoint only ever has to check *our* JWT, never
  // talk to Firebase again.
  async loginWithFirebase(idToken: string) {
    let decoded;
    try {
      decoded = await getFirebaseAdmin().auth().verifyIdToken(idToken);
    } catch {
      throw new UnauthorizedException('Invalid or expired Firebase token');
    }

    const email = decoded.email ?? null;
    const phone = decoded.phone_number ?? null;

    const orConditions: Array<{ email: string } | { phone: string }> = [];
    if (email) orConditions.push({ email });
    if (phone) orConditions.push({ phone });

    let user = orConditions.length
      ? await this.prisma.user.findFirst({ where: { OR: orConditions } })
      : null;

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          email,
          phone,
          fullName: (decoded.name as string | undefined) ?? 'New User',
          avatarUrl: (decoded.picture as string | undefined) ?? null,
          authProvider: decoded.firebase?.sign_in_provider ?? 'unknown',
        },
      });
    }

    const accessToken = this.signAccessToken(user.id, user.role);
    return { accessToken, user };
  }

  signAccessToken(userId: string, role: string): string {
    return this.jwt.sign({ sub: userId, role });
  }
}
