# Preintegration release — 05/11/2026

Owner confirmed the post-audit decisions recorded in
[PREINTEGRATION_DECISIONS.md](../../docs/PREINTEGRATION_DECISIONS.md).

- `evia-preintegration-flutter-baseline.log`: 141/141 baseline Flutter tests.
- `evia-fpt-red.log`, `evia-ui-policy-red.log`, `evia-manual-red.log`,
  `evia-notifications-red.log`: expected RED tests before each implementation.
  Notification RED imports a module that did not exist yet; other RED cases
  reproduce the old behavior or missing API. These are not passing evidence.
- `evia-fpt-tests.log`: 42-test intermediate backend suite.
- `evia-manual-green.log`: 45-test intermediate backend suite.
- `evia-notifications-green.log`: 50-test intermediate backend suite.
- `evia-preintegration-backend-final.log`: **51/51 PASS**, 0 fail/skipped,
  TypeScript build + loopback demo-project Emulator tests. Fixture cleanup never
  points at a live project. This final suite adds disabled/ended notification cases.
- `evia-preintegration-flutter-final.log`: **149/149 PASS**, including new
  ViewModel/widget tests. Test-only CampusService fakes are not a live adapter.
- `evia-preintegration-analyze.log`, `evia-preintegration-format.log`,
  `evia-preintegration-pub-get.log`: analyze clean, format and dependency resolve.
- `flutter-build-apk.log`: debug APK build PASS. No install/startup or native
  Firebase flow is asserted. Existing plugins warn about future Built-in Kotlin
  compatibility; the current build succeeds.
- `evia-preintegration-index-deploy.log`: live group indexes deployed.
- `evia-preintegration-functions-deploy.log`: all 41 exports deployed in 11
  batches, at most four per batch. Original per-batch logs live at
  `../firebase-migration/deploy-20261105-112147/`.
- `verify-cloud.mjs`, `cloud-verification.json`, `cloud-verification.log`:
  read-only checks, **41 ACTIVE Functions**, one source hash, 41 latest Cloud Run
  revisions ready, group indexes READY and fanout queries working, reminder
  Scheduler enabled/private/correct IAM. Two code callables reject anonymous;
  public catalogs respond successfully with empty results. No live write probes,
  Auth accounts, coins, fake events or notification runs were created.
- `npm-audit.json`: 6 moderate, 0 high/critical; packages unchanged by this task.

Scheduler configuration and IAM do not establish positive live business execution.
The mobile still needs real service adapters, canonical data and authorized
staff/admin accounts. Cafe cloud record remains absent pending approved data.
No native Google login, camera scanning or push delivery is claimed by these logs.
