# Kiểm thử Crashlytics trên Evia

## Android QA cho Lab 3

Dùng Android Emulator hoặc thiết bị QA có cấu hình `android/app/google-services.json`
của app cần nghiệm thu. Đăng nhập để mở **Profile** và gắn UID vào báo cáo.

```powershell
flutter run
```

Nếu có nhiều thiết bị, thêm `-d DEVICE_ID`. Bản debug có cấu hình Firebase thật
tự bật thu thập Crashlytics và nút **Crash**. SDK vẫn tôn trọng thiết lập thu
thập đã lưu trên thiết bị. Bản release thường vô hiệu hóa nút. Để thử release QA:

```powershell
flutter run --release --android-project-arg=eviaQaCrashlyticsEnabled=true --dart-define=FIREBASE_ENABLED=true --dart-define=ENABLE_CRASH_TEST=true
```

1. **Fatal.** Bấm **Profile → Crash** trên app, sau đó mở lại app khi có mạng.
   Trong Firebase Console, mở sự kiện fatal mới và kiểm tra key
   `is_test_crash=true`, log `Manual crash triggered from Profile` và UID.
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

Bật log chẩn đoán trước khi mở app và giữ logcat chạy qua lần khởi động lại.

```powershell
adb -s emulator-5554 shell setprop log.tag.FirebaseCrashlytics DEBUG
adb -s emulator-5554 logcat -s FirebaseCrashlytics TRuntime.CctTransportBackend
```

Tìm `Crashlytics report upload complete`, HTTP `204` hoặc phản hồi thành công
của request đến `crashlyticsreports-pa.googleapis.com`. Log đưa báo cáo vào
hàng đợi chỉ xác nhận SDK đã xếp lịch gửi. Nếu bản cài trước đó đã lưu trạng
thái tắt thu thập, dùng emulator QA mới hoặc giữ nguyên lựa chọn trên thiết bị.

[Firebase Crashlytics cho Flutter](https://firebase.google.com/docs/crashlytics/flutter/get-started)
