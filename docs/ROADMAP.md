# Ditto — Roadmap

Status lives here, in the repo — not in chat history. Whoever (or whatever)
continues this project should read this file first.

- [x] Phase 1 — Repository architecture
- [x] Phase 2 — Database schema
- [x] Phase 3 — Authentication
- [x] Phase 4 — Customer mobile app
- [x] Phase 5 — Tailor mobile app
- [ ] Phase 6 — Admin dashboard (in progress — backend API, RBAC, and admin-provisioning script done; no admin frontend yet)
- [ ] Phase 7 — Suit rental ops
- [ ] Phase 8 — AI styling & measurements
- [ ] Phase 9 — Messaging & notifications
- [ ] Phase 10 — Payments
- [ ] Phase 11 — Production infrastructure
- [ ] Phase 12 — Testing & QA
- [ ] Phase 13 — Security hardening
- [ ] Phase 14 — Deployment
- [ ] Phase 15 — App Store & Google Play release prep

**Note on roles:** no dedicated "Delivery Partner" app role. Ditto uses an
in-person Tailor Assistant Partner Program instead (training, certificate,
registered at an office). `TailorAssistant` is in the schema for roster and
certification tracking, not as an app-facing account type.

## Deferred

- More garment/fabric/detail options in the Create flow (currently 8
  garment types, 8 fabric swatches, 3 lapel/button styles) — later, not now.
- A full design pass across the customer app — later, not now.

## Phase 1 — repository architecture

NestJS backend skeleton in `backend/`: one module per domain
(`auth`, `users`, `tailors`, `rental-shops`, `orders`, `rentals`,
`payments`, `messaging`, `notifications`, `reviews`, `admin`), all wired into
`AppModule`. Shared `PrismaService`/`PrismaModule` (global). A real
`/health` controller.

**Verified:** `npm install` resolves cleanly (354 packages). `npm run build`
(`nest build`) compiles with zero errors.

## Phase 2 — database schema

`backend/prisma/schema.prisma` — 16 models / 5 enums covering users & roles,
tailor and rental-shop business profiles, tailor assistants, portfolio,
custom orders (with the production-stage enum from the prototype), rental
bookings, payments, reviews, messaging, notifications, wishlist, referrals,
and the business-application approval queue.

**Verified:** brace-balanced, every named relation appears on both sides,
every relation field type resolves to a real model — checked directly
against the schema text.

**Not verified here:** `prisma validate` / `prisma generate` need to
download a platform engine binary from `binaries.prisma.sh`, which this
sandbox's network allowlist doesn't include — so that specific check
couldn't run in this environment. Run it yourself right after cloning:
```bash
cd backend && npx prisma generate
```
It'll work normally on a machine with regular internet access. Booting the
server without having run that once will fail with `@prisma/client did not
initialize yet` — that's expected, not a bug, and confirmed in this sandbox.

## Phase 3 — authentication

`POST /auth/firebase` — verifies a Firebase ID token (Apple / Google /
Phone / Email sign-in happens client-side via Firebase; this endpoint is
where the client hands us that token). Finds or creates the matching
`User` row, then issues **our own** JWT — every other endpoint checks that
JWT and never talks to Firebase again.

`GET /users/me` — first protected endpoint, guarded by `JwtAuthGuard`.
Confirms the whole chain (`@nestjs/passport` → `JwtStrategy` →
`@CurrentUser()`) actually works, not just compiles.

**Verified:**
- `npm install`, `npm run build` — clean, 729 packages, zero compile errors
- `npm test` — 2/2 passing (JWT sign/verify round-trip, and that a token
  signed with the wrong secret is correctly rejected)
- Server still fails at boot for the one already-known reason (missing
  generated Prisma client) — confirmed no *new* startup errors from the
  auth module itself

**Not verified here, same reason as Phase 2:** the Firebase token
verification path itself needs a real Firebase project — `FIREBASE_PROJECT_ID`,
`FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` in `.env` — which only
exists once you create one. That's a Phase 3 follow-up, not blocking: create
a Firebase project, enable Apple/Google/Phone/Email sign-in providers, drop
a service-account key's values into `.env`, and `POST /auth/firebase` is
live.

