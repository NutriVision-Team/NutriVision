# 14 — Technical Documentation

**Project:** Sufra (سفرة)
**Group:** HRV | #17 | ONL5_SWD8_G1 | DEPI5
**Track:** Cross-Platform Mobile Development

The consolidated technical reference. Each section links to its detailed document.

---

## 1. System Overview

Sufra is an Arabic-first nutrition companion: a Flutter app (Android, iOS, Web, Windows, macOS, Linux from one codebase) backed by Firebase (Auth, Firestore, Storage, Messaging, App Check) and four serverless Cloudflare Workers (reset-code, health-coach, food-vision, progression). AI runs server-side on Workers AI (Gemma 4 26B A4B default, Qwen 3.8 27B silent fallback). Food data comes from Open Food Facts and USDA. Every layer runs on free tiers with quotas enforced as hard ceilings.

Details: [07 System Design](07-system-design.md)

---

## 2. Repository Layout

```
lib/
  app/        router, back guard
  core/       theme (tokens), widgets (design system), config, errors, utils
  data/       models, repositories
  features/   28 feature modules (auth, diary, meal_log, camera_analysis, ...)
  services/   platform services
  l10n/       Arabic-first localization (arb)
backend/
  reset-code/     password reset by email code
  health-coach/   coach chat + deterministic catalog calculation
  food-vision/    photo recognition with self-verification and fallback
  progression/    achievements/levels engine + tests
assets/       fonts, images, bundled data (foods, recipes, progression rules)
design/       Sufra_Design_UI_fast.html, the interactive design system (31 screens)
test/         292 Dart test files; 150+ golden renders
docs/         this documentation set + architecture and QA notes
firestore.rules / storage.rules / firebase.json
```

---

## 3. Database Summary

Owner-scoped subcollections under `users/{uid}` (nutrition_profiles, meal_entries, daily_logs, water_logs, weight_logs, meal_plans, shopping_lists+items, favorites, achievements, conversations+messages, devices, notifications). Public read-only reference collections: food_catalog, products, recipes, food_categories, app_config. Storage: owner-only `image/*` under 10 MB. Workers KV holds hashed, 5-minute reset codes only. No composite indexes needed.

Details: [08 Database Design](08-database-design.md), including the ERD and the denormalization rationale.

---

## 4. API Summary

| Worker | Endpoints | Auth |
|---|---|---|
| reset-code | `GET /health`, `POST /request`, `POST /confirm` | public flow, hashed codes, attempt-limited |
| health-coach | `GET /health`, `POST /chat` | Firebase ID token, per-user rate limit, typed input/output contracts |
| food-vision | `GET /health`, `POST /recognize` | Firebase ID token, consent-gated, rate-limited |
| progression | `POST /v1/award`, `GET /v1/profile` | engine + contract tests; trusted persistence designed, rollout pending |

Details: [10 API Documentation](10-api-documentation.md)

---

## 5. Security

- **Client:** no keys or secrets in the app; AI calls go to Workers only; HTTPS everywhere (cleartext off on Android); Android auto-backup disabled; no credentials or personal data in logs; auth calls time out instead of spinning.
- **Firestore rules:** owner-only user data with required key enforcement on profile creation; public collections client-unwritable; proposed gamification paths default-deny.
- **Storage rules:** owner path only, images only, under 10 MB.
- **Workers:** Firebase token verification, per-user rate limiters, input contracts with size caps, JPEG validation, hashed one-time reset codes, output contracts that strip model-invented numbers and links.
- **App Check** enabled for Firebase abuse protection.

Evidence: `firestore.rules`, `storage.rules`, worker sources, the sign-in security review in `docs/UI_FIXES_20261126.md`.

---

## 6. AI Design Notes

- **Coach (Gemma 4):** the model explains; it never computes. Nutrition numbers come from a deterministic catalog tool and are rendered by the app. System prompt fixes an educational, non-clinical scope, Egyptian Arabic style guidance, and a source-ID discipline. One corrective retry on contract violations.
- **Photo recognition:** consent-gated; a second self-verification pass reviews the first reading; silent model fallback; honest empty results; the user confirms items and quantities before anything is saved.
- **Model selection history:** Qwen rejected for recognition quality on Egyptian dishes, Moondream weaker than Gemma on the same images, other free options ruled out for cost or privacy terms. The full record is a team decision log.

---

## 7. Build & Run

From the README (verified):

```sh
flutter pub get
flutter analyze
flutter test test/core        # run folders separately; the full suite is large
```

Firebase (required): create a project, enable Email/Password and Google sign-in, `flutterfire configure`, place `google-services.json`, register the signing SHA-1 (see `docs/ANDROID_SIGNING_NOTE.md`).

Workers (optional): pass `--dart-define=SUFRA_RESET_URL=... --dart-define=SUFRA_COACH_URL=... --dart-define=SUFRA_FOOD_VISION_URL=... --dart-define=OFF_CONTACT=...`. Without them, AI and barcode features stay off and everything else works. Each Worker folder ships a `wrangler.example.*` to copy and fill.

Web builds also need `./scripts/build_image_worker.sh`.

**Executable/APK:** the DEPI deliverable is the complete Flutter project (per the team's delivery decision); no packaged APK is attached. The app runs with `flutter run` on any supported target after the Firebase step.

---

## 8. Testing Summary

292 Dart test files (unit, widget, golden, responsive matrix at 5 sizes × 2 languages × 2 themes) plus three backend test suites (health-coach, food-vision, progression). Defect log from the 26 Nov 2026 full review: 11 bugs found, 11 fixed and covered. Physical-device QA items are tracked openly.

Details: [12 Testing & QA](12-testing-qa.md)

---

## 9. Known Limits & Future Work

Kept honest on purpose:

- **Trusted award persistence** for gamification (server-side immutable ledger) is designed, not rolled out. The client projection is labeled as calculated, not verified. (`docs/PROGRESSION_ARCHITECTURE.md`)
- **CI/CD** is not configured; quality gates run locally. A GitHub Actions pipeline is the planned next step.
- **Release signing** uses the debug key; production signing is deferred (`docs/ANDROID_SIGNING_NOTE.md`).
- **Phone/SMS sign-in** has no free option yet; deferred.
- **Physical-device QA** for the items listed in the testing doc (real notifications, OTP with the real keyboard, end-to-end Google sign-in on a signed build).
- **Coach memory** is session-scoped; durable personalized memory is a future enhancement with its own consent story.
- **Suggested improvements** (for the Literature Review section): richer recipe completion tracking, weekly challenges, and a second independent AI provider as a quota-independent fallback.
