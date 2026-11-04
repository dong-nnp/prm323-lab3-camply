# EVIA LAB 3 — IMPLEMENTATION & EVIDENCE TRACKER

> **Project hiện tại:** `prm393-31822` (evia, Blaze), theo yêu cầu chuyển của người dùng.
> App đã chuyển bằng FlutterFire; 32 Functions + Rules đã deploy, 14 indexes READY.
> API smoke cloud + 20 Emulator tests + APK/startup Core đạt; [evidence](firebase-migration.md).
> UI, Google login/push thật và dữ liệu catalog chưa tích hợp.
> Các mục về `evia-lab3-kiet-2026` bên dưới là lịch sử, không phải project để deploy tiếp.


**Update 2026-11-04 (Codex):** project `evia-lab3-kiet-2026` and Android app created; FlutterFire config generated; empty Firestore database created in `asia-southeast1`; deny-all rules deployed. This is connection/security setup, **not business database implementation complete**. See `docs/firebase-setup.md` and local logs in `evidence/firebase-setup/`. Original handoff entries below remain unverified unless explicitly updated.  
**Repo intended:** https://github.com/dong-nnp/prm323-lab3-camply.  
**Owner of updates:** Codex adds verifiable evidence; ChatGPT reviews and updates status after examining artifacts.  
**Status convention:** `TODO`, `IN PROGRESS`, `BLOCKED`, `DONE - UNVERIFIED`, `VERIFIED` (only with evidence), `OUT OF SCOPE`.

## 1. Stage board

| ID | Work package | Current status | Completion evidence (required to mark VERIFIED) | Codex commit/PR |
|---|---|---|---|---|
| S0 | Inspect **existing** repo, no replacement | TODO | Repo tree/current branch, baseline setup outputs, gap report | — |
| S1 | Align documents/source of truth | IN PROGRESS | Live Figma 44-frame review and schema v1.3 + local backend API; owner decisions recorded for FD-01…11/13; FD-12 and other policies still OPEN, UI/Figma cleanup not implemented | Local docs diff, no PR |
| S2 | Configure Firebase development/emulators | IN PROGRESS | Real project/Android config and Pixel 5 emulator available; Auth/Firestore/Functions/Storage Emulator Suite configured and tested; team project Functions/Storage deployed; native flows pending | Local diff, no PR |
| S3 | Firestore schema, Security Rules, indexes | IN PROGRESS | Empty cloud database + deployed deny-all Rules; anonymous read HTTP 403. Rules/schema/indexes deployed to team project; 14 indexes READY, 20 Emulator tests + cloud read/denial checks pass | Local diff, no PR |
| S4 | Google + email/password signup/sign-in/reset / account init / guest access | IN PROGRESS | Real Auth providers enabled; 200-coin initializer + Auth Emulator transport tested. Native SDK wiring/login pending | Working tree, no PR |
| S5 | Organizer Follow/Unfollow, Bookmark | IN PROGRESS | Backend implemented/tested, no double follower count or guest follow; backend cloud deployed; Flutter integration pending | Working tree, no PR |
| S6 | Registration, slot capacity, Event Full, deposit, ticket | IN PROGRESS | Last-seat concurrency/cancel/idempotency pass locally; backend cloud deployed; authenticated mobile integration pending | Working tree, no PR |
| S7 | Registered ticket QR scan by authorized staff | IN PROGRESS | Server role + event assignment/revocation + refund/reward pass; staff tool/native scanner pending | Working tree, no PR |
| S8 | Walk-in student scanner / QR | IN PROGRESS | Server issuer/TTL/unique verification pass; native camera pending | Working tree, no PR |
| S9 | Wallet + append-only ledger | IN PROGRESS | Backend transactions/reconciliation/Rules pass locally; backend cloud deployed; mobile pending | Working tree, no PR |
| S10 | Daily Check-in | IN PROGRESS | 1-9 reward schedule, Vietnam midnight, gap/year boundary and races pass locally | Working tree, no PR |
| S11 | Monthly Gift schema / policy | BLOCKED | +200 amount recorded, policy owner-approved before live grant | — |
| S12 | Reward catalogue/redemption/voucher | IN PROGRESS | Atomic stock/balance/idempotency + private owner-code recovery pass; cashier policy OPEN | Working tree, no PR |
| S13 | Cloud Storage report export/upload | IN PROGRESS | Own PDF create/read + deny cross-UID/type/size/overwrite pass locally; cloud Rules on existing bucket deployed; export UI/real upload pending | Working tree, no PR |
| S14 | FCM + notifications inbox | IN PROGRESS | Inbox/device binding tested; generic notification trigger prepared; real-device push/deep-link pending | Working tree, no PR |
| S15 | Analytics, Crashlytics, Remote Config | TODO | 7+ events DebugView; test crash+nonfatal; 2 live config changes | — |
| S16 | Figma fidelity and UI states | TODO | 44-frame mapping status, 3 flows, loading/empty/error, 360/412dp | — |
| S17 | Google ARTEMIS E2E tests | TODO | >=10 tests ×>=3 runs, traces/pass-rate and exploratory report | — |
| S18 | AI code review & fix commits | TODO | >=5 findings, decisions, >=3 linked fix commits | — |
| S19 | Report/slide/video/evidence | TODO | PDF 8–12p; PDF slides 12–15p; video 5–10min; links work | — |
| S20 | Web Admin | OUT OF SCOPE | Future project; only minimal authenticated verifier for Lab 3 | — |

