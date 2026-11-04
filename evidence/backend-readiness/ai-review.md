# AI review output — Codex, 04/11/2026

Phạm vi: backend và integration contract tại commit `7e9c7bf`, so với `ff260d2`. Review local bằng Codex chat assistant, không phải output CodeRabbit/Copilot, không có PR approval. Tải dự kiến: lab traffic; không audit tải production lớn hoặc Flutter UI.

1. **CR-01 — Bug:** `functions/src/catalog.ts:15,30` cho terms version tới 128 ký tự, nhưng register/redeem requests chỉ nhận tối đa 100. Catalog với version 101 ký tự import được nhưng user không thể xác nhận terms hợp lệ. Giới hạn importer về 100, test cả event/reward tại ranh giới.
2. **CR-02 — Validation:** `functions/src/catalog.ts:32` cho catalog rỗng qua dry-run nhưng apply mới từ chối. Preflight cho `{}` báo thành công sai. Đưa non-empty validation vào schema dùng chung và test subprocess dry-run không gọi Firebase.
3. **CR-03 — Bug:** `functions/src/queries.ts:43` bỏ combining marks chưa chuyển đ sang d. Query “doan” không khớp “Đoàn”, trái contract không dấu. Normalize d-stroke; Emulator test cả query có/không dấu, giữ nguyên nội dung output.
4. **CR-04 — Contract/maintainability:** `docs/backend-integration.md:66` mô tả profile fields nullable nhưng accounts.ts chỉ cho phoneNumber null. Frontend gửi displayName null sẽ lỗi VALIDATION_FAILED. Sửa tài liệu, không tự mở rộng quyền xóa fields.
5. **CR-05 — Integration/test gap:** `docs/backend-integration.md:84,172–177` thiếu cách resolve notification ticketId sang eventId trong getTicket. Truyền entityId thẳng vào eventId sẽ mở vé sai/không tìm thấy. Handoff cần owner lookup tickets/{ticketId} trong service, allowlist entity types và native acceptance case; chưa cần thêm endpoint.

Verification đã quan sát:

- CR-01 RED: test terms versions thất bại `true !== false`; GREEN: standalone suite 4/4.
- CR-02 RED: empty dry-run test thất bại `Missing expected rejection`; GREEN: catalog suite 4/4.
- CR-03 RED: [Emulator](emulator-before-search-fix.log) 22 pass/1 fail; [scoped GREEN](search-after-fix.log) 1/1 pass.
- CR-04/05: đối chiếu source/Rules rồi sửa docs; chưa có native UI evidence.

Đánh giá: sửa ba lỗi code trước handoff. Giới hạn scan trang, QR không chứng minh hiện diện và FCM delivery chưa test thật vẫn phải công khai. Không tạo findings bằng nhận xét phong cách để đủ số.
