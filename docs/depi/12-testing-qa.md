# 12 — Testing & Quality Assurance

**Project:** Sufra (سفرة)
**Group:** HRV | #17 | ONL5_SWD8_G1 | DEPI5
**Track:** Cross-Platform Mobile Development

---

## 1. Test Plan

### Objectives
Prove that the app behaves correctly for its real users: Arabic and English, light and dark, phone to desktop, online and offline, with AI features that fail honestly instead of dangerously.

### Scope and levels

| Level | What it covers | Tools |
|---|---|---|
| Unit tests | Domain logic, repositories, models, the progression engine, coach contract, food-vision contract | `flutter test`, `node --test` |
| Widget tests | Screens and components in isolation, including back-guard behavior and effects | `flutter_test` |
| Golden tests | Pixel renders of screens at fixed sizes, both themes, both languages | Flutter golden tooling (150+ reference images) |
| Responsive matrix | 360, 390, 800×1280, 1280×800, 1440×900, Arabic + English, dark + light | Widget + golden tests |
| Worker contract tests | Input/output contracts, safety preflight, rate limits, fallback behavior | Node test runner per Worker |
| Emulator/qualification | Progression engine against a Firestore emulator; food-vision against an approved synthetic fixture only | Firebase emulator, signed qualification tokens |
| Static analysis | Whole codebase must stay analyzer-clean | `flutter analyze` |

### Environments
Local Flutter toolchain (3.35.7 / Dart 3.9.2), Node for Worker tests, Firebase emulator suite for progression.

### Entry criteria
Feature code complete for the area under test; analyzer clean.

### Exit criteria (milestone 1, met)
Analyzer clean; unit, widget, golden and responsive suites pass; worker contract suites pass; defects found in the 26 Nov 2026 review fixed and covered by tests.

### Honest gaps (tracked, not hidden)
Physical-device QA is under way. A recorded list of what is verified only in tests and not yet on a real device is maintained in `docs/UI_FIXES_20261126.md` ("Not verified on real devices": real notification delivery, OTP with the real keyboard, Google sign-in end to end on a signed build, the meal repository against live Firestore, and others).

---

## 2. Automated Testing Inventory

**Flutter suite: 292 test files** (`test/`), by area:

| Area | Files | Area | Files |
|---|---|---|---|
| planning | 41 | auth | 12 |
| core | 33 | gamification | 11 |
| progress | 24 | barcode | 10 |
| meal_log | 23 | reminders | 8 |
| home | 22 | capture | 6 |
| camera_analysis | 22 | favorites | 5 |
| health_coach | 21 | profile_setup | 4 |
| core/widgets | 16 | security | 3 |
| discovery | 15 | voice_logging | 2 |
| (+ goldens, theme, utils, integration, dashboard, nutrition_plan, meal_logging, premium, app) | 17 | | |

**Backend suites** (`backend/`, Node test runner):

| Worker | Test files |
|---|---|
| health-coach | coach, gemma-tools, owner-entry, catalog-calculation, response-quality, live_contract |
| food-vision | worker, estimate-contract, gemma-recognition, qwen-recognition |
| progression | engine, adapters, emulator, field_masks, worker_qualification |

Run commands: `flutter test test/<folder>` per folder (the full suite is large), `npm test` or `node --test` inside each Worker folder.

---

## 3. Sample Test Cases

