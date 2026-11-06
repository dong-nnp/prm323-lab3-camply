# Báo cáo Analytics live — 06/11/2026

Đã deploy riêng `evia:getAdminAnalyticsReport` vào `prm393-31822`,
region `asia-southeast1`, Node.js 22 Gen 2. Firebase CLI báo Successful update
và Deploy complete. Không deploy các callable khác, Rules hoặc Hosting;
không sửa GA4 permissions/property hoặc dữ liệu nghiệp vụ.

## Validation

- TypeScript build và hai query tests đạt trước khi deploy.
- Gọi callable thật bằng tài khoản admin demo: 6 tổ hợp nguồn/khoảng ngày
  Android/Web/Theo cấu hình × 7/30 ngày đều HTTP 200.
- Android trả 4 loại event, Web trả 5, toàn property trả 7 tại thời điểm kiểm.
  Đây là số dòng loại hành vi, không phải tổng lượt hoặc số người dùng.
- Caller cũ `{days:7}` vẫn HTTP 200, scope property.
- Anonymous bị UNAUTHENTICATED; staff bị PERMISSION_DENIED;
  source ngoài allowlist bị INVALID_ARGUMENT.
- Trên Chrome đang đăng nhập admin tại localhost:5173/#analytics, bấm
  Tải báo cáo với App Android/7 ngày: hết lỗi đỏ, bảng có bốn dòng và status
  “Đã tải 4 mục. Nguồn: Android · tất cả stream Android trong property.”

[Kết quả API tổng hợp](verification.json), [ảnh UI thật](admin-android-report.png).
JSON không chứa credentials, ID tokens hoặc UID của tài khoản test.
Script kiểm tra có assertions nằm trong `.local/` được Git ignore;
chỉ đăng nhập tài khoản có sẵn và đọc báo cáo, không tạo dữ liệu mẫu.

Báo cáo GA4 tổng hợp có độ trễ; kết quả bốn dòng tại thời điểm kiểm không
chứng minh tất cả events vừa thấy trong DebugView đã vào báo cáo tổng hợp.
Lượt này không đổi Dart/native nên không chạy lại Flutter suite/APK.
