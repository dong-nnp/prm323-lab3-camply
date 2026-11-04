# EVIA — FIRESTORE DATABASE DESIGN & BACKEND CONTRACT (FOR CODEX)

> **Project hiện tại:** `prm393-31822` (evia, Blaze), theo yêu cầu chuyển của người dùng.
> App đã chuyển bằng FlutterFire; 32 Functions + Rules đã deploy, 14 indexes READY.
> API smoke cloud + 20 Emulator tests + APK/startup Core đạt; [evidence](firebase-migration.md).
> UI, Google login/push thật và dữ liệu catalog chưa tích hợp.
> Các mục về `evia-lab3-kiet-2026` bên dưới là lịch sử, không phải project để deploy tiếp.


**Version:** 1.4 · **Date:** 2026-11-04 · **Status:** core backend in `functions/` deployed to team project `prm393-31822`; Rules/indexes cloud checks pass. Database has no seeded business records; Flutter adapters pending. Actual API v1: [backend-integration.md](backend-integration.md); proposed signatures below describe design intent, not deployed endpoints.  
**Scope:** Firebase Cloud Firestore + security/index/transaction/API plan supporting Evia Mobile PRM393 Lab 3. Full Web Admin postponed.  
**Read first:** [`PROJECT_CONTEXT.md`](./PROJECT_CONTEXT.md). **Never treat examples or OPEN policies as binding.**

**Live Figma review:** [database-figma-review.md](database-figma-review.md) maps all
44 final-page frames to data requirements. Section 1.3 defines the added field
contracts. The earlier Figma review was documentation only. Current implementation is local backend code; no cloud migration, production seed or business deployment was performed.

## Cập nhật policy v1.4 — local, chưa deploy

[BACKEND_POLICIES.md](BACKEND_POLICIES.md) là hợp đồng mới nhất cho Monthly Gift tự động, no-show mất cọc, đăng ký lại và admin xác nhận voucher ở nhà tài trợ. Nó thay thế mọi ghi chú OPEN/disabled về bốn mục này trong thiết kế v1.3 bên dưới. Cấu trúc thực tế: thêm `voucher_admins/{uid}` server-only, `registrations/{id}/history/{oldTicketId}` server-only; state `no_show`, redemption `used`; ledger `monthly_gift`/`no_show_forfeit`; monthly record có scheduledAt/grantedAt/policyVersion. Không dùng các chữ ký đề xuất bên dưới thay cho [API thực tế](backend-integration.md). Cloud vẫn là revision cũ cho đến deploy riêng.

## 0. Design goals and hard limits

- Firestore is the source of truth for Evia users, organizers, events, registrations, tickets, attendance, wallet, rewards, notifications. **Server-side Cloud Functions / Admin SDK controls every monetary mutation and validated attendance.**
- **No Waitlist** anywhere in schema, API, registration states, user flow or tests. At capacity, return `EVENT_FULL` with **zero** wallet/ticket/counter changes.
- A committed cancellation revokes its ticket, settles the held deposit and
  decrements the occupied registration count **once in the same transaction**.
  It reopens one place; concurrent registrations still compete atomically. A
  failed/repeated cancellation releases no additional place. Capacity 100 is an
  example, not a default. Same-user re-registration after cancel is now allowed if capacity remains; issue a new ticket and archive the cancelled attempt.
- Guest may read **public/published** organizers/events; **Follow/Unfollow, Register, Bookmark, Wallet and rewards are account-bound**. Support Google and email/password sign-up/sign-in/reset. The original Google flow remains supported; Follow is optional.
- At least **3 distinct valid interest IDs** are required to complete/save
  authenticated onboarding/preferences. No onboarding Skip; guest browsing is unaffected.
- The Café voucher in FD-04 costs **200 Coin**, configured in its server reward
  record. No screen-level price constant; all other Figma values remain illustrative.
- No milestones, feedback Coin bonus, missions, seasonal targets, assigned seats,
  VIP/ticket tiers, ticket-email delivery or fixed 2–3-day attendance reminder jobs.
  Walk-in accepts QR scans only; no manual-code fallback in the current scope.
- **Daily Coin grants:** `day 1…7 = [5,10,15,30,50,70,100]`, `day 8+ = 100/day`; missed calendar day resets next claim to day 1. **Monthly amount = 200 Coin**, at most once per eligible month, automatically on day 1 for initialized accounts at the Vietnam month cutoff; see v1.4 policy.
- New-account Coin is **once per UID**; **200 is owner-confirmed**, once per new UID. Registration deposit **50** and attendance reward **200** in diagrams are **event-level examples**, not global hard-coded business policy.
- No raw voucher secret, raw ticket token, service credential, staff key, registration email or student ID in public event docs, Firebase Analytics parameters, Git, README or screenshots.
- All business timestamps: server-produced **Firestore Timestamp** (UTC instant). When calculating reward **calendar day** use an explicit product timezone config; `Asia/Ho_Chi_Minh` is **owner-confirmed for Daily Check-in**; monthly also uses Asia/Ho_Chi_Minh under v1.4.
- Use integer Coin units (`int` / integer-valued Firestore Number); never use floating-point amounts or calculate wallet balances on the client.

## 1. Firestore collections — authoritative proposed paths

Symbols: `S` string, `B` bool, `N` integer Number, `T` Timestamp, `A<T>` array, `M` map, `?` optional, `null` explicit null when suitable. `uid` = Firebase Authentication UID. Public readable = `PUB` (published only); authenticated owner = `OWN`; server/authorized staff = `SVC`.

