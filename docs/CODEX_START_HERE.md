# CODEX — START HERE: EVIA LAB 3

> **Release mới nhất 04/11/2026:** 34 Functions ACTIVE cùng hash source, 34 Cloud Run latest revisions READY; 2 Scheduler jobs ENABLED, timezone/IAM/target đã kiểm tra. [Release evidence](backend-release.md). Ghi chú 32 Functions hoặc local-only phía dưới là lịch sử trước release; UI/data/instrumentation vẫn pending.

> **Latest local readiness (04/11/2026):** read [BACKEND_POLICIES.md](BACKEND_POLICIES.md), [FRONTEND_HANDOFF.md](FRONTEND_HANDOFF.md) and [DATA_READINESS.md](DATA_READINESS.md). Owner has resolved monthly/no-show/re-registration/admin voucher policy. Local 34-export backend passes 31 Emulator tests; new jobs/admin changes NOT deployed. Historical 20-test/policy-blocked notes below describe the earlier revision. No approved real catalog exists. Flutter/UI remains owned by the other team.

> **Project hiện tại:** `prm393-31822` (evia, Blaze), theo yêu cầu chuyển của người dùng.
> App đã chuyển bằng FlutterFire; 32 Functions + Rules đã deploy, 14 indexes READY.
> API smoke cloud + 20 Emulator tests + APK/startup Core đạt; [evidence](firebase-migration.md).
> UI, Google login/push thật và dữ liệu catalog chưa tích hợp.
> Các mục về `evia-lab3-kiet-2026` bên dưới là lịch sử, không phải project để deploy tiếp.



> Backend execution update 04/11/2026: user explicitly requested implementation
> without UI changes. `functions/` now implements the core backend, with 20/20
> Emulator tests passing in the working tree. Signup bonus is 200 once per UID;
> Daily uses Asia/Ho_Chi_Minh. Read [API v1](backend-integration.md) before
> integrating. Original iteration/PR plan below is historical, not a request to
> restart audit or hold already-authorized work. Cloud Functions/Storage still
> require billing approval; existing code is not a deployed production backend.


> **Purpose:** task handoff to Codex; this file is **not an implementation report**.

> **Owner update 2026-11-04:** read PROJECT_CONTEXT v1.3 / DATABASE_DESIGN v1.3
> before using older handoff/prototype text. Authentication now includes Google
> and email/password sign-up/sign-in/reset; minimum 3 distinct interests is required.
> Café voucher is 200 Coin; Figma data is illustrative. No milestones, manual
> walk-in codes, FD-09 extra business paths or FD-10 seat/tier inventory.
> Student/club verification is deferred; FD-12 cashier flow remains OPEN.
> **Target repo:** https://github.com/dong-nnp/prm323-lab3-camply (existing repository; old `camply` name in URL, product is now **Evia**). This repo was **not accessible to ChatGPT via its current GitHub connection**. You (Codex) must verify your own permissions. **Do not create a new repository, rename the existing one, or force-push.**

## Role split

- **Codex**: inspect existing source, implement, run tests, produce diffs and evidence, maintain progress tracker.
- **ChatGPT**: write/review product, architecture and database specifications; audit Codex deliverables and progress. It is **not** expected to edit/deploy the Firebase project.

## Documents to read in order

