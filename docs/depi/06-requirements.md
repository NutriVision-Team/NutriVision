# 06 — Requirements Gathering

**Project:** Sufra (سفرة), Arabic-first nutrition companion
**Group:** HRV | #17 | ONL5_SWD8_G1 | DEPI5
**Track:** Cross-Platform Mobile Development
**Source of truth:** every requirement below is implemented in the repository and traceable to code, tests, or rendered screens. Nothing here is aspirational unless explicitly marked as proposed.

---

## 1. Stakeholder Analysis

> **Status: draft proposed by the team.** Stakeholder needs were identified from the project brief and the problem domain, not from formal interviews. To be confirmed by the team before the final discussion.

| Stakeholder | Who they are | What they need | How Sufra addresses it |
|---|---|---|---|
| Arabic-speaking users (Egypt first) | People who want to track what they eat in their own language | Egyptian food names, right-to-left UI, Arabic-Indic numerals where they belong, no friction | Arabic-first design (not a translation), Egyptian catalog entries, Egyptian-Arabic coach, full English as a second language |
| Users logging meals in a hurry | Anyone who finds calorie apps tedious | Multiple fast input methods | Five logging methods: search, voice, barcode scan, photo, favorites |
| Users who distrust made-up numbers | People burned by apps that invent nutrition data | Real, sourced values or an honest empty state | Catalog backed by Open Food Facts and USDA, `sourceUrl` and `verificationStatus` on food records, never an invented number |
| Ramadan observers | Users fasting during Ramadan | Suhoor and iftar planning, fasting-day tracking | Dedicated Ramadan mode with its own design |
| Users with allergies or dietary preferences | People who must avoid specific foods | Allergen and preference awareness | Nutrition profile stores allergies, dietary preferences and health restrictions; barcode flow surfaces allergens |
| Privacy-conscious users | Anyone photographing personal meals | Control over what leaves the device | Consent before any photo is uploaded, owner-scoped Firestore and Storage rules, no AI keys inside the app |
| The development team (6 members) | DEPI students building the project | Clear ownership, real engineering experience | Defined screen split (see 03 Task Assignment & Roles), feature-first codebase, 292 test files |
| DEPI instructors and evaluators | Assess the graduation project | Evidence of process: planning, design, testing, documentation | This documentation set, the test suite, and the public repository history |
| Data providers | Open Food Facts, USDA FoodData Central | Fair use and attribution | Contact identification on Open Food Facts requests, catalog image credits in `docs/CATALOG_IMAGE_CREDITS.md` |
| Infrastructure providers | Firebase, Cloudflare | Staying within free-tier terms | Free tiers treated as hard ceilings enforced in code, not best-effort hopes |

---

## 2. User Stories

| ID | As a … | I want to … | So that … | Acceptance evidence |
|---|---|---|---|---|
| US-01 | new user | sign up with my first and last name, email and a confirmed password | the app greets me by name | Auth flow with name collection and password confirmation; widget tests in `test/features/auth` |
| US-02 | returning user | sign in with Google in one tap | I skip passwords | Native Google sign-in on Android/iOS, web path on web; fixed and covered after the callback defect (see 12 Testing, BUG-08) |
| US-03 | user who forgot a password | get a 6-digit code by email, valid 5 minutes, and set a new password | I recover my account safely | `reset-code` Worker; OTP boxes with auto-advance, paste-fill, Arabic-Indic digit conversion |
| US-04 | user | search an Egyptian food catalog in Arabic or English | I find what I actually ate | `food_catalog` with localized names, categories, serving sizes |
| US-05 | user | say my meal out loud | logging takes seconds | Voice logging via `speech_to_text` with Arabic food suggestions (`voice_food_suggestions.dart`) |
| US-06 | user | scan a product barcode | packaged food logs instantly | `mobile_scanner` flow; product data from Open Food Facts with Nutri-Score, ingredients, allergens |
| US-07 | user | photograph my plate and confirm what the AI sees | I log complex home meals | Consent-gated photo analysis, server-side recognition, self-verification pass, user edits and confirms before anything is saved |
| US-08 | user | see my day at a glance: calories, macros, water, meals | I know where I stand | Diary with daily totals and targets (`daily_logs`) |
| US-09 | user | track water glass by glass and my weight over time | I build the habit | Water logs, weight logs with notes, streaks and weekly stats |
| US-10 | user | get a weekly meal plan that fits my calorie target and a shopping list built from it | healthy eating becomes the default | Meal planner, `meal_plans`, `shopping_lists` with items linked to foods and products |
| US-11 | user | chat with a coach in Egyptian Arabic that knows my goals | I get guidance without leaving the app | Health coach Worker; server-computed nutrition shown by the app, model never invents numbers |
| US-12 | user | export my report as a PDF in Arabic or English | I can share progress | `pdf` package export, `/report/export` |
| US-13 | user | use the app in dark or light, on phone, tablet or desktop | it fits my device and eyes | Theme cubit, responsive shell verified at 5 sizes (see 11 UI/UX) |
| US-14 | fasting user | plan suhoor and iftar during Ramadan | the app respects the month | Ramadan mode (`features/ramadan`) with dedicated design |

