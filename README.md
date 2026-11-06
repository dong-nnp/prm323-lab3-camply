# PRM393 Lab 3 — Flutter source base

> **ARTEMIS — 06/11/2026:** đã có Python/pytest suite, SDK pin, account/AVD test riêng,
> thu trace, ảnh, structured observations và bảng kết quả. Chưa nghiệm thu đủ Lab:
> xem [hướng dẫn chạy](e2e_test/README.md), [kế hoạch](docs/artemis-plan.md) và
> [bằng chứng hiện có](evidence/artemis/README.md). Không tính collect/self-check
> hoặc agent SUCCESS đơn thuần là E2E pass.
> Chuyển người khác tiếp tục test: [tài liệu bàn giao ARTEMIS](docs/artemis-handoff.md).
> **Thông báo từ admin:** form gửi nội dung tùy ý tới một tài khoản, dùng FCM và inbox hiện có, không cần sự kiện. [Hướng dẫn demo và triển khai](docs/ADMIN_NOTIFICATIONS.md).

> **Form sự kiện — 06/11/2026:** Vite admin tự sinh mã/nguồn/điều khoản, chọn danh mục và ban tổ chức bằng tên, bỏ lịch JSON khỏi form. Chọn ảnh có preview, tải trực tiếp Firebase Storage khi lưu. Rules đã deploy, upload/download thật đã kiểm và dọn ảnh QA. [Hướng dẫn và giới hạn](docs/ADMIN_EVENT_EDITOR.md).

> **Analytics — 06/11/2026:** đã nối 11 events Android qua service/repository, thêm xuất CSV ở Coin History và bộ lọc Android/Web cho báo cáo Vite admin. Bật riêng `ANALYTICS_ENABLED=true` cùng `FIREBASE_ENABLED=true`; mặc định tắt, không tracking mock. [Chạy, deploy callable và giới hạn evidence](docs/ANALYTICS_INTEGRATION.md).

> **Admin Flutter Web — 06/11/2026:** [Portal quản trị độc lập](admin_flutter/README.md).
> Một admin quản lý CLB/sự kiện/check-in/quà/thành tựu/thông báo và tra cứu ví,
> không phân công staff, không sửa UI sinh viên. [Phạm vi/API](docs/ADMIN_WEB_PLAN.md),
> [validation thực tế](evidence/admin-flutter/).

> **Push Android — 06/11/2026:** dùng FCM và kênh HIGH `evia_events_v1`; app đang
> mở hiển thị notification hệ thống bằng native service bridge, app nền do FCM
> SDK hiển thị. Giữ layout cũ, không thêm dependency. [Cách chạy/giới hạn](docs/PUSH_NOTIFICATIONS.md).

> **Flow 3 — 06/11/2026:** nối ví/history, Daily, nhận thành tựu, catalog/đổi quà,
> My Rewards và QR voucher vào các màn gốc. API `getAccount.daily` đã deploy;
> 213/213 Flutter và 62/62 backend tests đạt. Chỉ sửa co giãn chữ theo owner
> cho phép, không đổi dialog gốc. [Contract/demo](docs/FLOW3_INTEGRATION.md) ·
> [Evidence và giới hạn](evidence/flow3-api-only/).

> **Push demo một lệnh:** dùng `functions/scripts/send-demo-notification.mjs`
> để tạo thông báo riêng cho UID demo và gửi qua FCM đang triển khai.
> [Cách chạy](docs/DEMO_PUSH.md); không cần nhập từng field trong Console.
> **Evia Admin web.** Chạy từ thư mục gốc với `npm --prefix admin ci` và
> `npm --prefix admin run dev`. Xem [hướng dẫn cấu hình và chạy](admin/README.md)
> và [phạm vi MVP](docs/ADMIN_WEB_PLAN.md).

> **Flow 2 — 05/11/2026:** nối My Events/lịch/hủy, check-in walk-in và inbox +
> Firebase Cloud Messaging vào màn hiện có. Owner cho phép nút demo nhỏ trên vé
> trong debug, server giới hạn account/event demo. 59 backend + 190 Flutter tests
> đạt; 14/14 ảnh same-data trùng RGBA; 7 API mới/cập nhật READY.
> [Evidence và giới hạn native](evidence/flow2-api-only/). Flow 3 xem cập nhật mới ở trên.

