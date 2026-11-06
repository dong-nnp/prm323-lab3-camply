# Gửi push demo bằng một lệnh

Chạy trong thư mục repository, bằng Node.js và tài khoản Firebase CLI có quyền
ghi Firestore của `prm393-31822` trên Windows. Dùng login hiện có; không đưa
credentials vào app hay dòng lệnh.

1. Mở Evia → Notifications và cấp quyền.
2. Bấm Home để app chạy nền.
3. Chạy lệnh sau, thay `<UID>` bằng User UID của tài khoản demo:

```powershell
node .\functions\scripts\send-demo-notification.mjs --uid <UID> --send
```

Mỗi lần chạy tạo một document `notifications/demo-push-<UUID>` mới cho đúng
UID, với `createdAt` do server đặt, `readAt:null` và nhãn `[DEMO]`. Trigger
`deliverNotification` hiện có gửi FCM; bấm thông báo mở `demo-career-talk`.
Inbox cũng lưu document này. Đây là push thử, không phải thay đổi lịch thật.

Muốn mở một sự kiện demo khác, thêm `--event demo-mobile-workshop`. Bỏ
`--send` để xem trước mà không đăng nhập, gọi mạng hoặc ghi Firebase.

Script chỉ gửi khi recipient đang active/`isDemo:true`, có token thiết bị,
và event được đánh dấu demo/published/public. Cần cùng tài khoản đang đăng nhập
trong app; công cụ không tự tìm UID hoặc gửi tới nhiều tài khoản. Trạng thái
“đã tạo” chỉ xác nhận lưu inbox, không khẳng định thiết bị đã nhận push.

Nếu chưa login CLI, chạy `firebase login`. Cách hiện tại tái sử dụng Firebase
CLI cài global trong `%APPDATA%/npm`, giống các công cụ vận hành đang có.

Validation: hai tests thuần Node đạt, gồm dry-run không credentials/network
và từ chối thiếu/sai UID hoặc event ID. Dry-run cũng chạy được với Node 24
trên máy hiện tại; tests chạy bằng Node 22. Chưa gửi push mới trong lượt này.
