# Quyết định đồng bộ trước tích hợp — 05/11/2026

> **Cập nhật dữ liệu tiếp theo cùng ngày:** owner đã yêu cầu tự generate dữ liệu
> và tài khoản vận hành. [DEMO_DATA.md](DEMO_DATA.md) ghi 32 catalog records demo
> và hai Auth operators đã tạo/verify, thay thế các ghi chú “chưa có dữ liệu /
> không tạo Café” bên dưới. Release checks trong tài liệu này là snapshot trước
> seed; không chạy lại script assert database rỗng để nghiệm thu dataset mới.

Các quyết định người dùng xác nhận sau lượt đối chiếu UI/Firebase thay thế
những mô tả QR-only, chưa có reminder hoặc định dạng STU/.edu trong tài liệu cũ.
Task này cập nhật policy/UI contracts và backend; **chưa nối toàn bộ mobile**.

## Phạm vi đã chốt

| Mục | Quyết định |
|---|---|
| Waitlist | Không có. Hết vé từ chối; hủy trả chỗ. Không tạo queue/intents kiểu waitlist |
| Hủy đăng ký | Hoàn 30% cọc làm tròn xuống; mất phần còn lại. Held giảm toàn bộ, available tăng đúng phần hoàn; demo cùng policy server |
| Daily | 5/10/15/30/50/70/100, ngày 8+100; Vietnam calendar, nghỉ ngày reset |
| Onboarding (cập nhật 13/11/2026) | Chọn sở thích tùy ý hoặc Skip. Chuyển tiếp sau khi `saveInterests` thành công. |
| Café | 200 xu. Chưa có nhà tài trợ/stock/địa điểm/hạn dùng/terms được duyệt: **không tạo record cloud** |
| Check-in dự phòng | Có nhập mã, cùng xác nhận và quyền như QR; không phải mã đăng nhập/SMS OTP |
| Thành tựu | Chưa đạt / Có thể nhận / Đã nhận, có loading; thao tác claim phải có server receipt, không tự cộng xu |
| Audience/eligibility | Ẩn hạn chế trường/khoa/CLB và verified-eligibility chưa hỗ trợ. Backend vẫn everyone |
| Feedback/học kỳ | Người dùng xác nhận **bỏ**, không thưởng feedback, missions hoặc mục tiêu theo mùa/học kỳ |
| Notifications | Thêm sự kiện mới, nhắc trước ba ngày và đổi lịch theo quy tắc dưới đây |
| Identity | MSSV hai chữ cái + sáu chữ số; email nhận mọi domain hợp lệ theo cập nhật 05/11/2026 |

## Email mở mọi domain; MSSV giữ nguyên

- Owner cập nhật 05/11/2026: Gmail, Outlook, Yahoo và mọi tên miền email hợp lệ
  đều tham gia được. Bỏ allowlist `fpt.edu.vn`/`fe.edu.vn` trên client và server.
- Email normalize trim/lowercase, tối đa 254 ký tự, kiểm syntax bằng cùng quy tắc
  ở `FptIdentity.validEmail` (tên class legacy) và server `emailAddress` trong
  `identity.ts`. Không bỏ validation, không chấp nhận email rỗng/sai định dạng.
- `authenticated()` vẫn cần Firebase Auth context có email hợp lệ, lỗi
  `EMAIL_REQUIRED`; không nhận UID/role từ body. Student ID giữ regex
  `^[A-Z]{2}[0-9]{6}$`, trim/uppercase.
- Áp dụng cho email/password, Google, reset password, profile/contact email,
  registration và mọi protected callable. Không đổi tên wire field
  `universityEmail` để tránh phá contract; label hiện có đổi thành Email.
- Không thêm email_verified, không coi email/MSSV là xác minh sinh viên thật.
  Staff/admin vẫn cần custom claims và assignments server-side như trước.
- Cần redeploy 32 callable có guard; 4 API public không dùng email và 5 triggers/
  schedulers giữ nguyên. Evidence mới ở [open-email](../evidence/open-email/).

## Mã check-in dự phòng

