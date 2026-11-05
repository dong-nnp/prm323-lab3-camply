# Authorized demo data setup — 05/11/2026

Owner explicitly requested generated demo catalog in live Firestore and operating
accounts. These are intentional demo records, not claims of real FPT activity.

- `before.json`: exact catalog-path backup before first write (all absent) and
  no collisions with the two reserved operator UIDs. Existing milestones preserved.
- `dry-run.log`: schema counts, scopes and digest; no network/roles/coins written.
- `apply.log`, `applied.json`: catalog import and two Firebase Auth operators,
  role scopes, initializeUser/signup bonus, successful password sign-in. Credentials
  and tokens are omitted; private handoff files are under ignored `.local/`.
- `repeat-apply.log`: completed batch rerun is a no-op with no network calls.
- `catalog-tests.log`: local Node behavior tests for references, taxonomy,
  check-in/registration windows, full/last-ticket cases and dry-run isolation.
- `verify.mjs`, `verification.log`, `verification.json`: authenticated cloud reads,
  public APIs, role checks that stop before writes, stock/price and exact counts.
  No attendance/redemption/claims were faked, no email/SMS was sent.

An initial Auth admin request used the top-level signup endpoint and failed due
to CLI OAuth/API-key projects differing; the project-scoped endpoint used by the
installed Firebase Admin SDK succeeded. The catalog commit was preserved and no
duplicate records/accounts were created. Final apply/verification logs show the
completed run. No credentials were printed while diagnosing the endpoint.

No Flutter integration, camera, push delivery or positive operational mutation is
claimed by this data task. Event live windows expire naturally after generation.
