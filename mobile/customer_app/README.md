# Ditto — customer app

Flutter app for customers. Talks to the NestJS backend in `../../backend`
(`POST /auth/firebase`, `GET /users/me` so far — see `docs/ROADMAP.md` at
the repo root).

## What's here

`lib/` is hand-written, real Dart — not scaffolded output:

- `core/env.dart` — backend base URL (override with `--dart-define=API_BASE_URL=...`)
- `core/token_storage.dart` — secure storage for *our* JWT
- `core/api_client.dart` — `loginWithFirebase()`, `getMe()`
- `core/auth_repository.dart` — Firebase sign-in (Apple/Google/Phone/Email) →
  exchanges the Firebase ID token for our JWT → stores it. This is the piece
  that matters: everything after sign-in only ever talks to our backend.
- `features/auth/` — login screen, phone OTP screen
- `features/home/` — profile screen, first screen that calls `GET /users/me`
- `models/user.dart` — mirrors the Prisma `User` model's JSON shape

## What's NOT here yet, and why

This sandbox has no Flutter SDK installed, so unlike the backend
(`npm install` / `npm run build` actually ran), none of this has been run
through `flutter pub get`, `flutter analyze`, `flutter test`, or a build.
Two things are still missing before it will actually run, and both need
tooling this environment doesn't have:

**1. Platform folders (`android/`, `ios/`).** These are normally generated
by the Flutter CLI, not hand-written (especially the iOS Xcode project —
hand-authoring `project.pbxproj` is not something to fake). Run this once,
in a real Flutter environment, from this directory:

```bash
flutter create --org com.ditto.app --project-name customer_app --platforms=android,ios .
```

`flutter create` on an existing project only fills in the platform folders
and merges `pubspec.yaml` — it will not overwrite `lib/`.

**2. Firebase platform config.** Same real-project dependency as the
backend's `FIREBASE_PROJECT_ID` / `FIREBASE_CLIENT_EMAIL` /
`FIREBASE_PRIVATE_KEY` in Phase 3 — this app needs to point at that *same*
Firebase project so a token it mints is one the backend can verify. Once
the project exists:

```bash
dart pub global activate flutterfire_cli
flutterfire configure   # generates lib/firebase_options.dart, google-services.json, GoogleService-Info.plist
```

Then update `main.dart`'s `Firebase.initializeApp()` call to pass
`options: DefaultFirebaseOptions.currentPlatform` (from the generated
`firebase_options.dart`).

Also enable, in the Firebase console: Google, Apple, Phone, and
Email/Password sign-in providers — `auth_repository.dart` assumes all four
are on.

## Running it (once the above is done)

```bash
cd backend && npm run start:dev   # in one terminal
cd mobile/customer_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

## Verified here

Nothing that requires the Flutter SDK. What *is* checked: the Dart source
matches the backend's actual contracts —
`POST /auth/firebase` request/response shape
(`backend/src/modules/auth/auth.controller.ts`,
`dto/firebase-login.dto.ts`) and `GET /users/me`'s response
(`backend/src/modules/users/users.controller.ts`, the Prisma `User` model)
were read directly from source, not assumed.
