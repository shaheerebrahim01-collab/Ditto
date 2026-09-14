# App Store & Google Play — listing prep

Phase 15. Store copy and asset requirements only, prepared against what's
actually built (`docs/ROADMAP.md` Phases 4/5/7 for what each app does
today). Stops before anything needing a real Apple Developer Program or
Google Play Console enrollment — both cost real money and tie to a real
legal entity, so account creation itself is the credential wall, same
shape as every other phase's stopping point.

## Shared facts (both apps)

- **Developer/publisher name:** placeholder — whatever legal entity
  enrolls with Apple/Google. Not decided yet, not this document's call.
- **Firebase project:** `ditto-713d5` (existing, both apps already
  registered against it for Auth).
- **Support URL / marketing URL:** both stores require one; needs the
  real domain from Phase 11's stopping point (`API_DOMAIN`/`ADMIN_DOMAIN`
  presuppose a domain exists — a support page can be a simple static page
  on that same domain once it does).
- **Privacy policy:** required by both stores before submission, drafted
  below — needs to be hosted at a real, publicly reachable URL before
  either store will accept it (same domain dependency as the support URL).
- **Data safety / privacy "nutrition label" (Play Console's Data Safety
  form, Apple's App Privacy questionnaire):** both stores now require
  answering this in their respective consoles directly (not a document
  upload) — the answers, based on what this app actually collects, are
  listed under "What we collect" below so filling in either form is a
  transcription job, not a research one, once you're in the console.

## Design system already established (for whoever builds the actual icon)

`mobile/*/lib/core/theme.dart`: cream/beige surfaces (`#FBF7F1`), warm
brown as the primary action color (`#8A6244`), gold accent (`#C7A363`),
near-black ink text (`#2B2320`). Fraunces for headings, Plus Jakarta Sans
for body text (both Google Fonts, already wired in). No app icon artwork
exists yet — `web/icons/Icon-*.png` in both apps are still Flutter's
default template placeholders — so this is a real open task, not
something this document can complete: an actual icon design, distinct
enough between the two apps that a user with both installed can tell them
apart at a glance (the two apps otherwise share the same visual language
by design, per `docs/ARCHITECTURE.md`).

## Customer app

**Name:** Ditto — Custom Tailoring
**Subtitle / short description (Play's 80-char limit):** Bespoke suits,
rentals & styling, made to measure.

**Full description draft:**

> Ditto connects you with real tailors for custom-made suits and formal
> wear — no guessing at sizes, no generic off-the-rack fit.
>
> - **Design your garment.** Pick the suit, fabric, lapel and button
>   style, add a monogram — see your price before you order.
> - **Get measured right.** Request an in-person measurement visit, or
>   enter your own measurements and save them for every future order.
> - **Rent for the occasion.** Browse rental shops near you for
>   tuxedos and formal wear by the day.
> - **Track every order.** Follow your garment from confirmed through
>   fitting to delivery, and message your tailor directly along the way.
> - **AI styling suggestions.** Describe the occasion and get a
>   recommendation built from real, orderable combinations — never a
>   made-up style you can't actually buy.
>
> Sign in with Apple, Google, phone, or email.

(The AI-styling bullet describes `POST /styling/recommend` — Phase 8 —
which is built but returns a clean "not configured yet" response without
`ANTHROPIC_API_KEY`; drop that bullet from the live listing if the key
still isn't set by submission time, rather than advertise a feature that
doesn't actually respond.)

**Keywords (Apple, comma-separated, 100-char limit):** tailor, custom
suit, bespoke, tuxedo rental, made to measure, formal wear, menswear

**Category:** Shopping (primary), Lifestyle (secondary)

**Age rating:** 4+ / Everyone — no user-generated content visible to
other users beyond the tailor a customer is already transacting with (1:1
messaging, not public), no mature content.

## Tailor app

Covers both roles it actually serves client-side (`docs/ARCHITECTURE.md`
— `RENTAL_SHOP` role-branches inside this same app, not a separate
listing): tailors and rental-shop owners.

**Name:** Ditto for Business
**Subtitle:** Manage orders, rentals & your shop on Ditto.

**Full description draft:**

> The business side of Ditto, for tailors and rental shop owners.
>
> **For tailors:**
> - Manage incoming custom orders through every production stage,
>   confirmed to delivered.
> - Claim measurement-visit requests from customers near you and record
>   what your team measures.
> - Showcase your work in a portfolio your customers can browse.
> - Message customers directly about their order.
>
> **For rental shop owners:**
> - List and manage your rental inventory — pricing, deposits, photos.
> - Track bookings from reserved through pickup, return, and any late
>   fees.
> - See your shop's profile the same way customers see it.
>
> Requires an approved Ditto business account — apply for tailor,
> rental-shop, designer, or embroidery-specialist status from within the
> app.

**Keywords:** tailor business, rental shop, order management, tailoring
CRM, bespoke workflow

**Category:** Business (primary), Productivity (secondary)

**Age rating:** 4+ / Everyone — business tool, no consumer-facing content
concerns.

**Note for the actual submission:** this app is explicitly *not* for
customers — both stores' review guidelines expect that distinction to be
clear from the listing itself (name, description, and screenshots should
never show the customer-facing browse/order flow), since this is a
role-gated business tool, not a second storefront.

## What we collect (for the Data Safety / App Privacy forms)

Drawn directly from `backend/prisma/schema.prisma` and what each app
actually sends, not guessed:

- **Account info:** name, email and/or phone (via Firebase Auth — Apple,
  Google, phone, or email sign-in).
- **Location:** only ever a free-text address the customer types for a
  measurement-visit request (`MeasurementVisitRequest.location`) — never
  device/GPS location; nothing in either app requests location
  permissions today.
- **Body measurements:** stored against the customer's own account
  (`Measurement` model), used only to size their own orders.
- **Order/purchase history:** garment choices, prices, order stage.
- **Payment info:** handled by Stripe Connect (Phase 10) — Ditto's own
  database never stores card numbers, only a Stripe `PaymentIntent`
  reference and status.
- **Messages:** 1:1 messages between a customer and their tailor/rental
  shop, stored to support the in-app chat feature itself.
- **Photos:** tailor portfolio images and rental-item photos, uploaded by
  the business account that owns them (Phase 11's `AWS_S3_BUCKET`/
  `CLOUDINARY_URL` gap — not live yet, so nothing is actually uploaded
  until that credential exists; update this line once it does).

None of the above is sold or shared with third parties for advertising —
Stripe (payments) and Firebase (auth) are the only third parties data
passes through, both as processors acting on Ditto's behalf, not as
independent recipients.

## Privacy policy (draft — needs real hosting before submission)

```
Privacy Policy — Ditto

Last updated: [date of actual publication]

Ditto ("we", "us") operates the Ditto customer and business mobile
applications and the services they connect to.

Information we collect
- Account information you provide or that your sign-in provider (Apple,
  Google, or phone/email via Firebase Authentication) shares with us:
  name, email address, and/or phone number.
- Information you provide directly: body measurements, order details,
  messages sent to tailors or rental shops, and (for business accounts)
  portfolio or inventory photos.
- Payment information is collected and processed by Stripe, our payment
  processor; we do not store your card details ourselves.

How we use it
- To create and maintain your account and authenticate you.
- To process and fulfil orders, bookings, and measurement-visit requests.
- To enable messaging between you and the tailor or rental shop you're
  working with.
- To process payments via Stripe.

Sharing
We do not sell your personal information. We share it only with the
service providers who help us run Ditto (Firebase for authentication,
Stripe for payments), and only as needed for them to provide that
service to us.

Data retention
We retain your account and order data for as long as your account is
active, or as needed to comply with legal obligations.

Your rights
You can request access to, correction of, or deletion of your personal
data by contacting [support email/URL].

Contact
[support email/URL]
```

Fill in the bracketed placeholders and publish at a real URL before
either store submission — both consoles reject a listing with a
placeholder or unreachable privacy-policy link.

## Asset requirements (verify exact current pixel specs in each console
at submission time — both platforms have changed these before)

**App icon:**
- Apple: 1024×1024 PNG, no transparency, no pre-rounded corners (the
  store applies the mask).
- Google Play: 512×512 PNG (Play Store listing) plus an Android adaptive
  icon (separate foreground/background layers, already a distinct asset
  from the one Play Store listing icon).

**Screenshots** — both stores require at least one set sized for their
largest current required device class; exact required sizes/counts are
set by each console at submission time (Apple: currently organized by
display size, e.g. the largest current iPhone and iPad classes; Google
Play: minimum 2, recommended set covering phone and tablet). Plan for
capturing:
- Customer app: sign-in, Explore/tailor browse, garment Create flow,
  order tracking, a rental listing.
- Business app: dashboard, incoming orders, portfolio (tailor) or
  inventory (rental shop).

**Not capturable yet, and why:** real screenshots need a build running
against real data that looks presentable, not the placeholder/empty
states most screens are still in ahead of a full design pass (`docs/
ROADMAP.md`'s "Deferred" section already flags "a full design pass across
the customer app" as later-not-now) — and neither app has generated its
`ios/` platform folder yet (`flutter create`, noted as an open Phase 4/5
step needing a real Apple Developer team id once one exists). Revisit
once both are true.

## Submission checklist (stop here without the account)

1. Enroll in the Apple Developer Program and a Google Play Console
   developer account (real money, real legal-entity details — the actual
   credential wall this phase stops at).
2. Register both apps in App Store Connect / Play Console using the
   names/descriptions above.
3. Generate real app icons from the design system above.
4. Run `flutter create --platforms=ios` in both `mobile/*_app/` dirs
   (needs the real Apple Developer team id from step 1) to generate the
   missing `ios/` folders, then `flutterfire configure` for each
   (mirrors what Phase 5 already did for Android).
5. Capture real screenshots per the device-size requirements current at
   submission time.
6. Publish the privacy policy above at a real URL; fill in both stores'
   Data Safety/App Privacy questionnaires from "What we collect" above.
7. Submit for review.
