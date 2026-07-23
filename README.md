# Ditto

Luxury tailoring marketplace — customer, tailor, rental shop, designer,
embroidery and admin experiences on one platform.

This is a real, continuing repository, not a demo. `docs/ROADMAP.md` is the
source of truth for build status; `docs/ARCHITECTURE.md` explains how it's
put together.

## Stack

- **Backend** — NestJS + TypeScript, PostgreSQL via Prisma, Redis
- **Mobile** — Flutter (planned, Phase 4+)
- **Auth** — Firebase Auth: Apple / Google / Phone / Email (Phase 3)
- **Payments** — Stripe, Apple Pay, Google Pay (Phase 10)

## Local setup

```bash
docker compose up -d          # postgres + redis
cd backend
cp .env.example .env
npm install
npx prisma generate
npx prisma migrate dev --name init
npm run start:dev
```

Health check: `GET http://localhost:3000/health`

## Continuing this project in a new session

**The repo is the source of truth, not chat history.** Nothing written to a
Claude.ai chat's sandbox persists once that conversation ends — so "pick up
where we left off" only works if the actual files are somewhere durable
(this folder, pushed to your own git remote).

To continue:

1. Push this folder to a GitHub repo (or just keep it locally).
2. Open it in **Claude Code** — it works against your real filesystem, so a
   new session can read `docs/ROADMAP.md`, see the actual code, and continue
   for real. That's the right tool for the remaining 13 phases.
3. If you'd rather continue in chat, open a new conversation and attach the
   files you want worked on — a fresh chat has no memory of this repo's
   contents otherwise.
