# Event editor — 06/11/2026

Implementation và validation tại [ADMIN_EVENT_EDITOR.md](../../docs/ADMIN_EVENT_EDITOR.md).

- `simple-event-form.png`: ảnh form đang mở, chọn danh mục/ban tổ chức từ catalog
  thật và preview asset có sẵn; chưa lưu thành một sự kiện thật.
- `storage-verification.json`: kết quả Firebase Web SDK upload/download/checksum
  trên bucket thật, xóa ảnh QA sau kiểm tra. Không chứa credentials, token hoặc UID.
- `storage-service-permission.json`: role cross-service được xác minh trên
  Firebase Storage service agent; không thay quyền người dùng.

Admin 12/12 + build; backend Emulator suite 81/81 + TypeScript build đạt.
Lượt đầu cấu hình emulator thiếu Functions và test Auth trùng email fixture đã
được sửa trong setup; lượt đầy đủ cuối cùng không fail/skipped. Storage create-only
được kiểm bằng cả upload lại cùng tên; đã bổ sung guard resource == null.
