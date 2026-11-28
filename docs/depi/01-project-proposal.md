# 01 — Project Proposal

**Project:** Sufra (سفرة) — Your health, on your table | صحتك على سفرتك
**Group:** HRV | #17 | ONL5_SWD8_G1 | DEPI5
**Track:** Cross-Platform Mobile Development
**Team:** NutriVision (6 members)
**Repository:** https://github.com/NutriVision-Team/NutriVision

---

## Overview

Sufra is an Arabic-first nutrition companion built with Flutter and Firebase. It helps Arabic-speaking users, Egyptians first, plan meals, log what they eat in the ways that feel natural (search, voice, barcode and photos), track water and weight, follow a calorie plan, and chat with a built-in health coach in Egyptian Arabic. The interface is right-to-left first and ships in English too, with light and dark themes, on Android, iOS, Web and desktop from one codebase.

Two constraints define the engineering character of the project:

1. **Honest data.** Nutrition values come from sourced records (Open Food Facts, USDA) or a clear empty state. The app never invents a number. AI models suggest; the user confirms; deterministic tools compute.
2. **Zero-cost operation.** Every layer runs on a free tier (Firebase Spark, Cloudflare Workers free, Workers AI free allocations, free public food databases). Quotas are enforced in code as hard ceilings, so the app can never generate a bill.

## Objectives

1. Deliver a complete, production-grade mobile app experience in Arabic-first design, from a single cross-platform codebase.
2. Make meal logging take seconds through five input methods: search, voice, barcode, photo, favorites.
3. Bring AI into the app responsibly: server-side inference, consent-gated photos, no keys in the app, output contracts that keep models from inventing facts.
4. Turn the free-tier constraint into an architecture feature: rate-limited, cache-friendly, offline-first.
5. Demonstrate real engineering process: planning, design system, automated testing, documentation, and a public repository history.

## Scope

**In scope (delivered in milestone 1):**
- Authentication: email/password with first and last name, Google sign-in, password reset by emailed 6-digit code.
- Health profile and computed calorie/macro targets.
- Meal logging (five methods) with an Egyptian food catalog; daily diary.
- Water and weight tracking; streaks, statistics, achievements; PDF report in Arabic and English.
- Weekly meal planner and shopping list; recipes and healthier alternatives.
- AI coach chat (Egyptian Arabic/English) and AI food-photo recognition, both server-side on Cloudflare Workers AI.
- Ramadan mode; reminders and notifications; favorites; light/dark themes; responsive phone/tablet/desktop layouts.
- Backend: four Cloudflare Workers (reset-code, health-coach, food-vision, progression) with per-user rate limiting and Firebase-token verification.
- Quality: 292 Dart test files plus backend test suites; analyzer-clean codebase.

**Out of scope (explicitly):**
- Medical advice, diagnosis or treatment plans (the coach is an educational assistant, not a clinician).
- Phone/SMS sign-in (no free provider option; deferred).
- In-app purchases (the Premium screen is display-only).
- Packaged store release / APK distribution (the deliverable is the complete Flutter project).

## Success criteria

A user can go from install to a personalized plan in minutes, log a real Egyptian meal by voice or photo, see honest numbers against their targets, and never hit a paywall or a billing surprise. The codebase stays analyzer-clean with a passing automated suite.

## Deliverables

The Flutter application, the four backend Workers, this documentation set, the automated test suites, the interactive design system (`design/Sufra_Design_UI_fast.html`), the final presentation, and the project infographic.
