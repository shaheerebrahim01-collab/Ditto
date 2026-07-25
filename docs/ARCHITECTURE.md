# Architecture

## Shape

Single NestJS backend, modularized by domain (`backend/src/modules/*`).
Each module will own its own controllers/services/DTOs as they're built out
— nothing reaches across module boundaries directly. Shared infrastructure
(Prisma now; config, guards, interceptors as they're needed) lives outside
`modules/` so domain modules only depend on what they actually use.

## Data layer

PostgreSQL via Prisma — one schema, one migration history, not a database
per module. `PrismaService` (`backend/src/prisma`) is a global Nest
provider, so every module injects the same client instance rather than
each opening its own connection.

## Why this stack

Matches what was specified: TypeScript end-to-end, a schema-first ORM with
real migrations rather than a codegen guess, and a relational model that
fits how tightly orders/measurements/payments/reviews reference each other.

## Mobile

Flutter, built against this API. Two separate apps, not one app with two
modes — separate `pubspec.yaml`, `main.dart`, and platform folders each,
since they're different products for different roles (a customer never
needs the tailor's order queue, and vice versa):

- `mobile/customer_app/` (Phase 4) — browsing, ordering, profile.
- `mobile/tailor_app/` (Phase 5, in progress) — dashboard, incoming
  orders, portfolio.

Both are layered the same way as the backend: `core/` for the API client,
token storage, and the Firebase-to-JWT auth exchange; `features/*` for
screens; `models/` mirroring the Prisma models each consumes. That `core/`
layer is duplicated between the two apps rather than extracted into a
shared package — with only two apps and no shared UI, a shared package
would be premature.

## What's deliberately not here yet

No controllers or services beyond `/health` — real business logic starts in
Phase 3. No CI/CD, no cloud infrastructure, no payment or auth-provider
wiring. Those need real credentials and land in Phases 10–11 with the exact
setup steps and the specific credential or action needed from you at that
point — not before.
