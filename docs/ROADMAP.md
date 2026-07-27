# Ditto — Roadmap

Status lives here, in the repo — not in chat history. Whoever (or whatever)
continues this project should read this file first.

- [x] Phase 1 — Repository architecture
- [x] Phase 2 — Database schema
- [x] Phase 3 — Authentication
- [x] Phase 4 — Customer mobile app
- [x] Phase 5 — Tailor mobile app
- [x] Phase 6 — Admin dashboard
- [ ] Phase 7 — Suit rental ops (in progress — backend foundation done: profiles, inventory, bookings, application submission; no admin/mobile UI yet)
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

## Phase 6 — admin dashboard

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

**Firebase login confirmed end-to-end with a real account.** First
attempt failed with "Invalid or expired Firebase token" — turned out to
be the same TLS-interception issue that's dogged this machine all
along (see Phase 5's Gradle note), this time hit by `firebase-admin`'s
token verifier fetching Google's public certs. Fixed the same way:
`NODE_OPTIONS=--use-system-ca` when starting the backend. Confirmed
`FIREBASE_PROJECT_ID`/`FIREBASE_CLIENT_EMAIL`/`FIREBASE_PRIVATE_KEY`
were never the problem — all three were correctly set the whole time.

**Suspend/reactivate for Users and Tailors** — the "only listing
exists" gap is closed:
- Schema: `User.suspended` (`Boolean @default(false)`,
  migration `20260725200953_add_user_suspended`). `TailorProfile`
  already had `BusinessStatus.SUSPENDED` in its enum, so tailors just
  needed the transition wired up (`APPROVED` ↔ `SUSPENDED` only —
  `PENDING`/`REJECTED` still go through the existing approve/reject
  path).
- `JwtStrategy` now checks `suspended` against the database on every
  request (the JWT's `role` claim is still trusted as-is, unchanged
  from before) — confirmed a suspended user's *existing, still-valid*
  token starts getting rejected immediately, not just on next login.
- New endpoints, same guard pattern as the rest of `/admin/*`:
  `POST /admin/users/:id/suspend`, `/reactivate`,
  `POST /admin/tailors/:id/suspend`, `/reactivate`. Both sides throw
  `BadRequestException` on a no-op transition (already suspended,
  already active, or a tailor not currently `APPROVED`/`SUSPENDED`).
- Frontend: Suspend/Reactivate buttons in both tables, with a status
  badge. The Users table hides the button on the signed-in admin's own
  row — suspending yourself would 401 you out immediately per the
  `JwtStrategy` check above, so it's not offered.
- **Bug caught by testing, fixed before commit:** the tailor
  suspend/reactivate endpoints originally returned the bare
  `tailorProfile.update()` result, missing the `user` relation and
  `completedOrders` that `listTailors()` includes — the frontend
  crashed (`Cannot read properties of undefined (reading 'fullName')`)
  when it tried to merge that response into the table. Fixed by
  extracting a shared `tailorInclude`/`shapeTailor` helper so both
  endpoints return the same shape; re-verified via the same
  Playwright/real-backend approach (suspend → reactivate round trip
  against a temporary tailor, zero console errors, temp rows deleted
  after).

**Pagination + create actions for Users and Tailors** — the last "not
built yet" gap is closed:
- `GET /admin/users` and `GET /admin/tailors` now take `page`/`pageSize`
  (default 20, capped at 100) and return `{ data, total, page, pageSize }`
  instead of a bare array. Added a `q` search param to both at the same
  time — pagination without it would have silently broken the existing
  client-side search (it could only ever see whatever page happened to be
  loaded), so search moved server-side (`contains`/`insensitive` over
  name/email/phone) to keep the two features composable.
- `POST /admin/users` creates a `User` row directly (`fullName` required,
  at least one of `email`/`phone` required, optional `role`). It's
  deliberately the same shape `auth.service.ts`'s find-or-create already
  matches on — an admin-provisioned account gets picked up by its real
  owner the first time they sign in with Firebase, rather than getting a
  duplicate row. `authProvider` is set to `"admin"` to mark that origin.
- `POST /admin/tailors` creates a `User` (role `TAILOR`) and its
  `TailorProfile` together in one transaction, status `APPROVED`
  (admin-onboarded directly, bypassing the pending-application queue —
  the admin is vetting it out of band). Worth flagging: this is the
  *only* code path that creates a `TailorProfile` at all —
  `approveApplication` only flips a `BusinessApplication`'s status, it
  never provisions the profile. That gap predates this change and is
  still open.
- Both create endpoints return `409 Conflict` on a duplicate email/phone
  (Prisma `P2002`), `400 Bad Request` if neither email nor phone is
  given.
- Frontend: new `Modal` and `Pagination` components (`admin/src/components/`),
  styled to match the existing cream/gold/copper tokens (no prototype
  precedent for either — `docs/admin-prototype.html` has neither
  pagination nor a modal). Users/Tailors pages debounce the search box
  (300ms) into the new `q` param, reset to page 1 on a new search, and
  each got an "Add user"/"Add tailor" button opening a form modal;
  successful creation refreshes the current page's data and the sidebar
  stat counts via the shared `StatsProvider`.

**Verified:** `npx tsc --noEmit` (backend) and `npm run build` + `npm run
lint` (admin) all clean. Ran both dev servers for real against the local
Postgres DB and drove the new endpoints directly with `curl` using a real
signed JWT for the already-promoted admin account: paginated listing,
search, successful create, the 400 (no email/phone) and 409 (duplicate)
paths all returned the right status and body. Then drove the actual UI
with headless Chromium (Playwright, installed temporarily and removed
afterward): created a user and a tailor through the modals and watched
the table update live with zero console errors; created 8 filler users
to push the count past one page and confirmed the pagination controls
(page count, Previous/Next disabled state, the "x–y of z" summary) work
correctly. All test rows deleted afterward, confirmed via `git status`
that no stray files were left behind.

## Phase 7 — suit rental ops (in progress)

Backend foundation only this round: `RentalShopsModule` and
`RentalsModule` (`backend/src/modules/rental-shops/`,
`backend/src/modules/rentals/`) went from empty skeletons (present since
Phase 1) to real controllers/services. No admin-frontend or mobile-app UI
yet — see "Not built yet" below.

**Found while reviewing how `BusinessApplication` handles rental-shop
applicants, fixed first since everything else depends on it:** approving
an application never did anything beyond flipping its `status` — no
`RentalShopProfile` (or `TailorProfile`) ever actually got created, so
there was no way for an approved rental-shop applicant to end up with a
usable account. There's also no endpoint anywhere that *creates* a
`BusinessApplication` in the first place — applicants apply through a
flow that doesn't exist yet, so today the only way one gets into the
table is a direct DB insert, same as the manual row Phase 6 used to
verify the approve/reject buttons. Fixed the provisioning half in
`admin.service.ts`'s `reviewApplication`: on approval, it now bumps the
applicant's `User.role` and upserts the matching profile
(`TailorProfile` for `businessType: "tailor"`, `RentalShopProfile` for
`"rental_shop"`) inside the same transaction as the status update.
`businessName` starts out as the applicant's own name — `BusinessApplication`
has no business-name field to draw from (same gap already noted in the
Phase 6 admin frontend) — until shop-profile editing lets them rename it.
`designer`/`embroidery` applications get the role bump only; neither has
a profile model in the schema, so there's nothing else to provision yet.
Submitting an application at all was still an open gap at this point in
the phase — closed further down, see "Submission endpoint added" below.

**`RentalShopsModule` (`/rental-shops/*`):**
- `GET /rental-shops` — public browse, `APPROVED` shops only, optional
  `q` search on `businessName`, paginated (`page`/`pageSize`, same
  bounded-parse helper as `AdminController`'s, copied rather than shared
  since there's no module both controllers already depend on).
- `GET /rental-shops/:id` — public shop detail + its items; 404s for
  anything not `APPROVED` rather than leaking that a pending/rejected
  shop exists.
- `GET/PATCH /rental-shops/me` — the signed-in shop owner's own profile
  (`@Roles(Role.RENTAL_SHOP)`); `PATCH` only exposes `businessName`,
  since that's the only editable field the schema has for this model.
- `GET/POST /rental-shops/me/items`, `PATCH/DELETE
  /rental-shops/me/items/:id` — inventory CRUD, all scoped to the caller's
  own shop. `DELETE` catches the Prisma FK-constraint error (`P2003`) an
  item with existing bookings would otherwise throw as a raw 500, and
  turns it into a `409 Conflict` instead.

**`RentalsModule` (`/rentals/*`):**
- `POST /rentals` — any logged-in user books an item: validates
  `returnDate > pickupDate`, `pickupDate` isn't in the past, and that the
  requested range doesn't overlap an existing `RESERVED`/`PICKED_UP`
  booking on the same item (a real availability check, not just a
  well-formed-dates check).
- `GET /rentals/me`, `POST /rentals/:id/cancel` — renter self-service;
  cancel only works from `RESERVED` (can't cancel after pickup), and a
  booking that isn't the caller's own 404s rather than 403s, so a renter
  can't probe for the existence of someone else's booking ID.
- `GET /rentals/shop` (optional `?status=`), `POST /rentals/:id/pickup`,
  `POST /rentals/:id/return` — shop-side (`@Roles(Role.RENTAL_SHOP)`),
  ownership-scoped through the caller's own `RentalShopProfile`.
  `return` computes a late fee (`daysLate × item.pricePerDay`, rounded up
  to a full day) when called after `returnDate`, rather than requiring a
  separate step. `RentalStatus.LATE` from the schema is intentionally
  unused — flipping a booking's status automatically as it goes overdue
  needs a scheduled job, which is Phase 11 infrastructure; `listShopBookings`
  computes an `overdue` boolean on the fly instead so the shop can see it
  today without that infra.

**Verified:** `npx tsc --noEmit` clean. Ran the dev server for real
against the local Postgres DB. Since there's no submit-application
endpoint, seeded a rental-shop applicant and a `BusinessApplication` row
directly (same approach Phase 6 used), then drove the entire flow
through the real HTTP endpoints with `curl` and real signed JWTs:
approved the application and confirmed the `User.role` flip and
`RentalShopProfile` creation directly in Postgres; created inventory
(including the validation-rejection path for a negative price); listed
and fetched shops/items through the public endpoints; booked an item,
confirmed a date-overlapping second booking is rejected, confirmed
past-dates and inverted-range are rejected; confirmed a `CUSTOMER` gets
`403` on the shop-only `/rentals/shop` route; ran a booking through
pickup → on-time return (`lateFee: 0`); separately seeded an already-overdue
`PICKED_UP` booking and confirmed both the `overdue` flag and the
late-fee math on return; confirmed deleting an item with bookings
against it returns `409` while a bookings-free item deletes cleanly;
confirmed cancelling twice and cancelling someone else's booking both
fail correctly (`400` and `404`). All seeded rows deleted afterward,
confirmed via `git status` that no stray files were left behind.

**Submission endpoint added — the "everything upstream of approve is
manual" gap above is closed.** New `BusinessApplicationsModule`
(`backend/src/modules/business-applications/`), one route:
`POST /business-applications`, covering all four business types (tailor,
rental_shop, designer, embroidery). Guarded by `JwtAuthGuard` only — any
authenticated user can apply, deliberately not restricted to
`Role.ADMIN` like everything under `/admin/*`; `applicantId` is taken
from the caller's own JWT, not the request body, so nobody can submit an
application on someone else's behalf. `businessType` is validated
against the same four values via `@IsIn` (previously just a free-form
string trusted from admin-inserted rows). Two checks before the row is
created, both looked up fresh from the database rather than the JWT's
claims (the JWT's `role` claim goes stale the moment an application gets
approved, same reason `JwtStrategy` already re-checks `suspended` fresh
on every request): reject if the applicant already holds that exact role
(`"You already have a tailor account"`), and reject if they have any
other application still `PENDING` — one in-flight application at a time,
regardless of type, rather than tracking per-type pending state
separately. Deliberately out of scope: no `GET` to check your own
application's status — the frontend that would consume this doesn't
exist yet either.

**Verified:** `npx tsc --noEmit` clean. Ran the dev server for real
against local Postgres: confirmed a logged-out request gets `401`, an
invalid `businessType` gets `400` with the allowed values listed, a
valid tailor submission succeeds and a second submission while it's
still pending is rejected. Approved that real (not seeded) submission
through the existing `/admin/business-applications/:id/approve`
endpoint and confirmed in Postgres that the applicant's `User.role`
flipped to `TAILOR` and a `TailorProfile` was created — the first time
this fix (from earlier in this phase) has been exercised starting from
an actual submission instead of a manually inserted row. With a second
applicant, submitted and approved as `designer`, then confirmed they
could still submit a fresh `embroidery` application afterward (the
pending-application block correctly only blocks while one is actually
pending, not permanently after their first application resolves) — and,
separately, confirmed the first applicant's stale `CUSTOMER`-role JWT
still correctly gets rejected with "already have a tailor account" after
approval, since that check reads the database, not the token. All test
users/applications/profiles deleted afterward, confirmed via
`git status` that no stray files were left behind.

**Not built yet:**
- No admin-frontend parity with Tailors (no Rental Shops tab, no
  suspend/reactivate for `RentalShopProfile` — `BusinessStatus.SUSPENDED`
  is defined and reachable in the enum, but nothing in `admin.service.ts`
  exposes it for rental shops the way `suspendTailor`/`reactivateTailor`
  do).
- No mobile UI (customer-side browsing/booking, or a shop-owner app or
  in-app screens) — this phase is backend-only so far.
- No payments integration on bookings — deposits/late fees are computed
  and stored but nothing charges a card; that's Phase 10.
- No rating-submission path — `ratingAvg`/`ratingCount` exist on
  `RentalShopProfile` but nothing writes to them yet (same situation
  `TailorProfile.ratingAvg` was already in before this phase).

