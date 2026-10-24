# PRM393 Lab 3 — Flutter source base

Repository ban đầu: `prm323-lab3-camply`. Tên Flutter package: `prm393_lab03`.
Android app dùng Flutter stable, Dart null safety, MVVM, Riverpod và go_router.
Đây chỉ là foundation; chưa có UI/flows Lab 2, dữ liệu nghiệp vụ hoặc Firebase
production integration.

## Yêu cầu môi trường

- Flutter **stable 3.47.8** / Dart **3.13.7** là bộ SDK đã dùng để tạo source.
  `pubspec.yaml` yêu cầu Dart `^3.13.7`; dùng Flutter stable có Dart tương thích.
- Android Studio, Android SDK/command-line tools, JDK tương thích với Flutter
  (Android host tạo bởi SDK hiện tại dùng Java 17 bytecode), emulator hoặc thiết bị.
- Android minSdk/compileSdk/targetSdk kế thừa Flutter SDK; bộ SDK trên có minSdk 24.
- Chạy `flutter doctor -v` và xử lý Android toolchain trước khi build native.
- Nếu Flutter chưa trong PATH, thêm thư mục `flutter/bin` của SDK bạn cài.
  SDK tạm dùng trong phiên setup ở
  `C:\Users\phuon\.codex\tmp\prm393-tools\flutter`; source không phụ thuộc đường dẫn này.

## Chạy khi chưa cấu hình Firebase

```powershell
flutter pub get
flutter devices
flutter run -d DEVICE_ID
```

Thay `DEVICE_ID` bằng ID từ `flutter devices`. Mặc định không cần
`google-services.json` hay `firebase_options.dart`; app hiển thị **Firebase chưa
được cấu hình** và nút kiểm tra lại. Dart bootstrap không gọi Firebase SDK ở
chế độ mặc định; native plugins vẫn được Flutter đăng ký như bình thường.

Flutter bootstrap qua `ProviderScope` → `MaterialApp.router` → foundation screen.
`FIREBASE_ENABLED` mặc định false, được đọc ở compile time. Nếu bật true mà thiếu
cấu hình hợp lệ, Dart initialization error sẽ chuyển thành error state có Retry,
không để exception SDK thoát thẳng ra màn hình. Không bật cờ trước khi hoàn tất
cấu hình Android/Gradle.

## Dependencies

Các version sau được **`flutter pub add` chọn và resolve**, không tự đoán.
Giữ `pubspec.lock` trong Git để tái lập đúng bản đã kiểm tra. Pubspec dùng caret
constraints; nâng version cần chạy lại analyzer/tests và native build.

| Dependency | Version đã resolve | Vai trò |
|---|---|---|
| flutter_riverpod | 3.4.3 | State management và DI |
| go_router | 18.1.1 | MaterialApp.router, redirect/auth guard |
| firebase_core | 5.1.0 | Khởi tạo SDK khi đã opt in |
| firebase_auth | 7.0.1 | Chuẩn bị Authentication |
| google_sign_in | 7.2.0 | Chuẩn bị Google Sign-In |
| firebase_storage | 14.0.1 | Chuẩn bị Cloud Storage |
| firebase_messaging | 17.0.1 | Chuẩn bị Cloud Messaging |
| firebase_analytics | 13.0.1 | Chuẩn bị Analytics, chưa tracking |
| firebase_crashlytics | 6.0.1 | Chuẩn bị Crashlytics, chưa handlers |
| firebase_remote_config | 7.0.1 | Chuẩn bị Remote Config |
| flutter_test | Flutter SDK | Unit/widget tests |
| flutter_lints | 6.0.0 | Dart/Flutter conventions |

Chưa thêm Firestore hoặc HTTP client vì chưa xác định nguồn dữ liệu Lab 2.
Chưa thêm ARTEMIS dependency hay automation. Firebase packages ngoài Core mới
chỉ được chuẩn bị trong dependency graph, chưa có real adapters/use cases.

## Cấu trúc và quy tắc

```text
lib/
├── main.dart
├── app/                 # App + router + authentication guard
├── core/
│   ├── constants/
│   ├── errors/
│   ├── providers/
│   └── utils/
├── theme/
├── models/
├── services/
├── repositories/
├── firebase/
├── viewmodels/
├── screens/
└── widgets/
test/                    # Unit/widget tests + test-only fakes
e2e_test/                # Chuẩn bị Google ARTEMIS, chưa có E2E
firebase/                # Deny-all storage.rules + Remote Config defaults {}
docs/                    # Kiến trúc và templates
android/                 # Android host
```

View → ViewModel → Repository → service interface → SDK adapter. SDK chỉ được
gọi trong `lib/services/`; domain models không chứa SDK types. Providers tạo và
inject dependencies, dễ override để test. Sáu service providers hiện dùng
`PendingFirebaseServices`: auth stream phát `unavailable`, các thao tác khác
báo `AppException` thay vì giả thành công. Khởi tạo Firebase Core thành công
**không tự thay** các adapter pending thành dịch vụ thật.

Root `/` là route công khai duy nhất. Đã có auth session stream và guard fail
closed; protected route list đang trống. Chưa có sign-in screen hoặc auth flow.