## Phase 4 — customer mobile app (in progress)

Flutter app in `mobile/customer_app/`. First real Flutter code — talks to
`/auth/firebase` and `/users/me`, so those needed to exist first (Phase 3).

Hand-written, not scaffolded: `core/api_client.dart` (`loginWithFirebase`,
`getMe`), `core/auth_repository.dart` (Firebase sign-in for Apple / Google /
Phone / Email, then exchanges the Firebase ID token for our JWT exactly the
way `auth.service.ts` expects), `core/token_storage.dart` (secure storage
for our JWT, never the Firebase token), login + phone-OTP screens, and a
home screen that renders whatever `GET /users/me` returns — the first
screen that proves the full chain works.

**Verified:** the Dart request/response shapes were checked directly
against `auth.controller.ts`, `firebase-login.dto.ts`, `users.controller.ts`,
and the Prisma `User` model — not assumed. A unit test
(`test/user_model_test.dart`) checks `DittoUser.fromJson` against the real
`/users/me` shape.

**Not verified here:** this sandbox has no Flutter SDK, so none of it has
gone through `flutter pub get` / `analyze` / `test` / a build — same
category of gap as Prisma's engine binary in Phase 2. Two things still need
a real Flutter environment and a real Firebase project (same one Phase 3's
follow-up needs) before this runs at all:

1. `flutter create --org com.ditto.app --project-name customer_app --platforms=android,ios .`
   in `mobile/customer_app/` — generates `android/` and `ios/` (an
   iOS Xcode project isn't something to hand-write).
2. `flutterfire configure` against that Firebase project, then wire the
   generated `firebase_options.dart` into `main.dart`.

Full detail in `mobile/customer_app/README.md`.

Fully built out in this repo (later, past the initial auth+profile
milestone above): Home, Explore, Create, Orders, and Profile — all five
bottom-nav tabs, running against local mock data ahead of the endpoints
that don't exist yet (tailor browsing, order placement, rental tracking).
See per-screen commit history for what each renders against and why.

## Phase 5 — tailor mobile app

A separate Flutter app in `mobile/tailor_app/`, not a second entry point in
`customer_app` — its own `pubspec.yaml`, its own `main.dart`, its own
Android/web platform folders. Reuses the *pattern* from `customer_app`'s
`core/` (env, token storage, API client, auth repository, theme) copied in
rather than shared via a package, since a shared package wasn't asked for
and would be premature for two apps.

Three tabs: Dashboard (rating, today's/this-week's income, today's orders),
Orders (incoming requests with Accept/Decline, plus an active-orders list),
Portfolio (grid of work, "+" picks a real photo via `image_picker` and adds
it to the grid). All three render against local mock data — no tailor-facing
endpoints exist yet.

Two things are ahead of what the backend currently models, flagged inline
in the code:
- The incoming-request queue (with Accept/Decline) — `CustomOrder` only
  starts at `OrderStage.ORDER_CONFIRMED`; there's no "pending tailor
  approval" row yet.
- Portfolio photo upload — picking a real image works, but there's no
  storage backend yet (`AWS_S3_BUCKET`/`CLOUDINARY_URL` are Phase 11), so
  nothing persists past a reload.

Firebase Auth is reused from the same project as `customer_app`
(`ditto-713d5`) since Auth is project-wide, not per-registered-app — the
web config was copied in and works as-is. `flutterfire configure` has since
been run against that project for `com.ditto.app.tailor_app`, registering
the Android app (`google-services.json`, Google Services Gradle plugin, and
a real `android` case in `firebase_options.dart`) — Android was the last
blocker and is now unblocked.

**Verified:** `flutter pub get` and `flutter analyze` — clean, 0 issues.
Ran in Chrome, logged in through the same backend as `customer_app`. Android
Firebase config verified statically (registered app ID matches across
`firebase_options.dart`, `google-services.json`, and `firebase.json`) —
an actual `flutter build apk` couldn't be run in this environment due to
an unrelated JDK/Gradle-wrapper TLS certificate issue on this machine.

## Phase 6 — admin dashboard (in progress)

Backend API in `backend/src/modules/admin/`, plus a frontend now started
in `admin/` (React + Vite + TypeScript) — not finished, see below.

Adds role-based access control — `@Roles(Role.ADMIN)` decorator
(`modules/auth/decorators/roles.decorator.ts`) plus a `RolesGuard`
(`modules/auth/guards/roles.guard.ts`) that reads that metadata off the
handler/class and checks it against `request.user.role`. Meant to sit
alongside `JwtAuthGuard`, same pattern as every other guarded controller —
`RolesGuard` trusts that `JwtAuthGuard` already ran and populated
`request.user`.

`AdminController`/`AdminService`, everything behind
`@UseGuards(JwtAuthGuard, RolesGuard)` + `@Roles(Role.ADMIN)`:
- `GET /admin/stats` — user count, tailor count, pending business
  applications, total revenue (summed from succeeded `Payment` rows),
  orders placed since the start of the current month
- `GET /admin/business-applications` (optional `?status=`), plus
  `POST /admin/business-applications/:id/approve` and `/reject` — the
  applicant's name/email/phone is joined in application code, not via a
  Prisma `include`, since `BusinessApplication.applicantId` has no
  relation to `User` in the schema
- `GET /admin/users` (optional `?role=`) and `GET /admin/tailors` — the
  latter includes a `completedOrders` count per tailor (orders at
  `OrderStage.DELIVERED`), added specifically so the admin frontend's
  Tailors table wouldn't have to fabricate that number

**Verified:** checked the service's Prisma calls directly against
`schema.prisma` (`BusinessApplication`, `Payment`, `TailorProfile`, `User`,
`Role`, `BusinessStatus`) — every field and enum matches. `ValidationPipe`
is already global in `main.ts`, so `ReviewApplicationDto` validation is
live with no extra wiring. `npx tsc --noEmit` — zero errors.

There's no signup flow for `Role.ADMIN` — `backend/prisma/promote-admin.js`
closes that gap by promoting an already-existing user (by email) to admin:
`npm run seed:admin -- someone@example.com`. Verified against the real
local dev database, including the not-found and already-admin paths.

Frontend in `admin/` — React + Vite + TypeScript, design tokens and
layout ported from `docs/admin-prototype.html` (same Fraunces/Plus
Jakarta Sans type, cream/gold/copper palette, light+dark theme).
Firebase Auth (email/password, same "ditto-713d5" project as the mobile
apps) → `POST /auth/firebase` → our JWT, stored in `localStorage`;
`RequireAdmin` redirects to `/login` if signed out or refuses sign-in
for non-`Role.ADMIN` accounts. Four routes, all wired to the real
endpoints above, no sample data:
- **Overview** — the four stat-card numbers, plus a 2-item preview of
  pending applications
- **Applications** — full pending queue, Approve/Decline call the real
  endpoints, card animates out on success and the sidebar badge updates
  via a shared `StatsProvider`
- **Users** / **Tailors** — tables with client-side search

Two spots where the prototype's sample data didn't map onto the real
schema, handled by adaptation rather than invention:
`BusinessApplication` has no business-name field, so the application
card's headline is the applicant's name instead; the prototype's
"+2 this week" stat-trend badges were dropped since there's no
historical-comparison endpoint to back them honestly.

**Verified:** `npm run build` (`tsc -b && vite build`) and `npm run
lint` (oxlint) both clean. Ran both dev servers for real — backend
(`npm run start:dev`) against the local Postgres DB, frontend
(`npm run dev`) — and drove it with a headless Chromium
(Playwright, installed temporarily for this check and removed
afterward): login screen renders correctly; a real JWT signed with the
dev `JWT_SECRET` was used to sign in as the already-promoted admin
account and exercise all four views against the live backend; inserted
a temporary `BusinessApplication` row, confirmed the application card
renders and its Approve button really calls `POST
.../approve` (row's `status`/`reviewedAt` updated in Postgres,
confirmed directly), then deleted the test row. Zero browser console
errors throughout.

**Not built yet:** full Firebase login end-to-end (no password on hand
for the real account, worked around as above for this check — someone
with the actual credentials should confirm the login form itself);
create/suspend actions for users or tailors (only listing exists);
pagination (fine while data volume is this low, will matter later).

