# 05 — KPIs (Key Performance Indicators)

**Project:** Sufra (سفرة)
**Group:** HRV | #17 | ONL5_SWD8_G1 | DEPI5
**Track:** Cross-Platform Mobile Development

> **Status: proposed KPI framework.** Targets are set by the team. Current values are reported only where a real measurement exists; everything else is marked **to be measured** rather than invented. Measurement happens during physical-device QA and the pilot period.

---

## 1. Engineering quality (measured now)

| KPI | Target | Current (real) | Source |
|---|---|---|---|
| Static analysis | Zero issues | **Zero issues (analyzer clean)** | `flutter analyze` |
| Automated test files | ≥ 150 | **292 Dart files + 3 backend suites** | `test/`, `backend/` |
| Golden reference renders | Cover every core screen | **150+ renders** | `test/**/goldens/` |
| Responsive matrix | 5 sizes × 2 languages × 2 themes | **Covered in tests** | `docs/UI_FIXES_20261126.md` |
| Defects from the 26 Nov full review | 100% fixed with tests | **11 / 11 fixed** | bug table, 12 Testing & QA |
| Operating cost | $0 | **$0 (free tiers only)** | architecture, rate limiters |

## 2. Performance (targets, to be measured in device QA)

| KPI | Target | Current |
|---|---|---|
| Cold start to interactive (mid-range Android) | ≤ 3 s | to be measured |
| Diary day render | ≤ 1 s after local cache | to be measured |
| Photo analysis round trip | ≤ 45 s ceiling (client timeout), typical ≤ 20 s | client timeout real; typical to be measured |
| Coach first token | ≤ 10 s | to be measured |
| Worker abuse protection | 100% of AI requests token-verified and rate-limited | **by construction (enforced in code)** |

## 3. Reliability & honesty (design-level, verifiable in code)

| KPI | Target | Current |
|---|---|---|
| Invented nutrition numbers shown to users | 0 | **0 by architecture** (numbers come from the catalog tool; contracts reject model-stated numbers) |
| Photo saved without user confirmation | 0 | **0 by architecture** (`requiresUserReview`, review screen before save) |
| AI feature failure shows technical error to user | 0 | **0 by design** (honest empty state, silent fallback, calm manual-logging message) |
| Secrets in repository or app bundle | 0 | **0** (git-ignored configs, Worker secrets, stubbed Firebase options) |

## 4. Adoption & UX (targets for the pilot, to be measured)

| KPI | Target | Current |
|---|---|---|
| Onboarding completion (sign-up → health profile done) | ≥ 80% | to be measured in pilot |
| Time to log a meal (search) | ≤ 30 s | to be measured |
| Time to log a meal (photo, incl. review) | ≤ 90 s | to be measured |
| Photo result confirmed without edits | ≥ 60% (accuracy proxy) | to be measured |
| Weekly active loggers during pilot | ≥ 70% of pilot users | to be measured |
| Crash-free sessions | ≥ 99% | to be measured (Firebase Crashlytics candidate) |

## 5. How KPIs will be measured

- **Engineering:** CI-style local gates (`flutter analyze`, test suites) on every merge; review after each milestone.
- **Performance:** timed runs on a mid-range physical Android device during the final-week QA window; worker latency from Cloudflare logs.
- **Honesty invariants:** these are architectural properties, not statistics; they are guarded by contract tests (`response-quality`, `estimate-contract`, `coach` suites).
- **Adoption:** a closed pilot (team + peers) with manual collection; privacy-preserving counters only, no third-party analytics without a consent update.
