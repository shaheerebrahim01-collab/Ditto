# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Ditto — a luxury tailoring marketplace: customer, tailor, rental shop,
designer, and embroidery experiences plus an admin dashboard, on one
NestJS + Prisma backend. This is a real, continuing project, not a demo.

**Read `docs/ROADMAP.md` first, every session.** It is the source of truth
for build status, not chat history — it records what's built, what's
verified (and how), what's explicitly deferred, and why, phase by phase.
`docs/ARCHITECTURE.md` covers the shape of the system. Update `ROADMAP.md`
as you complete work, in the same style already used there: what was
built, how it was actually verified (real DB/HTTP calls, not just "should
work"), and what's deliberately left out and why.

## Repo layout

- `backend/` — NestJS + TypeScript API, PostgreSQL via Prisma, Redis
- `admin/` — React + Vite + TypeScript admin dashboard
- `mobile/customer_app/` — Flutter app for customers
- `mobile/tailor_app/` — Flutter app for tailors *and* rental-shop owners
  (role-branches client-side; see Architecture below)
- `docs/` — `ROADMAP.md` (status), `ARCHITECTURE.md` (shape), an HTML
  design prototype the admin frontend's tokens were ported from

## Commands

### Backend (`backend/`)

```bash
docker compose up -d              # postgres + redis (from repo root)
npm install
npx prisma generate               # required before the server will boot
npx prisma migrate dev --name <name>   # after editing schema.prisma
npm run start:dev                 # watch mode, http://localhost:3000
npm run build                     # nest build
npx tsc --noEmit                  # typecheck only
npm test                          # jest, all specs
npx jest src/modules/auth/auth.spec.ts   # single test file
npm run seed:admin -- someone@example.com   # promote an existing user to Role.ADMIN
```

Health check: `GET http://localhost:3000/health`.

### Admin (`admin/`)

```bash
npm install
npm run dev       # vite dev server
npm run build     # tsc -b && vite build
npm run lint       # oxlint
```

Needs the backend running and a `Role.ADMIN` user already provisioned
(`npm run seed:admin` in `backend/`). Talks to `http://localhost:3000` by
default — see `admin/.env.example`.

### Mobile (`mobile/customer_app/`, `mobile/tailor_app/`)

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Chrome (`flutter run -d chrome`) has been the reliable run target on this
project's dev machine — Android emulator runs have repeatedly hung/hit
unrelated JDK/Gradle TLS issues. Prefer it when just verifying a change
works end-to-end.

## Architecture

### Backend: one module per domain

`backend/src/modules/*` — `auth`, `users`, `tailors`, `rental-shops`,
`rentals`, `orders`, `payments`, `messaging`, `notifications`, `reviews`,
`measurements`, `measurement-visits`, `styling`, `business-applications`,
`admin`. Each module owns its own controller/service/DTOs; nothing reaches
across module boundaries directly. Shared infrastructure (`PrismaService`
in `backend/src/prisma`, global) lives outside `modules/`.

One PostgreSQL schema, one migration history (`backend/prisma/schema.prisma`,
`backend/prisma/migrations/`) — not a database per module. `PrismaService`
is a global Nest provider; every module injects the same client instance.

`ValidationPipe({ whitelist: true, transform: true })` is global
(`main.ts`) — DTOs with `class-validator` decorators are enforced
everywhere with no extra per-route wiring.

### Auth model

Firebase Auth (Apple/Google/Phone/Email) happens client-side. The client
then calls `POST /auth/firebase` with the Firebase ID token; the backend
verifies it, finds-or-creates the matching `User` row, and issues **our
own** JWT. Every other endpoint checks that JWT (`JwtAuthGuard` →
`JwtStrategy` → `@CurrentUser()`) and never talks to Firebase again.

Role gating: `@Roles(Role.X)` decorator + `RolesGuard`, always stacked
after `JwtAuthGuard` (`@UseGuards(JwtAuthGuard, RolesGuard)`) —
`RolesGuard` trusts `JwtAuthGuard` already populated `request.user`.
`JwtStrategy` re-checks `User.suspended` against the database on *every*
request, so a suspended user's still-valid token stops working
immediately rather than on next login. Anything that can go stale between
token-issue and use (role changes from application approval, suspension)
is re-checked against the database inside the relevant service, not
trusted from the JWT claims — see how `business-applications` checks the
caller's current role/pending-application state fresh rather than off the
token.

`Role` enum: `CUSTOMER`, `TAILOR`, `RENTAL_SHOP`, `DESIGNER`,
`EMBROIDERY_SPECIALIST`, `ADMIN`. There is no separate delivery-partner
role — see `TailorAssistant` note below.

### Self-scoped resources

Endpoints over a user's own data (`/rentals/me`, `/measurements`,
`/measurement-visits/me`, `/rental-shops/me/*`) take no "whose" param —
they scope entirely off the caller's JWT. A resource that isn't the
caller's own returns `404`, not `403`, so a caller can't probe for the
existence of someone else's row by ID.

FK-constraint deletes (e.g. deleting a `RentalItem`/`Measurement` still
referenced by a booking/order) are caught and turned into `409 Conflict`
rather than leaking a raw Prisma `P2003` as a 500 — this pattern repeats
across modules; follow it for new delete endpoints.

### Business application → role/profile provisioning

