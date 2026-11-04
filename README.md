# PRM393 Lab 3 — Flutter source base


## Chuẩn bị backend không phụ thuộc UI — 04/11/2026

- [Handoff cho đội frontend](docs/FRONTEND_HANDOFF.md), [chuẩn bị dữ liệu thật](docs/DATA_READINESS.md).
- [Analytics plan](docs/analytics-plan.md), [Remote Config plan](docs/REMOTE_CONFIG_PLAN.md), [AI review](docs/code-review.md).
- [Checklist Lab 3](docs/LAB3_CHECKLIST.md). Bản backend local mới hơn snapshot cloud bên dưới; không sửa Flutter UI.
- [Khung report](docs/report-outline.md), chưa phải PDF nộp hoặc evidence app hoàn thành.

## Backend Firebase — 04/11/2026

Backend nghiệp vụ độc lập đã được thêm vào `functions/`; **20/20 tests đạt trên
Firebase Emulator**. Project hiện tại là **`prm393-31822` (evia, Blaze)**;
**32 Functions đã deploy**, Rules/Storage đã release và 14 indexes READY.
Cloud smoke đạt; xem [migration](docs/firebase-migration.md) cho evidence.
UI và các Flutter adapters demo hiện tại chưa được nối vào backend này.

- [Hợp đồng API và hướng dẫn đội giao diện tích hợp](docs/backend-integration.md).
- [Chạy backend độc lập](functions/README.md), [kết quả kiểm thử](docs/test-plan.md).
- Chốt 200 xu lần đầu/UID; Daily theo Asia/Ho_Chi_Minh; tiền/vé chỉ server ghi,
  chống vượt chỗ/trừ xu trùng; không Waitlist hay milestone.
- Policy mới đã chốt: Monthly Gift tự cộng ngày 1, no-show mất cọc, được đăng ký lại khi còn chỗ, admin xác nhận voucher ở nhà tài trợ. **Code mới local, chưa deploy**; xem [policy/jobs](docs/BACKEND_POLICIES.md).
- Runtime: Node22, Java21+ cho Emulator, Firebase CLI 15.30.2 đã kiểm tra.
  Backend dependencies: firebase-admin 14.5.0, firebase-functions 7.4.0, zod 4.6.7;
  build TypeScript 7.0.2, @types/node 22.20.5 (bản cài chính xác trong lockfile).
- Không dùng Figma làm production seed. Catalog/sở thích phải có nguồn được duyệt.
  Billing đã có ở project nhóm; Google login/FCM thật trong app vẫn chưa kiểm chứng.

Các mục demo Flutter bên dưới ghi lại implementation UI trước đó, không phải
backend production. Các ví dụ waitlist/coin cũ trong UI cần đội frontend thay bằng
contract đã chốt khi tích hợp. Task backend không sửa màn hình.


Repository ban đầu: `prm323-lab3-camply`. Tên Flutter package: `prm393_lab03`.
Android app dùng Flutter stable, Dart null safety, MVVM, Riverpod và go_router.
Source hiện có 44 màn hình/trạng thái Evia từ Figma, bên cạnh foundation và Firebase contracts.
Dữ liệu UI demo được tách riêng theo yêu cầu; chưa có Firebase production integration.

## Firebase development ban đầu — lịch sử 04/11/2026

Đã tạo project `evia-lab3-kiet-2026` và Android app
`com.example.prm393_lab03` bằng Firebase/FlutterFire CLI. Firestore mặc định
ở `asia-southeast1` dùng Rules deny-all; chưa có dữ liệu nghiệp vụ.
Xem [cấu hình, lệnh chạy và giới hạn](docs/firebase-setup.md).
Thiết kế database đã được [đối chiếu trực tiếp với 44 frame Figma](docs/database-figma-review.md);
xem [schema v1.2](docs/DATABASE_DESIGN.md), chưa triển khai dữ liệu nghiệp vụ.

Owner đã làm rõ scope sau review: không Waitlist (hủy vé trả lại chỗ), Café
voucher 200 xu từ server data, Google + email/password auth, tối thiểu 3 sở thích
bắt buộc. Bỏ milestones/nhập mã walk-in và các nghiệp vụ FD-09/10; verification
sinh viên/CLB tạm hoãn. Đây là yêu cầu cho implementation tiếp theo; UI demo
và mô tả prototype phía dưới chưa được đổi hành vi trong task tài liệu này.
SDK riêng trên máy hiện tại: `F:\Mobile_Programing\flutter_evia_lab3`
(Flutter 3.47.9 / Dart 3.13.7); không cần thay SDK constraints của app.

