import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PrismaService } from '../../../prisma/prisma.service';

interface JwtPayload {
  sub: string;
  role: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private readonly prisma: PrismaService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_SECRET ?? 'dev-secret-change-me',
    });
  }

  // Whatever this returns becomes `request.user` — picked up by the
  // @CurrentUser() decorator on any protected route. The token's own
  // `role` claim is trusted as-is (same as before — a promoted/demoted
  // user's existing tokens don't reflect that until they sign in again),
  // but `suspended` is checked fresh against the database on every
  // request, since that's the one thing an admin action needs to take
  // effect immediately rather than after the token expires.
  async validate(payload: JwtPayload) {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: { suspended: true },
    });
    if (!user || user.suspended) {
      throw new UnauthorizedException('This account has been suspended');
    }
    return { userId: payload.sub, role: payload.role };
  }
}
