# EVIA — PROJECT CONTEXT / SOURCE OF TRUTH FOR CODEX

> **Release mới nhất 04/11/2026:** 34 Functions ACTIVE cùng hash source, 34 Cloud Run latest revisions READY; 2 Scheduler jobs ENABLED, timezone/IAM/target đã kiểm tra. [Release evidence](backend-release.md). Ghi chú 32 Functions hoặc local-only phía dưới là lịch sử trước release; UI/data/instrumentation vẫn pending.

> **Project hiện tại:** `prm393-31822` (evia, Blaze), theo yêu cầu chuyển của người dùng.
> App đã chuyển bằng FlutterFire; 32 Functions + Rules đã deploy, 14 indexes READY.
> API smoke cloud + 20 Emulator tests + APK/startup Core đạt; [evidence](firebase-migration.md).
> UI, Google login/push thật và dữ liệu catalog chưa tích hợp.
> Các mục về `evia-lab3-kiet-2026` bên dưới là lịch sử, không phải project để deploy tiếp.


**Project:** Evia — Campus Event App, PRM393 Lab 3  
**Document version:** 1.4 · 2026-11-04 · **Mode:** backend deployed to team project prm393-31822; Flutter integration pending  
**Target:** Flutter Android + Firebase · **Repository to inspect:** https://github.com/dong-nnp/prm323-lab3-camply  
**Owner of execution:** Codex / developer. **ChatGPT role:** product analyst, technical documentation, architecture review, progress/evidence audit.  
**Current execution:** local repository inspected and backend added in `functions/`; see [integration contract](backend-integration.md) and `evidence/backend/`. Earlier GitHub 404 was a handoff observation, not the state of local access. No replacement repository was created. Flutter UI is outside this backend task.

> **Latest local policy update:** [BACKEND_POLICIES.md](BACKEND_POLICIES.md) records the owner decisions in this chat. New jobs/admin voucher code is tested locally, not part of the previous 32-function cloud deployment.

## 1. Mandatory reading order and conflict resolution

1. **Confirmed owner decisions in this document** (sections 2–4) override older illustrations, Figma sample numbers, or previous ChatGPT-generated text.
2. `reference/Evia_3_User_Flows_Updated.docx`: **student-authored Flow 1 ordering**, with the approved updated rewards copied from the prior ZIP. **Google Sign-In at step 05 precedes Follow CLB at step 07**. Follow is optional, not registration prerequisite.
3. `reference/design-traceability.md`: inventory of **44 frames** on the single Figma page, planned route/widget/data mapping, and gaps. This is a planning artifact, not proof that routes exist.
4. `reference/architecture.md`: existing MVVM + Riverpod proposal and target infrastructure; treat its **OPEN/proposed** policies as nonbinding until signed off. If it conflicts with a confirmed owner decision, use this context and record the change.
5. `reference/business-rules-decision-proposal.md`: decision proposals P-01…P-12; **not all accepted**. D-01/D-02/D-03 and explicit owner confirmations are binding.
6. Original PRM393 Lab 3 handout and Preparation Guide; keep academic requirements and evidence requirements intact.
7. Figma: https://www.figma.com/design/JQtHz2tigJtvvjVBsx03kx/Campus-Event-App--Copy-?node-id=2083-272 (page `2083:272`, name `màn hình cuối`). Do not silently alter designs; record deviations.

**Important source hazard:** a separate, later-remounted `.docx` in an earlier conversation had **old +50…+400 Daily / +500 Monthly** despite the updated ZIP. The copy in this handoff is extracted from the **updated ZIP** and retains the student's Flow 1 order. If Codex sees conflicting copies, **use the explicit values below** and report the mismatch rather than reverting them.

### Owner clarification — 2026-11-04, after Figma review

- All names, dates, locations, balances, rewards and other screen content in Figma
  are illustrative UI content, not real data to hard-code or automatically seed.
  Explicitly confirmed policies below take precedence over those samples.
- No Waitlist. A limited event closes registration when all tickets are allocated;
  a successfully cancelled registration releases one place for a new registration.
  Example capacity 100 is illustrative, not a global default. Re-entry by the same
  cancelled user remains a separate undecided policy.
- Daily rewards remain `[5,10,15,30,50,70,100]`, then 100/day from day 8 onward. Owner confirmed **Asia/Ho_Chi_Minh** calendar days and **200 Coin once per new UID** in the latest reply.
- The Café voucher discussed in FD-04 costs **200 Coin**. This applies to that
  reward, not every catalog item, and belongs in server data rather than UI constants.
