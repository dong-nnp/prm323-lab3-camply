# Gửi thông báo trực tiếp từ Vite admin

## Demo không cần sự kiện

1. Trên điện thoại, đăng nhập bằng tài khoản nhận. Mở Thông báo và cho phép
   ứng dụng gửi thông báo. Giữ mạng; có thể đưa app xuống nền.
2. Trên `admin/`, mở **Thông báo**, chọn đúng tài khoản đang dùng trên điện thoại.
3. Nhập nội dung tối đa 500 ký tự và bấm **Gửi thông báo**. Tiêu đề cố định là
   **Thông báo từ Evia**. Không cần follow CLB, tạo sự kiện hoặc dùng tài khoản demo.
4. Khi nhận push, nhấn để mở hộp thư trong app. Thông báo cũng được lưu trong inbox.

Form chỉ gửi tới một tài khoản được chọn; không broadcast. Danh sách phân trang
lấy các tài khoản active qua API quản trị hiện có, hiển thị tên/email để dễ chọn.
Nếu tài khoản chưa đăng ký thiết bị, form báo cách đăng nhập và cấp quyền trên app.
Nút Tải lại người nhận dùng khi có tài khoản mới hoặc khi tải danh sách lỗi.

## Contract và bảo vệ

- `sendAdminNotification({uid, body, requestId})`: cần admin claim và profile active.
  Recipient phải active và có ít nhất một device đăng ký. Backend trim body,
  giới hạn 1–500 ký tự; từ chối field không được định nghĩa.
- Ghi một document notifications loại `admin_message`, title cố định, body đã
  validate, entityType `inbox`, entityId rỗng, readAt null và createdBy admin UID.
  Không đọc/ghi event, vé, ví hoặc gửi token thiết bị về trình duyệt.
- ID phụ thuộc admin UID + requestId. Retry cùng nội dung/người nhận trả cùng ID;
  dùng lại requestId cho dữ liệu khác bị từ chối. Client giữ request khi lỗi,
  khóa form lúc gửi và xóa nội dung sau khi API trả thành công.
- Trigger `deliverNotification` hiện có gửi FCM qua channel `evia_events_v1`.
  Tap không có event được app hiện tại mở `/profile/notifications`, không đổi APK.
- Kết quả `queued` chỉ xác nhận đã lưu/xếp hàng, không xác nhận điện thoại đã hiện
  banner. FCM/Firestore trigger có thể retry; idempotency bảo vệ inbox, không phải
  cam kết push đúng một lần. Kết quả dispatch giữ trong pushDispatch như trước.
- Android có thể không hiện banner nếu quyền/kênh thông báo bị tắt hoặc app bị
  force-stop. Mở lại app và kiểm tra quyền trước khi demo.

## Triển khai và kiểm tra

Build backend rồi triển khai riêng callable mới, dùng trigger FCM đang có:

```powershell
npm --prefix functions run build
npx firebase-tools deploy --project prm393-31822 --only functions:evia:sendAdminNotification --non-interactive
```

Form Vite nằm trong `admin/src/notifications.js`, gọi qua adapter `firebase.js`;
route/auth reset do `main.js` điều phối. Không thêm dependency, tracking, Rules
hoặc thay đổi UI sinh viên. Các luồng thông báo sự kiện tự động vẫn giữ nguyên.

Evidence và validation của lượt này: [admin-notifications](../evidence/admin-notifications/README.md).
