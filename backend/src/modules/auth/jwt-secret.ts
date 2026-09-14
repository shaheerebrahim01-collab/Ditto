// Both JwtModule.register (signing) and JwtStrategy (verifying) need this
// same secret. No insecure fallback — an unset JWT_SECRET used to
// silently fall back to a hardcoded string, which meant anyone who'd read
// this file (or the ROADMAP snippets quoting it) could forge a valid
// token for any user/role, including ADMIN, on any deployment that forgot
// to set the env var. .env.example/.env.prod.example both already
// document it as required, so failing fast here just makes that
// requirement real instead of a comment.
export function getJwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET is not set — see backend/.env.example');
  }
  return secret;
}
