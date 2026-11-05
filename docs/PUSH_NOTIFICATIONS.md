# Push notification Android qua Firebase

Ngày 06/11/2026. Project `prm393-31822`, region `asia-southeast1`.

Thông báo sự kiện mới/lịch/reminder tiếp tục được backend tạo vào inbox;
`deliverNotification` gửi qua FCM. `push_notifications.ts` dùng Android delivery
priority `high`, channel `evia_events_v1`, icon `ic_notification` và tag theo ID
thông báo. Log `FCM dispatch finished` ghi notificationId, successCount và
failureCount: success là FCM chấp nhận, không phải xác nhận thiết bị đã hiển thị.
Token hết hạn vẫn được dọn; lỗi tạm thời vẫn được retry như trước.

Khi real Messaging adapter lấy token, app tạo kênh Android HIGH trước khi đăng
ký thiết bị. Khi app nền, Firebase SDK hiển thị notification. Khi app đang mở,
service nhận FCM và gọi native Android NotificationManager qua MethodChannel
`evia/notifications`; sau đó ViewModel tải lại inbox như trước. Không thêm thư
viện, màn hình hoặc thay đổi layout. Quyền Android vẫn chỉ được hỏi khi mở
Notifications, người dùng có thể tắt thông báo trong hệ thống.

Notification khi app đang mở dùng messageId thật của FCM trong PendingIntent;
FlutterFire xử lý tap qua `onMessageOpenedApp`/`getInitialMessage`, dùng lại
route event và auth guard hiện có. Chỉ notification payload mới hiện banner;
data-only message không tạo thông báo rỗng. Lỗi hiển thị native được map thành
AppException thay vì báo thành công giả. Native bridge chỉ dùng APIs Android;
không gọi Firebase SDK từ View hoặc ViewModel.

`FIREBASE_ENABLED=false` và local demo auth vẫn không đăng ký FCM. Không bật
Analytics, Crashlytics hoặc metrics export trong task này. Backend gửi cùng
channel nên APK mới cần được cài/mở trước khi kiểm banner; APK cũ có thể tiếp
tục rơi về kênh DEFAULT. Không thay cấu hình các kênh người dùng đã tắt.

## Demo

1. Cài bản mới bật Firebase thật, đăng nhập, mở Notifications và cấp quyền nếu hỏi.
2. Gửi riêng tới UID của tài khoản đang đăng nhập:

```powershell
node .\functions\scripts\send-demo-notification.mjs --uid <UID> --send
```

3. Kiểm khi app đang mở và khi chuyển app xuống nền. Bấm notification phải mở
   đúng event. Có thể thêm `--event demo-tech` nếu record demo đó đang published.

Script ghi nội dung “Thông báo thử từ Firebase”, không khẳng định điện thoại đã
nhận. Bản tin lịch sử giữ nguyên; không sửa hàng loạt inbox cũ. Công cụ vẫn chỉ
gửi cho active demo account đã đăng ký device và event demo/public/published.

Không force-stop app khi demo: Android chặn nhận FCM của app bị force-stop cho
đến khi người dùng mở lại. HIGH hỗ trợ banner; quyền/kênh người dùng và chế độ
không làm phiền vẫn do hệ điều hành quyết định.

Validation thực tế và ảnh: [evidence/push-notifications](../evidence/push-notifications/).
Nguồn: [Firebase foreground/tap handling](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages),
[Android notification channels](https://developer.android.com/develop/ui/compose/notifications/channels).