```powershell
& 'F:\Mobile_Programing\flutter_evia_lab3\bin\flutter.bat' run -d emulator-5554 --route=/foundation --dart-define=FIREBASE_ENABLED=true
```

Lệnh trên mở màn kiểm tra Firebase Core. Các màn Evia vẫn dùng dữ liệu demo;
Google Sign-In và sáu service adapters chưa được tích hợp thật.

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
`google-services.json` hay `firebase_options.dart`; app mở màn hình Evia login.
Chọn **Skip** để xem Discover Guest; **Sign up** mở chọn sở thích và **Continue**
mở Discover demo. Đây là điều hướng UI, không tạo tài khoản/session đăng nhập.
Màn hình trạng thái Firebase và nút kiểm tra lại vẫn có ở `/foundation`.

Flutter bootstrap qua `ProviderScope` → `MaterialApp.router` → Evia login.
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
| flutter_svg | 2.3.2 | Render SVG export gốc từ Figma, lưu cục bộ |
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

Các route Evia và `/foundation` đều là route công khai cho bản UI demo.
Auth session stream và guard fail closed vẫn giữ nguyên; chưa có protected route
hoặc tích hợp đăng nhập thật. Login hiển thị validation/trạng thái chưa cấu hình.

## Bộ màn hình Evia

Nhóm đầu đã đọc đủ 9 node trước khi triển khai từ file Figma `JQtHz2tigJtvvjVBsx03kx`,
page `2083:272`. Mapping đầy đủ ở `docs/design-traceability.md`.

| Route | Màn hình |
|---|---|
| `/` | Welcome back / Login |
| `/interests` | Discover interests you |
| `/discover` | Discover — Consistent Event Hierarchy |
| `/discover/guest` | Discover — Guest Mode |
| `/explore` | Explore idle; chuyển sang kết quả khi tìm kiếm |
| `/explore/results` | Kết quả tham chiếu `workshop`, 3 sự kiện |
| `/filters` | Advanced Event Filters |
| `/following/events` | Following — Their Events |
| `/following/organizers` | Following — Organizers |

Screens ở `lib/screens/evia/`, state/actions ở `lib/viewmodels/evia_view_model.dart`.
Mock content nằm riêng trong `lib/data/mock/evia_mock_data.dart`; models thuần Dart
ở `lib/models/evia_models.dart`. Không có event backend hoặc repository trả thành
công giả. State chọn sở thích/bookmark/follow/history chỉ tồn tại trong phiên app.
541 PNG/SVG exports được bundle trong `assets/figma/`; không có URL Figma tạm
trong runtime. Các vùng thumbnail rỗng trong Figma được giữ rỗng.

Tìm kiếm, lịch sử, bookmark, follow/unfollow, sort và bộ lọc có state thật trong
demo. Ngày tương đối dùng tuần tham chiếu 26/10/2026 của thiết kế. Custom range
có date picker. Dữ liệu không có duration hoặc verified eligibility; các bộ lọc
đó không giả định sự kiện đủ điều kiện. Thanh **Events** và **Rewards** mở các
nhóm màn hình bên dưới. Dịch vụ đăng nhập/đăng ký sự kiện thật chưa được tích hợp.
Body text giữ tối thiểu 14sp, touch target 48dp và Roboto fallback theo quy tắc
repository, nên typography/chiều cao nội dung có thể khác bản Inter trên Figma.

### My Events và Rewards — 18 màn hình bổ sung

Đã kiểm tra đọc đủ 18/18 node trước khi sửa source. Mock content riêng ở
`lib/data/mock/activity_mock_data.dart`; state/actions ở `ActivityViewModel`.

| Route | Màn hình / trạng thái |
|---|---|
| `/my-events` | Attendance Confirmed / All Upcoming Events |
| `/my-events/past-empty` | Past — No Events on Oct 27 |
| `/my-events/past-date` | Past — Oct 26 Selected |
| `/my-events/past-all` | Past — All Events |
| `/my-events/selected` | Selected Date — Nov 2 |
| `/my-events/calendar` | Monthly Calendar Bottom Sheet |
| `/my-events/ticket` | My Ticket; `?event=ai` để xem vé theo sự kiện |
| `/my-events/cancel` | Cancel Registration dialog; `?event=ai` cho sự kiện tương ứng |
| `/my-events/check-in` | Scan Event QR preview + nhập mã demo |
| `/rewards` | Earn Coins / Daily Check-in & Milestones |
| `/rewards/catalog` | Redeem Catalog |
| `/rewards/locker` | My Rewards Locker |
| `/rewards/detail` | Café Voucher Details |
| `/rewards/confirm` | Confirm Redemption dialog |
| `/rewards/success` | Redemption Successful |
| `/rewards/voucher` | Voucher & QR |
| `/rewards/milestones` | Event Milestones |
| `/rewards/history` | Coin History |

