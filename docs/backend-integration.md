# Backend Evia — hướng dẫn tích hợp

> **Push Android — 06/11/2026:** `deliverNotification` đã deploy sender dùng
> HIGH priority/channel `evia_events_v1`; log kết quả FCM theo notification ID,
> giữ cleanup token/retry. Contract inbox/callable giữ nguyên. [Hướng dẫn](PUSH_NOTIFICATIONS.md).

> **Flow 3 — 06/11/2026:** các màn Rewards đã nối API thật.
> `getAccount` bổ sung `daily: {dayKey,streakDay,coins,alreadyClaimed,serverTime,
> timezone}`; không đổi contract profile/wallet cũ. Server quyết định ngày Việt
> Nam và số xu. Chỉ Function này được deploy lại trong task; các mutation/owner
> query có sẵn được dùng lại. [Contract/call chain](FLOW3_INTEGRATION.md) ·
> [Evidence](../evidence/flow3-api-only/).

> **Flow 2 — 05/11/2026:** `verifyWalkInQr`/`verifyWalkInCode` bổ sung
> `expectedEventId?:string` tương thích caller cũ; khác event lỗi
> `QR_EVENT_MISMATCH`, không ghi attendance/wallet. `demoConfirmAttendance`
> nhận `{eventId,requestId}`, chỉ user `isDemo && demoAttendanceEnabled` và event
> `isDemo` do server quản lý; chỉ demo bỏ cửa sổ giờ. Không cần staff credentials
> trong APK. [Contract, cách tắt demo và evidence](../evidence/flow2-api-only/).

> **Email mở rộng 05/11/2026:** owner bỏ giới hạn domain email. Mọi địa chỉ
> đúng định dạng đều được đăng ký/đăng nhập/tham gia. MSSV vẫn hai chữ + sáu số;
> quyền staff/admin và điều kiện sự kiện giữ nguyên. [Contract](PREINTEGRATION_DECISIONS.md).

