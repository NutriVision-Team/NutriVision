# 10 — API Documentation

**Project:** Sufra (سفرة)
**Group:** HRV | #17 | ONL5_SWD8_G1 | DEPI5
**Track:** Cross-Platform Mobile Development

Sufra's backend is four small **Cloudflare Workers** (`backend/`). Shared rules:

- Every non-OPTIONS request (except `/health` and the public reset-code flow) carries the caller's **Firebase ID token** as `Authorization: Bearer <token>` and is verified server-side.
- Secrets are Worker secrets (`wrangler secret put`), never committed. Real `wrangler` configs are git-ignored; `wrangler.example.*` templates show the shape.
- Worker base URLs are passed to the app as build-time `--dart-define` values (`SUFRA_RESET_URL`, `SUFRA_COACH_URL`, `SUFRA_FOOD_VISION_URL`). Without them the corresponding features stay off and the rest of the app works.
- Responses are JSON with `cache-control: no-store`.

---

## 1. reset-code — password reset by email

Purpose: send and verify a 6-digit reset code, then update the password through the Google Identity Toolkit. Codes are stored only as salted hashes in Workers KV with a 5-minute TTL and an attempt counter.

### `GET /health`
Returns `{ "service": "sufra-reset", "ok": true }`.

### `POST /request`
Request body:
```json
{ "email": "user@example.com" }
```
Behavior:
- One request per email per 60 seconds (`429 rate_limited` otherwise).
- If the account exists, generates a 6-digit code, stores its hash (code + email + secret) with TTL 5 minutes, and emails it bilingually (Arabic first, English below).
- **Always** returns the same success body, so account existence cannot be enumerated.

Response:
```json
{ "ok": true, "expiresIn": 300 }
```

### `POST /confirm`
Request body:
```json
{ "email": "user@example.com", "code": "123456", "newPassword": "........" }
```
Validation and errors:
- `code` must be exactly 6 digits → `400 invalid_code`.
- Password must be 8–128 characters → `400 weak_password`.
- Unknown or expired code → `400 expired`.
- Too many wrong attempts → `429 rate_limited` (the code is destroyed).
- On success the code is deleted (single use) and the password is updated → `{ "ok": true }`.

---

## 2. health-coach — coach chat and food calculation

Purpose: the in-app coach. Runs Gemma 4 (`@cf/google/gemma-4-26b-a4b-it`) server-side under a strict typed contract, with per-user rate limits. The model explains; a deterministic catalog tool computes.

### `GET /health`
Returns service status and whether personal coach access is enabled.

### `POST /chat`
Request body (input contract, strictly validated, max body 24 KB):
```json
{
  "question": "عايز فكرة عشاء صحي",
  "locale": "ar",
  "consentVersion": "coach-external-v1",
  "context": {
    "profile": { "age": 26, "heightCm": 178, "goals": ["..."], "allergens": ["..."] },
    "facts": [ { "key": "...", "value": 1, "source": "...", "unit": "kcal" } ],
    "recentConversation": ["..."],
    "approvedMemories": ["..."],
    "reviewedCalculation": { "...": "..." },
    "reviewedHistory": { "from": "2026-11-01", "to": "2026-11-28", "coverage": "recorded_confirmed_meals_only", "missingDays": "unknown", "recordedDays": 12, "confirmedMeals": 20, "energyKcal": null, "proteinG": null }
  }
}
```
- `locale` must be `ar` or `en`. `question` max 2000 chars. Optional context blocks are schema-validated (profile numbers bounded, lists capped, conversation history max 8, memories max 20).

Response:
```json
{
  "text": "...",
  "sourceIds": ["..."],
  "navigation": ["planner"],
  "origin": "ai",
  "requiresUserReview": true,
  "model": "@cf/google/gemma-4-26b-a4b-it"
}
```

Output contract (enforced server-side, a violating reply is retried once with a corrective instruction naming the target language, then rejected):
- `text` max 6000 chars, **no URLs and no numeric nutrition claims** (the app renders numbers from the tool separately).
- `sourceIds` only from the server-provided knowledge IDs, never model-invented.
- `navigation` is a subset of the fixed enum `planner | diary | water | recipes | report`.
- Safety: a server preflight screens input; output passes `outputSafe` plus consistency, boundedness and non-repetition checks. The system prompt fixes the coach as an educational assistant, not a clinician.

Errors: `400 invalid_request` (contract break), `401` unauthenticated, `429 rate_limited`, `404` for other paths.

---

## 3. food-vision — meal photo recognition

Purpose: recognize food on a plate from a photo, server-side, with consent, self-verification and a silent fallback model.

### `GET /health`
Returns `{ "service": "sufra-food-vision", "personalUploadsEnabled": true|false }`.

### `POST /recognize`
Request:
- Headers: `Authorization: Bearer <Firebase ID token>`, `Content-Type: image/jpeg`.
- Body: raw JPEG bytes. Size capped (`413 invalid_size`); JPEG magic bytes validated (`400 invalid_image`); wrong type → `415 unsupported_image`.

Behavior:
1. Verifies the Firebase ID token. (A separate, short-lived ES256 qualification token exists for the approved synthetic test fixture only.)
2. Per-user rate limit (`429 rate_limited`).
3. Runs the primary vision model (Gemma 4), then a **self-verification pass** that reviews the first reading against the image.
4. On model failure, silently falls back to the next model (Qwen 3.8 27B). If every model fails: `503 inference_unavailable`.
5. Personal uploads are processed only when the account-qualified flag is on; otherwise only the approved non-personal test fixture is accepted (`403 nonpersonal_test_only`).

Response (success): recognized candidate items with names and estimated portions for the app to match against the food catalog, or an **honest empty result** when no food is found (a normal outcome, not an error).

---

## 4. progression — achievements and levels engine

Purpose: computes XP, levels and achievements from real user records only. Shipped as the engine plus its test suites (`backend/progression/`); see `docs/PROGRESSION_ARCHITECTURE.md` for the full trust-boundary design.

Service contract (exercised by the local contract runner and qualification harness):
- `POST /v1/award` — award an achievement event.
- `GET /v1/profile` — read the progression profile.

Engine rules (implemented and tested): daily XP allowance per activity type, stable event identity, duplicate replay prevention within a projection, account and date checks, future-day exclusion, non-consecutive activity days counted fairly.

**Honest status:** the app currently computes a read-only client-side projection from real records and labels it as calculated, not server-verified. Trusted server-side award persistence is designed (immutable award transactions, default-deny rules) and not yet rolled out. The qualification harness only accepts synthetic, fixture-locked, max-10-minute tokens; it never touches real user data.

---

## Cross-cutting

| Concern | Implementation |
|---|---|
| Authentication | Firebase ID token verification on every Worker request |
| Rate limiting | Per-user limiters (food-vision, health-coach); per-email 60 s window (reset-code) |
| Data minimization | Reset codes stored hashed, 5-minute TTL; coach context schema-bounded; photos processed in memory, not persisted by the Worker |
| CORS | reset-code is open for the app flows; food-vision and health-coach allow only local dev origins |
| Error style | Short machine-readable error codes (`invalid_code`, `rate_limited`, ...), mapped by the app to calm, human Arabic/English messages |
