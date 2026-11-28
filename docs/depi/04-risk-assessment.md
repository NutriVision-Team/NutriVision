# 04 — Risk Assessment & Mitigation Plan

**Project:** Sufra (سفرة)
**Group:** HRV | #17 | ONL5_SWD8_G1 | DEPI5
**Track:** Cross-Platform Mobile Development

Severity and likelihood: High / Medium / Low. Status reflects what actually happened during the project where applicable.

---

## Technical risks

| ID | Risk | L | S | Mitigation (as implemented) | Status |
|---|---|---|---|---|---|
| R-01 | **Work loss** (local copy or unsynced work destroyed) | M | H | GitHub as the single source of truth; frequent pushes; release ZIPs; restore drill rehearsed. | **Occurred 3 times** during development; recovered from repo + Drive backups. Rule now: nothing exists only locally. |
| R-02 | **Free-tier quota exhaustion** (Workers AI daily pool, Firestore reads) | M | M | Per-user rate limiters before any AI spend; silent model fallback; quotas treated as ceilings that stop requests, never bill; honest fallback to manual logging. | Mitigated in code. Note: fallback models share the same daily pool, so fallback covers model failure, not pool exhaustion; that path shows a calm manual-logging message. |
| R-03 | **AI model invents nutrition numbers** | M | H | Architectural ban: the coach never states numbers (deterministic catalog tool computes; the app displays); photo recognition returns items only, matched to sourced records; output contracts reject numeric claims and links. | Mitigated by design and enforced by contract tests. |
| R-04 | **Photo recognition accuracy on Egyptian dishes** | H | M | Model evaluation record (Qwen rejected on quality, Moondream weaker, Gemma chosen); self-verification pass; user review and edit before saving; explicit "visual estimate, not a measurement" labeling. | Accepted residual risk, human in the loop. |
| R-05 | **Auth provider misconfiguration per platform** | M | H | Platform-specific code paths with tests; the Google sign-in callback defect (BUG-08) was caught in review and fixed with coverage; SHA-1 registration documented. | Occurred once, fixed, covered. |
| R-06 | **Credential/secret leakage** | L | H | No keys in the app; Worker secrets via `wrangler secret put`; real configs git-ignored; `firebase_options.dart` stubbed in the public repo; no personal data in logs. | Controlled. |
| R-07 | **Responsive breakage on tablets/desktop** | M | M | Responsive shell; golden + widget matrix at 5 sizes × 2 languages × 2 themes; full-app review 26 Nov found and fixed the shell defects. | Occurred, fixed, covered. |
| R-08 | **Animation library breaking tests** | L | L | `flutter_animate` removed; plain animation widgets only. | Occurred, resolved. |

## Project risks

| ID | Risk | L | S | Mitigation | Status |
|---|---|---|---|---|---|
| R-09 | **Deadline compression** (implementation 30 Nov, final 4 Dec) | H | H | Milestone 1 merged 27 Nov; final week reserved for docs, QA and presentation only; no new features. | On track. |
| R-10 | **Scope creep** (client/demo requests late in the cycle) | H | M | Milestone-1 scope frozen; display-only Premium screen instead of a payment flow; deferred list documented (phone sign-in, CI/CD, release signing). | Managed. |
| R-11 | **Team coordination across 6 members** | M | M | Screen-based ownership (no overlapping files), shared design tokens and component library, leader review gate. | Worked; no merge conflicts of note. |
| R-12 | **Single point of knowledge on backend/AI** | M | M | This documentation set + backend READMEs make the Workers and contracts reproducible by any member. | Mitigated by documentation. |
| R-13 | **Physical-device defects found late** | M | M | Device QA window scheduled in the final week; the unverified list is tracked openly in `docs/UI_FIXES_20261126.md`. | In progress. |

## Operational risks (post-delivery)

| ID | Risk | L | S | Mitigation |
|---|---|---|---|---|
| R-14 | Food data provider changes (Open Food Facts API) | L | M | Catalog is seeded into Firestore; the app does not depend on live OFF for core logging, only for new barcode lookups. |
| R-15 | Model deprecation on Workers AI | M | M | Model is a single configuration constant; fallback path already exercises a second model; evaluation record documents the selection process for a re-run. |
| R-16 | Privacy incident (photo upload) | L | H | Consent gate, EXIF stripped on device, in-memory processing (`store:false`), owner-scoped storage, no request logging of content. |