- getTicketQr và issueWalkInQr trả thêm **manualCode** dạng `ABCD-EFGH`.
  Tám ký tự ngẫu nhiên, alphabet tránh I/O/0/1, nhận chữ thường/dấu gạch khi nhập.
- Mã vé tối đa **120 giây**; mã walk-in tối đa **60 giây** và không vượt cửa sổ
  check-in. Refresh QR cấp mã mới; mã cũ chỉ còn hiệu lực đến expiry cũ.
- Mã không thay vai trò: sinh viên nhập mã venue walk-in; **staff đúng sự kiện**
  nhập mã vé cá nhân. Sinh viên không tự xác nhận vé registration của mình.
- `verifyWalkInCode({code,requestId})`, `verifyRegisteredCode({code,requestId})`.
  Dùng chung attendance/transaction/ledger với verify QR. Hai cách không thể tạo
  thêm attendance hoặc thưởng hai lần cho cùng UID/event.
- Mỗi UID có tối đa **5 lần thử mới trong 60 giây**, lưu server-side, không reset
  khi đổi thiết bị/process. Lần sai vẫn commit attempt; không bị rollback cùng lỗi.
  Retry của receipt thành công không tiêu tốn thêm attempt. Registered receipt
  vẫn kiểm lại phân công staff, kể cả retry.
- `checkin_codes/{hash}` chỉ có tokenId/mode/expiry, không lưu raw code hoặc QR
  secret; `code_attempts/{hash}` là server-only. Rules deny mặc định, không public.
- Lỗi gồm CODE_INVALID, CODE_EXPIRED, CODE_RATE_LIMITED (retryAfterSeconds),
  OUTSIDE_CHECKIN_WINDOW, FORBIDDEN_STAFF, ALREADY_CHECKED_IN. Không log mã.
- operationKind vẫn verify-ticket / verify-walkin, operationId=requestId.
  Khi mất mạng, recover receipt trước khi tạo một action mới hoặc đổi QR/code.
  Mã/QR đều là bearer tại venue, không chứng minh hiện diện vật lý tuyệt đối.

## Notifications

- **new_event**: khi event trở thành published/public và còn ở tương lai, gửi
  cho người đã Follow CLB tổ chức trước thời điểm công bố. Mỗi UID/event một lần;
  retry hoặc republish không gửi trùng cho người đã nhận. Không broadcast toàn app.
- **schedule_updated**: khi đổi start/end/timezone/check-in window/venue/schedule,
  gửi cho registrations đang registered và Going hiện tại. Đổi counter, ảnh hoặc
  metadata khác không tạo lời nhắc đổi lịch. Retry cùng nội dung không tạo trùng;
  update cũ tới trễ không phát nội dung lịch đã lỗi thời.
- **event_reminder**: lấy startAt trừ **72 giờ**, không phải trừ ba ngày lịch.
  Job every 15 minutes, timezone Asia/Ho_Chi_Minh, retry 3. Bình thường có thể
  trễ một chu kỳ cộng thời gian xử lý; downtime/retry có thể trễ hơn.
- Nhắc người đã đăng ký/Going trước cutoff, còn tham gia và account active.
  Người mới đăng ký sau cutoff nhận registration confirmation, không truy lĩnh
  reminder ba ngày. Không gửi cho cancelled/no_show/attended, account disabled,
  event không còn published/public hoặc đã bắt đầu.
- Reminder có receipt theo event/startAt và từng UID; job chạy chồng không tạo
  hai inbox documents. `notification_runs` server-only đánh dấu fanout hoàn tất.
  Schedule đổi có thể tạo reminder mới theo startAt mới khi đến hạn.
- Inbox là nguồn dữ liệu; deliverNotification gửi FCM qua devices đã đăng ký.
  FCM retries có thể gửi lại, Android tag giữ cùng notification ID; không hứa
  exactly-once delivery trên mọi thiết bị. Native FCM integration vẫn pending.
- entityType cho ba loại mới là `event`, entityId là **eventId**; mobile resolve
  lại event sau auth khi cần, không dùng mapping tên sự kiện cố định trong demo.
- Fanout page 100; phù hợp lab. Cần task queue/checkpoint/due projection trước
  catalog hoặc số người theo dõi lớn vượt thời gian chạy 540 giây.

