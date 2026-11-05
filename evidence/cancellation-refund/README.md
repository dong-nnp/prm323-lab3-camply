# Chính sách hủy hoàn 30% — 05/11/2026

Owner thay quy tắc chủ động hủy: hoàn 30% cọc, làm tròn xuống số xu nguyên.
`refund=floor(registration.depositCoins*3/10)`, `forfeit=deposit-refund`.
Cọc 50 → hoàn 15/mất 35; cọc 55 → hoàn 16/mất 39. No-show vẫn mất toàn bộ.

Transaction hủy cập nhật wallet, revoke ticket, trả một chỗ, registration snapshot,
ledger `deposit_partial_refund` và operation receipt nguyên tử. Retry cùng requestId
không hoàn lần hai; request mới trên registration đã hủy bị từ chối. Đăng ký lại
giữ cọc mới. Không hoàn bù/sửa ledger hoặc receipt đã quyết toán trước cập nhật.

- [Build TypeScript](build.log) đạt.
- [Emulator suite](emulator-tests.log): **56/56 PASS**, không fail/skipped. Có
  retry/race, mở lại chỗ, làm tròn 0/1/3/4/55/199, dùng cọc snapshot khi giá event
  thay đổi, tranh chấp hủy/check-in, no-show và transport Auth thật qua Emulator.
- Lệnh Emulator có exit code 2 **sau khi test script đã exit 0 và toàn bộ 56 tests
  đạt**, do Firebase CLI timeout khi shutdown. Không ghi nhận exit code CLI là pass.
  Lần đầu dùng Java17 không khởi chạy được (`red-test.log`); lần sau discovery
  timeout 10s làm transport 404 (`emulator-tests-first-attempt.log`); đã sửa môi
  trường sang Java21 và `FUNCTIONS_DISCOVERY_TIMEOUT=60`. Đây không phải evidence
  RED của business logic.
- [Flutter suite](flutter-test.log): **173/173 PASS**; [analyze](analyze.log) sạch;
  [format](format.log), [pub get](pub-get.log) đạt. Preview hủy hoàn 30% một lần,
  rounding 55→16, refund được phân loại deposit transaction thay vì event reward.
- Giữ layout/style/assets. Chỉ sửa copy của dialog/terms/ghi chú hiện có và binding
  số xu refund; không bổ sung màn hoặc gắn thêm Flow 2 trong lượt policy này.

Cloud target duy nhất là `cancelRegistration` ở `prm393-31822/asia-southeast1`.
Đã [deploy thành công](deploy.log), function ACTIVE, Cloud Run latest revision
`cancelregistration-00004-fad` READY: [trước](function-before.json)/[sau](function-after.json).
Đã cập nhật 8 event terms sang `demo-refund30-v2`: [plan](terms-plan.json),
[backup](terms-before.json), [verify](terms-applied.json). Batch dùng updateTime
precondition, chỉ đổi registrationTerms/updatedAt; đã đối chiếu các trường khác
không thay đổi. Việc verify đầu tiên lỗi do CLI Client options giữ request body;
đã sửa options, đọc lại toàn bộ và xác minh 8 records, không apply lần hai.
File metadata/deploy/terms trong thư mục này ghi nhận kết quả live thực tế; không
lấy kết quả Emulator làm bằng chứng đã phát sinh hoàn xu trên production.
Không gọi hủy vé thật để thử tiền, không tạo attendance/bonus. Nút hủy thật của
mobile vẫn chưa gắn ở Flow 2; thay đổi runtime server và source app là hai lớp riêng.