- Authentication scope expands beyond Google to the email/password sign-up,
  sign-in and password-reset paths shown in FD-07. Google Sign-In is still required
  for the lab. Firebase Auth owns credentials; never store passwords in Firestore.
- FD-08 academic/club verification is **deferred**, not approved or implemented.
  Do not show a real verified badge or activate verified-eligibility filters.
- FD-09 ticket delivery emails, 2–3-day attendance reminders, feedback bonus,
  missions and seasonal attendance targets are **out of scope**, not pending jobs.
  This does not remove Firebase Auth password-reset emails or required lab FCM.
- FD-10 assigned seating/VIP/multiple ticket tiers are **out of scope**. Capacity
  is a ticket count, not a map of seats.
- FD-13 requires **at least 3 distinct interests** to complete/save authenticated
  onboarding/preferences. No Skip for that step; guest public browsing remains.
- FD-06 will be corrected by the design team; no Figma edit was performed here.
- FD-03 milestones are **removed entirely**, including progress, claims and bonus
  Coin. FD-11 is **QR-only** for now: no manual-code entry; contact staff on scan
  failure. FD-12 mới chốt admin xác nhận voucher tại nhà tài trợ; xem BACKEND_POLICIES.md.

## 2. Product and scope

Evia helps students **discover campus events**, **participate and check in**, **earn Evia Coin**, and **exchange coins for rewards**. A separate full Web Admin (event/reward/notification management) is **out of scope for Lab 3**. Build the mobile app and the **minimum controlled backend/operator verifier** needed to test student flows, without expanding to a full administrative site.

### Flow 1 — Explore, follow clubs, register

1. Guest opens Evia and **can view public events and public organizer profiles without signing in**.
2. Search/filter events by relevant categories, time and location; view results and event About/Schedule/Location details.
3. **Authentication is required for account-bound actions** (including **Follow/Unfollow a club**, Bookmark/save, registration, wallet access). Support Google and email/password under the clarified scope; handle cancel/failure and **return to original screen/action context** on success. The student-authored Google path remains valid.
4. Interests onboarding after sign-in **if not yet completed**; at least 3 distinct valid interests are mandatory, including on preference updates. Do not mark onboarding complete with fewer selections or via Skip.
5. **Follow club is OPTIONAL** and is NOT a prerequisite for registering for an event. The numbered student design has Google Sign-In at **05**, interests at **06**, Follow at **07**. Conceptually Follow is an independent branch from Organizer Profile; keep the documented ordering without forcing it as a mandatory step.
6. Followed organizers appear in Following Organizers, Their Events and `From Your Following` on Discover; Unfollow removes them. Following/Bookmark ≠ Registration ≠ Verified Attendance.
7. Confirm registration (after authentication), verify event capacity and optional coin deposit, then show success, My Events and a QR ticket for events requiring registration. **No waitlist.** Full events reject new registrations; successful cancellation reopens the released place. Competing requests for that place must still be serialized safely.

### Flow 2 — Participate and earn coins