> **Email mở rộng 05/11/2026:** owner bỏ giới hạn domain email. Mọi địa chỉ
> đúng định dạng đều được đăng ký/đăng nhập/tham gia. MSSV vẫn hai chữ + sáu số;
> quyền staff/admin và điều kiện sự kiện giữ nguyên. [Contract](docs/PREINTEGRATION_DECISIONS.md).

> **Hủy đăng ký 05/11/2026:** hoàn **30% cọc, làm tròn xuống**; mất phần còn lại.
> No-show mất toàn bộ cọc. Backend đã deploy, điều khoản demo đã đồng bộ;
> nút hủy thật vẫn chờ nối Flow 2. [Policy](docs/BACKEND_POLICIES.md) ·
> [Evidence](evidence/cancellation-refund/).

> **API-only theo owner 05/11/2026:** đã gỡ bộ màn `Flow1Screen` tạo ngoài phạm vi;
> nối Firebase vào các màn gốc, giữ layout/style/assets. Giữ 8 thẻ sở thích;
> Gaming/Environment chờ đội UI. Ảnh cũ làm minh họa khi chưa có URL; vé chỉ hiện
> QR trong ô cũ, chưa có mã dự phòng. [Phạm vi](docs/API_INTEGRATION_PHASES.md) · [Evidence sửa lại](evidence/flow1-api-only/).
> Các mô tả bộ màn live riêng/kết quả cũ bên dưới là lịch sử, không nghiệm thu bản này.


> **Gắn API theo giai đoạn — 05/11/2026:** [kế hoạch và phạm vi](docs/API_INTEGRATION_PHASES.md).
> Flow 1 có adapter Firebase Auth/Callable, catalog, onboarding, follow/save,
> đăng ký giữ cọc và vé server khi `FIREBASE_ENABLED=true` (không bật `DEMO_AUTH`).
> Flow 2/3 chưa tích hợp app. Các mô tả “pending/chưa nối Flutter” bên dưới là
> lịch sử hoặc chế độ preview, không áp dụng cho nhánh live Flow 1.

> **Dữ liệu demo đã được owner cho phép tạo 05/11/2026:** Firebase hiện có
> 10 interests, 5 organizers, 12 events, 5 rewards và 5 milestones có sẵn.
> Hai tài khoản Auth vận hành staff/admin đã khởi tạo và phân quyền app.
> [Dữ liệu, tài khoản và cách sửa](docs/DEMO_DATA.md) thay thế ghi chú “chưa có
> dữ liệu/chưa tạo Café” phía dưới. Đây là dữ liệu demo có nhãn, chưa nối Flutter.

> **Đồng bộ trước tích hợp 05/11/2026:** [quyết định mới](docs/PREINTEGRATION_DECISIONS.md)
> chốt MSSV hai chữ + sáu số; email hiện nhận mọi domain hợp lệ, QR + mã
> dự phòng và ba loại notification bổ sung. Đã sửa UI policy/claim controls;
> CampusService vẫn pending cho đến bước nối SDK. Không tạo Café record khi
> chưa có stock/nhà tài trợ/địa điểm/điều kiện thật được duyệt.

> **Firebase 05/11/2026:** đã bổ sung backend Event Milestones theo
> [hợp đồng thành tựu](docs/EVENT_MILESTONES.md): 5 mốc, manual claim một lần,
> admin-managed catalog và hai Remote Config keys cho presentation.
> Giao diện demo bên dưới chưa nối API này.

## Tài khoản mock để xem UI — 05/11/2026

Chỉ bản debug bật `--dart-define=DEMO_AUTH=true` mới dùng tài khoản local:
`alex.m@fpt.edu.vn` / `EviaDemo123!` (Alex Morgan).
Mặc định cờ tắt; profile/rewards/events vẫn là mock được phép dùng để preview.
Không tạo Firebase user/token, không cấp quyền backend; Google/sign-up vẫn unavailable.
Session chỉ nằm trong RAM, mất khi khởi động lại; Log Out xóa session và state demo.
Release/profile luôn tắt demo auth, kể cả truyền cờ.

```powershell
& 'F:\Mobile_Programing\flutter_evia_lab3\bin\flutter.bat' run -d R3CR60CT0WZ --dart-define=DEMO_AUTH=true
```



## Mô phỏng toàn bộ UI — 05/11/2026

Trong bản debug bật `DEMO_AUTH=true`, đăng nhập tài khoản demo ở trên rồi vào
**Profile → Demo screens** để mở 44 màn/trạng thái, gồm đăng ký thành công,
thất bại, hết chỗ, loading, lịch, vé, voucher và trạng thái rỗng.
Nút **View Splash / Welcome / Login / Sign up** đăng xuất để xem nhóm authentication.

