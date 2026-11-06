# Quy tắc backend đã chốt — 04/11/2026

> **Demo attendance — 05/11/2026, owner yêu cầu:** callable riêng
> `demoConfirmAttendance` chỉ chạy khi user có `isDemo:true` và
> `demoAttendanceEnabled:true`, event cũng `isDemo:true`. Server kiểm ownership,
> active ticket, receipt/transaction; client không thể tự bật cờ. Nút chỉ hiện
> debug. Chỉ demo bỏ cửa sổ check-in để trình diễn sự kiện tương lai; attendance
> ghi rõ `isDemo`/`verificationMethod`. QR thật vẫn giữ staff/window/rate guards.
> [Cách vận hành/tắt demo và evidence](../evidence/flow2-api-only/).

> **Email mở rộng 05/11/2026:** owner bỏ giới hạn domain email. Mọi địa chỉ
> đúng định dạng đều được đăng ký/đăng nhập/tham gia. MSSV vẫn hai chữ + sáu số;
> quyền staff/admin và điều kiện sự kiện giữ nguyên. [Contract](PREINTEGRATION_DECISIONS.md).

> **Bổ sung sau review 05/11/2026:** email domain mở, QR + mã dự phòng và ba loại
> notifications mới theo [PREINTEGRATION_DECISIONS.md](PREINTEGRATION_DECISIONS.md).
> Bỏ feedback/thành tích theo học kỳ. Café 200 nhưng chưa tạo record cloud khi
> không có stock/nhà tài trợ/địa điểm/terms được duyệt.

> **Bổ sung 05/11/2026:** owner chốt khôi phục thành tựu lifetime verified events,
> user bấm Nhận thưởng một lần/mốc. 1/3/5/10/20 → 50/100/150/300/500 xu;
> tổng +1.100 ngoài event reward. Admin-managed catalog và UI-only Remote Config:
> [hợp đồng version/snapshot/claim](EVENT_MILESTONES.md). Các số 34 Functions ở
> bản release 04/11 bên dưới là lịch sử; feature này bổ sung 3 callables thành 37.

Các quyết định trong chat hiện tại thay thế những mục Monthly Gift/no-show/re-registration/cashier còn OPEN ở tài liệu v1.3 trước đây. Implementation mới **đã deploy lên project prm393-31822**; hai jobs ENABLED, metadata/IAM đã verify. Xem [release](backend-release.md); chưa kiểm chứng lần chạy tự nhiên trên dữ liệu thật.

## Monthly Gift

- Chủ dự án chốt: **mọi tài khoản người dùng được tự cộng 200 xu ngày 1 hằng tháng**. Dùng timezone sản phẩm đã chốt `Asia/Ho_Chi_Minh`, lịch `0 0 1 * *` lúc 00:00.
- Tài khoản trong dữ liệu app là profile + wallet được `initializeUser` khởi tạo. Job không đòi onboarding; không lấy client eligibility flag. Auth account chưa khởi tạo profile/wallet chưa có ví để nhận; mobile phải luôn gọi initializeUser sau login.
- Kỳ tháng xét profile tồn tại vào 00:00 ngày 1; tài khoản được tạo sau mốc này bắt đầu từ ngày 1 tháng sau, không truy lĩnh giữa tháng. Đây là cách thực thi lịch ngày 1, không thêm nút claim.
- `monthlyGiftSchedule` nhận `scheduleTime` của lần cron, không tính kỳ từ lúc retry thực chạy; retry sau midnight/tháng sau vẫn gắn đúng kỳ ban đầu.
- Mỗi UID/tháng một `users/{uid}/monthly_grants/{YYYY-MM}` + wallet update + ledger `monthly_gift` trong cùng transaction. Retry/runs trùng không cấp hai lần; năm mới có month key mới.
- Callable cũ `grantMonthlyGift` giữ để client cũ nhận lỗi rõ `AUTOMATIC_ONLY`; không cho client chọn UID/tháng/số xu.
- Không tự backfill những tháng trước lúc triển khai. Khi vận hành cần replay một lần chạy lỗi, operator tin cậy dùng đúng scheduled timestamp, không đưa API replay public cho mobile.

## Chủ động hủy đăng ký — cập nhật 05/11/2026

- Đã deploy riêng `cancelRegistration` lên `prm393-31822`, revision mới READY;
  8 điều khoản demo đã đồng bộ. [Release evidence](../evidence/cancellation-refund/).
- Owner chốt hoàn **30% số xu cọc của lần đăng ký**, làm tròn xuống:
  `refund = floor(registration.depositCoins * 3 / 10)`. Cọc 50 → hoàn 15/mất 35;
  cọc 55 → hoàn 16/mất 39. Không tính trên tổng ví hoặc giá cọc hiện tại của event.
- Transaction giảm held toàn bộ cọc, cộng available đúng refund, thu hồi vé và
  giảm registeredCount một lần. Không cấp attendance/event reward/thành tựu.
- Registration lưu `depositSettlement: partially_refunded` (cọc 0: `none`),
  `cancellationRefundCoins`, `cancellationForfeitedCoins`,
  `cancellationPolicyVersion: refund-30-floor-v1`.
- Ledger mới `deposit_partial_refund`: `deltaAvailable=refund`, `deltaHeld=-deposit`.
  Response/receipt trả `depositRefunded`, `depositForfeited`, wallet. Cùng requestId
  trả lại receipt; request khác trên registration đã hủy bị từ chối, không hoàn lần hai.
