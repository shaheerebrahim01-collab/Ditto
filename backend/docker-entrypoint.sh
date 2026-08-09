#!/bin/sh
set -e

# Applies any migrations not yet on this database, then starts the app.
# `migrate deploy` (unlike `migrate dev`) is non-interactive and safe to
# run automatically on every container start — it's a no-op if nothing's
# pending.
npx prisma migrate deploy

exec node dist/main.js