- Ví demo bắt đầu với **2.000 xu khả dụng + 100 xu cọc**; mọi thay đổi chỉ ở RAM.
- Đăng ký giữ cọc, hủy hoàn 30% cọc làm tròn xuống; thao tác lặp không trừ/hoàn hai lần.
- Check-in sự kiện: **Enter code → EVIA-CLUB-2026**, xác nhận Campus Club Fair
  và cộng 80 xu một lần. Đây là mô phỏng, không mở camera/quét QR thật.
- Daily Check-in cộng 20 xu một lần trong phiên.
- Đổi mỗi loại thưởng một lần: cập nhật ví, lịch sử và voucher mã `DEMO-...`.
- **Reset demo** trong danh sách màn phục hồi ví/vé/thưởng ban đầu; đăng xuất
  qua Profile hoặc khởi động lại cũng xóa trạng thái phiên.
- Google sign-in, sign-up tạo tài khoản thật, email reset password, quyền thiết bị
  và gửi feedback chưa kết nối. Có thể xem giao diện tương ứng, không gửi dữ liệu.
- Các màn legacy (Waitlist/nhập mã check-in) chỉ để đối chiếu UI cũ,
  không khẳng định đây là scope backend đã chốt.

Không bật cờ: giữ chế độ preview cũ, không cho thay đổi xu khi Coin API chưa nối.
Release/profile không bật demo auth hoặc danh sách màn. Không thay Firebase Rules,
không seed cloud, không cấp Firebase token và không gọi API nghiệp vụ.

## Backend release — 04/11/2026

Đã deploy **34 Functions**, xác minh **34 latest Cloud Run revisions READY**, hai Scheduler jobs ENABLED (Monthly Gift/ngày 1, no-show/mỗi 60 phút). Timezone/IAM đã kiểm; 6/6 Callable smoke + 3/3 Rules smoke đạt. [Release và bằng chứng](docs/backend-release.md). Không chạy thủ công job/cấp xu, không seed dữ liệu thật. UI và instrumentation vẫn chưa tích hợp.



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
  chống vượt chỗ/trừ xu trùng; không Waitlist. Event Milestones đã được bổ sung
  theo [quyết định 05/11/2026](docs/EVENT_MILESTONES.md), chưa nối giao diện.
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
bắt buộc. Milestones khôi phục theo [policy mới](docs/EVENT_MILESTONES.md).
Bỏ nhập mã walk-in và các nghiệp vụ FD-09/10; verification
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

Android debug build có theo dõi input/output APK và tái sử dụng assets khi không
đổi. Chi tiết phạm vi, số đo và kiểm tra tránh APK cũ: [Build performance](docs/build-performance.md).

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
`google-services.json` hay `firebase_options.dart`; app mở S00 Splash rồi S01 Welcome.
Welcome (`/`) có đúng ba actions: **Get Started** → `/signup`, **Log In** → `/login`,
**Explore as Guest** → `/discover/guest`. Màn Login cũ giữ tại `/login`.
`/signup` có form Create Account dùng cùng styles, logo và tagline với Login,
không collage, bốn fields và lỗi inline. Thứ tự: fields → Terms checkbox →
Create Account → Google → Log In. Checkbox dùng chung cho hai cách đăng ký,
mặc định chưa chọn. Login giữ nguyên giao diện có collage.
Create Account gọi SignUpViewModel → AuthenticationRepository → AuthenticationService.
**Adapter tạo tài khoản và Google vẫn pending:** form hợp lệ báo chưa khả dụng,
không tạo tài khoản/session giả hoặc tự chuyển đến Interests. Backend có thể trả
yêu cầu xác minh email; khi thành công, router chỉ chuyển sau session thật xuất hiện.
Độ dài mật khẩu tối thiểu lấy từ adapter khi có; chưa cấu hình thì chỉ kiểm tra
bắt buộc/khớp mật khẩu, không tự đặt quy tắc giả. Chưa có URL Terms/Privacy nên
hiển thị văn bản, không tạo link hoặc trang pháp lý giả.
Guest được duyệt/tìm kiếm/lọc sự kiện, xem details và organizer công khai.
Lưu/follow/đăng ký/Going/check-in và các route dữ liệu cá nhân yêu cầu đăng nhập;
ViewModel cũng chặn mutation khi session chưa rõ/unavailable/signed out/lỗi.
Đây là điều hướng UI, không tạo tài khoản/session đăng nhập giả.
Màn hình trạng thái Firebase và nút kiểm tra lại vẫn có ở `/foundation`.