## Ranh giới Flutter trong task chuẩn bị

- Đã sửa UI policy, nút/status claim, loading, chống bấm trùng và bỏ Skip.
- View → ViewModel → CampusRepository → CampusService. Pending adapter **ném lỗi**
  khi chưa nối SDK; không lưu thành công giả hoặc tự cộng thưởng thành tựu.
- CampusService.claimEventMilestone phải lấy lại account wallet sau receipt rồi
  trả MilestoneClaimResult; không dùng wallet snapshot cũ của receipt làm số dư mới.
- Preview fixtures hiện có vẫn chỉ để xem UI. Danh sách/count/claimed/version
  thật phải lấy từ getEventMilestones khi nối adapter; không giữ cố định năm mốc
  trong production. Interest labels cũng phải đổi sang IDs active từ server.
- Chưa thêm cloud_functions/Firestore SDK adapter, Auth adapter thật, camera/
  QR renderer thật, FCM hoặc Remote Config fetch. Đây là bước tích hợp tiếp theo,
  không lấy tests/fakes của task này làm bằng chứng mobile đã nối Firebase.
- Còn cần dữ liệu catalog được duyệt và UID staff/admin; không seed users,
  attendance, quà giả hoặc cấp xu thử nghiệm trên cloud.

## Kiểm chứng

Backend hiện **51/51 Emulator tests PASS** (bao gồm 41 tests release cũ và cases
FPT/manual code/notifications mới). Flutter baseline trước sửa **141/141 PASS**.
Flutter sau sửa **149/149 PASS**, `flutter pub get`, `dart format lib test` và
`flutter analyze` đạt, không issues. `git diff --check` đạt.
`flutter build apk --debug` đạt; chưa cài lại hoặc thay bản app đang mở trên máy.
Gradle còn cảnh báo tương thích Built-in Kotlin của các Firebase plugins cho
Flutter tương lai; build hiện tại thành công, không nâng dependencies ngoài scope.

**Đã deploy lên prm393-31822 ngày 05/11/2026:** toàn bộ **41/41 Functions ACTIVE**,
cùng source hash; tất cả Cloud Run latest-created = latest-ready, condition
SUCCEEDED. Tăng từ 37 lên 41: thêm hai verify-code callables, eventNotifications
trigger và eventReminderSchedule. Các protected callables cũ được redeploy cùng
FPT guard, không giữ lẫn các revision chưa kiểm domain.

- 15 composite indexes cũ READY; hai collection-group field indexes cho
  following.organizerId/event_intents.eventId READY, đúng query fanout chạy được.
- Tổng ba Scheduler jobs ENABLED. Reminder every 15 minutes, timezone Việt Nam;
  target đúng Function, Cloud Run invoker chỉ service account được phân quyền,
  không public. Không gọi thủ công job để tạo bằng chứng giả.
- Hai verify-code API từ chối anonymous HTTP 401; bốn public catalogs HTTP 200,
  dữ liệu rỗng như kiểm kê. Năm milestone policies vẫn giữ nguyên; Remote Config
  client template version 1 không đổi.
- Không có cloud users/wallets/events/rewards/attendance/notifications/codes hoặc
  staff/voucher-admin assignments được tạo trong task. Positive business cases
  xác minh ở Emulator; native Auth/FCM/scan và claim thật vẫn chưa kiểm chứng.
- Dependency audit production: 6 moderate, 0 high/critical; không force-upgrade
  dependencies trong đợt này. Chưa commit/push các thay đổi trong task.

[Cloud metadata](../evidence/preintegration/cloud-verification.json),
[logs và cách đọc](../evidence/preintegration/README.md). Deploy dùng Node22 và
nhóm tối đa 4 Functions; toàn bộ 11 batch logs ở evidence/firebase-migration/
deploy-20261105-112147. Không đồng nhất checks này với mobile E2E.

Nguồn nền tảng:
[Firestore triggers và retry/order](https://firebase.google.com/docs/functions/firestore-events),
[scheduled Functions](https://firebase.google.com/docs/functions/schedule-functions).