---

## 3. Use Cases

**Actors:** Registered User, Firebase Auth, Firestore, Cloudflare Workers (reset-code, health-coach, food-vision), Workers AI, Open Food Facts, SMTP email service.

### UC-01 — Create an account
- **Actor:** New user. **Precondition:** none.
- **Main flow:** 1) User opens register, enters first name, last name, email, password and password confirmation. 2) App validates input and creates the Firebase Auth account. 3) App creates the `users/{uid}` profile document (required fields enforced by security rules). 4) User continues to the setup wizard (health profile). 5) Home opens with the user's name.
- **Alternate:** 2a) Google sign-in instead of email: native account picker on Android/iOS, web dialog on web.

### UC-02 — Reset a forgotten password
- **Actor:** Existing user. **Precondition:** account exists for the email.
- **Main flow:** 1) User requests a code. 2) `reset-code` Worker generates a 6-digit code, stores only its hash in KV (5-minute TTL), emails it (Arabic + English). 3) User enters the code in six boxes (auto-advance, paste fills all). 4) User sets and confirms a new password (8–128 chars). 5) Worker verifies hash and attempt count, updates the password via the Identity Toolkit, deletes the code.
- **Exceptions:** expired code → `expired`, a new code can be requested (one request per email per 60 s); too many wrong attempts → `rate_limited`; unknown email still returns `{ok: true}` so addresses cannot be enumerated.

### UC-03 — Log a meal by search
- **Main flow:** 1) User opens meal logging and picks search. 2) App searches `food_catalog` (Arabic/English). 3) User picks a food, a serving size and quantity. 4) App computes nutrition per 100 g basis. 5) Entry saved to `meal_entries`, day totals reflected in `daily_logs`.

### UC-04 — Log a meal by voice
- **Main flow:** 1) User speaks the meal in Arabic or English. 2) `speech_to_text` transcribes. 3) App suggests matching catalog foods. 4) User confirms, entry saved.

### UC-05 — Log a packaged product by barcode
- **Main flow:** 1) User scans a barcode. 2) App checks the local `products` collection. 3) On miss, queries Open Food Facts. 4) Product page shows Nutri-Score, ingredients, allergens. 5) User logs a portion or saves to favorites.
- **Alternate:** product not found anywhere → honest not-found state, user can search instead.

### UC-06 — Log a meal by photo
- **Actor:** Registered user. **Precondition:** consent to upload the photo.
- **Main flow:** 1) User photographs the plate. 2) App prepares the image locally (resize, JPEG). 3) App POSTs the image to the food-vision Worker with the Firebase ID token. 4) Worker verifies the token, enforces the per-user rate limit, validates the JPEG. 5) Workers AI recognizes items; a second self-verification pass reviews the first reading. 6) App matches candidates to catalog records. 7) User edits, adds, deletes items and confirms quantities. 8) Entry saved.
- **Exceptions:** no food found → calm empty state, never an error scare; first model unavailable → silent fallback to the next model; all models unavailable → honest message pointing to search or manual logging; quota/rate limit → `rate_limited`, try later.

### UC-07 — Track the day and progress
- **Main flow:** 1) Diary shows calories, protein, carbs, fat vs targets. 2) User adds water per glass; logs weight with an optional note. 3) Stats show streaks, weekly view; `/stats` is habit-first, `/nutrition-stats` keeps the detailed view. 4) Report exports to PDF in Arabic or English.

### UC-08 — Plan meals and shop
- **Main flow:** 1) App computes calorie and macro targets from the health profile. 2) User generates or edits a weekly plan. 3) Shopping list builds from the plan; items can link to catalog foods or scanned products, and check off when purchased.

### UC-09 — Chat with the coach
- **Main flow:** 1) User asks a question in Egyptian Arabic or English. 2) App sends the question with structured context (profile, facts, recent conversation) under the published input contract. 3) Worker runs a safety preflight, computes any nutrition through the deterministic catalog tool, and asks the model to explain. 4) Reply passes an output contract: no invented numbers or links, sources only from server-provided IDs, optional navigation to app screens. 5) App displays numbers from the tool separately from the model's text.
- **Exceptions:** reply violates the contract → one corrective retry naming the target language; unsafe input → safe refusal; rate limit → calm message.

### UC-10 — Ramadan mode
- **Main flow:** 1) User enables Ramadan mode. 2) Suhoor and iftar planning, fasting-day tracking, Ramadan-specific design. 3) Logging and stats adapt to fasting days.

---

## 4. Functional Requirements

### Authentication and accounts
- **FR-01** Email/password registration with first name, last name and password confirmation.
- **FR-02** Google sign-in: native picker on Android/iOS, web flow on web.
- **FR-03** Password reset via emailed 6-digit code, valid 5 minutes, attempt-limited, single-use.
- **FR-04** Profile document creation enforced by Firestore rules (required keys, owner-only).
- **FR-05** Logout clears the session and the device Google account; router redirects signed-out users to login.

