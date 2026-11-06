# Form gửi thông báo — 06/11/2026

[Contract/demo](../../docs/ADMIN_NOTIFICATIONS.md).

- Admin: 15/15 Node tests đạt; Vite production build đạt.
- Backend: TypeScript build đạt; full suite Auth/Firestore/Functions/Storage
  Emulators 84/84, 0 fail/skipped. Log local (Git ignored):
  `.local/admin-notification-emulator.log`.
- Cloud: triển khai riêng `evia:sendAdminNotification` tại asia-southeast1 thành
  công. [live-guards.json](live-guards.json) xác minh callable thật từ chối
  anonymous/staff và admin payload sai; không gửi thông báo hoặc tạo inbox thử.
  Log triển khai local: `.local/admin-notification-deploy.log`.
- Tests mới: gửi tới ordinary active user không cần event/demo; concurrent retry
  tạo một inbox; body trim; payload FCM/channel đúng qua messaging fake; requestId
  conflict; thiếu device; anonymous/student/staff/disabled sender và recipient;
  body rỗng/quá dài/field lạ; pagination/retry UI, khóa gửi trùng, logout bỏ kết quả cũ.
- `form.png`: browser thật đọc danh sách active users từ backend thật, chọn tài
  khoản và nhập nội dung; nút gửi bật. Không bấm gửi thông báo trên cloud.
- Viewport 360×800 và 412×844 không tràn ngang; select/nút mới tối thiểu 48px.
  Đã trả viewport về mặc định. Giữ style admin hiện có.
- Không đổi Dart/native/dependency, không chạy lại Flutter/APK. Chưa nghiệm thu
  banner thật cho luồng gửi mới; FCM được dùng lại từ trigger đã có.
