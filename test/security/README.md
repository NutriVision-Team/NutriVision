# Local Firestore rules review

The authoritative `../../firestore.rules` is unchanged. Its recipe read condition permits unpublished recipes because it contains an always-true branch. `firestore.proposed.rules` is a separate review candidate that removes that branch. No rule has been deployed.

## Run the isolated checks

Use Node 22 or newer and Java 21 for the current Firebase CLI. From this folder:

```sh
npm ci
npx firebase emulators:exec --only firestore --project demo-sufra-local --config emulator.json 'node rules.test.mjs'
```

The test refuses to run unless `FIRESTORE_EMULATOR_HOST` is exactly `127.0.0.1:8089`. The CLI supplies that value for the command. Both project IDs use Firebase's `demo-` prefix. Fixtures are created only inside the emulator. No real users or remote project data are changed.

The 21 assertions test the original behavior and the proposed correction, including published-recipe queries, unpublished-recipe denial, owner access, cross-user isolation, unauthenticated access, and catalog write denial. Denied test operations intentionally print permission errors. The final result must report all 21 assertions passed.

## Verification record

- Both versions passed all 21 assertions after the locked dependency updates.
- Original rules SHA256: `4bcc7e3f44f15b91d687ba9b4ff546d828293c5655e1db55f668795325f728b0`.
- Test-only tooling audit at preparation: 14 moderate advisories, zero high or critical advisories. These are inherited CLI development dependencies, not Flutter runtime dependencies. Run `npm audit` again before use because advisories can change.
- Do not include `node_modules`, emulator logs or downloaded emulator binaries in the application archive.

Approval of this candidate and any deployment are separate decisions. Passing these checks is not a claim that every possible rule path has been audited.