1. [`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md) — **highest-priority source of confirmed product decisions** and still-open policies.
2. [`docs/DATABASE_DESIGN.md`](docs/DATABASE_DESIGN.md) — database schema, Rules, transaction contracts, QR security and acceptance tests.
3. [`docs/IMPLEMENTATION_TRACKER.md`](docs/IMPLEMENTATION_TRACKER.md) — current status and evidence checklist (starts unverified).
4. `reference/Evia_3_User_Flows_Updated.docx` — retains student-authored Flow 1 step 05 Google Sign-In → step 07 Follow; **correct reward schedule** in this handoff.
5. `reference/architecture.md`, `reference/design-traceability.md`, `reference/business-rules-decision-proposal.md` — background and Figma mapping. Some **OPEN** proposals exist; they are not approvals.

## Task for your first iteration (do this first, not code blindly)

1. Verify access to the **existing** GitHub repo and inspect the current default branch, project tree, Flutter/Dart version, Firebase config, `functions`, `android`, `pubspec.yaml`, Rules, existing migrations/seeds/tests, and commit history. Check if Firebase project IDs already exist; **do not print secrets**.
2. Produce an **as-is vs target gap report** mapped to the current `DATABASE_DESIGN.md` sections. If you find a working schema, **extend and migrate it**; don't replace the database or destroy working users/transactions.
3. Identify the **smallest first PR**: recommend Firestore model + Security Rules + Emulator Suite tests as a foundation, then transactions and callables in later PRs.
4. Add/update `docs/IMPLEMENTATION_TRACKER.md` with actual repo findings, file paths, blockers and evidence. Make an initial documentation commit/PR without inventing results.
5. Explain any remaining policy ambiguities and **block sensitive live features** pending explicit owner decision (monthly eligibility/scheduling, no-show, same-user re-register, QR rotation mode and cashier authority). Do not reintroduce owner-removed milestones as an OPEN feature.

## Work after the as-is audit (in small reviewable PRs)

- PR-1: Firebase dev/emulator setup, Firestore Rules + indexes + security tests.
- PR-2: account initialization and one-time signup bonus (200 Coin confirmed); public events/organizers + signed-in Follow/Bookmark.
- PR-3: registration capacity/deposit/cancel, no Waitlist, tickets, QR verification; staff-scoped verifier.
- PR-4: wallet/ledger, Daily Check-in (5/10/15/30/50/70/100; day 8+100), monthly data contract (**grant disabled until owner policy confirmation**).
- PR-5: reward catalog/stock, redemption/voucher, concurrent redemption tests.
- PR-6: connect Flutter UI to data; six Firebase lab services, ARTEMIS plan/results, evidence. Adapt PR scope to repo reality.

## Non-negotiable acceptance criteria

- Product name **Evia**, currency **Evia Coin**; authentication (Google or email/password) before Follow club. Follow is **optional**; keep the original Google flow supported.
- **No Waitlist**: full closes registration, committed cancellation releases one place; no waitlist collection/endpoint or automatic queue promotion.
- Authenticated staff scans a **registered student's QR ticket**; signed-in student scans **walk-in organizer's QR**.
- All wallet, rewards, attendance and registration-money mutations are server-authorized, transaction-safe, idempotent and tested. Client cannot directly write wallet or ledger.
- All user-owned data blocked cross-UID; public listing constrained to published/public data; no secrets in Git.
- Tests must demonstrate actual results; **do not claim successful compile, deployed Cloud Functions, working Firebase or a completed flow without logs/screenshots and a commit SHA**.
- Do not enable Blaze billing, deploy to production, bulk delete/write user data, or use personal Google accounts in tests without explicit owner approval.

## Required status report after each PR

Reply in this shape:

```markdown
### EVIA PR / milestone update
- Repository + branch:
- Commit SHA / PR URL:
- Implemented (actual files):
- Tests run (exact commands + pass/fail + logs/evidence):
- Firestore / rules / indexes verified in emulator? [yes/no + evidence]
- Any live Firebase deployment? [NO by default; project ID + approval if yes]
- User-confirmed rules respected: [Follow auth, no Waitlist, reward table, monthly amount]
- Open risks or business questions:
- Next smallest implementation milestone:
```

When this report is shared with ChatGPT, it will be reviewed against `docs/PROJECT_CONTEXT.md` and `docs/DATABASE_DESIGN.md` and the tracker will be updated honestly.

## One-message instruction to paste into Codex

The original snippet below retains the student's Google path. Apply the current
owner update above as well: email/password is also supported, minimum 3 interests
is mandatory, Café is 200 Coin, and removed features must not be implemented.

> Tôi giao bạn triển khai Evia Lab 3 tại repository hiện có `https://github.com/dong-nnp/prm323-lab3-camply`. Trước khi sửa mã, hãy đọc toàn bộ `CODEX_START_HERE.md`, `docs/PROJECT_CONTEXT.md`, `docs/DATABASE_DESIGN.md`, `docs/IMPLEMENTATION_TRACKER.md` và tài liệu trong `reference/`. Bắt đầu bằng kiểm kê repo hiện tại và lập báo cáo as-is/gap so với schema. Tuyệt đối không tạo repo mới, không ghi đè dữ liệu thật, không triển khai production hoặc bật billing khi chưa được chấp thuận. Luồng 1: Guest xem sự kiện, Google Sign-In trước Follow CLB, Follow tùy chọn; không có Waitlist. Daily Coin lần lượt 5,10,15,30,50,70,100, ngày 8+ 100/ngày; quà tháng 200 nhưng eligibility/schedule còn OPEN. Dùng Firebase Auth/Firestore/Cloud Functions với Rules và emulator tests, giao dịch xu atomic/idempotent. Mỗi PR gửi SHA, file đã sửa, lệnh test và evidence; cập nhật `docs/IMPLEMENTATION_TRACKER.md`. Trước hết chỉ thực hiện repo audit và đề xuất PR nhỏ nhất, chưa triển khai database lên cloud.