| ID | Area | Scenario | Expected result | Automation |
|---|---|---|---|---|
| TC-01 | Auth | Register with matching password confirmation | Account created, profile doc written, home opens with the user's name | `test/features/auth` |
| TC-02 | Auth | Google sign-in on Android/iOS | Native account picker opens (web callback no longer hijacks the flow) | auth widget tests + BUG-08 fix |
| TC-03 | Reset | Enter the 6-digit code from email | OTP boxes auto-advance, paste fills all, Arabic-Indic digits convert | mock reset service test |
| TC-04 | Reset | Wrong code 5+ times | `rate_limited`, code destroyed | reset-code Worker tests |
| TC-05 | Logging | Search "كشري" and log a serving | Entry saved with per-100 g nutrition scaled to the portion | meal_log tests |
| TC-06 | Photo | Recognized plate, user edits items before confirming | Only the confirmed items save; nothing persists without confirmation | camera_analysis tests (22 files) |
| TC-07 | Photo | Photo of a non-food object | Honest empty result, no error scare | food-vision worker tests |
| TC-08 | Photo | First model fails | Silent fallback to the next model; user never sees technical detail | worker fallback tests |
| TC-09 | Coach | Ask for calories of a meal | Numbers computed by the catalog tool, shown by the app; model text contains no numbers | catalog-calculation + response-quality tests |
| TC-10 | Coach | Model replies in the wrong language | One corrective retry naming the target language; wrong-language reply rejected | coach contract tests |
| TC-11 | Diary | Log meals across two days | `daily_logs` totals and streaks update per `dateKey` in the user's timezone | progress/planning tests |
| TC-12 | Gamification | Replay the same activity event | Duplicate prevented, daily XP cap enforced | gamification + progression engine tests |
| TC-13 | Responsive | Open Home at 1440×900 Arabic dark | Proper shell, no stretched phone layout, golden match | responsive matrix |
| TC-14 | Back | Press system back on a signed-in page with nothing to pop | Goes to Home; second press within 2 s exits | back_guard tests |
| TC-15 | Security | Client tries to write `food_catalog` | Denied by Firestore rules (read-only public data) | rules design + security tests |

---

## 4. Bug Reports

Source: the 26 Nov 2026 full-screen review (`docs/UI_FIXES_20261126.md`), covering all screens at 5 sizes × 2 languages × 2 themes. All defects below are **fixed** and covered by tests.

| ID | Severity | Area | Defect | Resolution |
|---|---|---|---|---|
| BUG-01 | High | Responsive | Tablet/desktop widths showed a stretched phone layout | Proper responsive shell; widget tests at 5 sizes |
| BUG-02 | Medium | Home | Hero card layout broke on wide and narrow screens | Layout corrected |
| BUG-03 | Medium | Account tab | Content broke inside the tablet shell | Fixed in shell |
| BUG-04 | Low | Favorites | 3–5 px overflow below 380 px | List layout under 380 px |
| BUG-05 | High | Navigation | System back behaved inconsistently per page | `back_guard.dart`: pop when possible, Home fallback, double-press exit, wizard steps back |
| BUG-06 | Medium | Effects | Hover/press effects missing on custom controls; shadows clipped | `SufraControlFeedback` everywhere, `overlay: true` |
| BUG-07 | Medium | Tooling | `flutter_animate` pending timers failed widget tests | Removed; plain animation widgets |
| BUG-08 | Critical | Auth | Google sign-in on Android/iOS silently took the web path and reported "canceled" without opening the picker | Web callback passed only on web; native picker on mobile |
| BUG-09 | Medium | Premium | Premium screen existed at `/premium` but nothing linked to it | Profile card entry; display-only (no purchase flow by design) |
| BUG-10 | High | Session | No logout affordance | Profile logout card with confirm dialog; clears device Google account; router redirects to login |
| BUG-11 | Medium | Reset | Code entry was a plain field | Six OTP boxes: auto-advance, backspace, paste-fill, Arabic-Indic conversion |

**Security review outcomes (same pass, no defect):** no passwords/tokens stored by the app; HTTPS-only networking with cleartext off on Android; Android auto-backup disabled; logs contain no emails, codes, tokens or uids; 30-second auth timeouts; double-tap protection; mapped, human error messages; no automatic sign-in retries by design.

**Open verification items:** physical-device QA items listed in section 1 ("Honest gaps"); release signing still on the debug key (`docs/ANDROID_SIGNING_NOTE.md`).
