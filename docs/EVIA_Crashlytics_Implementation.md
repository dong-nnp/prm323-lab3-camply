# Kiểm thử Crashlytics trên Evia

## Android QA cho Lab 3

Dùng Android Emulator trên cùng máy Windows với Web Admin và
`android/app/google-services.json` của app Android cần nghiệm thu. Có thể thử
ở chế độ khách. Đăng nhập nếu cần minh chứng có User ID.

```powershell
flutter run -d emulator-5554 --android-project-arg=eviaQaCrashlyticsEnabled=true --dart-define=FIREBASE_ENABLED=true
npm --prefix admin run dev:android-qa -- emulator-5554
```

Chạy hai lệnh ở hai terminal và thay `emulator-5554` bằng ID máy ảo của bạn.
Điền cấu hình Firebase Web trong `admin/.env.local` và đặt
`VITE_FIREBASE_EMULATORS=false`.
Mở Web Admin ở `http://127.0.0.1:5174/#crashlytics` và đăng nhập admin.

1. **Fatal.** Giữ app Evia mở, bấm **Crash Android QA** trên Web Admin rồi
   xác nhận. Nếu trình duyệt hỏi, cho phép mở trình kiểm thử Windows. Mở lại
   app sau khi app đóng và tìm `CrashedByAdbException` trong Firebase Console.
   Kiểm tra `app_surface=mobile_android` và UID nếu đã đăng nhập.
2. **Non-fatal.** Chạy app theo luồng mặc định khi đang đăng nhập. Ngắt mạng
   trên thiết bị trước khi mở Discover trong một tiến trình app mới để yêu cầu
   tải catalog gặp lỗi thật. Đợi màn hình hiển thị lỗi và nút **Thử lại**, sau đó
   bật mạng và bấm **Thử lại** để kiểm tra khả năng phục hồi. Thoát hẳn rồi mở
   lại app khi có mạng để SDK gửi các lỗi đã lưu. Trong Crashlytics của app
   Android, đổi bộ lọc **Event type** sang **Non-fatals** và tìm
   `EVIA_DISCOVER_CATALOG_LOAD_FAILED`. Kiểm tra User ID và
   `app_surface=mobile_android` trong chi tiết sự kiện.
3. Sau khi xác nhận hai báo cáo, lưu ảnh dashboard dưới `evidence/` và đưa
   đường dẫn vào báo cáo hoặc slide. Chỉ dùng UID của tài khoản thử nghiệm
   khi chụp minh chứng.

Nút QA chỉ xuất hiện khi đăng nhập admin trên phiên Web Admin cục bộ dành
cho Android QA. Trình kiểm thử Windows chỉ gửi lệnh cho tiến trình Evia debug
đã bật cờ thu thập trên máy ảo được chọn. Terminal Web Admin hiển thị đường
dẫn log cục bộ. Dùng emulator thử nghiệm mới nếu một bản cài trước đó đã lưu
trạng thái tắt thu thập và log vẫn báo `DISABLED by API` sau khi cài bản QA.

[Firebase Crashlytics cho Flutter](https://firebase.google.com/docs/crashlytics/flutter/get-started)
