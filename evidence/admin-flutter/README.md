# Nghiệm thu Flutter Admin — 06/11/2026

Project thật `prm393-31822`, region `asia-southeast1`. Portal nằm riêng trong
`admin_flutter/`; không thay UI sinh viên. Một admin làm hết, không phân công staff.
Không commit/push hoặc thay Hosting trong lượt này.

## Đã kiểm tra thực tế

- Backend Emulator: toàn bộ **76/76 tests đạt**. Bao gồm quyền thường/staff/admin,
  admin quét vé/phát QR không cần assignment, organizer revision/followerCount,
  dữ liệu cá nhân chỉ trả fields cho phép, phân trang, gửi demo idempotent,
  xác nhận quà vật lý một lần/không thêm debit. Test voucher và milestone không
  cần allowlist; disable profile chặn cả retry receipt.
  Sau sửa thao tác xóa URL logo CLB, chạy lại 7/7 tests workspace đạt; xác nhận
  logo bị xóa thật và followerCount vẫn giữ nguyên.
- Flutter admin: format/analyze đạt; **11/11 tests đạt**, gồm bootstrap chưa cấu
  hình không gọi Firebase/không fake login, auth guard staff/signed out, khóa
  submit trùng, giữ requestId khi timeout, parse voucher QR, giờ Việt Nam,
  published identity locks và form save. Các trang được render ở 360/412/1440 với chữ 2×;
  đã sửa dropdown khoảng thời gian bị tràn ngang ở 360 với chữ 2×.
- App sinh viên: analyze đạt; **218/218 tests đạt**. Không đổi mobile Dart/native
  hoặc dependencies trong lượt này; không cần APK mới cho portal web độc lập.
- `flutter build web --dart-define-from-file=../.local/admin-flutter-live.json`
  đạt. Build có cảnh báo icon font Cupertino của dependency; không chặn build.
- Firebase thật: 16 Functions đợt triển khai ACTIVE; read checks và revisions
  ở [cloud-verification.json](cloud-verification.json). Staff bị từ chối vào portal;
  tài khoản admin hiện có đăng nhập/read được dữ liệu thật.
- Browser thật: đăng nhập admin, xem events/CLB, tạo `demo-admin-web-smoke` với
  `published:false`, tải lại bản release và vẫn thấy record. Xem Remote Config
  version 5 từ server. [Ảnh record đã lưu](saved-club.png).

API read checks không sửa ví, attendance, giá quà, definition milestones hoặc
Remote Config. Browser chỉ tạo thêm CLB demo chưa công khai; không xuất bản sự kiện
hay fanout thông báo từ bài kiểm thử này. Không nhúng credentials vào evidence.
Logs chi tiết nằm riêng trong `.local/admin-flutter-*.log` (Git ignore).

## Giới hạn còn lại

- Remote Config đọc được; Analytics trả danh sách rỗng, không có bằng chứng dữ liệu
  tracking mới từ portal. Crashlytics report trả `CRASHLYTICS_NOT_CONFIGURED`;
  cần bảng BigQuery export và quyền/cấu hình trước khi báo cáo có dữ liệu.
- Chưa thử camera quét vé vật lý/voucher bằng browser hoặc kiểm bàn giao ngoài đời.
  Kiểm QR/manual/tiền/receipt dùng Emulator; không trộn thành cloud end-to-end proof.
- Không gửi thêm push từ portal tới điện thoại trong lượt này. FCM acceptance
  không xác nhận banner; các bằng chứng push trên điện thoại ở task trước.
- Chỉ có preview local `http://127.0.0.1:8768` khi server còn chạy; chưa publish web.
- RequestId đang chờ giữ RAM, mất khi reload tab. Server chặn double use/debit;
  tra lại trạng thái nếu reload sau timeout. Tìm kiếm chỉ trong trang 20 records.

Hướng dẫn: [admin_flutter/README.md](../../admin_flutter/README.md).