> **Policy hủy mới 05/11/2026:** chủ động hủy hoàn 30% cọc, làm tròn xuống số xu
> nguyên; phần còn lại mất. No-show vẫn mất toàn bộ. Không hoàn bù giao dịch cũ.
> [Contract và ledger](BACKEND_POLICIES.md#chủ-động-hủy-đăng-ký--cập-nhật-05112026).

> **API bổ sung 05/11/2026:** [contract trước tích hợp](PREINTEGRATION_DECISIONS.md)
> thêm manualCode vào QR responses, verifyRegisteredCode/verifyWalkInCode và
> notifications event/new/schedule/reminder; protected API nhận mọi email hợp lệ từ Firebase Auth token.
> Các ghi chú 34 Functions/no manual/no follower fanout ở snapshot cũ được thay thế.

Ngày 04/11/2026. Implementation: `functions/src/`. **Project hiện tại:
`prm393-31822` (evia, Blaze)**. Emulator/tests dùng `demo-evia-backend`.
Đã deploy 34 Functions; 34 Cloud Run latest revisions READY, 2 Scheduler jobs ENABLED. Rules smoke đạt, 14 indexes READY; xem [release mới](backend-release.md).
Bằng chứng: [firebase-migration.md](firebase-migration.md).
UI và các adapter Flutter hiện tại chưa được nối vào backend này.

## Backend readiness local — API v1.1 (04/11/2026)

Bản local mới có đăng ký lại sau hủy (vé mới, giữ lịch sử), admin xác nhận voucher một lần, Monthly Gift tự động và no-show forfeiture. **Đã deploy thay đổi này**; evidence migration 32 Functions là lịch sử revision trước. Xem [handoff](FRONTEND_HANDOFF.md), [data readiness](DATA_READINESS.md) và [policy/jobs](BACKEND_POLICIES.md).

## Chạy backend độc lập với giao diện

Cần Node.js **22**, Java **21+** trên PATH và Firebase CLI (đã kiểm tra với
15.30.2). Node/Java của Flutter có thể khác toolchain backend. Từ root repository:

```powershell
node --version
java -version
npm --prefix functions ci
$env:FUNCTIONS_DISCOVERY_TIMEOUT = '60'
npm --prefix functions run test:emulator
npm --prefix functions run serve
```

`test:emulator` tự mở/dừng Auth, Firestore, Functions, Storage và xóa dữ liệu
**demo trong Emulator** giữa các case. Không chạy đồng thời với `serve`.
Tests từ chối chạy nếu thiếu host loopback hoặc project khác `demo-evia-backend`.
Fixtures chỉ nằm trong `functions/test/`; `serve` không tự thêm dữ liệu mẫu.
Emulator UI: http://127.0.0.1:4000; Auth 9099, Firestore 8080, Functions 5001,
Storage 9199. Android Emulator gọi host máy tính qua `10.0.2.2`; thiết bị thật
cần đường kết nối riêng vì mặc định các server chỉ listen loopback.

## Quy ước API v1

- Tất cả là **Firebase HTTPS Callable**, region `asia-southeast1`, không phải
  REST tự viết. Flutter dùng `FirebaseFunctions.instanceFor(region: ...)` trong
  **SDK adapter**, rồi inject service → repository → ViewModel theo kiến trúc repo.
  Khi tích hợp mới thêm `cloud_functions` bằng Flutter resolver và domain models;
  màn hình không gọi SDK trực tiếp. Không cần đổi giao diện để chạy tests backend.
- Request là object JSON; field thừa bị từ chối. Không truyền `uid`, balance,
  reward amount hay staff role từ client; server lấy UID/custom claims từ Auth.
- Trả object domain; mọi Timestamp qua Callable là ISO-8601 UTC string, nullable
  fields giữ `null`. Firestore realtime SDK vẫn trả Timestamp: adapter phải map.
- `FirebaseFunctionsException.details.code` là mã lỗi nghiệp vụ; `code` của SDK
  là trạng thái như `failed-precondition`, `permission-denied`, `unauthenticated`.
- Mutation tiền/vé có `requestId`: chuỗi `[A-Za-z0-9_-]`, 8–128 ký tự. Tạo **một
  lần cho một lần xác nhận**, giữ lại khi timeout/retry. Không tạo ID mới chỉ vì
  mạng lỗi. ID cũ + input khác trả `DUPLICATE_CONFLICT`; retry cùng input trả
  receipt cũ. Không cộng/trừ xu lạc quan ở client. Receipt có thể chứa số dư tại
  thời điểm giao dịch; đọc `getAccount`/wallet stream để lấy số dư hiện tại.
- Trước actions nghiệp vụ phải `initializeUser`, rồi hoàn thành `saveInterests`.
  Guest được xem dữ liệu public; private collections chỉ owner đọc, client không
  được ghi trực tiếp. Người dùng không thể tự sửa tiền, vé, attendance hoặc staff.

## Authentication và tài khoản

Google Sign-In, email/password sign-up/sign-in, reset password, logout do **Firebase
Auth SDK** thực hiện trong service adapter. Không có endpoint lưu mật khẩu ở
Firestore. Sau đăng nhập gọi `initializeUser`; sau logout gỡ FCM device trước khi
sign out. Google và email/password provider đã bật trên project thật; debug SHA-1/SHA-256
của máy hiện tại đã đăng ký, FlutterFire config đã sinh lại. Release/máy khác cần
fingerprint đúng signing key. Kiểm thử Auth Emulator không xác nhận Google OAuth trên thiết bị.

| Callable | Request | Kết quả chính |
|---|---|---|
| `initializeUser` | `{}` | `{profile,wallet,created}`; tặng **200 xu một lần/UID**, chưa onboarding |
| `getAccount` | `{}` | `{profile,wallet,interestOptions:[{id,label}]}` |
| `updateProfile` | Một hoặc nhiều `displayName`, `studentId`, `universityEmail` (string, không null), `phoneNumber` (string hoặc null) | `{updated:true}`; không sửa xác minh/role |
| `saveInterests` | `{interests:[id,...]}` | Tối thiểu **3 ID khác nhau**, tối đa 50; phải tồn tại active trong `interests/`; `{interests,onboardingCompleted:true}` |
| `getServerInfo` | `{}`; guest được gọi | API version, server time, region, timezone, cờ monthly/admin voucher true trên cloud; monthly mode automatic |

Danh mục sở thích phải do chủ dự án duyệt/import; backend không tự chọn taxonomy
từ tên minh họa Figma. Chưa import thì options rỗng và không thể hoàn tất onboarding.

## Khám phá, Follow, Saved, My Events

| Callable | Request | Kết quả |
|---|---|---|
| `getPublicCatalog` | `{kind,limit?,cursor?,...filters}` | `{items,nextCursor,scannedCount}` |
| `getEvent` / `getOrganizer` / `getReward` | `{eventId}` / `{organizerId}` / `{rewardId}` | Public record; event thêm `spotsRemaining` |
| `followOrganizer` / `unfollowOrganizer` | `{organizerId}` | `{organizerId,following}`; đếm follower atomic, không phải membership |
| `setBookmark` | `{eventId,saved:boolean}` | `{eventId,saved}`; không đăng ký/giữ chỗ |
| `setWalkInGoing` | `{eventId,going:boolean}` | `{eventId,going}`; chỉ walk-in, không vé/cọc/xu |
| `listOwned` | `{kind,limit?,cursor?,status?}` | `{items,nextCursor}`; chỉ dữ liệu UID hiện tại |
| `listMyEvents` | `{limit?,cursor?,tab?,localDate?}` | `{items:[{event,registration,going,attendance,past}],nextCursor,scannedCount}` |
| `getTicket` | `{eventId}` | `{registration,ticket,event}` của owner; không chứa bearer QR |

`kind` public: `events`, `organizers`, `rewards`, `interests`.
Event filters: `organizerId`, `category`, `participationMode` (`registration` hoặc
`walk_in`), `featured`, `from` inclusive / `until` exclusive ISO timestamps,
`availability` (`available`, `full`, `unlimited`), `timeOfDay` (`morning` 00–12,
`afternoon` 12–18, `evening` 18–24 theo timezone sự kiện), `duration`
(`under_hour`, `one_to_three_hours` inclusive 60–180 phút, `over_three_hours`).
`q`: substring không phân biệt hoa/dấu trên title/name + description.
Event `feed`: `all` (guest), `following`, `recommended` (đã onboarding).
Recommended hiện lọc category/tags trùng sở thích, **chưa phải thuật toán xếp hạng**.

`kind` owner: `following`, `bookmarks`, `event_intents`, `ledger`, `notifications`,
`redemptions`, `vouchers`, `registrations`, `attendance`. Mới nhất trước;
`status` chỉ dùng với vouchers/redemptions hoặc state của registrations.

Limit mặc định 20, tối đa 50. Cursor là ID cuối của **trang ứng viên**; events
sort `startAt` rồi ID. Các bộ lọc và My Events xử lý trang ứng viên có giới hạn
để không cần hàng loạt composite indexes. **Trang rỗng vẫn có thể có nextCursor**:
tiếp tục đến cursor null hoặc đủ dữ liệu hiển thị. Không có tổng kết quả toàn cục,
full-text/fuzzy search hoặc đảm bảo trang đầy. Dùng search index/projection khi
catalog lớn; đây là giới hạn có chủ đích, không được trả mock để lấp trang.
`listMyEvents` hợp nhất theo event ID, lấy lịch canonical hiện tại (không dùng
ngày đăng ký), `tab` upcoming/past dựa endAt; past không có nghĩa đã attendance.
`localDate` dạng YYYY-MM-DD theo timezone sự kiện. My Events đọc tối đa 3 quan hệ
owner cho mỗi event ứng viên; cần projection khi lượng sự kiện tăng.

## Vé, QR, Daily và xu

| Callable | Request | Kết quả chính |
|---|---|---|
| `registerForEvent` | `{eventId,requestId,expectedDepositCoins,acceptedTermsVersion,attendeeInput:{fullName,studentId,universityEmail,phoneNumber?}}` | `{registrationId,ticketId,wallet}` |
| `cancelRegistration` | `{eventId,requestId}` | `{registrationId,state:'cancelled',depositRefunded,depositForfeited,wallet}` |
| `getTicketQr` | `{eventId}` | `{ticketId,ticketNumber,qrPayload,expiresAt}`; owner vé active, TTL 120 giây |
| `issueWalkInQr` | `{eventId}` | `{eventId,qrPayload,expiresAt}`; staff được phân công, TTL tối đa 60 giây |
| `verifyRegisteredTicket` | `{qrPayload,requestId}` | `{attendanceId,eventId,coinsGranted,depositRefunded}`; không lộ ví sinh viên cho staff |
| `verifyWalkInQr` | `{qrPayload,requestId}` | Các field trên + `wallet` của sinh viên |
| `claimDailyCheckin` | `{}` | `{dayKey,streakDay,coinsGranted,wallet}` |
| `getOperationStatus` | `{operationKind,operationId}` | `{status:'complete',result}` hoặc `NOT_FOUND` |
| `grantMonthlyGift` | `{}` | `AUTOMATIC_ONLY`; client không tự claim, scheduler cấp xu |

Không Waitlist. Vé cuối được cấp trong transaction; full trả `EVENT_FULL` không
đổi tiền/counter. Giá cọc/terms lệch trả `QUOTE_CHANGED`/`TERMS_CHANGED` để client
tải lại và yêu cầu người dùng xác nhận. Mặc định đóng đăng ký tại startAt; có thể
cấu hình `registrationClosesAt`. Hủy hoàn 30% cọc làm tròn xuống, vé revoked và mở đúng một chỗ.
Cùng UID được đăng ký lại sau hủy bằng requestId mới nếu còn chỗ và chưa đóng đăng ký; cọc cũ đã hoàn 30% làm tròn xuống, lần mới giữ cọc mới. Mỗi lần có ticketId mới; snapshot lần hủy chuyển vào `registrations/{id}/history/{oldTicketId}` (server-only). QR vé cũ vẫn revoked. No-show được job xử lý sau cả endAt và checkInEndAt, không hoàn cọc; xem policy/jobs.

Hủy mới: registration lưu `cancellationRefundCoins`, `cancellationForfeitedCoins`,
`cancellationPolicyVersion=refund-30-floor-v1`, `depositSettlement=partially_refunded`
(cọc 0: `none`). Ledger `deposit_partial_refund` ghi `deltaAvailable=floor(cọc*3/10)`,
`deltaHeld=-cọc`. Cọc lấy từ registration snapshot, không lấy giá event vừa sửa.
Giao dịch/receipt đã settle trước release giữ nguyên, không hoàn bù.

QR là token opaque ngẫu nhiên, hash nằm private; không parse token để cấp xu
ở app. Staff phải có custom claim `staff:true` **và** active document
`staff_assignments/{SHA256(JSON.stringify([staffUid,eventId]))}` với
`{staffUid,eventId,active:true,permissions:[...]}` do Admin SDK/operator tin cậy
cấp. Permissions là `verify_ticket`, `issue_walk_in`. Role/assignment không do
client tạo, không có public API tự nâng quyền. Dùng Firebase Auth account thật của
staff, `initializeUser` + onboarding trước verify. Không có staff UI trong scope.

Registered: staff quét QR cá nhân; hoàn cọc và thưởng snapshot tại đăng ký cùng
transaction. Walk-in: sinh viên quét QR venue trong cửa sổ check-in; chỉ một
attendance/UID/event dù đổi QR/requestId. Replay khác request trả
`ALREADY_CHECKED_IN`; token hết hạn/sai/revoked trả `QR_INVALID`; ngoài giờ trả
`OUTSIDE_CHECKIN_WINDOW`. QR TTL giảm replay, **không chứng minh hiện diện vật lý**.
Có manual fallback theo [contract mới](PREINTEGRATION_DECISIONS.md). Event Milestones bổ sung 05/11/2026: xem
[3 API và receipt contract](EVENT_MILESTONES.md). Claim gửi expectedVersion;
không dùng requestId mới để nhận lại cùng milestone.

Daily theo **Asia/Ho_Chi_Minh**: 5/10/15/30/50/70/100; ngày 8+100; nghỉ một ngày
reset streak; cùng ngày trả receipt cũ. OperationKind: `register`, `cancel`,
`daily`, `redeem`, `verify-ticket`, `verify-walkin`, `verify-voucher`; operationId = requestId,
riêng daily = YYYY-MM-DD. Verify-ticket receipt luôn kiểm tra lại phân công staff.

## Rewards, inbox, FCM và Storage

| Callable | Request | Kết quả |
|---|---|---|
| `redeemReward` | `{rewardId,requestId,expectedPriceCoins,expectedTermsVersion}` | `{redemptionId,voucherId,costCoins,expiresAt,wallet}`; voucherId null cho physical |
| `getVoucherCode` | `{voucherId}` | `{voucherId,code,qrPayload,expiresAt}`; owner, unused, chưa hết hạn |
| `verifyVoucher` | `{code,requestId}` | `{voucherId,redemptionId,status:'used',usedAt}`; admin được cấp quyền, transaction dùng một lần |
| `markNotificationsRead` | `{notificationIds?:[id,...],before?:ISO}` hoặc `{}` | `{updatedCount,before,hasMore}` |
| `registerDevice` | `{installationId,token,platform}` | `{registered:true}` |
| `unregisterDevice` | `{installationId}` | `{unregistered:true}` |

Chỉ trừ available, không trừ held. Kiểm tra stock/giá/terms trong transaction;
retry không trừ lần hai. Giá Café đã chốt 200 nhưng phải nằm trong **record thật
được duyệt**, backend không seed voucher minh họa. `validDays` tùy catalog;
implementation tính duration N×24 giờ từ lúc redeem, bỏ trống = không expiry.
Không tự lấy ví dụ 30 ngày làm chính sách. Chủ dự án phải duyệt expiry của record
trước import; nếu muốn cutoff theo ngày lịch cần sửa contract trước phát hành.
Code ổn định được lưu **private server-only**, không nằm trong owner-readable
voucher/receipt/log; gọi lại được sau restart. Admin xác nhận voucher tại nhà tài trợ qua `verifyVoucher`; phải có claim `admin:true` và server-only `voucher_admins/{uid}.active=true`, tài khoản đã init/onboard. Không tự cấp quyền từ app; rotation mã vẫn chưa triển khai. Request chỉ gửi code 43 ký tự, không gửi nguyên QR; backend tra hash private. Quyền được kiểm lại cả khi retry receipt, operationKind `verify-voucher`. Dùng lần thứ hai trả `USED`, hết hạn trả `EXPIRED`; không trừ thêm xu.

Inbox tạo khi đăng ký hoặc redeem thành công; payload chỉ chứa generic text và
allowlisted entity reference. `mark all` tối đa 100 bản ghi/lần, giữ cutoff `before`
khi lặp `hasMore` để không đánh dấu thông báo mới đến. Chọn IDs tối đa 30/lần.
`deliverNotification` gửi FCM khi inbox document được tạo, retry lỗi tạm thời,
Android dùng notification ID làm tag; inbox deterministic chống tạo trùng.
Một user tối đa 10 installations; token được chuyển khỏi account cũ khi account
mới đăng ký token đó. Gỡ token logout và đăng ký lại khi refresh. FCM bị bỏ qua
rõ ràng trong Emulator; push thật/permission/deep-link/background **chưa kiểm chứng**.
Đã bổ sung follower new-event fanout, schedule updates và reminder trước 72 giờ;
xem PREINTEGRATION_DECISIONS.md. Native push/mobile routing vẫn chờ nối adapter.

Storage: upload PDF tại `reports/{uid}/{unique-id}.pdf`, MIME `application/pdf`,
0 < size ≤ 5 MiB; owner authenticated đọc/tạo, không overwrite/delete/cross-UID.
Tên file chỉ chữ/số/`_`/`-` + `.pdf`. Adapter dùng authenticated SDK download;
không phát tán download-token URL vì người có URL có thể dùng như bearer link.
Rules kiểm metadata, không kiểm nội dung PDF; tạo report/progress/export UI chưa
triển khai trong task backend. Không dùng Storage cho public avatar/event image.

## Dữ liệu thật và triển khai cloud

`functions/src/catalog.ts` là schema chuẩn cho `interests`, `organizers`, `events`,
`rewards`. JSON gồm các mảng cùng tên; mỗi record cần `id`, `sourceRef` HTTPS và
fields đúng schema. Không có production seed giả, không import tên/ngày từ Figma.
`audience.scope` hiện chỉ `everyone`; student/club verification đang hoãn.

```powershell
npm --prefix functions run build
node functions/scripts/import-catalog.mjs --project demo-evia-backend --input approved.json
# Chỉ khi đã duyệt dữ liệu, với Emulator đang chạy và FIRESTORE_EMULATOR_HOST set:
node functions/scripts/import-catalog.mjs --project demo-evia-backend --input approved.json --apply
```

Mặc định dry-run chỉ validate, không network. `--apply` create-only, toàn bộ import
atomic, không ghi đè ID có sẵn; live cần ADC bên ngoài Git và project ID explicit.
Không dùng Firebase CLI login như thể tự động là Admin SDK ADC. Không thêm file
service-account key vào repo. Chưa có dữ liệu nguồn được duyệt để import cloud.

Người dùng đã yêu cầu chuyển sang project nhóm có Blaze: `prm393-31822`.
Billing được xác nhận enabled; không liên kết billing mới. [Migration](firebase-migration.md)
ghi nhận kiểm tra tài nguyên, OAuth, deployment và evidence. Lệnh đúng project:

```powershell
firebase deploy --project prm393-31822 --only firestore:rules,firestore:indexes,storage
# Functions theo nhóm nhỏ để tránh spike quota CPU khi startup:
.\functions\scripts\deploy-dev.ps1
```

Functions dùng Node22, `minInstances:0`, `maxInstances:3` **mỗi function**,
256MiB, `cpu:gcf_gen1`, concurrency 1 theo quota khu vực hiện tại. Không phải
giới hạn chi phí toàn project. 14 indexes đã được kiểm tra READY trên cloud (`indexes-status.json`); Emulator
không tự chứng minh yêu cầu index của cloud. App Check mặc định
chưa enforce để không khóa app chưa tích hợp; đặt `ENFORCE_APP_CHECK=true` trong
Functions environment sau khi client đã đăng ký App Check. Không log credentials.

Auth API xác nhận Google/email-password enabled ở project mới (`evidence/firebase-migration/auth-status.json`);
đây chưa phải kiểm thử đăng nhập app. Kiểm thử OAuth Android, FCM thật, owner-authorized cloud data flows, tải lớn và nối service
Flutter vẫn là bước riêng. Analytics/Crashlytics/Remote Config cần instrumentation
phía app; task này không bật auto-collection, hooks hoặc giả evidence lab.

Nguồn chính thức: [Callable](https://firebase.google.com/docs/functions/callable),
[Emulator](https://firebase.google.com/docs/functions/local-emulator),
[runtime/deployment](https://firebase.google.com/docs/functions/manage-functions),
[Storage Rules resource](https://firebase.google.com/docs/reference/security/storage).