| Collection / document | Key fields and types | Reads | Writes | Role |
|---|---|---|---|---|
| `users/{uid}` | `displayName:S?`, `universityEmail:S?`, `studentId:S?`, `phoneNumber:S?`, `photoUrl:S?`, `interests:A<S>`, `onboardingCompleted:B`, `eligibility:M?` (deferred), `createdAt:T`, `updatedAt:T`, `accountStatus:S` | OWN | Server initializes protected fields; user edits allowlisted preferences/profile, never trusted eligibility | User + first-time setup; credentials only in Firebase Auth |
| `organizers/{organizerId}` | `name:S`, `description:S`, `tagline:S?`, `kind:S?`, `logoUrl:S?`, `tags:A<S>`, `followerCount:N`, `published:B`, `createdAt:T`, `updatedAt:T`, `sourceRef:S?` | PUB if `published=true` | SVC seed/future Admin; follower count only SVC | Clubs/university units |
| `events/{eventId}` | `organizerId:S`, `title:S`, `subtitle:S?`, `description:S`, `category:S`, `tags:A<S>`, `imageUrl:S?`, `status:S`, `visibility:S`, `startAt:T`, `endAt:T`, `timezone:S`, `doorsOpenAt:T?`, `checkInStartAt:T`, `checkInEndAt:T`, `venue:M`, `audience:M`, `benefits:A<M>`, `participantRequirements:A<S>`, `schedule:A<M>`, `scheduleNote:S?`, `featured:B`, `admissionNote:S?`, `registrationTerms:M?`, `participationMode:S`, `capacity:N?`, `registeredCount:N`, `depositCoins:N`, `attendanceRewardCoins:N`, `sourceRef:S`, `createdAt:T`, `updatedAt:T` | PUB if `status=published AND visibility=public` | SVC seed/future Admin; counters only SVC | Event discovery / slot control; nested contracts in 1.3 |
| `users/{uid}/following/{organizerId}` | `organizerId:S`, `createdAt:T` | OWN | Validated follow/unfollow callable only | Follow/Unfollow club, atomic with organizer follower count |
| `users/{uid}/bookmarks/{eventId}` | `eventId:S`, `createdAt:T` | OWN | Validated callable only | Saved Events (not registration) |
| `users/{uid}/event_intents/{eventId}` | `eventId:S`, `createdAt:T` | OWN | Authenticated owner via validated callable | Walk-in Going: schedule intent only, no seat/ticket/deposit/reward |
| `registrations/{registrationId}` | `uid:S`, `eventId:S`, `state:S`, `attendeeSnapshot:M`, `termsAcceptance:M`, `depositCoins:N`, `attendanceRewardCoinsSnapshot:N`, `ticketId:S?`, `registeredAt:T`, `cancelledAt:T?`, `attendedAt:T?`, `depositSettlement:S` | OWN; event-specific staff limited via callable | SVC only | Registration + deposits; private form snapshot |
| `tickets/{ticketId}` | `uid:S`, `eventId:S`, `registrationId:S`, `ticketNumber:S`, `status:S`, `issuedAt:T`, `revokedAt:T?`, `checkedInAt:T?`, `tokenVersion:N` | OWN metadata; authorized staff minimal via callable | SVC only | Personal QR ticket metadata; no seat/tier fields; display number is not a bearer secret |
| `attendance/{attendanceId}` | `uid:S`, `eventId:S`, `mode:S`, `registrationId:S?`, `verifiedAt:T`, `verifiedBy:S`, `verificationLocationLabel:S?`, `rewardCoinsGranted:N` | OWN; SVC/staff limited | SVC only | Exactly once verified attendance; gate label from trusted verifier |
| `wallets/{uid}` | `availableCoins:N`, `heldCoins:N`, `version:N`, `updatedAt:T` | OWN | SVC only | Materialized wallet balance |
| `wallets/{uid}/ledger/{ledgerId}` | `type:S`, `deltaAvailable:N`, `deltaHeld:N`, `sourceType:S`, `sourceId:S`, `operationKey:S`, `createdAt:T`, `metadata:M?` | OWN | SVC only, append-only | Auditable transaction history |
| `users/{uid}/daily_checkins/{dayKey}` | `localDate:S`, `streakDay:N`, `coinsGranted:N`, `createdAt:T`, `timezone:S`, `policyVersion:S` | OWN | SVC only | Daily exactly-once history |
| `users/{uid}/monthly_grants/{monthKey}` | `monthKey:S`, `coinsGranted:N`, `scheduledAt:T`, `grantedAt:T`, `policyVersion:S` | OWN | SVC scheduled transaction, local only until deploy | Monthly exactly-once history |
| `rewards/{rewardId}` | `title:S`, `description:S`, `category:S`, `priceCoins:N`, `stockRemaining:N`, `status:S`, `validDays:N?`, `usageLocations:A<S>`, `termsText:S`, `termsVersion:S`, `redemptionSteps:A<S>`, `fulfillmentType:S`, `redemptionInstructions:S?`, `imageUrl:S?`, `sourceRef:S?`, `updatedAt:T` | PUB/OWN as appropriate | SVC only | One authoritative price for catalog/detail/confirmation |
| `redemptions/{redemptionId}` | `uid:S`, `rewardId:S`, `priceCoinsSnapshot:N`, `rewardTitleSnapshot:S`, `rewardSnapshot:M`, `status:S`, `voucherId:S?`, `redeemedAt:T`, `expiresAt:T?` | OWN | SVC only | Historical result keeps original terms/fulfillment details |
| `vouchers/{voucherId}` | `uid:S`, `rewardId:S`, `redemptionId:S`, `status:S`, `expiresAt:T?`, `usedAt:T?`, `createdAt:T` | OWN **safe metadata only** | SVC only | No raw code or code hash in owner-readable document |
| `voucher_secrets/{voucherId}` | `code:S` (private owner-recovery secret), `codeHash:S`, `tokenVersion:N` | SVC only | SVC only | Private verifier data; owner gets usable code through authorized callable |
| `notifications/{notificationId}` | `uid:S`, `type:S`, `title:S`, `body:S`, `entityType:S?`, `entityId:S?`, `readAt:T?`, `createdAt:T` | OWN | SVC create; OWN only mark-read via allowlist or callable | Typed entity target mapped to allowlisted routes, not arbitrary URLs |
| `users/{uid}/devices/{installationId}` | `token:S`, `platform:S`, `updatedAt:T` | SVC only | Validated register/unregister callable | Private FCM delivery registration, not public profile data |
| `operation_receipts/{operationKey}` | `uid:S`, `kind:S`, `inputHash:S`, `result:M`, `status:S`, `createdAt:T` | SVC only | SVC only, immutable success | Global idempotency and reconcile |
| `checkin_tokens/{tokenId}` | `eventId:S`, `mode:S`, `tokenHash:S`, `validFrom:T`, `validUntil:T`, `revoked:B`, `issuedBy:S` | SVC only | SVC only | Ticket/venue QR token verification |
| `staff_assignments/{assignmentId}` | `staffUid:S`, `eventId:S`, `active:B`, `permissions:A<S>`, `createdAt:T` | SVC/staff scope via callable only | SVC only | Organizer-scanned ticket authority |
| `export_jobs/{jobId}` *(optional)* | `uid:S`, `reportType:S`, `storagePath:S`, `status:S`, `createdAt:T`, `finishedAt:T?` | OWN | SVC/owner allowlisted | Export audit if needed |