`BusinessApplicationsModule` (`POST /business-applications`) lets any
authenticated user apply as `tailor`/`rental_shop`/`designer`/`embroidery`.
Approval (`admin.service.ts`'s `reviewApplication`) is the *only* place
that flips `User.role` and provisions the matching profile
(`TailorProfile`/`RentalShopProfile`) — both happen in one transaction.
`designer`/`embroidery` get only the role bump; neither has a profile
model yet. Keep this the single provisioning path if you touch it —
don't add a second way for a `TailorProfile` to come into existence.

### `TailorAssistant` is not an app account

`TailorAssistant` (roster/certification tracking, belongs to a
`TailorProfile`) has no login of its own — it's a name/certificate record
a tailor manages, not a role. Don't wire auth or app-facing endpoints
directly to it; work assigned to "an assistant" goes through the tailor's
account (e.g. `MeasurementVisitRequest.assistantId` is just a pointer into
the claiming tailor's own roster).

### Rental shops share `tailor_app`, not a third app

`RENTAL_SHOP` is a full app-facing role, but there's no `rental_shop_app`
— `mobile/tailor_app`'s `AuthGate` (`main.dart`) branches on
`currentUser.role`: `RENTAL_SHOP` gets `RentalShopShell`, everything else
gets `TailorShell`. Follow this pattern (role-branch inside the existing
app) rather than starting a new Flutter project if a new role needs its
own mobile surface, unless there's a strong reason to duplicate the whole
`core/` layer again.

### Mobile apps: duplicated `core/`, not shared

`customer_app` and `tailor_app` are separate Flutter apps (own
`pubspec.yaml`, `main.dart`, platform folders, own Firebase app
registration under the same `ditto-713d5` Firebase project — Auth is
project-wide). Each has its own `core/` (`api_client.dart`,
`auth_repository.dart`, `token_storage.dart`, `env.dart`, `theme.dart`)
and `models/`, hand-copied between the two rather than extracted into a
shared package — deliberate, not an oversight, since a shared package
would be premature for two apps with no shared UI. Known pre-existing
duplication, not something to "fix" incidentally while doing unrelated
work.

`core/api_client.dart` calls real backend endpoints as they're built;
several screens still render from `lib/data/mock_*.dart` ahead of
endpoints that don't exist yet — check `docs/ROADMAP.md`'s current phase
before assuming a screen is wired to a real endpoint.

### AI styling — constrained, not open-ended

`POST /styling/recommend` (`backend/src/modules/styling/`) calls the
Anthropic Claude API but constrains its output via tool-use/structured
output to the exact garment/fabric/lapel/button vocabulary already in
`mobile/customer_app/lib/data/garment_builder_options.dart`
(mirrored in `garment-vocabulary.ts`) — a recommendation can only ever be
a combination actually orderable through the existing Create flow.
Requires `ANTHROPIC_API_KEY`; without it the endpoint returns a clean
`503`, not a crash — keep that fallback if you touch this module.

## Working conventions specific to this repo

- **Credentials are requested exactly when needed, not stubbed.** Phases
  that need a real credential (`FIREBASE_*`, `ANTHROPIC_API_KEY`,
  `STRIPE_SECRET_KEY`, `AWS_S3_BUCKET`/`CLOUDINARY_URL`) say so in
  `docs/ROADMAP.md` and block cleanly (a real `503`/config error) rather
  than being faked out with mock data.
- **Verification means real DB/HTTP calls**, not "should work." The
  existing `ROADMAP.md` entries show the bar: run the dev server for
  real, drive endpoints with `curl` and real signed JWTs (or a headless
  browser for the admin/mobile UI), check the actual Postgres row
  afterward, and delete any seeded/test data afterward — confirm cleanup
  with `git status` so nothing stray is left behind.
- `.env` files are gitignored; `.env.example` in `backend/` and `admin/`
  documents every variable, including ones not wired in yet (commented,
  tagged with the phase that needs them) so their shape is never a
  surprise later.

## Standing instructions: build to completion

Work through the remaining phases in order, committing and pushing after
each real milestone — not just at the end — so nothing is lost if
something goes wrong.

- Phase 9 (Messaging & Notifications): continue what's in progress.
- Phase 10 (Payments): build everything up to the point of needing a real
  Stripe account (Connect, since this platform pays out to tailors and
  rental shops, not just charges customers). Stop there.
- Phase 11 (Production Infrastructure): write the infrastructure-as-code,
  Docker/deployment configs, and CI/CD pipeline. Stop before anything
  needing a real hosting account, domain, or that costs real money.
- Phase 12 (Testing & QA): build real test coverage. Fully buildable now,
  no blockers.
- Phase 13 (Security Hardening): dependency audits, input validation,
  rate limiting, auth edge cases. Fully buildable now, no blockers.
- Phase 14 (Deployment): prepare everything possible. Stop before
  actually provisioning real infrastructure.
- Phase 15 (App Store / Play Store): prepare store listing copy and asset
  requirements. Stop before anything needing real Apple Developer or
  Google Play Console enrollment.

The moment something genuinely needs my credentials, a business
decision, or a real external account: stop, write exactly what's needed
and why in `docs/ROADMAP.md`, and move to the next unblocked thing
instead of stalling. Never fake or mock around a blocker.
