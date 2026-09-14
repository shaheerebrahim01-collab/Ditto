# Deployment runbook

Operator steps for taking `docker-compose.prod.yml` from "built and
verified locally" (Phase 11) to "actually running in production" (Phase
14). Everything referenced here already exists in the repo and was
verified locally in Phases 11–13; this document doesn't introduce new
infrastructure, it's the checklist for using what's already there. See
`docs/ROADMAP.md` Phase 11 for how the stack itself was built and Phase
13 for the security hardening baked into the image.

## Prerequisites (the actual credential wall)

Everything below this line needs something that doesn't exist in this
environment: a real VPS, a real domain, and — depending on which phases'
credentials have been filled in by the time you deploy — real
Firebase/Anthropic/Stripe credentials. Nothing past this point can be
verified without them, per this project's standing rule of not faking
around a credential wall.

1. A VPS (any provider — nothing here is provider-specific) with Docker +
   Docker Compose v2 installed, reachable on 80/443.
2. Real DNS `A`/`AAAA` records for `API_DOMAIN` and `ADMIN_DOMAIN` pointed
   at that server's IP, live *before* first boot — Caddy's automatic
   HTTPS (Let's Encrypt) fails its first request otherwise.
3. `backend/.env.example` and `.env.prod.example` (repo root) list every
   variable needed; copy the latter to `.env.prod` on the server and fill
   in real values — a freshly generated `JWT_SECRET` (see the note in
   Phase 13 on why this must never fall back to a default), the real
   domains from step 2, and whichever of Firebase/Anthropic/Stripe are
   live by deploy time.

## First deploy

```bash
git clone <this repo> && cd ditto
# .env.prod filled in per the prerequisites above, on the server, never committed
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
```

`backend/docker-entrypoint.sh` runs `npx prisma migrate deploy`
automatically on container start — no separate migration step. Confirm:

```bash
curl -k --resolve "$API_DOMAIN:443:127.0.0.1" "https://$API_DOMAIN/health"
docker compose -f docker-compose.prod.yml logs caddy --tail=50   # real cert issued, not a self-signed fallback
```

## Routine deploys (after the first one)

```bash
git pull
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
```

`up --build` is required, not optional — `docker compose up` alone reuses
whatever image it last built and silently skips rebuilding even when the
source changed (the exact mistake Phase 11's ROADMAP entry recorded
costing real time). `--build` closes that gap here for good.

Once `GITHUB_ACTIONS` variable `VITE_API_BASE_URL` is set to the real
`API_DOMAIN` (Phase 11's `docker-publish.yml` note), `ghcr.io` also holds
a built image per push to `main` — pulling that instead of building
locally on the VPS is a possible later optimization, not required for
this to work.

## Rollback

```bash
git checkout <previous-commit-or-tag>
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
```

A schema migration is the one thing a plain rollback doesn't undo —
`prisma migrate deploy` only ever applies forward. If the commit being
rolled back to predates a migration that already ran, restore the last
backup taken before that migration (see below) rather than trying to
hand-roll a down-migration.

## Backups

`scripts/backup-db.sh` / `scripts/restore-db.sh` (repo root), verified
against the real local dev Postgres container as part of Phase 14: a
`pg_dump --clean --if-exists`, gzipped, timestamped — restoring replays
cleanly into a database that already has the same tables rather than
erroring on "relation already exists".

```bash
scripts/backup-db.sh                       # dumps to ./backups/ditto-<timestamp>.sql.gz
scripts/backup-db.sh docker-compose.yml    # same, against local dev instead of prod

scripts/restore-db.sh backups/ditto-<timestamp>.sql.gz     # prompts before dropping tables
FORCE=1 scripts/restore-db.sh backups/ditto-<timestamp>.sql.gz   # skip the prompt, scripted use
```

Neither script is wired into a cron job yet — that's an operator decision
(how often, how long to retain, whether backups get shipped off the VPS
itself rather than living next to the database they're backing up), not
something to guess at. A simple starting point once the VPS exists:

```cron
0 3 * * * cd /path/to/ditto && ./scripts/backup-db.sh >> backups/backup.log 2>&1
```

`/backups/` is gitignored (`.gitignore`) — dumps contain real user data
and never belong in the repo.

## Day-to-day operations

```bash
docker compose -f docker-compose.prod.yml logs -f backend   # tail one service's logs
docker compose -f docker-compose.prod.yml ps                # container health at a glance
docker compose -f docker-compose.prod.yml exec postgres psql -U "$POSTGRES_USER" "$POSTGRES_DB"   # a real psql shell
```

Secret rotation (e.g. `JWT_SECRET`): edit `.env.prod`, then `docker
compose -f docker-compose.prod.yml --env-file .env.prod up -d backend` —
rotating `JWT_SECRET` specifically invalidates every currently-issued
token immediately (`JwtStrategy` verifies against the new secret on the
very next request), so every signed-in user gets logged out at once. Plan
this as a deliberate, communicated action, not a silent config tweak.

## What's still deferred, on purpose

- **No automated deploy-on-push to the VPS.** `docker-publish.yml`
  (Phase 11) already builds and pushes images to `ghcr.io` on every push
  to `main`; actually pulling and restarting on the VPS in response is a
  real SSH-into-a-real-host action that can't be written and verified
  without that host existing — writing it now would mean guessing at
  connection details with zero ability to test the result, the same
  category of premature complexity this project has avoided at every
  other credential wall. Once the VPS from the Prerequisites section
  exists, add a `deploy.yml` workflow that SSHes in and runs the routine
  deploy command above — that's an additive follow-up, not a redesign.
- **No off-server backup shipping** (S3/other remote storage for backup
  files) — same shape of gap as `AWS_S3_BUCKET`/`CLOUDINARY_URL` elsewhere
  in this project (Phase 11's image-upload gap): needs a real bucket and
  credential, not fakeable.
- **No alerting/uptime monitoring** (e.g. a pinger against `/health`) —
  needs a real account with an external monitoring service; the endpoint
  it would watch already exists and already works.