Theme lấy màu, typography, spacing, radius và quy tắc responsive từ Camply Lab 2
ở dự án liền kề, không sao chép data prototype. Dùng Roboto/system fallback theo
handoff; TODO bundle Inter được cấp phép khi có font assets. Không tải fonts từ
mạng. Xem [design traceability](docs/design-traceability.md) để biết nguồn và gaps.

## Cấu hình Firebase thật — thao tác thủ công

Không có Firebase project/credentials/config giả trong repository. Chỉ thực
hiện các bước sau bằng tài khoản và project thật được cấp quyền.

1. Xác nhận `applicationId`/namespace trong `android/app/build.gradle.kts`.
   Hiện dùng ID mặc định của Flutter: `com.example.prm393_lab03`; chốt ID thật
   trước khi đăng ký app vì đổi ID sau đó cần cấu hình Firebase lại.
2. Cài Firebase CLI và FlutterFire CLI, đăng nhập:

   ```powershell
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure --platforms=android
   ```

   Nếu không tìm thấy `flutterfire`, thêm Pub Cache `bin` vào PATH. Chọn Firebase
   project thật và Android app đúng application ID. CLI sinh cấu hình thật như
   `lib/firebase_options.dart`, `android/app/google-services.json` và cập nhật
   Gradle theo workflow. Không tự viết file options hoặc điền giá trị giả.
3. Kiểm tra Google Services Gradle plugin đã được khai báo và áp dụng đúng module
   `android/app`; kiểm tra Crashlytics Gradle plugin khi bắt đầu tích hợp dịch vụ
   đó. Chạy lại `flutterfire configure` khi thêm sản phẩm/nền tảng Firebase theo
   [hướng dẫn FlutterFire chính thức](https://firebase.google.com/docs/flutter/setup).
4. Foundation hiện **chỉ target Android**: `FirebaseInitializationService` gọi
   `Firebase.initializeApp()` để đọc native resources do Google Services plugin
   sinh từ JSON thật. Không cần import file options trong `main.dart`. Nếu sau
   này mở rộng nền tảng, truyền `DefaultFirebaseOptions.currentPlatform` từ file
   CLI sinh vào initialization **trong service layer**.
5. Kiểm tra Core initialization bằng:

   ```powershell
   flutter run -d DEVICE_ID --dart-define=FIREBASE_ENABLED=true
   ```

   Nếu chưa cấu hình thật, tiếp tục dùng `flutter run` mặc định. Cờ chỉ kiểm soát
   Dart bootstrap; native Firebase có thể auto-initialize khi có native config.
6. Sau khi xác nhận yêu cầu và phạm vi tích hợp, triển khai từng service adapter:
   - **Authentication:** bật Google provider trong Firebase Console, đăng ký
     SHA-1/SHA-256 của signing certificate thực tế, tải/cập nhật config nếu cần;
     triển khai Google Sign-In → Firebase credential trong service, trả AuthSession.
   - **Storage:** khởi tạo bucket theo project thật. `firebase/storage.rules`
     hiện **deny all**; chưa deploy. Khi dùng Firebase CLI, chọn đúng project và
     trỏ storage rules path tới file này. Viết rules theo quyền và test trước khi
     mở truy cập; không thay bằng public allow-all để demo.
   - **Messaging:** triển khai token, permission và message handlers trong service
     sau khi xác định flow; không đăng ký token/yêu cầu quyền ở foundation.
   - **Analytics/Crashlytics:** viết adapter, kế hoạch tracking/handlers và test
     ở môi trường dev. Android manifest hiện tắt auto collection và automatic
     screen reporting; chưa có Analytics observers hay Crashlytics error hooks.
   - **Remote Config:** `firebase/remote-config-defaults.json` hiện là `{}` vì
     chưa xác định keys. Bổ sung defaults thật và nối `setDefaults`/fetch ở service;
     file này chưa được tải tự động vào app hoặc publish lên Console.
7. Thay provider tương ứng trong `lib/core/providers/service_providers.dart`,
   thêm tests và chỉ chủ động bật collection/FCM auto-init khi integration đó
   đã được yêu cầu. `FIREBASE_ENABLED=true` tự nó không bật tracking hay adapters.

Các file cấu hình môi trường được ignore để mỗi máy tự cấu hình bằng CLI. Không
commit service-account keys, signing keys, tokens hoặc secrets. Nếu nhóm cần
version hóa config Firebase không bí mật, quyết định rõ chính sách trước khi đổi
`.gitignore`; chưa có thay đổi Firebase bên ngoài được thực hiện ở bước setup.

## Validation

```powershell
flutter pub get
dart format lib test
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Unit/widget tests không cần Firebase credentials, native plugins hoặc emulator.
Native build/run cần Android SDK và các components mà Flutter/Gradle yêu cầu.
Test fakes chỉ kiểm soát trạng thái bootstrap, không có mock business data.

- [Kiến trúc + sơ đồ MVVM](docs/architecture.md)
- [Design traceability](docs/design-traceability.md)
- [Analytics plan template](docs/analytics-plan.md)
- [Test plan template](docs/test-plan.md)
- [Code review template](docs/code-review.md)
- [Google ARTEMIS preparation](e2e_test/README.md)

Templates giữ TODO/chưa thực hiện cho các việc ngoài scope. Không có kết quả
E2E, AI review, Firebase production tests hoặc evidence được tạo giả.
