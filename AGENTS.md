# Hướng dẫn làm việc trong repository

File này áp dụng cho toàn bộ repository `prm393_lab03` (PRM393 Lab 3).
Tuân thủ yêu cầu hiện tại của người dùng; dùng các quy tắc dưới đây cho những
quyết định chưa được chỉ định. Khi yêu cầu mới mở rộng phạm vi foundation,
cập nhật tài liệu liên quan cùng implementation để tránh hướng dẫn lỗi thời.

## Tài liệu cần đọc

- [README.md](README.md): môi trường, dependencies, chạy app và FlutterFire setup.
- [docs/architecture.md](docs/architecture.md): MVVM, dependency flow, DI và bootstrap.
- [docs/design-traceability.md](docs/design-traceability.md): nguồn thiết kế, token
  mapping và các khoảng trống chưa được xác nhận.
- [docs/test-plan.md](docs/test-plan.md): phạm vi kiểm thử và validation.
- [docs/analytics-plan.md](docs/analytics-plan.md): tham chiếu khi task có tracking.
- [docs/code-review.md](docs/code-review.md): checklist/template khi task có review.

Các tài liệu kế hoạch và template không phải bằng chứng công việc đã hoàn thành.

## Phạm vi và cách thay đổi code

- Mặc định chỉ duy trì source base; chỉ triển khai business features, màn hình/
  flows Lab 2, Firebase integration, tracking, ARTEMIS hoặc AI Code Review khi
  task hiện tại yêu cầu rõ phần việc đó.
- Không sửa file ngoài phạm vi task, ghi đè hoặc hoàn tác thay đổi đang có của
  người dùng. Kiểm tra working tree trước khi sửa.
- Ưu tiên giải pháp đơn giản, dễ bảo trì; tận dụng cấu trúc hiện có. Không tạo
  framework nội bộ, abstraction, repository hoặc dependency khi chưa có nhu cầu.
- Dùng Flutter stable, Dart null safety và Android target. Giữ package name
  `prm393_lab03`; lấy SDK constraints từ `pubspec.yaml` và hướng dẫn từ README.
- Theo Dart/Flutter conventions: tên file `snake_case`, class `UpperCamelCase`,
  biến/hàm `lowerCamelCase`; ưu tiên immutable models, `final` và `const` phù hợp.
- Không thêm mock business data vào runtime; test fixtures/fakes chỉ nằm trong tests.

## Kiến trúc bắt buộc

Luồng gọi: **View → ViewModel → Repository → Service interface → SDK adapter**.
State trả về View qua Riverpod. Giữ cấu trúc `lib/` theo architecture document.

- **View (`screens/`, `widgets/`):** chỉ render presentation state và chuyển user
  actions cho ViewModel. Không gọi repository, service, Firebase SDK, Google
  Sign-In hoặc HTTP trực tiếp; không chứa business logic.
- **ViewModel (`viewmodels/`):** quản lý state, loading/empty/error/data, business
  rules và điều phối actions. Dùng `AppState<T>` khi phù hợp; chặn submissions
  trùng, xử lý lỗi và không cập nhật state sau dispose.
- **Repository (`repositories/`):** data access qua service contracts; không phụ
  thuộc Widgets hoặc ViewModels. Chỉ thêm khi có use case cần data access.
- **Service (`services/`):** nơi duy nhất được gọi Firebase SDK, Google Sign-In
  SDK hoặc HTTP client. Map SDK results/errors thành domain models/AppException.
- **Model (`models/`):** domain/presentation data thuần Dart; không import Flutter,
  Riverpod hoặc Firebase SDK. Không để SDK types lọt ra contract công khai.
- **DI (`core/providers/`):** chọn concrete adapters và inject dependencies bằng
  Riverpod. Cho phép override interface providers trong tests. Không dùng global
  mutable state hoặc truy cập singleton trực tiếp từ UI.
- **Routing (`app/`):** dùng `MaterialApp.router` và go_router. Guard phải từ chối
  protected routes khi auth chưa rõ, unavailable, signed out hoặc lỗi. UI guard
  không thay thế backend authorization/Firebase Rules.

## Firebase và dependencies

- Giữ app chạy được khi chưa cấu hình Firebase. Mặc định `FIREBASE_ENABLED=false`;
  bootstrap không gọi SDK từ Dart và hiển thị trạng thái chưa cấu hình.
- Không tự tạo `firebase_options.dart`, `google-services.json`, credentials,
  project IDs, secrets hoặc kết quả dịch vụ giả. Cấu hình thật phải được tạo
  bằng FlutterFire CLI theo README; không commit secrets/signing keys.
- `lib/firebase/` chứa cấu hình không phụ thuộc SDK; initialization SDK nằm trong
  service layer. Không chuyển initialization vào Widget hoặc ViewModel.