## 2. Decisions pending (do not guess)

| ID | Pending question | Why it blocks implementation | Temporary handling |
|---|---|---|---|
| O-01 | RESOLVED — signup bonus 200; Daily timezone Asia/Ho_Chi_Minh | Owner confirmed in current chat | Implemented once per UID / local calendar day; no bulk live grant |
| O-02 | No-show deposit settlement after event | Avoid indefinitely held deposits or invented forfeiture | No automatic no-show settlement until approved |
| O-03 | Can user re-register after cancellation? | Deterministic registration ID/state machine | Reject by default until approved |
| O-04 | Monthly Gift: automatic vs claim, who eligible, when, timezone | Scheduled/triggered credit grants | Schema + emulator only; **do not enable live grants** |
| O-05 | RESOLVED — milestones removed entirely | No milestone feature or extra Coin issuance | No progress/claim/grant models or active UI/API; existing demo cleanup pending |
| O-06 | Technical default — walk-in TTL60s, ticket TTL120s | Replay protection, not physical presence proof | Implemented locally; native scanner/operator handoff pending |
| O-07 | Authorized staff verifier form (CLI/mobile/minimal tool) | Demonstrating real registered check-in | Propose secure minimal verifier and seek owner/lecturer sign-off |
| O-08 | Real event/club/reward data sources | Lab prohibits mock/hardcoded submitted build | Dev fixtures only, plan verified-source import |
| O-09 | Firebase project ID, billing approval for Storage/Functions | Real deployment | Emulator only until owner approves cloud changes |
| O-10 | Figma revisions (waitlist, coin values, rewards) | Design fidelity rubric | Maintain design deviations; don't edit Figma unrequested |
| O-11 | Lab 2 handoff tokens and component specs | Pixel accuracy | Need `design/DESIGN.md` + `handoff/flutter-handoff.md` |
| O-12 | Repo naming mismatch PRM323 vs PRM393 | Submission conventions | Preserve existing repo; ask lecturer before rename |
| O-13 | DEFERRED — student/faculty/club verification | Owner temporarily excluded this feature | No verified badges/filters; no client-forged verification or bypass of existing restricted events |
| O-14 | RESOLVED — Café price is 200 Coin; Figma content illustrative | One server record, no hard-coded UI values | 200 applies only to the Café voucher; real event/catalog data still needs sources under O-08 |
| O-15 | OUT OF SCOPE — ticket email/fixed reminders, feedback bonus, missions, seasonal targets, seats/VIP/tiers | Owner explicitly removed these business paths | No jobs/grants/inventory; Auth reset emails and required lab FCM remain in scope |
| O-16 | PARTIAL — minimum 3 distinct interests mandatory, no Skip; taxonomy/ranking/search boundaries OPEN | Onboarding/preference contract decided; query details still need design | Enforce complete/save minimum 3; do not infer taxonomy or ranking from prototype labels |
| O-17 | Voucher cashier authority, secret recovery/rotation, validity cutoff and physical pickup | One-time real voucher use | Server-only verifier data; no unrestricted mark-used API or extra Coin debit |

**Resolved (binding):** Follow requires authentication (Google or email/password);
no Waitlist; full closes registration and cancellation releases one place;
Daily 5/10/15/30/50/70/100, day8+100; monthly amount 200 (eligibility still OPEN);
Café voucher 200; at least 3 distinct interests mandatory; registered staff scans
student ticket, walk-in uses QR only; cancel forfeits deposit. Milestones and
FD-09/10 business paths removed; academic/club verification deferred.

## 3. Evidence log (fill with real run outcomes)

| Date | Stage | Branch / commit / PR | Test command | Actual result | Evidence link/path | Reviewed by |
|---|---|---|---|---|---|---|
| 2026-11-04 | Documentation handoff | none | none | Prepared docs only; no repo checks/tests/deploy | `CODEX_START_HERE.md`, `docs/PROJECT_CONTEXT.md`, `docs/DATABASE_DESIGN.md` | ChatGPT (document author) |
| 2026-11-04 | Firebase development baseline | `KietDM/feat/backend`, uncommitted config diff | See `docs/test-plan.md` | Project/app + empty Firestore + deny-all Rules created; APK build and emulator Core bootstrap PASS; foundation tests 12/12; full suite 76 pass / 5 fail | `evidence/firebase-setup/`, `docs/firebase-setup.md` | Codex local execution; no PR approval claimed |
| 2026-11-04 | Figma → database design review | `KietDM/feat/backend`, uncommitted docs | JSON/frame/traceability checks + `git diff --check`; no new Flutter run | Read 44 live frames / 1,342 visible texts, visually checked 6; schema v1.1, typed additions and 13 discrepancy records; no cloud writes | `docs/database-figma-review.md`, `evidence/figma-database/` | Codex read-only Figma + local documentation; not backend test evidence |
| 2026-11-04 | Owner decisions after Figma review | Uncommitted docs only | Document consistency + `git diff --check`; no app/backend tests rerun | Schema v1.2 records revised scope, min interests, Café price, reopened capacity and removed features. No runtime/cloud implementation claimed | `docs/PROJECT_CONTEXT.md`, `docs/DATABASE_DESIGN.md`, `docs/database-figma-review.md` | User decisions in this chat, recorded by Codex |

