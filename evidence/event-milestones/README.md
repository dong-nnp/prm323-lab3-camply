# Event Milestones release — 05/11/2026

Target `prm393-31822`, region `asia-southeast1`. Owner approved five policies,
manual claims, historical verified attendance and dynamic admin management.

- `contract-red.log`, `tests-red-api.log`: expected failing contract tests before
  implementation; `tests-red.log` is an interrupted infrastructure attempt.
- `emulator-tests-release.log`: final source build + **41/41 PASS**, no skips.
  Older emulator logs record 39-test iterations, not the release suite.
- `deploy-firestore.log`, `deploy-functions.log`: successful selective deployment
  of Rules/index and four Functions (three new, getOperationStatus updated).
- `policy-config-before.json`: empty catalog/config backup before the release.
- `published.json`, `publish.log`: atomic create-only policy commit and Remote
  Config version 1 publish. No user/event/attendance/coin test data was seeded.
- `publish.mjs`: one-time release script, intentionally refuses a nonempty
  catalog; **do not rerun** after this release. CLI auth is used without saving
  tokens or credentials. Future changes use the authorized admin API.
- `verify.mjs`: read cloud metadata/query/policies; check unauthenticated API and
  client writes are rejected. Anonymous write probe uses the already approved
  value and must return 403. No live authenticated reward claim is made.
- `npm-audit.json`: production dependencies, 6 moderate, 0 high/critical. No
  dependency upgrades were made in this feature.

Cloud verification **PASS**: 37 ACTIVE Functions, four changed Cloud Run latest
revisions READY, attendance index READY, exact aggregate query succeeds, five
public approved policies, direct write 403, three anonymous callables 401 and
Remote Config version 1. Result: `cloud-verification.json` and `cloud-smoke.log`.
Initial probes observed CREATING while the index built; final checks passed only
after READY. `policy-dry-run.log` validates the approved catalog without writes.
No Flutter/admin UI integration or real mobile end-to-end claim is asserted.
