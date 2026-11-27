# Sufra progression implementation status

## Current implementation

- Separate pure domain engine and configurable JSON rules, with five levels and ten achievements. Rules are parsed outside widgets.
- Read-only adapters for completed setup, owned meals and saved meal plans. No use of client-written legacy achievement documents as trusted award evidence.
- A new habit-first `/stats` view. Existing nutrition statistics are preserved at `/nutrition-stats`, with water, weight and reports still reachable.
- Daily XP allowance per activity type, stable event identity, duplicate replay prevention within a projection, account/date checks and future-day exclusion.
- Activity-day achievements do not require consecutive days. Yesterday counts for the current streak. Missing days do not subtract calculated XP or past activity counts.
- Ten badge definitions exist. Learning and recipe-completion badges remain locked with explicit unavailable-tracking copy. No fictional activity is inserted into the production adapter.
- Screen labels points as calculated from current records, not server-verified rewards. Deleting a source record can change the projection. There is no durable award ledger yet.

## Not yet delivered

- Trusted award persistence and historical ledger, atomic cross-device deduplication, configurable server rules rollout, trusted event validation and abuse controls.
- Weekly/monthly challenges, completion tracking for lessons and tried recipes, reward celebrations, notification delivery, cosmetic unlocks, seasons and journey map.
- Device runtime and a signed-in browser test using real account data.

## Trust boundary and persistence plan

No new Firestore rules were deployed or changed for this feature. Default-deny means proposed new `gamification` paths are not client writable under the current rules. Existing legacy achievement documents remain separate and are not promoted to trusted status.

A future trusted processor must independently read source records, establish ownership and qualifying state, validate the active config version, enforce event identity and daily caps, then atomically create an immutable award transaction and update the profile. The client must have no direct write grant on verified XP, levels or awarded badges. Server timestamps alone never establish source validity.

Recommended durable paths:
- `users/{uid}/gamification/profile`
- `users/{uid}/gamification/profile/transactions/{eventId}`
- `users/{uid}/achievements/{achievementId}` only after a reviewed migration separates legacy projections from verified awards.
- `app_config/gamification` as a read-only, versioned configuration document, with validated bundled fallback.

The earlier proposed `gamification_config/achievements/{id}` path has three segments and is a collection path, not a document path. Use a valid document path and specify its collection/document semantics explicitly before deployment.

Do not enable Cloud Functions, upgrade a Firebase plan, attach billing, deploy rules/config, or publish source as part of this draft. A separately approved no-billing trusted execution design is still needed before verified cloud rewards can be claimed.

## Health principles

No XP for losing weight, lowering calorie intake, skipping food, or reaching an arbitrary water quota. No forced leaderboard or rank comparison. Extra same-day meals do not multiply daily meal XP. Current labels describe habits, not medical health outcomes.