Flutter bootstrap qua `ProviderScope` → `MaterialApp.router` → `/splash`.
Splash dùng artwork PNG EVIA chính thức, nền trắng #FFFFFF giống Welcome.
Login giữ nền và trang trí gốc theo yêu cầu. Vé xuất hiện giữa màn hình
(0–300ms), trượt trái (300–800ms) trong lúc chữ “via” được wipe từ trái sang phải
(350–800ms); hai tia lime xuất hiện/pulse một lần (700–950ms), rồi giữ đến 1200ms.
Các lớp trong `assets/splash/` được tách nguyên pixel từ PNG gốc bằng
`python tool/derive_splash_layers.py` (tool phát triển cần Pillow). Script kiểm tra
ghép lại trùng RGBA ảnh nguồn. Không vẽ lại chữ, không crossfade sang ảnh khác.
Giảm chuyển động hiển thị PNG đầy đủ tĩnh. Chỉ điều hướng khi logo và initialization/auth
đã sẵn sàng; initialization lỗi mở `/foundation` để Retry.

Session chưa đăng nhập/unavailable/lỗi đến Welcome (`/`). Session thật đã đăng
nhập đến `/interests` nếu chưa xử lý personalization, hoặc `/discover` nếu đã
hoàn tất/bỏ qua. Khi session thật đăng nhập thành công trên Welcome/Login/Sign Up,
router cũng áp dụng quy tắc này. `AuthSession.personalizationHandled` là field adapter thật cần
cung cấp từ account profile; không suy ra từ sở thích mẫu. Continue/Skip giữ
lựa chọn hiện có và đánh dấu theo user trong phiên, không tạo session giả.
**Giới hạn:** chưa có adapter auth/profile thật; trạng thái này chưa được lưu lên
backend/qua lần khởi động. Bản mặc định dùng auth unavailable nên đến Welcome.
Android native splash dùng riêng ảnh vé xanh chữ e (`evia_ticket.png`) trên nền
trắng, tự nhường cho frame Flutter đầu tiên; logo EVIA đầy đủ nằm trong animation Flutter.
S01 render logo gốc và `assets/EVIA_Welcome_Hero.png` thành hai image riêng, cùng
text/buttons Flutter thật. `assets/EVIA_S01_Welcome_Reference.png` chỉ là tài liệu
layout, không bundle hay dùng làm background. Bố cục scroll trên màn thấp/chữ lớn.
Repository chưa có iOS host; chưa xác minh native splash iOS.

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
| firebase_auth | 7.0.1 | Firebase Authentication cho Flow 1 |
| cloud_functions | 7.0.1 | Callable backend Flow 1 tại asia-southeast1 |
| qr_flutter | 4.1.0 | Render QR vé do backend cấp |
| mobile_scanner | 7.5.0 | Camera quét QR walk-in trong khung màn hiện có |
| google_sign_in | 7.2.0 | Chuẩn bị Google Sign-In |
| firebase_storage | 14.0.1 | Chuẩn bị Cloud Storage |
| firebase_messaging | 17.0.1 | FCM push, quyền Android, mở thông báo và gỡ thiết bị khi logout |
| firebase_analytics | 13.0.1 | 11 events; bật qua ANALYTICS_ENABLED |
| firebase_crashlytics | 6.0.1 | Ghi lỗi Flutter toàn cục và lỗi tải catalog trên Android khi bật collection |
| firebase_remote_config | 7.0.1 | Remote Config cho Event Milestones |
| flutter_test | Flutter SDK | Unit/widget tests |
| flutter_lints | 6.0.0 | Dart/Flutter conventions |

