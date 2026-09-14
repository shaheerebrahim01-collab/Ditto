import { CorsOptions } from '@nestjs/common/interfaces/external/cors-options.interface';

// Shared by main.ts's bootstrap() and test/utils/test-app.ts so the two
// can't silently drift — they already did once (test-app.ts mirrored
// rawBody/bodyParser/helmet by hand but missed enableCors entirely, which
// a security e2e test then caught as a false failure, not a real bug).
//
// CORS_ORIGIN is unset in local dev and in the e2e test env — undefined
// here means "allow any origin", matching the mobile apps' native HTTP
// calls (no browser origin to restrict) and the admin dev server on
// whatever port Vite picks. In production, docker-compose.prod.yml sets
// it to the real admin origin (https://${ADMIN_DOMAIN}) so the API only
// answers cross-origin browser requests from the actual admin dashboard.
export function getCorsOptions(): CorsOptions | undefined {
  const corsOrigin = process.env.CORS_ORIGIN;
  return corsOrigin ? { origin: corsOrigin.split(',').map((o) => o.trim()) } : undefined;
}