## 4. Review checklist after every Codex PR

- [ ] Does the PR keep Google Sign-In and support the owner-added email/password paths, require auth before Follow, and allow guest public browsing?
- [ ] Does it avoid any Waitlist implementation and treat `EVENT_FULL` as a no-side-effect failure?
- [ ] Are all Coin changes trusted server-side, idempotent, atomic and ledger-backed?
- [ ] Does it use exactly the confirmed Daily reward schedule and +200 monthly amount (without inventing eligibility)?
- [ ] Does it separate staff-scanned registered QR from student-scanned walk-in QR?
- [ ] Are Firestore/Storage rules least-privileged and tested against cross-user access?
- [ ] Is no private key, service account, access token or student data in a commit/screenshot/log?
- [ ] Are the changed files documented and tests shown with exact commands and logs?
- [ ] Are errors (offline, insufficient funds, no results, already redeemed/check-in, cancelled sign-in) visible and recoverable?
- [ ] Are all new deviations from Figma documented and approved before claiming UI fidelity?

## 5. User-facing progress report template

```markdown
**EVIA — tiến độ cập nhật [YYYY-MM-DD]**
Đã xác minh hoàn thành: [mốc + evidence link]
Đang thực hiện: [mốc + chủ nhiệm/PR]
Bị chặn: [chính sách/quyền truy cập + người cần quyết định]
Kiểm thử: [số case thật + logs; không suy đoán]
Bước kế tiếp: [nhiệm vụ nhỏ nhất, điều kiện bắt đầu]
```

**Reminder:** Documentation completeness is not equivalent to implementation completeness. Do not change `TODO` to `VERIFIED` based on prose alone.

## 6. Backend-only delivery — 2026-11-04

Working-tree implementation, no commit/PR or cloud sign-off claimed.
See [backend API and integration](backend-integration.md). Existing Flutter/UI
work and its earlier failures were not changed or re-tested in this task.

| Area | Current evidence boundary |
|---|---|
| S3/S5/S6/S7/S9/S10/S12 core | Implemented locally with Emulator transactions, race/idempotency and authorization tests |
| S4 Auth | Callable Auth transport + email/password Emulator signup/account init tested; native Google/email UI integration pending |
| S8 walk-in | Server QR issuer/verifier tested; camera/staff UI not implemented here |
| S13 Storage | Own PDF create/read + cross-user/type/size/overwrite denial tested locally; app export/progress and cloud bucket pending |
| S14 notifications | Inbox/token registration/reassignment implemented; FCM trigger prepared, device push not tested |
| S11 / FD-12 | Monthly grants/cashier blocked by unapproved policy; no fake success |
| Catalog/cloud | Approved data/interest taxonomy not supplied; importer dry-run/create-only; billing checked disabled in `evidence/backend/cloud-status.json` |
| S15/S17/S18/S19 | App instrumentation, E2E, rubric AI review, report/video outside backend delivery |

Commands/results: `docs/test-plan.md` and `evidence/backend/`. Npm audit has
moderate transitive findings; see audit JSON. No production-safety claim.

Live development Auth update: owner logged into Firebase Console, then Firebase
Auth initialized and Google/email-password enabled (API + screenshot evidence).
Debug signing SHA-1/SHA-256 registered; FlutterFire config regenerated. No real
user account/test login, cloud Functions/Storage deployment or billing linkage.

Validation cuối backend: `npm --prefix functions run test:emulator` **20/20 PASS**
(log `evidence/backend/emulator-tests.log`); Android config build debug **PASS**
(`evidence/backend/flutter-build-apk.log`). `git diff --check` đạt; no new UI diff.

## Chốt migration project nhóm — 04/11/2026

User yêu cầu dùng `prm393-31822` có Blaze. Đã deploy 32 Functions, release Rules
Firestore/Storage, kiểm tra 14 indexes READY; 32 latest Cloud Run revisions ready.
4 Callable HTTP checks + 3 Firestore public/private checks đạt, không ghi test data.
APK debug + Pixel 5 Core startup đạt; 20 backend tests chạy lại đạt.
Bằng chứng `evidence/firebase-migration/`, hướng dẫn `firebase-migration.md`;
working-tree delivery, chưa commit/PR. Backend cloud setup hoàn tất, mobile UI
services/push/login/data/E2E và các policy OPEN vẫn chưa hoàn tất.