**No `waitlist`, `waitlisted`, `Join Waitlist`, `waitlistEnabled`, waitlist positions, or waitlist scheduler.** Figma contains old examples; log a design discrepancy rather than inventing a backend state.

### 1.1. Types, enums and constraints

| Object | Allowed values / invariant |
|---|---|
| `events.status` | `draft`, `published`, `cancelled`, `completed` |
| `events.visibility` | `public`, `private` |
| `events.participationMode` | `registration`, `walk_in` (only registered mode can require deposit/ticket) |
| `events.capacity` | `null` = unlimited, otherwise integer `>=0`; `0 <= registeredCount <= capacity` if limited |
| `events.depositCoins`, `attendanceRewardCoins` | integers `>=0`, server source of truth, per event |
| `registrations.state` | `registered`, `cancelled`, `attended`, `no_show` (no `waitlisted`; don't persist transient client loading as business state) |
| `registrations.depositSettlement` | `held`, `forfeited`, `refunded`, `none`; exactly one final settlement per registration |
| `tickets.status` | `active`, `checked_in`, `revoked`, `expired` |
| `attendance.mode` | `organizer_scanned_ticket`, `student_scanned_walkin` |
| `redemptions.status` | `issued`, `used`, `cancelled` *(cancellation policy OPEN; no user-cancel API)* |
| `vouchers.status` | `unused`, `used`, `expired`, `revoked` |
| `wallets.*Coins` | integer `>=0`; balance never trusts client-calculated amount |
| `ledger.type` | `signup_bonus`, `deposit_hold`, `deposit_refund`, `deposit_forfeit`, `event_reward`, `daily_checkin`, `monthly_gift`, `redeem_reward`; **no milestone, feedback or mission reward types** |
| `daily_checkins.streakDay` | integer `>=1`; store true day number, cap **only award amount** to day-7 award (100) |
| `notifications` | `readAt=null` until read; no client control over message payload |

### 1.2. Document ID strategy (prevent duplicates)

- `users/{uid}`, `wallets/{uid}`: UID from **Firebase Auth**, never user-provided email/student ID.
- `following/{organizerId}`, `bookmarks/{eventId}`: deterministic. Deleting and re-following can recreate a fresh timestamp; no Coin on Follow.
- `registrationId`: deterministic hash of `(uid,eventId)`, e.g. SHA-256 of unambiguous canonical encoding. Blocks multiple concurrent registrations by that user. Re-registration by the same cancelled UID is allowed; all users compete atomically for remaining capacity.
- `attendanceId`: deterministic hash of `(uid,eventId)` (**independent of scanner type and token**), so one person cannot earn twice for same event.
- `daily_checkins/{YYYY-MM-DD}` and `monthly_grants/{YYYY-MM}`: explicit local date/month keys (once for that UID/date or UID/month).
- `operation_receipts/{operationKey}` and ledger IDs: deterministic from business operation and UID/event/date/reward request. Do not create random receipt IDs for a retried operation.
- `redemptionId`: stable unique ID from `(uid,clientRequestId)` for the **same attempt**. Enforce reuse of the same requestId across retries, reject reusing it with a different reward/quantity.
- `checkin_tokens`: cryptographically strong random IDs/secret hashes or verifiable signed tokens; do **not** store a reusable raw token in a public Firestore document.

### 1.3. Field contracts confirmed necessary by the final-screen review

These are proposed storage/API shapes inferred from observed UI needs, not new
owner-approved business policies. See [44-frame evidence and conflicts](database-figma-review.md).

- **Authentication:** Firebase Auth handles Google and email/password account
  creation, sign-in and password-reset emails. No password/hash/reset token in
  Firestore, logs, Analytics or app domain models. The login email is an Auth
  identity; `universityEmail` remains a self-declared registration contact field,
  not proof of academic eligibility. Provider linking must not silently merge
  accounts or grant a second signup bonus. This is a design contract, not a claim
  that the existing Google-only service interface already implements email auth.
- **Interests:** validate at least 3 distinct IDs from the canonical interest
  vocabulary on complete/save. A new/incomplete account may have fewer while
  onboarding, but cannot set `onboardingCompleted=true` or save final preferences
  below 3. The UI must remove Skip from this step; no new business collection needed.
- **User identity (verification deferred by owner):** `phoneNumber` is optional, private, with format validated
  server-side. `eligibility` contains `verificationStatus:S`, `universityId:S?`,
  `facultyId:S?`, `memberOrganizerIds:A<S>`, `verifiedAt:T?`. Only a trusted server
  may write these fields. Google Sign-In, an entered student ID/email, or Follow
  does not establish university/faculty/club membership. The verification source
  is deferred. Do not implement verification workflows, claim Account verified,
  or activate verified-only filters in this phase. Reserved eligibility fields
  stay absent/unverified and protected from client writes. Do not silently admit
  unknown users to an existing verified-only event: keep such event publication
  outside the current scope until the verification feature is re-enabled.
- **Audience (verified restrictions deferred):** `{scope:S, hostUniversityId:S?, facultyIds:A<S>, organizerIds:A<S>}`;
  scope is `everyone`, `any_university`, `host_university`, `faculty`, or
  `club_members`. Require the relevant IDs for restricted scopes. `visibility`
  controls discovery; `audience` can describe the audience now. Enforcement that
  requires verified university/faculty/club membership is deferred, not bypassed.
  If later enabled, validate in backend registration/walk-in as well as the filter.
- **Event timing:** enforce `startAt < endAt` and `checkInStartAt < checkInEndAt`;
  `doorsOpenAt` is optional and distinct from admission/check-in windows. Event
  `timezone` is an explicit IANA identifier for display/calendar conversion; it
  is independent of the confirmed Asia/Ho_Chi_Minh Daily policy; monthly schedule is now day 1 Asia/Ho_Chi_Minh under v1.4.
- **Event details:** `benefits` is an ordered list of `{title:S, description:S}`;
  `schedule` is an ordered list of `{id:S, title:S, startAt:T, endAt:T?,
  description:S?, locationLabel:S?}`. Entries must be chronological and consistent
  with the published event program; doors/check-in items may precede `startAt`.
  `venue` is `{name:S, address:S?, entranceLabel:S?, latitude:Number?,
  longitude:Number?, checkInInstructions:S?, accessibilityNotes:S?, transitNotes:S?}`.
  Coordinates must be a valid pair with real provenance; no coordinates inferred
  from a decorative map. Generate/allowlist Maps links from validated coordinates
  or address. `admissionNote` is display content, not a payment implementation.
- **Discovery:** `category` and interest/tag IDs need one documented taxonomy
  mapping; Figma mixes topics (Technology) and formats (Workshop/Seminar).
  `featured` is publisher-owned. Recommended/Popular are query/ranking results,
  not user-writable flags or fabricated counts. Ranking policy remains OPEN.
- **Organizer counts:** `followerCount >= 0` is server-maintained; repeated
  Follow/Unfollow must not drift the count. Upcoming/past event counts are derived
  from the same visibility/time filters used by the lists, not copied prototype values.
- **Registration:** `attendeeSnapshot` is `{fullName:S, studentId:S,
  universityEmail:S, phoneNumber:S?}` captured after validation. It is private and
  immutable for this registration; editing a profile does not rewrite issued
  tickets. Staff receives only the identity subset required for entry via a
  scoped callable, never all registration PII. Student-ID format/email domain
  rules must not be hard-coded from sample values. Academic/club verification and
  verification-dependent domain checks are deferred under FD-08; self-declared
  form values do not create a verified badge.
- **Terms:** `events.registrationTerms = {version:S, text:S}` for a registration
  event. `termsAcceptance = {version:S, acceptedAt:T}` records explicit consent
  and server time at commit. Reject missing/outdated acceptance before any capacity,
  deposit or ticket write. Terms must reflect the confirmed cancellation rule;
  generic Figma copy does not authorize different refund/no-show behavior.
- **Quotes:** client `expectedDepositCoins`, `expectedPriceCoins` and expected
  terms versions are consent preconditions only, never authoritative money values.
  Compare them with server values inside the transaction. If any changed since
  preview, return refreshed details and require confirmation before a hold/debit.
- **Walk-in Going:** `event_intents/{eventId}` is deterministic. Set/remove it
  only for a valid visible walk-in event; repeating the action is idempotent.
  This does not create `registrations`, increment `registeredCount`, hold coins,
  issue tickets, or count attendance. A walk-in user may check in without a Going intent.
- **Ticket:** `ticketNumber` is a server-issued display reference. Assigned seating,
  VIP and ticket tiers are explicitly excluded; do not store row/seat/pass-tier
  fields from prototype backdrops. QR is produced by `getTicketQr`, never reconstructed from the
  display number, student ID or public event ID. Ticket identity comes from its
  authorized registration snapshot; event details come from the canonical event.
- **Rewards:** `fulfillmentType` is `voucher` or `physical`; `usageLocations` and
  `redemptionSteps` are ordered display lists. `termsVersion` identifies the terms
  shown at redemption. `rewardSnapshot` stores `{title:S, imageUrl:S?,
  fulfillmentType:S, usageLocations:A<S>, termsText:S, termsVersion:S,
  redemptionSteps:A<S>}` from the authoritative reward at commit. Preserve its
  old instructions/expiry after catalog edits. Compute expiry server-side using
  an explicit validity policy; Figma's 30-day example does not define timezone,
  exact cutoff or physical pickup rules. Return actual resulting wallet balances
  with the receipt; do not derive success balances from stale client state.
- **Voucher verification:** move the old `codeHash` out of owner-readable metadata
  into `voucher_secrets`; Rules cannot hide individual fields. Never persist a raw
  secret in public documents or local fixtures as a real code. The backend must
  retain/recover or securely regenerate an owner's code across restarts; a hash
  alone cannot implement `getVoucherCode`. Final secret storage/signing/rotation
  rotation remains OPEN; admin authority is confirmed in v1.4. Authorized verification atomically
  marks a voucher used once, without deducting coins again.
- **Notifications/devices:** active proposed types are `registration_confirmed`,
  `new_event`, `schedule_update`; Figma's `event_reminder` is excluded with FD-09,
  and no fixed attendance-reminder scheduler/email delivery is planned. Required
  lab FCM reception/history remains in scope. Map `(entityType, entityId)`
  to allowlisted app routes and re-check auth on open. Create notification IDs
  deterministically from business operation/recipient; repeated FCM delivery
  refers to the same inbox record. A failed push does not roll back registration.
  Mark-all-read affects only the authenticated user's records up to a server cutoff;
  it must not mark later arrivals read. Device tokens are private, validated and
  unlinked from the UID on sign-out; no client listing of another user's tokens.
- **Derived/local state:** upcoming/past depends on event time, not attendance;
  store no `past` registration status. Remaining spots, duration, eligibility labels,
  reward affordability, unread counts and daily/month grouping
  are derived. Search history, draft filters, selected calendar day, form errors,
  loading and retry state are local presentation state; no cloud tables for these
  without a separate persistence requirement. Coin-history Earned/Spent/Deposits
  filters use ledger types/deltas; do not count a deposit refund as new earnings.

## 2. Core invariants and transaction ledger

### 2.1. Wallet conservation / audit invariants

1. All Coin amounts are integers; `availableCoins` and `heldCoins` cannot be negative.
2. Wallet snapshot, ledger rows, domain state and operation receipt are committed **atomically** in the *same Firestore transaction*.
3. Ledger is append-only; never silently delete or edit history to “fix” a balance. Financial corrections require a compensating entry with an audit reason.
4. Signup bonus once per UID; daily once per product day; monthly once per eligible month; attendance once per `(uid,eventId)`; reward redemption once per `requestId`; cancel settlement once per registration.
5. A double click or timed-out response must not repeat the effect. A retry with the same requestId returns the same completed result; a requestId reused with altered input is rejected.
6. **Transaction callback may retry** in Firestore: read all documents before writes, no emails/FCM/remote calls inside callback; send side effects **after commit** with idempotent outbox/event IDs.
7. FCM/Analytics/Crashlytics are observability, not authoritative proof of a Coin transaction.

### 2.2. Balance delta table

| Operation | Δ Available | Δ Held | Ledger type | Unique key / safe trigger |
|---|---:|---:|---|---|
| First user initialized | `+signupBonusCoins` (200 **confirmed**) | 0 | `signup_bonus` | `signup:{uid}`; only once |
| Registration with deposit | `-depositCoins` | `+depositCoins` | `deposit_hold` | `register:{uid}:{eventId}`; event capacity check |
| Cancel registration | 0 | `-depositCoins` | `deposit_forfeit` | `cancel:{registrationId}`; ticket revoked |
| Verified registered check-in | `+depositCoins` | `-depositCoins` | `deposit_refund` | `attendance:{uid}:{eventId}` (sub-entries share operation key) |
| Same registered check-in reward | `+attendanceRewardCoins` | 0 | `event_reward` | SAME attendance operation, second ledger row |
| Verified walk-in check-in | `+attendanceRewardCoins` | 0 | `event_reward` | `attendance:{uid}:{eventId}` |
| Daily claim | `+dailyReward(streakDay)` | 0 | `daily_checkin` | `daily:{uid}:{YYYY-MM-DD}` |
| Eligible monthly grant | `+200` | 0 | `monthly_gift` | `monthly:{uid}:{YYYY-MM}` (local scheduler, not deployed) |
| Redeem reward | `-priceCoinsSnapshot` | 0 | `redeem_reward` | `redeem:{uid}:{requestId}` |

**Deposit semantics:** holding a deposit **moves existing Coin** from `available` to `held` (not an extra debit from total wallet); refund reverses the hold and rewards grant a separate addition. For example, starting `available=200, held=0`, register `50` -> `available=150, held=50`; verified attendance with `200` reward -> `available=400, held=0`. Cancel instead -> `available=150, held=0` (50 forfeited). These are **illustrative event/config values**.

### 2.3. Daily check-in algorithm contract

Inputs are *server* `now` and last qualifying check-in day, not user-sent `date`, `streakDay`, or `coins`.

```text
calendarDay = localDate(serverNow, productTimezone)
if daily_checkins/{calendarDay} exists: return ALREADY_CLAIMED and previous result
if previousCheckinDay == calendarDay - 1 calendar day: newStreak = lastStreak + 1
else: newStreak = 1
reward = [5,10,15,30,50,70,100][min(newStreak,7)-1]
transaction: create daily receipt + daily doc + ledger, update wallet and streak metadata
```

- Different from “24 hours since last claim”; use **calendar days** in a named timezone; handle month/year boundaries and idempotent concurrency.
- Day 7 = +100, Day 8 = +100, Day 30 = +100 if uninterrupted; if a day missed, next claim day 1 = +5. One claim per calendar day.
- Recommend server-maintained `users/{uid}/reward_state/daily` (`lastLocalDate:S`, `streakDay:N`) for O(1) computations; it is an optional additional document, **server-only write**. If omitted, read latest daily check-in safely inside transaction.

### 2.4. Monthly gift contract (v1.4 confirmed; local scheduler)

`maintenance.grantMonthly(scheduleTime)` grants 200 once per UID/month in one wallet/grant/ledger transaction. Scheduled at 00:00 day 1 Asia/Ho_Chi_Minh, all app profiles initialized at cutoff, no onboarding requirement. Callable grantMonthlyGift returns AUTOMATIC_ONLY. Retry keeps original scheduled month. See BACKEND_POLICIES.md; no cloud job was deployed in this update.

### 2.5. Removed features

Owner removed Event Milestones entirely: no progress/claim documents, milestone
screen/API or Coin grants. No missions, seasonal targets, feedback bonus,
assigned seats or ticket-email/reminder jobs from FD-09/10. Existing Figma/demo
assets may still show them; that is pending UI cleanup, not approved backend scope.

## 3. Backend callable contracts (proposal)

All write endpoints: Firebase Authentication required; staff endpoints also require **role + event-specific assignment**; validate payload and enforce App Check if configured. UID from `request.auth.uid`, never accept a `uid` string to select whose wallet is changed. Return typed business errors and **official server state**, never just booleans.

| API (proposed) | Caller → inputs (no passwords) | Server side-effects | Important errors |
|---|---|---|---|
| `initializeUser` | signed-in student; `requestId?` | ensure `users/{uid}`, wallet and one-time signup ledger; **200 server-owned**, not client; do not infer student verification from Google login | `UNAUTHENTICATED`, `SETUP_FAILED` |
| `followOrganizer` / `unfollowOrganizer` | signed-in; `organizerId` | atomically add/delete deterministic follow doc and update followerCount only if membership changed; no Coin | `UNAUTHENTICATED`, `ORGANIZER_NOT_FOUND` |
| `registerForEvent` | signed-in; `eventId`, `requestId`, `attendeeInput`, `acceptedTermsVersion`, `expectedDepositCoins` | validate fields/terms/quote; snapshot attendee/terms; atomically reserve capacity/deposit and issue ticket. Verified-only event handling deferred with FD-08 | `VALIDATION_FAILED`, `TERMS_CHANGED`, `QUOTE_CHANGED`, `EVENT_FULL`, `ALREADY_REGISTERED`, `INSUFFICIENT_COINS`, `EVENT_NOT_OPEN` |
| `setWalkInGoing` | signed-in; `eventId`, `going:B` | validated idempotent create/delete of own intent only; no registration, seat, ticket or coins | `UNAUTHENTICATED`, `EVENT_NOT_FOUND`, `WRONG_PARTICIPATION_MODE` |
| `cancelRegistration` | signed-in; `eventId`, `requestId` | atomically cancel active registration, forfeit held deposit, revoke ticket, decrement occupied registration count once; reopened place available to new registration | `ALREADY_CANCELLED`, `CANNOT_CANCEL`, `ALREADY_ATTENDED` |
| `getTicketQr` | owner; `eventId` | return short-lived **opaque/signed QR payload** for active ticket; no wallet change | `NO_ACTIVE_TICKET`, `NOT_OWNER`, `TOKEN_EXPIRED` |
| `verifyRegisteredTicket` | authenticated staff; `qrPayload`, `requestId` | validate staff assignment, ticket, time; create attendance, refund hold + grant reward, mark ticket | `FORBIDDEN_STAFF`, `WRONG_EVENT`, `QR_INVALID`, `OUTSIDE_CHECKIN_WINDOW`, `ALREADY_CHECKED_IN` |
| `verifyWalkInQr` | signed-in; scanned `qrPayload`, `requestId` | validate event/venue QR, auth and window; create attendance + award; no registration/ticket or manual-code entry. Verified-only events deferred with FD-08 | `QR_INVALID`, `WRONG_EVENT`, `OUTSIDE_CHECKIN_WINDOW`, `ALREADY_CHECKED_IN` |
| `claimDailyCheckin` | signed-in; `requestId` | calculate server day/streak; create daily + ledger + wallet + receipt | `ALREADY_CLAIMED`, `UNAUTHENTICATED` |
| `grantMonthlyGift` | authenticated callable retained for explicit error | Client cannot claim; monthlyGiftSchedule performs grant/wallet/ledger transaction | `AUTOMATIC_ONLY` |
| `redeemReward` | signed-in; `rewardId`, `requestId`, `expectedPriceCoins`, `expectedTermsVersion` | compare quote/terms to server; atomically stock--, wallet--, redemption + voucher + ledger + receipt; return actual resulting balances | `PRICE_CHANGED`, `TERMS_CHANGED`, `OUT_OF_STOCK`, `INSUFFICIENT_COINS`, `REWARD_INACTIVE`, `DUPLICATE_CONFLICT` |
| `getOperationStatus` | signed-in; `requestId`, `operationKind` | read outcome for retry reconciliation; authorize owner, reveal no other user data | `NOT_FOUND`, `FORBIDDEN` |
| `getVoucherCode` | authenticated voucher owner; `voucherId` | return only own usable voucher secret (if valid) | `NOT_OWNER`, `EXPIRED`, `USED` |
| `verifyVoucher` | admin claim + active voucher_admins document; `code`, `requestId` | Verify private code/expiry; atomically mark voucher/redemption used, record usedBy/usedAt; no second Coin debit | `FORBIDDEN_ADMIN`, `VOUCHER_UNAVAILABLE`, `EXPIRED`, `USED` |
| `markNotificationsRead` | signed-in; optional own notification IDs or mark-all | owner-scoped update of `readAt`; all uses server cutoff; cannot alter payload/UID/target | `UNAUTHENTICATED`, `NOT_FOUND`, `FORBIDDEN` |
| `registerDevice` / `unregisterDevice` | signed-in; own `installationId`, token for register | private FCM delivery binding; UID from auth; unlink on sign-out | `UNAUTHENTICATED`, `VALIDATION_FAILED` |

If the repo already contains equivalent functions, **adapt interfaces instead of creating duplicate names**. Document the public callable shape and failure types that the Flutter ViewModels will use.

## 4. Two QR protocols and threat model

### 4.1. Registered event: **staff scans student ticket**

1. Student registered with a valid wallet-backed deposit, sees *My Ticket* QR.
2. Authorized organizer/staff scanner sends QR to backend `verifyRegisteredTicket`, along with own auth context. Staff must have active `staff_assignments` for the QR event.
3. Server validates signature/secret hash, event, current check-in window, registration state, ticket not revoked/used, attendance uniqueness, then commits attendance + `deposit_refund` + `event_reward` in a single transaction.
4. On replay or already-used QR: show `ALREADY_CHECKED_IN`; never grant twice. A screenshot of someone else's ticket does not authorize impersonating staff. Optional staff verifies student identity at entrance.

**Do not** put Admin SDK or static admin credentials in the student app; do not make a student-side “verify my own registered ticket” mutation. Since Web Admin is postponed, implement a small restricted staff/test verifier only once scope is approved; show the real scan interaction in demo if this is required for grading.

### 4.2. Walk-in: **student scans organizer's venue QR**

1. Staff displays a QR linked to a specific `walk_in` event, during its check-in window.
2. Signed-in student scans it in Evia with camera permission (fallback if denied) and calls `verifyWalkInQr`.
3. Server validates event, token lifetime/revocation, server time and uniqueness of `(uid,eventId)`, and grants event reward once.

**Risk:** a static QR photographed and shared remotely cannot prove presence. **Preferred security design**: time-limited/rotating token displayed by authorized staff. If a printed static QR is required for lab demo, record this as a **known anti-fraud limitation**, use event window + auth + one attendance per person + token rotation/revocation when possible. Choose final strategy with owner; never claim the static QR proves physical attendance.

## 5. Security Rules / IAM matrix

Target actual Firestore Rules as `firebase/firestore.rules`, Cloud Storage Rules as `firebase/storage.rules`, index definitions as `firebase/firestore.indexes.json`; use Firestore/Storage emulator tests before deploy.

| Path / resource | Guest | Signed-in owner | Other signed-in | Authorized staff | Privileged server |
|---|---|---|---|---|---|
| `events`, `organizers` published | Read public only | Read public | Read public | Read scope | Create/update controlled |
| Private user profile `users/{uid}` | Deny | Read; edit allowlisted interests/profile only | Deny | Deny (except vetted staff callable views) | Init/privileged update |
| `users/{uid}/following` | Deny | Read own; write through callable only | Deny | Deny | Validated write + follower count |
| `users/{uid}/bookmarks` | Deny | Read/write narrowly scoped; no arbitrary extra fields | Deny | Deny | Authorized maintenance |
| `users/{uid}/event_intents` | Deny | Read own; set Going through callable | Deny | Deny | Validated write |
| `users/{uid}/devices`, `voucher_secrets` | Deny | Deny direct | Deny | Deny direct | Authorized backend only |
| `registrations`, `tickets`, `attendance` | Deny | Read own **safe fields** | Deny | Read event-specific via callable | Write |
| `wallets/{uid}`, ledger, daily, monthly | Deny | Read own | Deny | Deny | Write ONLY |
| `rewards` active public catalogue | Read safe public | Read catalogue | Read catalogue | Read scope | Write stock/price |
| `redemptions`, `vouchers` | Deny | Read own **safe fields** | Deny | Scoped verifier only | Write |
| `notifications` | Deny | Read own; mark `readAt` only | Deny | Deny | Create |
| `operation_receipts`, `checkin_tokens`, `staff_assignments` | Deny | Deny direct | Deny direct | Deny direct (via backend only) | Read/write |
| Storage `reports/{uid}/...` | Deny | Read/write own reports, type/size restrictions | Deny | Deny | Admin maintenance |

**Critical Firebase details:**

- Firestore Rules **are not query filters**: Flutter's queries for guest events must include all properties necessary to satisfy Rules (`status=published`, `visibility=public`), otherwise the whole query may be denied.
- SDK/Admin code running in trusted Functions **bypasses Firestore Security Rules**; enforce role and ownership in the callable function using Firebase Auth/custom claims/assignment and restrict server IAM.
- No broad `allow read, write: if true`, no write access to balance, QR token or capacity counter from client.
- Validate that `users/{uid}` profile edits only touch allowlisted fields: cannot change `uid`, `createdAt`, `accountStatus`, roles, wallet or reward state.
- `vouchers/{id}` contains no secret/hash. Store verifier data in server-only `voucher_secrets/{id}` and return usable codes through the owner-scoped callable; Firestore Rules cannot redact individual fields in a readable document.
- Validate staff claims AND `staff_assignments/{eventId,staffUid}`, not just a user-supplied role flag or email domain.
- Restrict Storage upload path and size/type; deny anonymous and cross-UID access, and avoid exposing public download URLs if reports include private data.

## 6. Index/query plan (validate against actual queries)

| Screen/use case | Query | Likely composite index |
|---|---|---|
| Discover (public) | `events` published/public and future, order `startAt` | `status ASC, visibility ASC, startAt ASC` |
| Explore | additional category/time/mode filters | Create combinations used by real UI; avoid combinatorial explosion |
| Following feed | `organizerId in <limited IDs>`, published, future | `organizerId ASC, status ASC, startAt ASC` (+ visibility if filtered) |
| My Events | `registrations` where `uid==me`, filter state, sort `registeredAt` | `uid ASC, state ASC, registeredAt DESC` |
| Attendance | `attendance` where `uid==me`, `verifiedAt DESC` | `uid ASC, verifiedAt DESC` |
| Notifications | `notifications` where `uid==me`, `createdAt DESC` | `uid ASC, createdAt DESC` |
| Rewards catalog | `rewards.status==active`, order category/price | `status ASC, category ASC, priceCoins ASC` if used |
| Coin History | `wallets/{uid}/ledger` order `createdAt DESC` | single-field index sufficient for normal collection query |

Add required actual indexes from emulator/query errors, commit `firebase/firestore.indexes.json`. Paginate, avoid query-loading all events, and do not run broad queries disallowed by Rules.

Figma-driven query corrections (design targets, not deployed indexes):

- My Events is the de-duplicated union of own registrations, walk-in Going intents
  and verified attendance, joined with canonical events. Upcoming/past and calendar
  selection use event time in the event timezone, not `registeredAt`. A day query
  uses a half-open `[localMidnight, nextLocalMidnight)` UTC range. Product policy
  for multi-day event calendar inclusion is still OPEN.
- The original `uid/state/registeredAt` index supports registration history only;
  it is not sufficient for event-date calendar queries. Before implementation,
  choose a bounded server query or a server-maintained per-user event-time read
  model with reschedule propagation. Do not perform an unbounded client-side join
  or deploy speculative composite indexes. Counts must de-duplicate event IDs
  and use the same filters as the list; an intent plus attendance is one event.
- Saved Events follows bookmarks plus canonical events; Upcoming/Past is derived
  from those events. Following supports organizer filter and soonest order, and
  must page/chunk the followed IDs rather than assume an unlimited `in` query.
- Coin History filters by calendar month and ledger type/deltas, ordered by
  `createdAt`. My Rewards uses owner + status/expiry, not invented rows to satisfy
  Figma's sample counts. Add the actual indexes after choosing these queries.
- Search covers event titles and organizer names. This project's Standard/Core
  field indexes do not automatically provide full-text search; do not promise
  substring/fuzzy search from `orderBy`. The current native text-search feature
  documented by Firebase requires Enterprise edition; no edition change is proposed.
  A prefix/token strategy and its limits, taxonomy normalization, ranking, and
  exact time-of-day/duration filter boundaries need a documented query contract.
  Do not add a paid search service without a concrete requirement/approval.

## 7. Data provenance and seed plan

- **No hard-coded/mock event list in the submitted build.** Use genuine event/organizer data with approved source/attribution; for Lab 3 evidence the lecturer may check whether data comes from the named source. Do not invent university details or attendance receipts.
- Suggested *seed import CSV/JSON structure* (no real values fabricated):

```json
{
  "organizerId": "<validated-club-id>",
  "title": "<real-event-title>",
  "category": "technology",
  "participationMode": "registration",
  "capacity": 100,
  "depositCoins": 50,
  "attendanceRewardCoins": 200,
  "status": "draft",
  "visibility": "private",
  "sourceRef": "<verified-official-source-link>"
}
```

The `50/200` values above are **illustrative seed configuration**, not mandated event defaults. Enrich with required fields (time, location, organizer, eligibility) and validated data; publish only after review. Use **dev project/emulator** first, opt-in idempotent upsert scripts keyed by stable event/organizer IDs, a dry-run mode, backup/rollback plan and least-privilege credentials stored outside Git. Don't seed fictional attendance, transactions or user identities as real demo evidence.

## 8. Emulator acceptance tests — minimum bar for database PR

Tests must show commands, logs and commit references; all results are **NOT RUN** until Codex supplies evidence.

| Test ID | Scenario / assert |
|---|---|
| SEC-01 | Guest can query only published/public events and organizer profiles; cannot query private/draft. |
| SEC-02 | Guest cannot Follow/Bookmark/Register; authentication required before Follow via Google or email/password. No password/hash/reset token stored in Firestore. |
| SEC-03 | User A cannot read User B profile, wallet, ledger, registrations, tickets, notifications or report storage. |
| SEC-04 | Authenticated client cannot set `availableCoins`, edit ledger, attendance, counter, stock or monthly grants. |
| SEC-05 | Authorized staff on event E can verify ticket for E only; unrelated staff or student cannot. |
| AUTH-01 | Same user initialization run twice grants signup coins **at most once** (amount config, confirmed before live). |
| REG-01 | Two users racing for final slot yields exactly one registration; other returns `EVENT_FULL`, no deposit. |
| REG-02 | Register/cancel replay cannot duplicate held/forfeit ledger entries or tickets; correct counter settlement. |
| REG-03 | No waitlist path/status is produced; Event Full only. |
| REG-04 | Capacity reached rejects new requests; committed cancellation releases exactly one place, repeated/failed cancellation releases none; concurrent attempts for the reopened place yield exactly one registration without overselling. |
| QR-01 | Registered staff scan refunds deposit and grants reward once; double scan does not change wallet. |
| QR-02 | Student walk-in QR scan grants once; invalid/expired/revoked/outside window scans do not grant. |
| DAILY-01 | Simulate seven consecutive product days: credits exactly `[5,10,15,30,50,70,100]`. |
| DAILY-02 | Day 8 and 9 grant +100 each; day gap resets next grant to +5; duplicate same-day claim does not recredit. |
| MONTH-01 | Monthly transaction rejects duplicate same-month grants; cutoff, onboarding-independent eligibility and year rollover tested locally; cloud Scheduler not deployed. |
| REW-01 | Concurrent redemptions with stock=1 give exactly one successful voucher; no negative stock or wallet. |
| REW-02 | Insufficient balance, inactive reward or repeated requestId has no double debit. |
| TIME-01 | Calendar-day boundary & year/month rollover correctly evaluated in configured product timezone. |
| DATA-01 | Wallet ledger deltas reconcile with materialized wallet; no negative balance at any tested step. |
| FIG-01 | **DEFERRED with FD-08:** verified student/faculty/club feature tests are not an active acceptance gate. Do not show verified badges or activate verified-only filters; reserved trusted fields remain protected. |
| FIG-02 | Missing or stale terms/form validation fails before any capacity, deposit, ledger or ticket change; profile edits preserve the registration attendee snapshot. |
| FIG-03 | Repeated Going saves one walk-in intent, creates no reserved seat/ticket/coins, and appears once in My Events even after attendance. |
| FIG-04 | One server reward price feeds catalog/detail/confirmation; price changed since preview requires refreshed confirmation before any debit. Redemption history retains original terms/expiry. |
| FIG-05 | Owner sees voucher metadata but cannot directly read secrets/hash; unauthorized cashier rejected; replayed use never consumes twice or debits coins again. |
| FIG-06 | Duplicate FCM deliveries create one inbox item; mark-all-read affects only caller's notifications before cutoff; sign-out unlinks device; new arrivals stay unread. |
| FIG-07 | My Events/bookmarks date filters use canonical event time, handle rescheduling/timezone/day boundaries, de-duplicate intent/registration/attendance, and never equate past with attended. |
| FIG-08 | Fewer than 3 distinct valid interests cannot complete onboarding or save final preferences; duplicate/unknown IDs do not satisfy the count; no Skip; guest public browsing still works. |
| FIG-09 | Removed milestones, feedback/mission/seasonal Coin paths, assigned seats, ticket-email/fixed reminder jobs and manual walk-in code entry have no active callable or ledger effect. |

## 9. Database deliverables / review gate for Codex

Expected PR/files (adapt to actual repo naming, don't overwrite working implementations):

- `docs/DATABASE_DESIGN.md` and committed ADR/deviation notes.
- `firebase/firestore.rules`, `firebase/storage.rules`, `firebase/firestore.indexes.json`, `firebase.json` with local emulators configured.
- `functions/` (TypeScript or current trusted backend stack) with scoped, idempotent operations and tests; no unsafe wallet writes from mobile.
- `scripts/seed/` or equivalent with dry-run, provenance and no secrets/PII.
- `docs/IMPLEMENTATION_TRACKER.md` updated with actual file paths, PR/commit, test logs, index deployment status, Firestore project ID (nonsecret), outstanding blockers.
- Screenshot/evidence only from real emulator/console runs, not synthesized.

### Completion criteria (all required for *database implementation complete*)

- [ ] Read current repo, inventory existing Firebase config, no destructive changes.
- [ ] Core collections documented and verified by code/schema validators.
- [ ] Rules and indexes are in version control and tests run against Emulator Suite.
- [ ] Cross-user and client-wallet-write attempts are denied.
- [ ] Register/cancel/check-in/daily/redeem use server transactions and idempotent receipts.
- [ ] Full-event, duplicate QR, concurrent reward stock and daily streak edge cases pass.
- [ ] Any deployed Firebase service/real data has explicit owner approval and console evidence.
- [ ] No secrets, API keys (except approved public app config), service-account JSON or test-user passwords in Git.
- [ ] All **OPEN business policies** are recorded/blocked rather than guessed.
- [ ] `docs/IMPLEMENTATION_TRACKER.md` includes exact evidence and handoff to mobile integration.

## 10. Firebase references (official; implementation verification)

- [Firestore transactions & atomicity](https://firebase.google.com/docs/firestore/manage-data/transactions) — transaction callback can rerun; no side effects inside.
- [Firestore rules vs queries](https://firebase.google.com/docs/firestore/security/rules-query) — Rules are not filters.
- [Callable Functions](https://firebase.google.com/docs/functions/callable) — auth context + input validation.
- [Firebase Storage for Flutter](https://firebase.google.com/docs/storage/flutter/start) — Cloud Storage billing prerequisites should be checked before enabling.
- [Functions getting started](https://firebase.google.com/docs/functions/get-started) — deployment/billing checks.
- [Firebase Auth triggers](https://firebase.google.com/docs/auth/extend-with-functions) — confirm gen 1/gen 2 behavior; **do not assume every Auth lifecycle trigger is supported on every generation**; idempotent callable initialization is a valid planning alternative.
- [Field-level access](https://firebase.google.com/docs/firestore/security/rules-fields) — readable documents cannot hide selected fields using Rules; put verifier secrets in private documents.
- [Text-search edition requirements](https://firebase.google.com/docs/firestore/enterprise/text-search) — do not assume Standard/Core indexes implement the search UX.

**Evidence boundary:** Design/acceptance reference. Current endpoints and limitations: `backend-integration.md`; actual local test outcomes: `evidence/backend/`. A passing Emulator run is not proof of cloud deployment or mobile integration.

## 11. Local backend implementation delta — 2026-11-04

- `functions/src/` implements account init, profile/interests, catalog queries,
  follow/bookmarks, registration/cancel, QR verification, wallet/ledger, Daily,
  redemption/voucher recovery, inbox/read markers and FCM device contracts.
- All client Firestore mutations are denied. Profile/preferences/bookmarks also
  use allowlisted callables; earlier conceptual tables do not authorize direct
  writes. Only published public catalog is guest-readable.
- Added paths: `interests/{id}` = `{label,status,sourceRef,...}` (approved catalog,
  active public); `device_bindings/{hash(token)}` server-only `{uid,installationId}`;
  `users/{uid}/reward_state/daily` stores streak state.
- Ticket QR TTL120s, walk-in TTL60s; staff requires claim plus event assignment.
  Voucher private document stores code for owner recovery; never expose via Rules.
- Catalog import is create-only/dry-run by default. Interests, prices, stock,
  dates and event rewards are approved server data, not Figma constants.
- Historical v1.3 policy blockers are superseded by BACKEND_POLICIES.md: monthly/no-show jobs, same-user re-registration and admin voucher use are implemented locally. Voucher rotation remains unimplemented. No manual walk-in code, milestone or Waitlist.
- `validDays` means N times 24 hours from redemption, not a local end-of-day
  cutoff. Require approved per-record expiry before live import.
- Queries use bounded candidate pagination; filtered pages can be empty with a
  next cursor. My Events uses canonical events plus owner relations, no totals.
- Composite indexes are defined locally; Emulator does not enforce cloud index
  build status. Storage permits own create-only PDF reports up to 5MiB.
- Flutter services/UI, actual Google login, cloud FCM and live deployment remain
  separate work; this is not full Lab 3 completion.
