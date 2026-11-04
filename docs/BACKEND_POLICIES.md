# Quy tắc backend đã chốt — 04/11/2026

Các quyết định trong chat hiện tại thay thế những mục Monthly Gift/no-show/re-registration/cashier còn OPEN ở tài liệu v1.3 trước đây. Implementation mới **chỉ local, chưa deploy**; không suy ra jobs đang chạy trên Firebase thật.

## Monthly Gift

- Chủ dự án chốt: **mọi tài khoản người dùng được tự cộng 200 xu ngày 1 hằng tháng**. Dùng timezone sản phẩm đã chốt `Asia/Ho_Chi_Minh`, lịch `0 0 1 * *` lúc 00:00.
- Tài khoản trong dữ liệu app là profile + wallet được `initializeUser` khởi tạo. Job không đòi onboarding; không lấy client eligibility flag. Auth account chưa khởi tạo profile/wallet chưa có ví để nhận; mobile phải luôn gọi initializeUser sau login.
- Kỳ tháng xét profile tồn tại vào 00:00 ngày 1; tài khoản được tạo sau mốc này bắt đầu từ ngày 1 tháng sau, không truy lĩnh giữa tháng. Đây là cách thực thi lịch ngày 1, không thêm nút claim.
- `monthlyGiftSchedule` nhận `scheduleTime` của lần cron, không tính kỳ từ lúc retry thực chạy; retry sau midnight/tháng sau vẫn gắn đúng kỳ ban đầu.
- Mỗi UID/tháng một `users/{uid}/monthly_grants/{YYYY-MM}` + wallet update + ledger `monthly_gift` trong cùng transaction. Retry/runs trùng không cấp hai lần; năm mới có month key mới.
- Callable cũ `grantMonthlyGift` giữ để client cũ nhận lỗi rõ `AUTOMATIC_ONLY`; không cho client chọn UID/tháng/số xu.
- Không tự backfill những tháng trước lúc triển khai. Khi vận hành cần replay một lần chạy lỗi, operator tin cậy dùng đúng scheduled timestamp, không đưa API replay public cho mobile.

## No-show

- Chủ dự án chốt: không tham dự thì **mất cọc, không hoàn**.
- `noShowSchedule` kiểm tra mỗi 60 phút, chỉ xử lý registration còn `registered` khi **cả sự kiện và cửa sổ check-in đã kết thúc**. Có thể xuất hiện trễ tối đa một chu kỳ job cộng thời gian chạy/retry.
- Transaction chuyển state thành `no_show`, vé `revoked`, held giảm đúng deposit, available giữ nguyên và có ledger `no_show_forfeit` nếu deposit >0. Không cấp attendance reward.
- State/ticket/wallet transaction chống chạy trùng hoặc tranh chấp với check-in/cancel. Event count giữ số chỗ đã phân bổ cho sự kiện đã kết thúc, không mở đăng ký lại sau giờ đóng.
- Registration đã cancel/attend không bị xử lý lại. Event `cancelled` không tự coi là no-show: hoàn cọc do đơn vị hủy là policy riêng chưa được yêu cầu.

## Đăng ký lại sau hủy

- Chủ dự án chốt: được đăng ký lại nếu slot còn trống. Kiểm tra capacity và đóng đăng ký tại transaction time; không giữ slot ưu tiên cho người vừa hủy.
- Client dùng requestId mới. Cọc đã mất của lần trước không hoàn; lần mới giữ cọc theo quote/terms hiện tại.
- Registration canonical vẫn theo `(uid,eventId)`. Lần hủy cũ được archive server-only tại `registrations/{id}/history/{oldTicketId}`; ledger/receipts cũ giữ nguyên.
- TicketId mới theo registration + requestId. Vé và QR cũ không được kích hoạt lại; counter tăng đúng một nếu thắng slot.

## Voucher ở nhà tài trợ, admin xác nhận sử dụng

- Chủ dự án chốt: sử dụng voucher tại nhà tài trợ của sự kiện; **admin xác nhận đã dùng**. Không yêu cầu tài khoản thu ngân riêng từng quán.
- Admin cần Firebase custom claim `admin:true` **và** server-only document `voucher_admins/{uid}` có `{active:true}`. Backend không tự cấp quyền; mobile/Firestore clients không ghi được các quyền này.
- Admin phải là tài khoản app đã initialize/onboard theo operation contract hiện có. Chưa có admin UI hoặc công cụ tự cấp role.
- QR owner: `evia:voucher:<voucherId>:<code>`. Verifier tách code, gọi `verifyVoucher({code,requestId})`; backend tìm secret qua hash, kiểm unused và expiry, rồi atomically cập nhật voucher + redemption + receipt.
- Thành công trả `{voucherId,redemptionId,status:'used',usedAt}`; lưu `usedBy` server-side. Không trả PII chủ voucher, không trừ xu thêm.
- Cùng requestId retry trả receipt; request mới dùng lại code trả `USED`. Admin bị revoke trong document không được gọi lại hoặc đọc receipt verifier qua getOperationStatus.
- Stock/price/terms/expiry/địa điểm sử dụng phải lấy từ catalog thật đã duyệt; không seed nhà tài trợ minh họa. Chưa có rotation mã, hoàn đổi thưởng hoặc xử lý tranh chấp.

## Ranh giới triển khai và validation

- Source mới có **34 exports** (32 trước đó + 2 scheduled Functions); số deployed vẫn là snapshot cũ 32 cho đến khi deploy thật.
- Jobs đọc từng trang 100 records, xử lý per-record transaction, dừng và retry khi lỗi. Phù hợp lab; cần task queue/checkpoint trước khi fanout lớn có nguy cơ quá timeout 540 giây.
- Emulator kiểm business logic trực tiếp, không chứng minh Cloud Scheduler tự gọi đúng lịch/IAM trên cloud. Phải kiểm scheduler timezone, service account, retries và logs sau deployment.
- Triển khai scheduled Functions tạo tài nguyên Cloud Scheduler và có thể có phí; lượt này không tạo tài nguyên hay ghi tiền trên project thật.

Nguồn triển khai: [maintenance.ts](../functions/src/maintenance.ts), [events.ts](../functions/src/events.ts), [rewards.ts](../functions/src/rewards.ts). Nguồn nền tảng: [Firebase scheduled Functions](https://firebase.google.com/docs/functions/schedule-functions), [ScheduledEvent.scheduleTime](https://firebase.google.com/docs/reference/functions/2nd-gen/node/firebase-functions.scheduler.scheduledevent).