- Giữ contracts cho Authentication/Google Sign-In, Storage, Messaging, Analytics,
  Crashlytics và Remote Config. Pending adapters phải báo unavailable/lỗi rõ
  ràng; không trả thành công giả hoặc âm thầm bỏ qua thao tác.
- Khởi tạo Firebase Core thành công không có nghĩa các adapter pending đã được
  tích hợp. Chỉ thay provider khi real adapter tương ứng đã được triển khai.
- Chưa bật auto collection, Analytics observers, Crashlytics hooks, FCM auto-init,
  permission prompts hoặc Remote Config fetch ngoài task được yêu cầu.
- Giữ `firebase/storage.rules` deny all cho đến khi có yêu cầu quyền truy cập
  cụ thể. Không đổi sang public allow-all. Remote Config defaults chỉ chứa keys
  đã được xác định; không tự suy đoán dữ liệu nghiệp vụ.
- Không thêm Firestore hoặc chọn nguồn dữ liệu Lab 2 khi chưa có yêu cầu rõ.
- Khi cần thêm dependency, dùng resolver như `flutter pub add PACKAGE` để chọn
  bản stable tương thích; không đoán version hoặc dùng prerelease ngoài yêu cầu.
  Giữ `pubspec.lock` trong Git và cập nhật bảng dependencies ở README khi đổi.

## Design system và accessibility

- Dùng tokens từ `lib/theme/app_tokens.dart` và styles từ `AppTheme`; không
  hard-code màu, typography, spacing, radius hoặc elevation trong screens.
- Tái sử dụng button, text field, loading, empty, error và responsive widgets
  hiện có. Validation/business rules thuộc ViewModel; Widget chỉ hiển thị lỗi.
- Tham chiếu handoff và DESIGN.md Lab 2 được ghi trong design traceability khi
  task cần triển khai UI. Không tự suy đoán thiết kế nếu thiếu tài liệu; giữ
  cấu trúc/token hiện có và ghi TODO cụ thể cho phần chưa xác định.
- Hỗ trợ 360dp và 412dp, SafeArea, keyboard insets, nội dung scroll và system
  text scaling. Không dùng fixed-height text containers gây cắt chữ/overflow.
- Touch targets tối thiểu 48 × 48dp; body text tối thiểu 14sp. Trạng thái lỗi,
  lựa chọn và thành công phải có text/icon, không chỉ dựa vào màu.
- Chưa có font assets thì dùng fallback đã ghi trong theme; không tự thêm
  runtime font downloads hoặc tài nguyên chưa rõ quyền sử dụng.

## Kiểm thử và validation

- Tests phải kiểm tra hành vi có ý nghĩa, ưu tiên state transitions, lỗi/retry,
  lifecycle, auth guard và UI phản ánh state. Không tạo test chỉ lặp implementation.
- Override Riverpod providers bằng test-only fakes; unit/widget tests nền tảng
  không được yêu cầu Firebase account, credentials hoặc production network.
- Khi đổi Dart code/dependencies, thực hiện các bước phù hợp sau trước khi bàn giao:

  ```sh
  flutter pub get
  dart format lib test
  flutter analyze
  flutter test
  ```

- Khi đổi Android host/native plugins, kiểm tra thêm `flutter build apk --debug`
  và startup trên thiết bị/emulator nếu môi trường cho phép. Duy trì khả năng
  khởi động khi chưa cấu hình Firebase.
- Với thay đổi chỉ ở Markdown/tài liệu, kiểm tra nội dung, links/paths và
  `git diff --check`; không cần chạy lại Flutter tests nếu không ảnh hưởng code.
- Sửa lỗi do thay đổi vừa tạo gây ra. Nếu môi trường chặn validation, báo chính
  xác lệnh chưa chạy/không đạt và nguyên nhân; không ghi nhận thành pass.
- `e2e_test/` chỉ là nơi chuẩn bị Google ARTEMIS cho đến khi task yêu cầu triển
  khai E2E. Không tự tạo automation, AI review findings, test results, screenshot
  hoặc evidence giả; chỉ ghi nhận những gì đã thực sự thực hiện.

## Tài liệu và bàn giao

- Cập nhật README/architecture/design traceability/test plan khi thay đổi làm các
  tài liệu này không còn đúng. Không tự tick checklist của việc chưa thực hiện.
- Không đánh đồng test fixture, prototype checklist hoặc kết quả lần chạy trước
  với evidence cho thay đổi hiện tại.
- Báo cáo ngắn gọn bằng tiếng Việt: thay đổi chính, files liên quan, validation
  thực sự đã chạy, hạn chế còn lại và bước tiếp theo nếu cần.
