# NutriVision | Sufra (سفرة)

An Arabic-first nutrition app built with Flutter and Firebase. It helps people plan meals, log what they eat, track water and weight, follow a calorie plan, and get guidance from a built-in coach. The interface is right-to-left first and also ships in English, with light and dark themes.

> **Status:** Milestone 1 implementation. Analyzer clean, automated tests for logic, screens, responsive layouts and overlays. Not yet exercised on a store build; see [docs/UI_FIXES_20261126.md](docs/UI_FIXES_20261126.md) for what is verified and what still needs a real device.

The original NutriVision planning document is kept in [docs/nutrivision-original/README.md](docs/nutrivision-original/README.md). The first prototype (auth screens) remains in this repository's history on `main`.

## Features

- Onboarding, email and Google sign-in, password reset with a 6-digit emailed code (entered in separate boxes)
- Daily diary, meal logging by search, barcode, voice and photo
- Calorie and macro plan, weekly meal planner, shopping list, Ramadan planner
- Progress: weight, water, reports with PDF export, achievements
- Coach: chat, food calculator and recipe help
- Favorites, recipes, healthier alternatives, reminders and notifications
- Responsive layouts for phone, tablet and desktop; system back navigation; reduced-motion support

## Architecture

- **Client:** Flutter, feature-first folders (`domain / data / presentation`), `Cubit` state management, `go_router` with an auth-aware redirect, ARB localisation (Arabic and English).
- **Data:** Firebase Auth, Cloud Firestore with per-user security rules, Firebase Messaging. Local, offline-first storage for reminders, caches and a protected progress ledger.
- **AI features:** food photo analysis and the coach run behind small Cloudflare Workers, so model access stays on the server. Every request carries the user's Firebase ID token and is rate limited per user.
- **Security:** no credentials are stored by the app, HTTPS only, secrets live as Worker secrets and are never committed.

```
lib/           app entry, core, data, features, l10n, services
assets/        images, fonts, bundled food and recipe data
backend/       Cloudflare Workers (reset-code, health-coach, food-vision, progression)
design/        original HTML design reference
docs/          architecture notes, credits, signing note, UI fixes, original NutriVision plan
test/          unit, widget, golden and responsive tests
firestore.rules, storage.rules, firestore.indexes.json
```

## Getting started

Requirements: Flutter 3.35.7 (Dart 3.9.2).

```sh
flutter pub get
flutter analyze
flutter test test/core        # the full suite is large; run folders separately on small machines
```

### Configure Firebase (required to run)

Firebase settings are not committed.

1. Create a Firebase project and enable Email/Password and Google sign-in.
2. Run `flutterfire configure` to generate `lib/firebase_options.dart`.
3. For Android, place your `google-services.json` in `android/app/` and register your signing SHA-1 (see [docs/ANDROID_SIGNING_NOTE.md](docs/ANDROID_SIGNING_NOTE.md)).
4. Optional: copy `.env.example` to `.env.local` for local overrides.

### Backend Workers (optional)

Each Worker folder has a `wrangler.example.*`. Copy it to the real config name, fill in your own account and Firebase project ids, and set secrets with `wrangler secret put`. See [backend/README.md](backend/README.md).

The web build also needs the image worker asset: `./scripts/build_image_worker.sh`.

## Fonts and licences

The typefaces in `assets/fonts/user` are supplied by the project owner and keep their own licences. Package licences are listed inside the app. Catalog image credits are in [docs/CATALOG_IMAGE_CREDITS.md](docs/CATALOG_IMAGE_CREDITS.md).