- Áp dụng cho thao tác hủy mới. Không backfill các lần đã hủy/settle hoặc sửa receipt,
  ledger, attendance cũ. No-show vẫn mất toàn bộ cọc theo quy tắc bên dưới.
- Mobile Flow 2 chưa nối nút hủy thật; chỉ đồng bộ copy trong dialog cũ và preview.
  Các kiểm chứng release mới ghi ở [evidence/cancellation-refund](../evidence/cancellation-refund/).

## No-show

- Chủ dự án chốt: không tham dự thì **mất cọc, không hoàn**.
- `noShowSchedule` kiểm tra mỗi 60 phút, chỉ xử lý registration còn `registered` khi **cả sự kiện và cửa sổ check-in đã kết thúc**. Có thể xuất hiện trễ tối đa một chu kỳ job cộng thời gian chạy/retry.
- Transaction chuyển state thành `no_show`, vé `revoked`, held giảm đúng deposit, available giữ nguyên và có ledger `no_show_forfeit` nếu deposit >0. Không cấp attendance reward.
- State/ticket/wallet transaction chống chạy trùng hoặc tranh chấp với check-in/cancel. Event count giữ số chỗ đã phân bổ cho sự kiện đã kết thúc, không mở đăng ký lại sau giờ đóng.
- Registration đã cancel/attend không bị xử lý lại. Event `cancelled` không tự coi là no-show: hoàn cọc do đơn vị hủy là policy riêng chưa được yêu cầu.

## Đăng ký lại sau hủy

- Chủ dự án chốt: được đăng ký lại nếu slot còn trống. Kiểm tra capacity và đóng đăng ký tại transaction time; không giữ slot ưu tiên cho người vừa hủy.
- Client dùng requestId mới. Lần hủy trước đã hoàn 30% cọc (làm tròn xuống), phần mất không hoàn thêm; lần mới giữ toàn bộ cọc theo quote/terms hiện tại.
- Registration canonical vẫn theo `(uid,eventId)`. Lần hủy cũ được archive server-only tại `registrations/{id}/history/{oldTicketId}`; ledger/receipts cũ giữ nguyên.
- TicketId mới theo registration + requestId. Vé và QR cũ không được kích hoạt lại; counter tăng đúng một nếu thắng slot.

## Voucher ở nhà tài trợ, admin xác nhận sử dụng

- Chủ dự án chốt: sử dụng voucher tại nhà tài trợ của sự kiện; **admin xác nhận đã dùng**. Không yêu cầu tài khoản thu ngân riêng từng quán.
- Từ 06/11/2026: Admin cần custom claim `admin:true`, profile active đã initialize/onboard; không cần `voucher_admins` allowlist. Backend không tự cấp quyền; mobile/Firestore clients không ghi được role.
- Đã có [Flutter admin web](ADMIN_WEB_PLAN.md) xác nhận voucher và bàn giao quà vật lý; không có công cụ tự cấp role hoặc sửa ví tùy ý.
- QR owner: `evia:voucher:<voucherId>:<code>`. Verifier tách code, gọi `verifyVoucher({code,requestId})`; backend tìm secret qua hash, kiểm unused và expiry, rồi atomically cập nhật voucher + redemption + receipt.
- Thành công trả `{voucherId,redemptionId,status:'used',usedAt}`; lưu `usedBy` server-side. Không trả PII chủ voucher, không trừ xu thêm.
- Cùng requestId retry trả receipt; request mới dùng lại code trả `USED`. Admin có profile bị disable không được gọi lại hoặc đọc receipt verifier qua getOperationStatus; bỏ claim cần refresh token/thu hồi phiên để quyền trong ID token được cập nhật.
- Stock/price/terms/expiry/địa điểm sử dụng phải lấy từ catalog thật đã duyệt; không seed nhà tài trợ minh họa. Chưa có rotation mã, hoàn đổi thưởng hoặc xử lý tranh chấp.

## Ranh giới triển khai và validation

- Source mới có **34 exports** (32 trước đó + 2 scheduled Functions); 34/34 đã deploy, cùng source hash và Cloud Run latest revisions READY.
- Jobs đọc từng trang 100 records, xử lý per-record transaction, dừng và retry khi lỗi. Phù hợp lab; cần task queue/checkpoint trước khi fanout lớn có nguy cơ quá timeout 540 giây.
- Emulator kiểm business logic trực tiếp, không chứng minh Cloud Scheduler tự gọi đúng lịch/IAM trên cloud. Scheduler timezone/service account/retry config đã kiểm trong release; business execution theo lịch thật chưa được dùng làm evidence.
- Triển khai scheduled Functions tạo tài nguyên Cloud Scheduler và có thể có phí; release đã được người dùng cho phép và tạo hai Scheduler jobs; không gọi thủ công job hoặc ghi tiền thử nghiệm.

Nguồn triển khai: [maintenance.ts](../functions/src/maintenance.ts), [events.ts](../functions/src/events.ts), [rewards.ts](../functions/src/rewards.ts). Nguồn nền tảng: [Firebase scheduled Functions](https://firebase.google.com/docs/functions/schedule-functions), [ScheduledEvent.scheduleTime](https://firebase.google.com/docs/reference/functions/2nd-gen/node/firebase-functions.scheduler.scheduledevent).
