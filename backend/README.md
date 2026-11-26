# Backend Workers

Small Cloudflare Workers used by the app. Each folder has a `wrangler.example.*` file. Copy it to the real config name and fill in your own account, Firebase project and KV ids; the real configs are git-ignored.

| Folder | Purpose |
| --- | --- |
| `reset-code/` | Sends and verifies the 6-digit password reset code (valid 5 minutes) |
| `health-coach/` | Coach chat and food calculation, with per-user rate limits |
| `food-vision/` | Food photo recognition, authenticated users only |
| `progression/` | Achievements and levels engine and its tests |

Every request verifies the caller's Firebase ID token. Secrets are Worker secrets (`wrangler secret put NAME`) and must not be committed. Run a Worker's tests with `npm test` or `node --test` inside its folder where a `package.json` exists.
