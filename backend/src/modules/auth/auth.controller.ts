import { Body, Controller, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { FirebaseLoginDto } from './dto/firebase-login.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // The app calls this right after Firebase sign-in succeeds on the device.
  // Returns our own JWT — that's what the app stores and sends on every
  // request after this.
  @Post('firebase')
  async loginWithFirebase(@Body() dto: FirebaseLoginDto) {
    return this.authService.loginWithFirebase(dto.idToken);
  }
}
