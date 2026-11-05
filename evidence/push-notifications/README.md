# Push notification thật — 06/11/2026

Firebase `prm393-31822`, Android SM-G996N. [Contract/demo](../../docs/PUSH_NOTIFICATIONS.md).
Chỉ thay sender FCM, Android notification host và Messaging SDK adapter;
không sửa Widget/ViewModel/layout của các màn app.

## Validation đã thực hiện

- `flutter pub get`, `dart format lib test`, `flutter analyze`: đạt, analyze sạch.
- Full Flutter suite: **216/216 đạt**. Ba tests mới kiểm foreground notification,
  giữ event data, data-only không tạo notification rỗng và native error không
  báo thành công. Stream dùng test-only input; không cần Firebase account.
- Backend Emulator Node22/Java21: **64/64 đạt**. Hai tests mới kiểm channel và
  priority, không có device, token hết hạn và giữ retry cho lỗi tạm thời.
- APK debug arm64, Firebase thật, tắt local demo auth: build/cài/startup đạt.
- `git diff --check`: đạt. Không đổi dependencies hoặc Rules.

Lần analyze đầu có hai lint ở constructor/fake callback, đã sửa rồi chạy lại
format/analyze/full tests. Build còn cảnh báo KGP hiện có của plugins; build
thành công, không nâng dependencies ngoài phạm vi.

## Firebase triển khai

Chỉ deploy `deliverNotification`. [Metadata](function-after.json) ghi ACTIVE,
revision `delivernotification-00004-yev`, latest created = latest ready.
Sender chọn HIGH delivery priority, channel `evia_events_v1`, notification icon
và tag theo notification ID. Log đếm FCM chấp nhận/từ chối, không chứa token.
[Ba dispatch logs](cloud-delivery.json) đều successCount=1, failureCount=0.
Đây là FCM acceptance; bằng chứng hiển thị nằm ở kiểm tra native dưới đây.

## Điện thoại thật

Trước test: quyền POST_NOTIFICATIONS đã cấp, DND=0, heads-up enabled=1. App
tạo kênh `evia_events_v1` importance=4, giữ nguyên kênh fallback cũ và quyền
người dùng. Cài APK mới giữ phiên đăng nhập. Chỉ gửi ba bản tin riêng đến UID
đang đăng nhập, không gửi hàng loạt, không sửa coin/event/attendance của owner.

| Trạng thái | Kết quả quan sát |
|---|---|
| App đang mở màn Notifications | [Banner nổi](foreground-banner.png), inbox cập nhật. Bấm notification mở [Career đúng payload](foreground-open.png) |
| App chạy nền | Notification thật vào khay hệ thống, channel importance=4; bản tin thứ hai trỏ Workshop |
| Tiến trình app đã đóng | Xác nhận PID main không còn trước gửi; [banner nổi trên launcher](terminated-banner.png). Bấm notification khởi động app, qua startup rồi mở [Workshop đúng payload](terminated-open.png) |

Test tiến trình đóng dùng kill đúng PID thuộc app debug sau khi chuyển nền,
không dùng Android force-stop làm trạng thái nhận push. Lần `am kill` đầu không
đóng được PID nên không được ghi nhận là test terminated đạt; đã kiểm lại PID
trước lần gửi thứ ba. UI startup cần chờ mạng; ảnh loading không tính là mở
event thành công. Ảnh kết quả được chụp sau khi event tải xong.

## Giới hạn

- Chưa kiểm riêng màn hình khóa hoặc các hãng/thiết bị khác.
- Chưa tạo thêm event live để fanout tới toàn bộ followers trong lượt này;
  fanout giữ code cũ và có Emulator tests. Ba native tests dùng cùng trigger
  gửi FCM đang triển khai, tạo inbox demo chỉ cho một UID.
- Không bật Analytics/BigQuery, không thêm device ack. SuccessCount không được
  diễn giải thành thiết bị đã nhận; native screenshots là bằng chứng riêng.
- Kênh/quyền/DND người dùng và tình trạng mạng vẫn ảnh hưởng hiển thị.
- Nội dung inbox demo lịch sử không bị sửa; bản tin mới đã bỏ câu “đã gửi push”.
- Bằng chứng ghi nhận trước commit; tài khoản, token và APK giữ ngoài Git.