Các route tham chiếu giúp xem từng thiết kế độc lập; trong app có thể đổi tab,
chọn ngày/tuần/tháng, mở vé, giữ hoặc hủy đăng ký và rời waitlist. Hủy chỉ thay
đổi dữ liệu demo trong phiên. Màn hình scanner dùng **ảnh mô phỏng** từ Figma,
không gọi camera hay đèn pin thật. **Enter code** với mã `EVIA-CLUB-2026` xác nhận
check-in demo một lần và cộng 80 xu; mã sai/nhập lặp không cộng xu.

Daily check-in cộng 10 xu một lần trong phiên. Đổi thưởng trừ available coins,
giữ nguyên 100 xu deposits, lưu receipt và cập nhật lịch sử. Các thao tác này
không ghi backend hay tạo voucher dùng ngoài đời. QR/voucher code là mẫu Figma.
UI state không được lưu qua lần khởi động app mới.

Figma có giá café **200 xu trong catalog**, **250 xu trong chi tiết/xác nhận**;
source giữ riêng `catalogCost` và `redeemCost` để khớp từng frame. Đổi café dùng
250 xu, từ 420 còn 170. Route success mở trực tiếp dùng receipt tham chiếu;
đi từ xác nhận sẽ dùng receipt của thao tác vừa thực hiện.

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
     trước đây **deny all**. Backend hiện có Rules own-user đã deploy lên project nhóm;
     xem `docs/firebase-migration.md`. Khi dùng Firebase CLI, chọn đúng project và
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
Runtime fixtures được user cho phép, tách riêng trong `lib/data/mock/`;
test fakes cho bootstrap/service vẫn chỉ nằm trong tests.

- [Kiến trúc + sơ đồ MVVM](docs/architecture.md)
- [Design traceability](docs/design-traceability.md)
- [Analytics plan template](docs/analytics-plan.md)
- [Test plan template](docs/test-plan.md)
- [Code review template](docs/code-review.md)
- [Google ARTEMIS preparation](e2e_test/README.md)

Templates giữ TODO/chưa thực hiện cho các việc ngoài scope. Không có kết quả
E2E, AI review, Firebase production tests hoặc evidence được tạo giả.

## Event details, registration và Profile — 17 màn hình mới

Đã đọc đủ 17/17 frame (cả User Profile 1–4) trước khi sửa source.
Vào Discover → Campus Music Night → Register Now để xem luồng đăng ký;
chọn Profile ở thanh điều hướng để mở hồ sơ, Saved Events, My Interests hoặc
Notifications. Chạm Student Union trong chi tiết sự kiện để mở organizer.

Các route reference được liệt kê đầy đủ trong `docs/design-traceability.md`.
`/registration/legacy-error`, `/registration/error`, `/registration/loading`,
`/registration/full`, `/registration/failed` cho phép xem từng trạng thái Figma.
Thành công/Going/Full cũng có route reference; chỉ submit/Going/Join Waitlist mới
thay đổi state, việc mở route preview không tạo đăng ký hay trừ coin.

Mock riêng: `lib/data/mock/registration_mock_data.dart`. RegistrationViewModel
quản lý validation, loading và kết quả; ProfileViewModel quản lý bookmark,
notification read state, chỉnh hồ sơ và draft sở thích. Đăng ký thành công giữ
100 coin từ Available (420 → 320), tăng Deposits (100 → 200), thêm vào My Events
và mở vé. Walk-in/waitlist không giữ coin; walk-in không có vé. Chặn submit trùng
và debit trùng. Lỗi giữ nguyên dữ liệu form để sửa/thử lại.

Đây là state demo trong phiên, chưa gửi đăng ký, thanh toán, thông báo hay xác
minh tài khoản đến server. Logout xóa demo state. Open in Maps mở hướng dẫn
vị trí trong app; Share organizer sao chép thông tin mẫu, chưa có public app URL.
