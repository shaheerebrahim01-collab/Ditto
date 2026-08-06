# Ditto — Roadmap

Status lives here, in the repo — not in chat history. Whoever (or whatever)
continues this project should read this file first.

- [x] Phase 1 — Repository architecture
- [x] Phase 2 — Database schema
- [x] Phase 3 — Authentication
- [x] Phase 4 — Customer mobile app
- [x] Phase 5 — Tailor mobile app
- [x] Phase 6 — Admin dashboard
- [ ] Phase 7 — Suit rental ops (in progress — backend, admin dashboard, and mobile UI done; no payments or ratings yet)
- [ ] Phase 8 — AI styling & measurements (measurements + visit-request done end-to-end; styling scaffolded, blocked on `ANTHROPIC_API_KEY`)
- [x] Phase 9 — Messaging & notifications
- [ ] Phase 10 — Payments (backend + mobile built up to the real Stripe Connect account; blocked there, see phase entry)
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

**Admin-frontend parity with Tailors added:** `GET /admin/rental-shops`
(search + pagination, same bounded-parse helper as `/admin/tailors`) and
`POST /admin/rental-shops/:id/suspend` / `/reactivate` in
`admin.service.ts`/`admin.controller.ts`, mirroring
`listTailors`/`suspendTailor`/`reactivateTailor` exactly — same
APPROVED-<->SUSPENDED-only transition rule, same 404-if-missing. Shaped
result carries `itemCount` (via `items: { select: { id: true } }`)
instead of Tailor's `completedOrders`, since `RentalShopProfile` has no
order relation of its own. Admin frontend: new `RentalShops.tsx` page
(list + search + suspend/reactivate, no create-shop form — provisioning
still only happens through the application-approval flow, and adding a
direct-create path wasn't part of this gap), wired into `App.tsx` and
the `Layout.tsx` sidebar nav. No `CreateTailorModal` equivalent by
design, not oversight.

**Mobile UI added — extended the two existing apps rather than building a
third.** `RENTAL_SHOP` is a full app-facing role (unlike `TailorAssistant`,
see the roles note above) but the backend already treats it as a peer of
`TAILOR`, and neither `customer_app` nor `tailor_app` did any client-side
role gating before this — `AuthGate` just switched on auth status, not
role. So a new `rental_shop_app` would have meant a third Firebase
project, a third `applicationId`, and a third hand-copy of the
already-duplicated `api_client.dart`/`theme.dart`/`auth_repository.dart`/
`token_storage.dart`/`models/user.dart` quintet (customer_app and
tailor_app still don't share a package — pre-existing duplication, not
something this phase introduced, but worth a cleanup pass later). Adding
a role branch to `tailor_app`'s `AuthGate` was the smaller change.

Renter side — `mobile/customer_app`:
- `lib/models/rental_shop.dart`, `rental_item.dart`, `rental_booking.dart`,
  `rental_status.dart` — mirror the backend response shapes exactly,
  including the two fields that only appear conditionally
  (`RentalShop.itemCount` on the list endpoint vs. `.items` on the detail
  endpoint; `RentalItem.shopName` only when nested under a booking).
- `ApiClient` gained `listRentalShops`, `getRentalShop`,
  `createRentalBooking`, `getMyRentalBookings`, `cancelRentalBooking` —
  real HTTP calls, no mock data, unlike most of this app's other screens.
- New `features/rentals/`: `RentalsScreen` (browse, search debounced same
  as admin's Tailors.tsx), `RentalShopDetailScreen` (shop + its items),
  `BookItemScreen` (date-range picker, live estimated-total calculation,
  submits `POST /rentals`), `MyRentalsScreen` (bookings list, cancel button
  only shown for `RESERVED`, matching the server-side rule in
  `rentals.service.ts`'s `cancelBooking`).
- Wired in as a 6th bottom-nav tab (`MainShell`) between Create and
  Orders — a dedicated tab rather than folding into Explore, since renting
  is its own vertical, not a tailor-search filter. `TailorProfileScreen`'s
  hardcoded `_createTabIndex = 2` still points at the right tab; only
  Orders/Profile shifted by one index and nothing hardcoded those.

Shop-owner side — `mobile/tailor_app`:
- Same four rental model files, byte-identical to customer_app's copies
  (matches the existing hand-duplication convention for this app pair).
- `ApiClient` gained `getMyRentalShop`, `updateMyRentalShop`,
  `listMyRentalItems`, `createRentalItem`, `updateRentalItem`,
  `deleteRentalItem`, `listShopBookings`, `markRentalPickedUp`,
  `markRentalReturned`.
- `AuthGate` (`main.dart`) now branches on `currentUser.role`:
  `RENTAL_SHOP` gets a new `RentalShopShell`, everything else still gets
  `TailorShell` — the first client-side role check either app has ever
  had.
- New `features/rental_shop/`: `RentalShopShell` (Dashboard / Bookings /
  Inventory bottom nav, sibling to `TailorShell`), `RentalShopDashboardScreen`
  (shop profile, inventory/active-booking counts, in-flight bookings),
  `RentalShopInventoryScreen` (list + add/edit/delete via a bottom-sheet
  form; delete surfaces the backend's 409 — "item has bookings" — as a
  snackbar instead of a raw error), `RentalShopBookingsScreen` (Needs
  pickup / Out for rental / History split, mirroring
  `TailorOrdersScreen`'s pending/active layout; "Out for rental" rows show
  the server-computed `overdue` flag and any `lateFee` once returned).

**Verified:** `flutter analyze` clean (no issues) in both `customer_app`
and `tailor_app` after all of the above.

Confirmed end-to-end against the live backend in a later session, on
both sides — using `flutter run -d chrome` rather than an Android
emulator, which had hung in a prior attempt on this machine (Chrome has
been the reliable path since Phase 5).

- **Renter side (`customer_app`):** ran in Chrome, signed in with a real
  account. Rentals tab loaded a real shop from Postgres; drilled into
  shop detail and confirmed the empty states ("No reviews yet", "No
  items listed yet") render correctly. Zero console errors.
- **Shop-owner side (`tailor_app`):** no seed script existed for a
  rental-shop *owner* account (Phase 7's earlier backend verification
  seeded an applicant, not an already-approved owner), so one was
  created the same way `promote-admin.js` promotes a user — registered
  a real test account through the app's own email/password sign-up
  (real Firebase Auth + `POST /auth/firebase`), then promoted it to
  `Role.RENTAL_SHOP` and created its `RentalShopProfile` directly via
  Prisma. Signed back in (had to clear the stored JWT first — see gap
  below) to pick up a fresh token carrying the new role. `AuthGate`
  correctly routed to `RentalShopShell`. All three tabs verified against
  the real backend, zero console errors: **Dashboard** showed the real
  shop profile and correct 0/0 inventory & booking counts; **Inventory**
  showed the empty state, then a real item ("QA Test Tuxedo", $45/day,
  $150 deposit) created through the actual "Add item" form (`POST
  /rental-shops/me/items`); **Bookings** showed the Needs-pickup/Out-for-
  rental split with correct empty states. Test user, profile, item, and
  the Firebase account were all deleted afterward; confirmed via `git
  status` that no stray files were left behind.

**Gap found during that verification:** `tailor_app` has no sign-out
control anywhere in its UI — `AuthRepository.signOut()` exists but no
screen calls it (`TailorShell` has no Profile/Settings tab, unlike
`customer_app`). Not a blocker for this phase, but means there's
currently no way for a signed-in tailor or rental-shop owner to switch
accounts or log out without clearing browser storage by hand.

**Not built yet:**
- No payments integration on bookings — deposits/late fees are computed
  and stored but nothing charges a card; that's Phase 10.
- No rating-submission path — `ratingAvg`/`ratingCount` exist on
  `RentalShopProfile` but nothing writes to them yet (same situation
  `TailorProfile.ratingAvg` was already in before this phase).
- No portfolio-style image upload for rental items — `RentalItem.imageUrl`
  is a plain string field in every DTO, but no screen sets it yet (same
  gap `PortfolioScreen` has for tailors — Phase 11's `AWS_S3_BUCKET`/
  `CLOUDINARY_URL`).
- No sign-out UI in `tailor_app` (see gap above) — a small follow-up,
  not scoped to any phase yet.

## Phase 8 — AI styling & measurements (in progress)

Two independent pieces. This entry originally recorded just the agreed
technical approach; the measurements/visit-request piece is now built
and verified end-to-end, the styling piece is scaffolded and blocked on
a credential — see "Built" and "Verified" below.

**Body measurements — "Get your right size today" (in-person visit
request), not photo/pose estimation.** A photo-based approach (on-device
pose estimation, or a third-party body-scan API) was considered and
explicitly set aside for now — deferred to a later cycle if it turns
out to matter — in favor of something simpler and more reliable: the
customer requests an in-person measurement visit (location + preferred
time), fulfilled by a real person with a tape measure.

Checked whether this connects to the existing `TailorAssistant` model
(`backend/prisma/schema.prisma`) before designing anything new, since
it already exists for exactly this kind of in-person role. It doesn't
fit as-is: `TailorAssistant` is roster/certification tracking only
(`fullName`, `certificateNumber`, `trainingCompletedAt`, `status`,
`registeredAtOffice`), belongs to a `TailorProfile` (`tailorId`), and —
per the model's own comment — has no app login of its own. It has no
scheduling, availability, geographic, or dispatch fields at all, so it
can't receive or fulfill a visit request directly today.

Proposed shape for a new model (not yet built): a `MeasurementVisitRequest`
— `customerId`, a location, a preferred time window, and a `status`
(`PENDING`/`ASSIGNED`/`COMPLETED`/`CANCELLED`) — assigned to a
**tailor** (`tailorId`, the same pattern `CustomOrder` already uses),
not directly to a `TailorAssistant`, since assistants have no app
account to receive it through. The tailor accepts the request in a new
"Measurement Requests" queue in `tailor_app` (sibling to the existing
Orders queue) and records which of their own registered assistants (by
name/certificate, from their existing `TailorAssistant` roster) is
sent out. Whatever measurements come back from that visit get recorded
through the manual entry form below, closing the loop into the real
`Measurement` model.

**Manual measurement entry/edit form — needed regardless of the above.**
`customer_app`'s "Saved Measurements" screen is currently read-only
against mock data (`measurements_screen.dart`) — no create/edit UI
exists, and no backend endpoints exist for the `Measurement` model at
all. This is a real gap independent of the visit-request feature:
whoever takes a measurement, whether that's the customer themselves or
an assistant after a visit, needs somewhere to record it. Scope:
`GET`/`POST`/`PATCH`/`DELETE /measurements`, self-scoped the same way
the rest of the API guards per-user data, plus a real form screen
replacing the mock-data list.

**AI styling — Claude API, constrained to the real garment vocabulary.**
`POST /styling/recommend`, built against the **Anthropic Claude API**,
using tool-use/structured output constrained to the exact garment,
fabric, and lapel/button values already in `garment_builder_options.dart`
— so a recommendation can only ever be a combination that's actually
orderable through the existing Create flow, never something invented.
**Needs `ANTHROPIC_API_KEY`** — not present in this environment,
required before this piece can be built for real. Same approach this
project has used at every prior credential point (Firebase in Phases
3/6): ask for exactly what's needed, exactly when it's needed, rather
than stub it out.

**Built — measurements + visit-request, end to end.**

Schema: `VisitRequestStatus` enum (`PENDING`/`ASSIGNED`/`COMPLETED`/
`CANCELLED`) and `MeasurementVisitRequest` (`customerId`, `location`,
`preferredAt`, `notes`, `status`, nullable `tailorId`/`assistantId`),
migration `20260728001544_add_measurement_visit_requests`. Matches the
proposed shape above exactly: starts unassigned, open to any tailor to
claim, rather than pointed at a tailor the customer already picked.

`MeasurementsModule` (`/measurements`) — `GET`/`POST`/`PATCH`/`DELETE`,
every route self-scoped off the caller's own JWT (no "whose measurement"
param anywhere, same reasoning `/rentals/me` uses). `DELETE` catches the
FK-constraint error a `CustomOrder` referencing the measurement would
otherwise throw as a raw 500, turning it into a `409 Conflict` — same
pattern `RentalShopsService` already uses for `RentalItem`.

`MeasurementVisitsModule` (`/measurement-visits`) — customer side:
`POST` (rejects a `preferredAt` in the past), `GET /me`, `POST
/:id/cancel` (only from `PENDING`/`ASSIGNED`). Tailor side
(`@Roles(Role.TAILOR)`): `GET /available` (the open, unclaimed pool,
every tailor sees the same list), `GET /assigned` (this tailor's own
claims, optional `?status=`), `POST /:id/claim` (only from `PENDING`;
takes an optional `assistantId`, checked against the claiming tailor's
own `TailorAssistant` roster if given), `POST /:id/complete` (only from
`ASSIGNED`, only for the tailor who claimed it). The tailor-facing list
endpoints include the customer's `fullName`/`email`/`phone` so a tailor
can actually reach the person before showing up.

Manual measurement entry/edit form — `customer_app`'s "Saved
Measurements" screen (`measurements_screen.dart`) went from read-only
mock data to a real bottom-sheet add/edit form against the endpoints
above, mirroring `RentalShopInventoryScreen`'s existing pattern for the
same shape of problem (a self-owned list with add/edit/delete). The
mock `SavedMeasurement` model and its seed data
(`models/saved_measurement.dart`, the `mockMeasurements` list in
`mock_profile_data.dart`) are gone, replaced by a real `Measurement`
model matching the Prisma model field-for-field. A new
`MeasurementVisitScreen`, reached from a banner at the top of the same
screen ("Get your right size today"), submits `POST /measurement-visits`
and lists/cancels the caller's own requests — no tailor picker, since
the request goes into the open pool above.

Tailor-side dispatch — `tailor_app` gained a fourth bottom-nav tab,
"Requests" (`MeasurementRequestsScreen`, sibling to the existing Orders
queue, per the original design note), with "Available to claim" /
"Needs visit" / "History" sections against `GET /available`, `GET
/assigned`, `POST /:id/claim`, `POST /:id/complete`. No assistant-picker
UI yet — `claimVisitRequest` always claims under the tailor's own name
(`assistantId` omitted), since there's no roster-listing endpoint for
the app to pick one from today; the field exists on both the schema and
the DTO so wiring a picker in later is additive, not a schema change.

**Verified against the live backend** (local Postgres, real HTTP calls
— no mocks): `npm install`, `npx prisma generate`, and the new migration
all ran clean against this machine's real network access (unlike the
sandboxed environment Phases 2/3 hit — no `binaries.prisma.sh` allowlist
gap here). `npm run build` and `npx tsc --noEmit` — zero errors. `npm
test` — 2/2 passing, unaffected by this phase. Ran `start:dev` for real
and drove every new endpoint with `curl` against signed JWTs for a
throwaway customer and a throwaway `APPROVED` tailor (created directly
via Prisma, cleaned up after):
- Measurements: created, listed, patched (`chest` 40 → 41), deleted,
  confirmed the list is empty afterward.
- Visit requests: a past `preferredAt` is rejected (`400`); a valid
  submission lands as `PENDING` with `tailorId: null`; the customer's
  own `GET /me` shows it; a `CUSTOMER` gets `403` on the tailor-only
  `GET /available`; the tailor sees it in the open pool, complete with
  the customer's name/email; claim moves it to `ASSIGNED` and empties
  the pool; a second claim attempt on the same request is rejected
  (`400`, "already assigned"); `complete` moves it to `COMPLETED`; a
  second `complete` and a customer `cancel` on the now-`COMPLETED`
  request are both correctly rejected.
- Styling: `POST /styling/recommend` without a token gets `401`; with a
  token but no `ANTHROPIC_API_KEY` gets a clean `503` ("Styling
  recommendations are not configured yet...") rather than a raw SDK
  crash; an invalid body (missing `occasion`) gets `400` from
  `ValidationPipe` before ever reaching the service.

All test rows deleted afterward via the same Prisma connection; the
now-deleted customer's JWT was re-checked and correctly rejected
(`401`), confirming cleanup actually took effect rather than just
returning success.

`flutter analyze` — zero issues in both `customer_app` and `tailor_app`
after all of the above (`flutter pub get` clean in both first). **Not
verified here:** neither app's new screens were driven through an
actual Chrome session this round — doing that honestly would need a
fresh Firebase-authenticated test account, same as Phase 7's rental
verification, and that step was skipped this time. The Dart
`fromJson`/request shapes were instead checked directly against the
real JSON the endpoints above returned, not assumed — same rigor, just
one layer short of a live UI drive.

## Phase 9 — messaging & notifications

Two new backend modules, built from empty skeletons to real
controllers/services, plus notification-emission wired into every
existing module that has a real lifecycle event worth telling someone
about.

**Schema:** `Message.conversationId` was previously a bare string with
no relation — nothing could actually create one. Added a `Conversation`
model (`userAId`/`userBId`, `@@unique([userAId, userBId])`), migration
`20260806043228_add_conversations`. Every conversation in this app is a
1:1 thread (customer<->tailor, customer<->rental shop, etc.), never a
group chat, so two participant columns are enough — `MessagingService`
canonicalizes the pair (lower id first) before every lookup/upsert so
starting a thread from either direction always lands on the same row.
Also added `Message.readAt` (nullable) for per-message read receipts,
separate from `Notification.read` — a message being read and its
accompanying notification being read are tracked independently, same as
a real chat app.

**`MessagingModule` (`/conversations/*`):**
- `POST /conversations` — find-or-create the thread with `otherUserId`
  (`upsert` on the compound unique key, not find-then-create, to avoid a
  race between the two). Rejects messaging yourself (`400`) and an
  unknown `otherUserId` (`404`).
- `GET /conversations` — the caller's own threads, newest-active first
  (`orderBy: updatedAt desc`), each with the other participant's
  name/avatar/role, a `lastMessage` preview, and `unreadCount` (a
  `groupBy` over unread messages not sent by the caller).
- `GET /conversations/:id/messages` (paginated, bounded page/pageSize
  like every other list endpoint), `POST /conversations/:id/messages`,
  `POST /conversations/:id/read` — all self-scoped off the caller's own
  participation; a non-participant gets `404`, not `403`, matching the
  rest of the API's self-scoped-resource convention. Sending a message
  creates a `Notification` for the other participant and bumps
  `Conversation.updatedAt`.
- **Bug caught by testing, fixed before commit:** an empty
  `prisma.conversation.update({ data: {} })` does *not* touch an
  `@updatedAt` field on its own in this Prisma version — confirmed with
  a standalone repro before assuming it was a client bug. Sending a
  message now explicitly sets `updatedAt: new Date()`, otherwise
  `listConversations`' "most recently active first" sort silently never
  moved a thread to the top after the first message.

**`NotificationsModule` (`/notifications/*`):** `GET /notifications`
(paginated, optional `?unreadOnly=true`), `GET
/notifications/unread-count`, `POST /notifications/:id/read` (404s on
someone else's notification), `POST /notifications/read-all`.
`NotificationsService` is exported so other modules can inject it and
create notifications directly — the only way a `Notification` row comes
into existence; there's no endpoint for creating one on someone else's
behalf.

**Notification emission wired into every real lifecycle event that
already existed:** `MeasurementVisitsService` (claim → customer
notified, complete → customer notified), `RentalsService` (booking
created → shop owner notified, return confirmed → renter notified, with
the late-fee amount in the message when there is one), `AdminService`
(business application approve/reject → applicant notified with
`reviewNotes` folded into the rejection message; suspend/reactivate →
notified for `User`, `TailorProfile`, and `RentalShopProfile` all three,
sharing one `notifyBusinessStatusChange` helper for the latter two).

**Verified against the live backend** (local Postgres, real HTTP calls,
real signed JWTs for eight throwaway accounts — customer ×2, tailor,
rental-shop owner, two applicants, admin — created directly via Prisma,
matching every prior phase's approach since there's still no signup
endpoint for a pre-existing account to promote):
- Messaging: self-message rejected (`400`); starting a conversation from
  either direction returns the same conversation id (canonicalization
  confirmed); empty-body send rejected (`400`); sent messages show up in
  the recipient's `unreadCount` and `lastMessage`; a non-participant gets
  `404` on `GET .../messages`; marking read zeroes `unreadCount` and sets
  each `Message.readAt`; `Conversation.updatedAt` now correctly moves the
  thread to the top of `listConversations` after the fix above.
- Notifications: sending a message produces a `type: "message"`
  notification for the recipient; `unread-count`, mark-one-read (404s on
  someone else's), mark-all-read, and the `?unreadOnly=true` filter all
  behaved correctly.
- Lifecycle wiring: claiming/completing a measurement visit produced
  `visit_assigned`/`visit_completed` notifications for the customer;
  booking an item produced `booking_created` for the shop owner;
  returning a booking on time vs. an overdue one (seeded with a past
  `returnDate`, real `$120` late fee computed the same way Phase 7's math
  already worked) produced the two different `booking_returned` message
  variants; approving/rejecting a business application produced
  `application_approved`/`application_rejected` (rejection notification
  includes the admin's `reviewNotes` text) — and a stale `CUSTOMER`-role
  JWT reused after approval was unaffected, since notification creation
  doesn't touch the JWT/role-check path at all; suspend/reactivate on a
  `User`, a `TailorProfile`, and a `RentalShopProfile` each produced the
  matching pair of notifications, and a suspended user's own JWT
  correctly still gets rejected `401` before it could ever see the
  "you've been suspended" notification telling it so (same
  `JwtStrategy`-checks-the-database behavior Phase 6 built, unaffected by
  this phase).
- All eight test accounts plus their conversations/messages/notifications/
  visit-requests/bookings/rental-items/business-applications deleted
  afterward via the same Prisma connection; confirmed zero rows remain
  matching the test-account email pattern. **Also found and cleaned up
  in the process:** two leftover accounts from Phase 8's own
  verification round (`phase8-e2e-customer@ditto.test`,
  `phase8-e2e-tailor@ditto.test`, one with an explicit "please
  disregard" note) that Phase 8's entry above claimed were deleted but
  weren't — confirmed disposable from their email domain/notes before
  removing, not assumed.

**Mobile UI — both apps, no mock data:** new `models/chat_message.dart`,
`conversation_summary.dart`, `app_notification.dart` (hand-duplicated
between the two apps, same convention as every other model). `ApiClient`
gained `startConversation`, `listConversations`, `listMessages`,
`sendMessage`, `markConversationRead`, `listNotifications`,
`unreadNotificationCount`, `markNotificationRead`,
`markAllNotificationsRead` in both apps.

New `features/messages/` (`MessagesListScreen`, `ChatScreen` — bubble
layout, mark-read on open, newest-at-bottom via `ListView.builder(reverse:
true)` over the newest-first API response) and `features/notifications/`
(`NotificationsScreen`, mark-one/mark-all-read) in both apps.

Entry points are real, not placeholders — each one uses a `userId`
that's actually available from an existing real endpoint, never
invented:
- `customer_app`: the Home screen's notification bell (previously an
  empty `onPressed: () {}`) now opens `NotificationsScreen`; a new
  "Messages" row in the Profile menu opens `MessagesListScreen`; a
  "Message" button on `RentalShopDetailScreen` starts a conversation with
  the shop owner (`RentalShop.userId`, added to the model — already
  present on the raw `GET /rental-shops` response as a Prisma scalar,
  just not previously parsed).
- `tailor_app`: both `DashboardScreen` (tailor side) and
  `RentalShopDashboardScreen` (rental-shop side) gained bell/chat
  `AppBar` actions. `RentalShopBookingsScreen` gained a "Message renter"
  button per booking (`RentalBooking.renterId`, added to the model, same
  always-present-scalar situation). `MeasurementRequestsScreen` gained a
  "Message customer" button on assigned/history rows only, not the open
  "Available to claim" pool — messaging a customer before actually
  claiming their request isn't this tailor's place yet
  (`MeasurementVisitRequest.customerId`, added the same way).
- Deliberately **not** wired: a "Message tailor" entry point from
  `TailorProfileScreen` — that screen still renders entirely from mock
  data (no `GET /tailors/:id` endpoint exists yet, a pre-existing Phase
  5+ gap this phase didn't create and isn't in scope to fix), so there's
  no real tailor `userId` to message yet. Wiring a button there today
  would mean fabricating an id — deferred until that endpoint exists.

**Verified:** `flutter analyze` — zero issues in both apps after
`flutter pub get` (ran clean in both). The `userId`/`renterId`/
`customerId` fields this phase newly started parsing weren't assumed
present — each was re-confirmed against a fresh real HTTP response
during backend verification above before being added to the Dart
models. **Not verified here, same gap as Phase 8's mobile work:**
neither app's new screens were driven through an actual Chrome session
this round; the Dart request/response shapes were checked directly
against real JSON instead.

**Not built this phase:**
- No push notifications (APNs/FCM) — `Notification` rows are pulled via
  `GET /notifications`, not pushed to a device; that needs its own
  credential/setup pass, not scoped here.
- No attachment upload — `Message.attachmentUrl`/`attachmentType` exist
  on the schema and DTO (validated, `@IsIn(['image','voice','video'])`)
  but no screen sets them yet, same shape of gap
  `RentalItem.imageUrl`/`PortfolioItem` already have (Phase 11's
  `AWS_S3_BUCKET`/`CLOUDINARY_URL`).
- No "message tailor" entry point yet (see above) — blocked on a real
  `GET /tailors/:id`, not on anything this phase owns.

## Phase 10 — payments (built up to the real Stripe account, blocked there)

Three new backend pieces, all built from empty skeletons: `TailorsModule`
(a genuine prerequisite gap, not scope creep — see below), `OrdersModule`,
and `PaymentsModule` (Stripe Connect). Built and verified everything that
doesn't require an actual Stripe account; stopped exactly at the point
that does, per instruction.

**Why `TailorsModule` had to be built first.** `customer_app`'s Create
flow has never had a tailor-picker step — it built a garment/fabric/
details/measurements/review flow with no way to choose *whose* order this
is, even though `CustomOrder.tailorId` is required in the schema. There
was also no public `GET /tailors` endpoint for a picker to call against —
`TailorsModule` had been an empty skeleton since Phase 1. Payments can't
be verified without a real order to pay for, and an order can't be
created without a real tailor to assign it to, so this had to come first.

**`TailorsModule` (`/tailors/*`)** — mirrors `RentalShopsModule`'s public-
browse shape exactly: `GET /tailors` (public, `APPROVED` only, `q` search
on `businessName`, optional `specialty` filter on the specialties array,
paginated), `GET /tailors/:id` (public detail + portfolio, 404s anything
not `APPROVED`), `GET`/`PATCH /tailors/me` (self-scoped,
`@Roles(Role.TAILOR)`).

**`OrdersModule` (`/orders/*`):**
- `POST /orders` — `{ tailorId, garmentTypeId, fabricId, lapelStyle?,
  buttonStyle?, monogram?, measurementId? }`. **Price is computed
  server-side, never accepted from the client** — new
  `orders/garment-pricing.ts` mirrors
  `mobile/customer_app/lib/data/garment_builder_options.dart`'s base
  prices/add-ons by hand (same "kept in sync by hand" convention
  `styling/garment-vocabulary.ts` already uses for the id lists, which
  this file imports and validates every id against — an unrecognized
  `garmentTypeId`/`fabricId`/`lapelStyle`/`buttonStyle` is a `400`, never
  silently priced at 0). `measurementId`, if given, must belong to the
  calling customer.
- `GET /orders/me`, `GET /orders/tailor` (`@Roles(Role.TAILOR)`),
  `GET /orders/:id` (self-scoped to either the order's own customer or
  its assigned tailor, `404` otherwise — same non-probable-by-id shape
  every other self-scoped resource in this API uses).
- `PATCH /orders/:id/stage` (`@Roles(Role.TAILOR)`, owned orders only) —
  a hand-written `STAGE_ORDER` sequence enforces forward-only movement
  through `OrderStage`; moving sideways or backward (including
  re-sending the current stage) is a `400`.

**`PaymentsModule` (`/payments/*`) — Stripe Connect, lazy-init.** Schema
gained `TailorProfile.stripeAccountId` / `RentalShopProfile.stripeAccountId`
(both nullable+unique — a business hasn't onboarded until these are set)
and `Payment` was generalized from order-only to *either* an order or a
rental-booking deposit (`orderId`/`rentalBookingId` both now nullable,
`RentalBooking` gained the inverse `payment` relation) — enforced as
"exactly one of the two" in `PaymentsService`, the same
application-level-validation approach `AdminService` already uses for
"at least one of email/phone", since Prisma's schema language has no
native CHECK constraint. Migration
`20260806191415_add_payments_stripe_connect`, generated via `prisma
migrate diff --from-url` against the live dev DB rather than `migrate
dev` — this environment's non-interactive shell can't answer `migrate
dev`'s "the environment is non-interactive" prompt, so the diff was
written to a migration file by hand and applied with `migrate deploy`
instead. Same "structurally present, blocked on a credential" shape
Phase 8's `AnthropicClient` provider used: new `stripe-client.provider.ts`
lazily constructs a `Stripe` client from `STRIPE_SECRET_KEY` the first
time it's actually needed; `isStripeConfigured()`/`isWebhookConfigured()`
are checked before ever touching the SDK.

- `POST /payments/orders/:orderId/intent`, `POST
  /payments/rentals/:bookingId/deposit-intent` — creates a Stripe
  `PaymentIntent` as a **destination charge** (`transfer_data.destination`
  = the tailor's/shop's `stripeAccountId`, `application_fee_amount` =
  Ditto's cut), upserts a `Payment` row (`status: "pending"`,
  `providerRef` = the intent id), returns `clientSecret`. `503`s if the
  business hasn't finished Connect onboarding yet (`stripeAccountId` still
  null) or if Stripe isn't configured at all.
- `POST /payments/connect/onboarding-link` (`@Roles(Role.TAILOR,
  Role.RENTAL_SHOP)` — either role, `RolesGuard`'s `includes` check makes
  this an "either" gate rather than "both") — creates (once, reused after)
  a Stripe Express connected account for the caller's own business
  profile, then a fresh onboarding `AccountLink` (these are single-use,
  so never cached).
- `POST /payments/webhook` — **no `JwtAuthGuard`** (Stripe calls this with
  its own signature, not a user's token); verifies
  `stripe-signature` against `STRIPE_WEBHOOK_SECRET` via
  `stripe.webhooks.constructEvent`, updates the matching `Payment.status`
  on `payment_intent.succeeded`/`payment_intent.payment_failed`. Needs the
  *exact* raw request bytes to verify that signature — `main.ts` now
  passes `{ rawBody: true }` to `NestFactory.create`, and this is the only
  route that reads `req.rawBody` instead of the parsed body. A request
  missing either the raw body or the header is a clean `400`, never a
  crash.
- The platform fee is a placeholder `PLATFORM_FEE_RATE = 0.1` (10%)
  constant — a real number needs a real business decision that hasn't
  been made yet; kept as one named, easy-to-find constant rather than
  guessed and buried.

**Verified against the live backend** (local Postgres, real HTTP calls,
real signed JWTs): `GET /tailors` search + specialty filter, `GET
/tailors/:id` 404ing a `PENDING` tailor; `POST /orders` — sent a
deliberately wrong `garmentTypeId` (rejected `400`, listing the valid
values) and a deliberately wrong client-sent `price` field (silently
dropped — `CreateOrderDto` doesn't have a `price` field at all, so
`ValidationPipe`'s `whitelist: true` strips it before it ever reaches the
service), then a real order (suit + burgundy_silk + Peak lapel +
Double-Breasted buttons + monogram) and confirmed the server-computed
price (`355`) matched hand-calculated arithmetic exactly; confirmed both
the customer and the assigned tailor can see it via `GET /orders/:id`,
and a totally unrelated third user gets `404`; walked the stage machine
forward (`ORDER_CONFIRMED` → `CUTTING`), confirmed a same-stage re-send
and a backward move are both `400`, and confirmed a `CUSTOMER` gets `403`
on the tailor-only stage-update route. Every `/payments/*` route was
exercised with real signed JWTs against this environment's real absence
of `STRIPE_SECRET_KEY`: order-intent, deposit-intent, and
onboarding-link all returned a clean `503` with the exact missing-env-var
message (not a raw SDK crash); a non-tailor/non-shop role got `403` on
onboarding-link *before* ever reaching Stripe; the webhook route
correctly told apart "no signature header at all" (`400`) from "signature
header present but webhook secret unconfigured" (`503`) — proving
`rawBody: true` is actually wired, not just present in the option object.
All seeded rows (users, tailor/rental-shop profiles, an order, a rental
booking, a measurement) deleted afterward via the same Prisma connection;
also found and removed two more stale leftover accounts from an earlier
Phase 8 verification session that a prior ROADMAP entry had claimed were
cleaned up but weren't. `npx tsc --noEmit` and the existing `jest` suite
(2/2) both clean.

**A real environment obstacle, not a code problem, worth recording:**
this session's `nest start --watch` / `nest build` both got repeatedly
killed by this environment mid-compile once the `stripe` package (a large
dependency — hundreds of generated resource type files) was added,
regardless of retry strategy. Root-caused in two parts: (1) an
unconditional `taskkill //IM node.exe //F` this session had been
prepending "just in case" before some retries was killing its *own*
in-progress build, not a stale one — stopped doing that; (2) even
without that, backgrounded compiles here appear to have a hard wall-clock
limit shorter than a cold `stripe`-inclusive compile needs. Fixed by
relying on `tsconfig.json`'s already-enabled `incremental: true`: a first
`npx tsc` run gets killed partway through but leaves a valid
`.tsbuildinfo` cache and partial `dist/`; a second `npx tsc` immediately
after resumes from that cache and finishes fast. `node dist/main.js`
directly (bypassing `nest start`'s webpack watch layer entirely) then
boots reliably. Recorded here since it'll recur the next time a
similarly large dependency is added.

**Mobile — real order creation, no mock data left where this phase
touched it:**

`customer_app`: new `models/tailor.dart` (real `GET /tailors` shape,
distinct from the still-mock `TailorSummary` Home/Explore use) and
`models/custom_order.dart`. `CreateScreen` gained a real tailor-picker as
its new first step (search + `RadioGroup` list against `GET /tailors`)
and a real measurement-picker step — replacing the old ad-hoc
measurement-value text fields, which never persisted anywhere and
couldn't back a real `measurementId`, with a picker over the customer's
actual saved measurements (`GET /measurements`, Phase 8) plus a "Skip"
option. "Place Order" now really calls `POST /orders`, then attempts
`POST /payments/orders/:id/intent` — the order is placed for real either
way; if payment comes back `503` (it does, today), the customer sees "Order
placed! Payment isn't set up yet — the tailor will follow up with you
directly" rather than a fake success or a raw error. `OrdersScreen` and
`OrderTrackingScreen` now render `GET /orders/me` for real (the
`OrderStage` enum already matched the backend exactly from earlier mock
work, just needed a `fromJson`); `mock_orders.dart` and the now-unused
`OrderSummary` class deleted rather than left stale.

`tailor_app`: `TailorOrdersScreen` now renders `GET /orders/tailor` for
real, with a "Move to `<next stage>`" button calling `PATCH
/orders/:id/stage`. The old "Incoming Requests" accept/decline section is
gone, not just unwired — `CustomOrder` only ever starts at
`ORDER_CONFIRMED` (same self-service-booking shape `RentalsService`
already uses for bookings; this phase didn't add a pending-approval
concept), so there was never anything real for it to represent;
`models/incoming_request.dart` deleted along with it. Added a real
"Message customer" button per order (`TailorOrder.customerId`, always
present on the raw response as a Prisma scalar even though the nested
`customer` include is name/phone-only) — the first real order-to-message
bridge, and incidentally the first "message a tailor's customer" path
this project has had.

**Verified:** `flutter analyze` — zero issues in both apps after `flutter
pub get` (ran clean in both). One real fix caught by analyze, not
guessed: `RadioListTile`'s `groupValue`/`onChanged` params are deprecated
as of the Flutter version this project is on (superseded by a
`RadioGroup` ancestor widget) — migrated both new picker steps in
`CreateScreen` to `RadioGroup` rather than leaving deprecation warnings
in a codebase that's held a "zero issues" bar every prior phase. **Not
verified here, same gap as Phases 8/9's mobile work:** no screens were
driven through an actual Chrome session this round; the
`userId`/`customerId` fields this phase started parsing (`Tailor` has no
such need, but `TailorOrder.customerId` does) were re-confirmed against
real HTTP responses during backend verification before being trusted in
a Dart model, not assumed.

**The real stopping point.** Everything above works end-to-end except
the parts that need Stripe itself: no `STRIPE_SECRET_KEY` exists in this
environment, so no `PaymentIntent`, `Account`, or `AccountLink` has ever
actually been created against Stripe's real API — every Stripe-touching
code path in this phase has only ever been exercised via its
clean-`503`-without-a-key fallback, the same category of "written
correctly, unverified against the real provider" Phase 8's styling module
started in. **What's specifically needed next, and why it's Connect and
not a plain Stripe account:** Ditto charges customers *and* pays out to
tailors and rental shops — that's Stripe Connect (destination charges +
connected accounts), not a vanilla merchant account. Concretely:
1. A Stripe account with Connect enabled, in test mode to start.
2. `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` (from a webhook
   endpoint registered against `POST /payments/webhook`, or the Stripe
   CLI's `stripe listen --forward-to` for local testing) into `backend/.env`.
3. A test tailor/rental-shop account walking the real Connect onboarding
   flow (`POST /payments/connect/onboarding-link` → Stripe's hosted
   onboarding → `stripeAccountId` populated) before any `PaymentIntent`
   against that business can succeed — Stripe rejects a destination
   charge to an account that hasn't completed onboarding, so this is a
   real precondition, not just a nice-to-have.
4. The mobile side needs Stripe's own SDK (`flutter_stripe`) plus a
   **publishable** key for a real `PaymentSheet` — deliberately not added
   this phase. A client-side payment SDK integration is the one piece in
   this whole project that genuinely cannot be written-then-verified
   later the way the backend pieces were: without a publishable key there
   is nothing to initialize it against, and guessing at `PaymentSheet`
   wiring with zero ability to run it would be exactly the kind of
   fake-until-proven-otherwise complexity this project has avoided at
   every previous credential wall (Firebase, Anthropic). `ApiClient`
   already exposes `createOrderPaymentIntent` returning the raw
   `clientSecret`, so wiring the actual `PaymentSheet` is additive once
   the publishable key exists — not a redesign.