Flow 1 dùng callable thay vì Firestore SDK/HTTP client trực tiếp. Chưa thêm
ARTEMIS vào app runtime; bộ chạy ngoài app tại [e2e_test](e2e_test/README.md)
gồm pytest/fixture/evidence tools dùng Gemini và runner smoke Android với DeepSeek.
Kết quả từng bộ chạy được ghi riêng; chưa nghiệm thu đủ E2E Lab 3. Remote Config
đã nối hai tham số Event Milestones cho chế độ Firebase live. Messaging,
Analytics và Crashlytics đã có adapters; phạm vi/flags xem hướng dẫn tương ứng.
Xem [hướng dẫn Crashlytics](docs/EVIA_Crashlytics_Implementation.md) để kiểm thử
lỗi trên Web Admin và Android debug QA.

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
e2e_test/                # ARTEMIS pytest/fixtures/evidence + DeepSeek smoke runner
firebase/                # Deny-all storage.rules + Remote Config defaults {}
docs/                    # Kiến trúc và templates
android/                 # Android host
```

View → ViewModel → Repository → service interface → SDK adapter. SDK chỉ được
gọi trong `lib/services/`; domain models không chứa SDK types. Providers tạo và
inject dependencies, dễ override để test. Auth/Backend chọn real adapter trong
live mode; cấu hình tắt dùng pending/unavailable, demo auth chỉ bật riêng ở debug.
Các service chưa tích hợp dùng `PendingFirebaseServices` và báo lỗi rõ ràng.
Crashlytics chọn adapter Android khi bật Firebase live và chỉ ghi lỗi khi đã bật collection.

Welcome, Login, Sign Up, nội dung sự kiện công khai và `/foundation`
không yêu cầu đăng nhập. Các route cá nhân/đăng ký/voucher áp dụng auth guard S01.
Auth session stream và guard fail closed vẫn giữ nguyên. Live mode dùng adapter
đăng nhập/đăng ký thật; hoàn tất onboarding dựa trên profile server.

## Bộ màn hình Evia

Nhóm đầu đã đọc đủ 9 node trước khi triển khai từ file Figma `JQtHz2tigJtvvjVBsx03kx`,
page `2083:272`. Mapping đầy đủ ở `docs/design-traceability.md`.

| Route | Màn hình |
|---|---|
| `/` | S01 Welcome |
| `/login` | Welcome back / Login |
| `/signup` | Create Account form (chờ adapter auth thật) |
| `/interests` | Discover interests you |
| `/discover` | Discover — Consistent Event Hierarchy |
| `/discover/guest` | Discover — Guest Mode |
| `/explore` | Explore idle; chuyển sang kết quả khi tìm kiếm |
| `/explore/results` | Kết quả tham chiếu `workshop`, 3 sự kiện |
| `/filters` | Advanced Event Filters |
| `/following/events` | Following — Their Events |
| `/following/organizers` | Following — Organizers |
| `/event/schedule?event=<key>` | Chi tiết sự kiện đã chọn, mở tab Schedule |

**Skip** ở Login và **Explore as Guest** ở Welcome mở Discover Guest. Ô tìm
kiếm mở Search & Explore ngay trong Discover. **Filter events** mở bộ lọc
riêng, **Apply Filters** quay lại phần tìm kiếm và giữ truy vấn. Chạm thẻ sự
kiện mở Schedule với dữ liệu của thẻ, các tab About và Location giữ cùng sự kiện.

Hai tab Following cần đăng nhập. Khi bật backend thật, **Their Events** đọc các
đăng ký từ Firebase qua `ActivityViewModel`; **Organizers** đọc các đơn vị tài
khoản đã Follow. Chế độ preview dùng trạng thái trong phiên. Đổi tài khoản
khởi tạo lại hai danh sách; Going và đăng ký đã hủy không thuộc Their Events.

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

Mock data remains visible for UI preview: 420 available coins, 100 deposit coins,
transaction history and a sample voucher. These are not real transactions.

Local coin/streak persistence and balance mutations have been removed. Check-in,
redemption and registrations requiring a deposit wait for the coin API; they do
not report successful transactions or change the preview balance.

Daily Check-in previews day 8 with this schedule: days 1-2 +5, days 3-4 +10,
days 5-6 +15, day 7 onwards +20. The backend must confirm the actual streak,
missed days and rewards. There is no shared_preferences currency storage.

Cafe pricing is consistently 250 coins. My Rewards contains a sample voucher;
unknown codes show an empty state. Back returns to Rewards catalog. Coin icons
share the gold CoinIcon widget. Other event filters and demo cancellation remain
session-only presentation actions. Scanner imagery and QR codes are previews.

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
   - **Analytics:** Android manifest mặc định tắt auto collection và automatic
     screen reporting.
   - **Crashlytics:** xem quy trình bật collection và kiểm thử Android debug QA
     trong [hướng dẫn Crashlytics](docs/EVIA_Crashlytics_Implementation.md).
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