### Meal logging
- **FR-06** Log by catalog search with serving sizes and per-100 g nutrition.
- **FR-07** Log by voice with Arabic speech recognition and food suggestions.
- **FR-08** Log by barcode with Open Food Facts lookup (Nutri-Score, ingredients, allergens).
- **FR-09** Log by photo through server-side AI recognition with consent, self-verification, silent model fallback and user confirmation before saving.
- **FR-10** Save and reuse favorites (foods, products, recipes).
- **FR-11** Meal entries store items, totals, input method and data source with confidence.

### Tracking and progress
- **FR-12** Daily diary with calorie and macro totals against targets.
- **FR-13** Water tracking in millilitres with glass increments.
- **FR-14** Weight tracking with notes and history.
- **FR-15** Habit-first stats (streaks, weekly activity) and detailed nutrition stats.
- **FR-16** PDF report export in Arabic and English.
- **FR-17** Achievements and levels computed from real records only (no fictional activity), with daily XP caps and duplicate prevention.

### Planning
- **FR-18** Calorie and macro targets computed from the health profile (gender, date of birth, height, current and target weight, activity level, goal).
- **FR-19** Weekly meal plans with meals and food portions.
- **FR-20** Shopping lists generated from plans, with categories, quantities and purchased state.
- **FR-21** Healthier-alternatives view comparing dishes side by side.

### Coach
- **FR-22** Coach chat in Egyptian Arabic and English under a strict server-enforced input/output contract.
- **FR-23** Nutrition calculations performed by the deterministic catalog tool; the model explains and never states numbers.
- **FR-24** Coach may suggest in-app navigation (planner, diary, water, recipes, report) via a fixed enum.

### System and personalization
- **FR-25** Full Arabic (RTL-first) and English (LTR) localization.
- **FR-26** Light and dark themes.
- **FR-27** Responsive layouts for phone, tablet and desktop.
- **FR-28** Local notifications and reminders (`flutter_local_notifications`, FCM device registration).
- **FR-29** Ramadan mode (suhoor/iftar planning, fasting-day tracking).
- **FR-30** Offline-first behavior: local caches and queues keep the app usable without a connection.

---

## 5. Non-functional Requirements

| ID | Category | Requirement | Evidence |
|---|---|---|---|
| NFR-01 | Cost | Every layer runs on free tiers: Firebase Spark, Cloudflare Workers free, Workers AI free allocations, Open Food Facts, USDA. Quotas are ceilings enforced in code (rate limiters, caps), never a billing surprise. | Worker rate limiters, backend README, architecture docs |
| NFR-02 | Security | All Worker endpoints verify the caller's Firebase ID token. Secrets live in Worker secrets (`wrangler secret put`), never in the repo or the app. Real `wrangler` configs are git-ignored. | Worker sources, `wrangler.example.*` files |
| NFR-03 | Security | Firestore rules: owner-only read/write under `users/{uid}`; public collections (`food_catalog`, `products`, `recipes`, `food_categories`, `app_config`) are read-only for everyone and unwritable by clients. | `firestore.rules` |
| NFR-04 | Security | Storage accepts only images under 10 MB, only inside the owner's path. | `storage.rules` |
| NFR-05 | Privacy | No photo leaves the device without explicit consent. Coach input follows a published consent version (`coach-external-v1`). Passwords, tokens and Google credentials are never stored by the app. | Consent-gated provider, sign-in security review in `docs/UI_FIXES_20261126.md` |
| NFR-06 | Privacy | Reset codes are stored only as salted hashes with 5-minute TTL and attempt limits; unknown emails get the same response as known ones. | `reset-code` Worker |
| NFR-07 | Reliability | AI features degrade honestly: empty result instead of an error scare, silent fallback model, calm fallback to manual logging. | Food-vision worker, decision record |
| NFR-08 | Reliability | Offline-first storage: local caches and a local ledger queue; the app remains usable without connectivity. | README pillars, gamification local ledger |
| NFR-09 | Usability | Arabic-first RTL design with Egyptian food names; full English support. Arabic-Indic digits convert correctly in code entry. | Design system, OTP field, l10n |
| NFR-10 | Accessibility | Reduced-motion support; large-text layout covered by golden tests; state cards communicate status without color alone. | Theme and golden tests (`reminders_large_text.png`) |
| NFR-11 | Performance | Image preparation on-device before upload; streaming reads with byte and time budgets on Workers; oversized or slow responses rejected. | `MealImagePreparer`, food-vision worker |
| NFR-12 | Compatibility | Android, iOS, Web, Windows, macOS, Linux from one Flutter codebase; verified at 360, 390, 800×1280, 1280×800, 1440×900 in Arabic and English, dark and light. | Responsive test matrix |
| NFR-13 | Maintainability | Feature-first structure, analyzer-clean, central design tokens (no scattered literal colors), 292 Dart test files plus backend test suites. | Repository, `analysis_options.yaml` |
| NFR-14 | Data integrity | Nutrition values carry their source; unknown stays unknown ("missing days are unknown, never zero"). | Catalog model, coach contract |
