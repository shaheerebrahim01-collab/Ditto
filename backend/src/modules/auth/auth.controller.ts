import { Body, Controller, Post } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { FirebaseLoginDto } from './dto/firebase-login.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // The app calls this right after Firebase sign-in succeeds on the device.
  // Returns our own JWT — that's what the app stores and sends on every
  // request after this. Tighter than the app-wide default: every call does
  // a real Firebase token verification plus a DB lookup/create, so it's the
  // one unauthenticated route worth guarding against being hammered.
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Post('firebase')
  async loginWithFirebase(@Body() dto: FirebaseLoginDto) {
    return this.authService.loginWithFirebase(dto.idToken);
  }
}