- **Registered event:** event-specific **deposit**, illustration **50 Coin**. The student displays **personal ticket QR**; the **organizer/staff scans it**, with event-scoped authenticated verification via backend. A successful *verified* check-in refunds the held deposit and separately awards the configured event reward (illustration **+200 Coin**), e.g. available +250 from this moment; no double credit.
- **Walk-in event:** student attends without preregistration, scans the **organizer's QR displayed at the venue** using Evia. Backend verifies event, check-in window, user, token and uniqueness; awards the event-specific reward only once. An `I'm Going` intent does not grant coins or reserve a slot.
- **Cancel a registered event:** forfeits the held deposit (owner-confirmed in the user-authored flow), revokes ticket, gives no attendance reward. **No-show forfeits held deposit** after event/check-in close; **re-registration is allowed while capacity remains**, with a new ticket and a new deposit. Owner confirmed in current chat; local implementation pending cloud deployment.
- **Daily Check-in:** per consecutive local day, **day 1–7** grants `[5, 10, 15, 30, 50, 70, 100]` Coin; **day 8 and later +100 Coin/day** while maintaining streak. Once per day per user. After missing a day, the next check-in restarts at day 1 (+5); previously earned coins remain.
- **Monthly Gift:** **+200 Coin** per eligible month, **at most once per UID/month**. Owner confirmed automatic credit for all user accounts on day 1 monthly. Local scheduler uses 00:00 Asia/Ho_Chi_Minh; accounts initialized after the cutoff start next month. No onboarding requirement for the job. See [policy/job details](BACKEND_POLICIES.md); not deployed yet.
- **New account bonus:** owner confirmed **200 Coin**, exactly once per UID on first account initialization. Atomic user + wallet + append-only signup ledger in `functions/src/accounts.ts`; no client-controlled grant amount.
- **Event Milestones:** removed by the owner after Figma review. No milestone
  screen/claims/progress model or milestone Coin grants in the target app/backend.
  Verified attendance still exists for event check-in and its event-specific reward.

### Flow 3 — Wallet, redemption, My Rewards

- User sees **available** and **held/in-deposits** amounts separately and an immutable transaction history.
- Catalogue of rewards is read from Firestore (price, stock, conditions, validity); choose an item, confirm cost, redeem **available coins only**; get redemption result and voucher/QR (or physical redemption instruction) in My Rewards.
- Validate stock, price and balance **at transaction time on the server**. A double-tap, network timeout or retry cannot create two rewards or deduct twice.
- The Café voucher from FD-04 has owner-confirmed price **200 Coin**. Other reward
  prices, stock and event data come from their real server records, not Figma samples.

## 3. Binding decisions versus OPEN items

| Topic | Status | Required behavior |
|---|---|---|
| App identity | **CONFIRMED** | Evia, Evia Coin (not Camply). |
| Guest mode | **CONFIRMED** | Public event discovery/detail; auth required for protected actions. |
| Follow CLB | **CONFIRMED** | Only signed-in users can Follow; Google or email/password; optional branch. |
| Authentication methods | **CONFIRMED EXPANDED** | Google plus email/password sign-up, sign-in and password reset; credentials stay in Firebase Auth. |
| Waitlist / capacity | **CONFIRMED** | No queue. Full closes registration; a committed cancellation releases capacity for a new registration. |
| Café voucher | **CONFIRMED** | 200 Coin, stored in reward data; not a global price for all rewards. |
| Figma sample values | **ILLUSTRATIVE** | Do not hard-code/seed screen content as real business data. |
| Interests | **CONFIRMED** | Minimum 3 distinct valid interests to complete/save; no onboarding Skip. |
| Student/club verification | **DEFERRED** | No real verified badges or verified-eligibility feature in the current phase. |
| FD-09 extra business paths | **OUT OF SCOPE** | No ticket-email delivery, fixed 2–3-day reminders, feedback Coin bonus, missions or seasonal targets. Required FCM/Auth emails are separate. |
| Assigned seats / VIP | **OUT OF SCOPE** | General admission capacity only; no row/seat inventory or tiers. |
| QR ownership | **CONFIRMED** | Staff scans registered ticket; student scans walk-in event QR. |
| Daily rewards | **CONFIRMED** | 5/10/15/30/50/70/100; day 8+100; reset after missed day; Asia/Ho_Chi_Minh calendar. |
| Monthly gift amount | **CONFIRMED** | 200 per eligible month, at most once. |
| Cancellation deposit | **CONFIRMED FOR CANCEL** | Forfeit held deposit, no refund, revoke ticket. |
| Bonus on first account | **CONFIRMED** | 200 Coin once per UID, server-owned policy. |
| Event deposit/reward values | **ILLUSTRATIVE** | 50 deposit and 200 attendance reward are examples; define per-event server-side. |
| No-show handling | **CONFIRMED** | Held deposit forfeited after event/check-in end, no available debit. Local hourly job, not deployed. |
| Re-register after cancel | **CONFIRMED** | Allowed if slot still available and registration open; new requestId/ticket/deposit; retain history. |
| Monthly eligibility/schedule | **CONFIRMED** | All initialized app accounts at month cutoff, +200 automatically on day 1, Asia/Ho_Chi_Minh. Local only until deployment. |
| Voucher use authority | **CONFIRMED** | Voucher at sponsor, authorized admin marks used once. No separate café cashier UI in this task. |
| Event Milestones | **REMOVED** | No milestone feature, progress, claims or extra Coin awards. |
| Walk-in manual entry | **REMOVED FOR NOW** | QR only; no Enter code endpoint/UI; contact staff if scanning fails. |
| Walk-in QR rotation strategy | **OPEN technical design** | Implement a secure demo approach with documented threat model; get approval before claiming real-world anti-fraud. |
| Operator-side ticket verifier | **NEEDED FOR DEMO** | Minimal event-scoped authenticated tooling, not full admin; security cannot be bypassed. |
| Flutter vs Figma fidelity | **GAP** | 44 Figma frames, errors and variants; record divergences, seek approval to update Figma. |

## 4. Lab 3 engineering constraints and evidence

- **UI:** every Lab 2 Final UI screen (>=8) and all 3 flows end-to-end (including alternative and error/recovery paths); real source data; export at least one generated file and upload to cloud.
- **Architecture:** Flutter MVVM + Riverpod (or Provider, but target Riverpod), strictly one-directional dependencies; no Firebase/HTTP SDK calls directly from widgets. Explicit `loading/empty/error/data` states; injected interfaces and fake services.
- **Design system:** `ThemeData(ColorScheme, TextTheme, named spacing/radius/elevation)`, reusable Lab 2 component widgets/states, accessibility >=48dp tap target, >=14sp body text, 360/412dp checks. `design/DESIGN.md` and `handoff/flutter-handoff.md` **not provided**; cannot claim pixel-perfect handoff implementation yet.
- **Six graded Firebase services:** Authentication (Google), Cloud Storage, Cloud Messaging, Analytics, Crashlytics, Remote Config. Cloud Firestore supports real data but is not a substitute for any of the six. Build failure UX and capture console evidence for each.
- **Analytics:** `docs/analytics-plan.md` before instrumentation, >=7 product events with trigger, typed parameters, product question; no names/emails in event parameters; DebugView evidence.
- **E2E:** Google **ARTEMIS** (not Flutter integration tests alone), >=10 pytest cases, each run >=3 times, structured assertions beyond `SUCCESS`, native interaction, an error-path test, analytics confirmation, 15–30 minute Pro exploratory session and traces.
- **AI Review:** PR-focused AI code review with >=5 file:line findings across >=2 categories, justified decisions, >=3 fixes in linked commits. Disclose AI tools (including ChatGPT/Codex).
- **Submission:** accessible GitHub repo, final report 8–12 pages PDF, slides 12–15 PDF slides, demo 5–10 minutes, verifiable screenshots/logs.
- **Versioning:** Pin Flutter/FlutterFire/ARTEMIS versions after running tools, never fabricate pass rates or console proof. Preserve incremental Git commits.
- **Firebase cost:** Cloud Storage and deployed Cloud Functions may require **Blaze billing**, with budget/usage controls. Do not turn on billing, deploy live services, import real personal data or incur costs without owner authorization.

## 5. Delivery responsibilities

### Codex — implement and prove

1. Inspect `dong-nnp/prm323-lab3-camply`: branches, existing features and existing Firebase project config. **Do not force-push, rename or replace repo**; commit in a feature branch/PR where possible.
2. First provide an **as-is inventory** compared to this document and `docs/DATABASE_DESIGN.md` before touching data.
3. Implement/verify Firestore schema, Rules, indexes, controlled sample seeding, emulator tests, transaction-safe Cloud Functions and code interfaces consistent with current codebase. Scope each PR with a small reviewable goal.
4. Do **not** mutate production datasets, create billing resources or expose private keys without explicit consent.
5. After each milestone, update `docs/IMPLEMENTATION_TRACKER.md` with commit/PR, test command/output, evidence links, blockers and next step. Unverified work remains **NOT VERIFIED**.

### ChatGPT — product/architecture oversight

- Validate Codex's plan and diffs against user decisions, security/data model, Figma traceability and Lab 3 rubric; maintain open-decision registry and track progress.
- Do not claim builds/tests/deploys have passed without logs and evidence. No direct repo edits or Firebase deployment are required for this handoff.

## 6. Proposed implementation ordering (not an execution claim)

1. Repo audit + local toolchain check → agree on actual source tree and Flutter/Firebase project IDs.
2. Security model + Firestore Rules and emulator tests → deploy to a **separate dev project** only after approval.
3. Auth bootstrap & one-time account grant contract → guest public reads → Following/bookmarks.
4. Registration/capacity/deposit/ticket → registered QR verifier → walk-in QR attendance.
5. Wallet/ledger + daily claim → monthly automatic grant (local scheduler; deploy separately) → reward stock/redemption/vouchers.
6. Storage export + messaging + Analytics/Crashlytics/Remote Config and demo area; real screenshots.
7. ARTEMIS, AI review, report/slides/video and evidence audit.

**Next file:** [`DATABASE_DESIGN.md`](./DATABASE_DESIGN.md) for field-level schema, security rules policy, transactions, API contracts and acceptance tests.
