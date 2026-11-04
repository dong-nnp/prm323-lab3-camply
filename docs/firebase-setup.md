# Firebase development setup — 2026-11-04

> **Project hiện tại:** `prm393-31822` (evia, Blaze), theo yêu cầu chuyển của người dùng.
> App đã chuyển bằng FlutterFire; 32 Functions + Rules đã deploy, 14 indexes READY.
> API smoke cloud + 20 Emulator tests + APK/startup Core đạt; [evidence](firebase-migration.md).
> UI, Google login/push thật và dữ liệu catalog chưa tích hợp.
> Các mục về `evia-lab3-kiet-2026` bên dưới là lịch sử, không phải project để deploy tiếp.


## Tài nguyên đã tạo

- Project: `evia-lab3-kiet-2026`, tên `Evia Lab 3`.
- Console: https://console.firebase.google.com/project/evia-lab3-kiet-2026/overview
- Android package: `com.example.prm393_lab03`.
- Firebase Android app: `1:197044882486:android:84a4f0d4523df15c989c97`.
- Firestore `(default)`: Native / Standard, `asia-southeast1`, `freeTier=true`.
- Đã deploy `firebase/firestore.rules`: deny all. Không tạo dữ liệu nghiệp vụ.
- Không liên kết billing, không triển khai Cloud Functions hay Storage bucket.

## Cấu hình local

FlutterFire CLI 1.4.1 đã sinh `android/app/google-services.json`,
`lib/firebase_options.dart` và phần `flutter` của `firebase.json`:

```powershell
dart pub global run flutterfire_cli:flutterfire configure --project=evia-lab3-kiet-2026 --platforms=android --android-package-name=com.example.prm393_lab03 --yes
```

Hai file app config vẫn được Git ignore theo quy định hiện tại của repo.
Android chỉ apply Google Services/Crashlytics plugins khi có native config,
để checkout chưa cấu hình vẫn build được với `FIREBASE_ENABLED=false` mặc định.
Máy khác cần có quyền project và chạy lại FlutterFire. `firebase.json` được
version hóa vì chứa paths/project identifiers, không chứa credentials.
Không commit token đăng nhập, service-account keys hay signing keys.

SDK riêng: `F:\Mobile_Programing\flutter_evia_lab3`, tag Flutter 3.47.9,
Dart 3.13.7. SDK cũ trên PATH vẫn giữ nguyên; dùng đường dẫn đầy đủ bên dưới.
Flutter `jdk-dir` đã sửa từ đường dẫn không tồn tại
`C:\Program Files\Java\jdk-17` sang
`C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot`.

Native build gặp Kotlin incremental cache lỗi `different roots` do Pub Cache ở
ổ C: còn repo ở D:. `android/gradle.properties` tắt Kotlin incremental compilation
cho project; có thể build chậm hơn khi sửa Kotlin. Bật lại sau khi toolchain xử lý
được cross-drive paths. Tham chiếu:
https://kotlinlang.org/docs/gradle-compilation-and-caches.html

```powershell
& 'F:\Mobile_Programing\flutter_evia_lab3\bin\flutter.bat' pub get
& 'F:\Mobile_Programing\flutter_evia_lab3\bin\flutter.bat' run -d emulator-5554 --route=/foundation --dart-define=FIREBASE_ENABLED=true
```

Chọn ID khác từ `flutter devices` nếu cần. Khởi tạo vẫn nằm trong service;
Android lấy options từ native resources của Google Services plugin.
File options do CLI sinh chưa cần import vào Dart cho Android.

## Phạm vi kiểm chứng

Firebase Core khởi tạo không chứng minh Auth, Firestore data access hoặc các
adapter khác đã hoạt động. `PendingFirebaseServices` vẫn trả unavailable/lỗi.
Màn login và các flow Evia hiện vẫn là UI demo. Chưa có đăng nhập Google thật,
wallet transactions, QR verification, FCM, tracking hay Remote Config fetch.

Rules deny-all là trạng thái khóa an toàn, không phải bộ phân quyền nghiệp vụ.
Thử đọc document không đăng nhập nhận HTTP 403; chưa có Emulator Suite tests
cho cross-UID, capacity, attendance, redemption hoặc wallet invariants.

Logs kiểm chứng local nằm trong `evidence/firebase-setup/`; xem kết quả cuối
trong `docs/test-plan.md`. Chỉ ghi nhận các lệnh đã chạy, không dùng việc tạo
project làm bằng chứng hoàn thành database theo `DATABASE_DESIGN.md`.

Native demo đã build/cài trên Pixel 5 emulator và Samsung SM-G996N. Emulator
hiển thị “Firebase đã khởi tạo”, có ảnh và UI hierarchy. Điện thoại có log native
init thành công nhưng đang khóa, chưa xác minh visual. Bản APK đã cấu hình được
giữ tại `build/app/outputs/flutter-apk/app-firebase-debug.apk` (không commit).

Nguồn workflow: https://firebase.google.com/docs/flutter/setup

## Backend implementation follow-up — 04/11/2026

`functions/` đã triển khai backend và đạt 20/20 tests local Emulator (xem
`evidence/backend/emulator-tests.log`). `firebase.json` và Rules/indexes local
đã mở rộng cho backend; **cloud vẫn ở baseline deny-all, chưa deploy các file mới**.
Billing GET ngày 04/11 trả `billingEnabled:false`; không gọi API bật billing.
Auth ban đầu trả `404 CONFIGURATION_NOT_FOUND`; sau khi người dùng đăng nhập
Console, đã khởi tạo Firebase Auth và bật Google + email/password. Admin API
kiểm tra lại cả hai enabled=true. Đã đăng ký debug SHA-1/SHA-256 của máy hiện tại
và chạy lại FlutterFire CLI để sinh config có OAuth clients; chưa login native.
Bằng chứng: `evidence/backend/cloud-status.json`
và `auth-status.json`. Chưa có real Google login/FCM/cloud business acceptance.

Xem [backend integration](backend-integration.md) cho Emulator ports, API contract,
approved-data import và lệnh deploy đã chuẩn bị nhưng chưa chạy. Dart/native
Flutter không đổi trong lượt backend này; các kết quả build trước đó là lịch sử.

Auth evidence: `evidence/backend/auth-providers.png`, `auth-status.json`,
`android-sha-list.json`, `flutterfire-configure.log`. Public app name: Evia Lab 3;
support email: owner account. Không nâng Identity Platform, không bật SMS/MFA/
Anonymous, không tạo tài khoản app thật để test. Release signing fingerprints
cần bổ sung khi nhóm có signing key; không commit debug/private key.
