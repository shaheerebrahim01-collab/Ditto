import { IsString, MinLength } from 'class-validator';

// What the app sends us after a user signs in with Firebase (Apple, Google,
// Phone, or Email) on their phone — just the token Firebase gave them.
export class FirebaseLoginDto {
  @IsString()
  @MinLength(10)
  idToken: string;
}
