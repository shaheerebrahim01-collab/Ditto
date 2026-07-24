import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

// Put @UseGuards(JwtAuthGuard) on any route that should require login.
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}
