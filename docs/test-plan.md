# Test plan — template

Trạng thái: có unit/widget tests cho foundation và Evia UI; chưa có E2E ARTEMIS.
Tài liệu này là kế hoạch, không xác nhận pass/fail cho các bước chưa chạy.

## Phạm vi foundation

| Loại | Trường hợp | Test source |
|---|---|---|
| Unit | Bootstrap loading/empty/data/error, retry, chống gọi lặp, dispose | `test/viewmodels/bootstrap_view_model_test.dart` |
| Unit | Lỗi không lộ chi tiết nội bộ, timeout message | `test/core/exception_mapper_test.dart` |
| Unit | Guard public/protected với các trạng thái auth | `test/app/authentication_guard_test.dart` |
| Unit | Chưa cấu hình không cần native SDK; pending auth không giả thành công | `test/services/firebase_preparation_test.dart` |
| Widget | App root 360/412dp, text scale 1x/2x, button >=48dp, error/retry | `test/widgets/foundation_app_test.dart` |

Lệnh: `flutter pub get`, `dart format --output=none --set-exit-if-changed lib test`,
`flutter analyze`, `flutter test`. Native smoke: `flutter run -d DEVICE_ID`
khi chưa thêm Firebase config. Không cần Firebase account cho unit/widget tests.

## Evia — lần triển khai 04/11/2026

- `test/widgets/evia_screens_test.dart`: 9 route ở 360/412dp, text scale 1x/2x;
  Skip → guest → search → filters; follow/unfollow; minimum interests; login
  không giả thành công. Foundation tests dùng override route `/foundation`.
- `test/viewmodels/evia_view_model_test.dart`: search/category/filter draft/apply,
  reset, lịch sử deduplicate, bookmark/follow và date/time/custom range.
- Đã tải và kiểm tra đủ 131 asset files, không rỗng; XML root kích thước SVG đã đọc.
- `flutter pub get`, format, analyzer và `git diff --check`: xem kết quả run bàn giao.
- `flutter test`: **bị chặn trước khi chạy test**. Windows Application Control
  từ chối chạy `dartaotruntime.exe` (frontend compiler) ở cả SDK Downloads và SDK
  được ghi trong README. Không thay đổi chính sách bảo mật trên máy.
- Chưa chạy được widget render, screenshots hoặc native smoke; không coi static
  analysis là xác nhận visual fidelity hay responsive pass.

Sau khi môi trường cho phép Flutter compiler, chạy `flutter test`; để xuất hình
tham chiếu app vào thư mục scratch, đặt biến môi trường `EVIA_CAPTURE_DIR` rồi
chạy `flutter test test/widgets/evia_screens_test.dart --plain-name "render all requested frames"`.
Capture test dùng font Roboto từ Flutter SDK nếu có `FLUTTER_ROOT`. Đối chiếu
từng hình với node Figma trong design traceability trước khi visual sign-off.

## Mẫu test case tiếp theo

## My Events / Rewards — kết quả kiểm tra bổ sung 04/11/2026

`test/widgets/activity_screens_test.dart` có 18 route, mỗi route kiểm tra 360/412dp
và text scale 1x/2x. Có thêm flow tests cho Keep/Cancel Registration và đổi café
→ receipt → locker → voucher. `test/viewmodels/activity_view_model_test.dart`
kiểm tra chọn ngày/calendar draft, year boundary, cancellation counts, daily
reward một lần, redemption một lần, insufficient balance, deposits giữ nguyên,
history filters và mã check-in sai/lặp.

Lệnh scoped: `flutter test test/widgets/activity_screens_test.dart test/viewmodels/activity_view_model_test.dart --concurrency=1`.
Lượt có thêm `EVIA_ACTIVITY_CAPTURE_DIR` xuất 18 PNG + asset geometry JSON vào
scratch, gồm **44 tests đạt**: 18 responsive, 3 user flows (kể cả catalog search),
18 captures, 5 VM tests.
Không cần Firebase credentials, network hoặc camera/emulator cho các tests này.

`flutter pub get`, `dart format --output=none --set-exit-if-changed lib test`,
`flutter analyze` đã chạy. Assets mới: 230/230 tồn tại và không rỗng.

Lượt baseline toàn bộ suite trước khi thêm nhóm mới phát hiện 5 tests lỗi ở
`evia_screens_test.dart` do overflow trong Discover/Following preview của nhóm
màn hình trước. Không quy các lỗi đó thành lỗi của 18 màn hình mới, và không
đánh dấu toàn bộ suite pass từ scoped run. Xem kết quả bàn giao cho lần full run
cuối: **46 đạt, 5 lỗi**, đều 5 tests cũ nói trên; các tests My Events/Rewards có
trong full run đều đạt. Catalog-search regression test được bổ sung và xác minh
qua scoped run sau đó. Chưa chạy native Android smoke hoặc Firebase/camera
backend integration.

| ID | Requirement / design ID | Layer | Preconditions | Steps | Expected | Automation source | Status |
|---|---|---|---|---|---|---|---|
| TODO | TODO | Unit/widget/native/E2E | TODO | TODO | TODO | TODO | Chưa thực hiện |

## Mẫu ghi nhận run thật (để trống đến khi chạy)

- Commit / build: TODO
- Thiết bị / Android API / viewport / text scale: TODO
- Môi trường Firebase: TODO
- Lệnh / timestamp / người chạy: TODO
- Kết quả thực tế và đường dẫn log/screenshot: Chưa ghi nhận trong template
- Defects / follow-up: TODO

TODO: native Google Sign-In cancel/failure, Storage Rules deny/allow theo quyền,
FCM permission/token/background delivery, Remote Config fetch/cache, Analytics
DebugView và Crashlytics test crash chỉ sau tích hợp thật. Xác nhận công cụ
Google ARTEMIS trước khi thêm E2E vào `e2e_test/`.

## Đợt 3 — Registration / Profile

Scoped command: `flutter test test/widgets/registration_screens_test.dart test/viewmodels/registration_view_model_test.dart`.
Set `EVIA_FLOW_CAPTURE_DIR` tới thư mục scratch để xuất 17 PNG và geometry JSON.
Lượt cuối **46 tests đạt**: 17 responsive (360/412dp, scale 1x/2x), 17 captures,
3 UI flows và 9 ViewModel tests. UI flows phủ detail → register → loading →
success → ticket, sửa lỗi form, mark all notifications read. VM tests phủ identity
validation/consent, debit một lần, chặn pending submit trùng, failed/full giữ form
và ví, waitlist/walk-in không giữ coin, dispose/invalidate trong pending request,
saved filters/remove, interests tối thiểu 3 và notification unread count.

`flutter pub get`, format check và `flutter analyze` đều thành công. Full suite
sau khi thêm nhóm mới: **76 đạt / 5 lỗi**, vẫn đúng 5 tests cũ ở
`test/widgets/evia_screens_test.dart` (Discover/Following overflow). Không sửa
mismatch ngoài phạm vi. Scoped tests đợt 3 đạt sau lượt tinh chỉnh layout cuối.
180 local exports không rỗng; audit SVG native root dimensions/callsite/geometry
trong cả 17 capture không có mismatch. Không phải pixel-diff hoặc Android visual
sign-off. APK debug biên dịch thành công; Gradle in cảnh báo native-access/KGP
của Firebase plugins hiện có. Chưa kiểm thử real registration/backend/camera.

## Rewards UI/UX regression — 05/11/2026

`test/widgets/rewards_regression_test.dart` kiểm tra tote → confirm → success →
locker → đúng mã, nhiều receipt và chọn đúng món, mã không tồn tại, empty states,
header/khung ví không nhảy khi chuyển tab, vùng bấm tối thiểu 48dp, Profile mở đúng
màn hình, milestone sau check-in và lịch sử khác tháng. Có kiểm tra café/tote đã
lưu ở cả 360/412dp, text scale 1x/2x. VM tests thêm ngưỡng 249/250 xu, debit đúng
giá, chống đổi lặp sau khi kiếm thêm xu và lọc nhóm lịch sử theo tháng.

`flutter pub get`, `dart format lib test`, `flutter analyze` đạt.
`flutter test --concurrency=1`: **90 đạt / 5 lỗi**, các lỗi đều ở
`evia_screens_test.dart`, cùng 5 tests đã lỗi trước sửa Rewards; không ghi toàn bộ
suite đạt. Toàn bộ tests Rewards mới đạt.

Capture riêng 9 route Rewards sau sửa: **18 tests đạt** (9 responsive và 9
captures); đã xem đủ 9 ảnh. Capture success/locker/voucher gọi redeem café trong
test-only state; runtime chưa có receipt thì render empty state. Không nhầm fixture
capture với reward/backend thật. APK debug x64 đã build/cài thành công. Native smoke
trên emulator-5554: Skip → Rewards → đổi tote 400 → số dư 20 → My Rewards → đúng
ảnh/mã tote đã đạt. Xem [báo cáo Rewards](rewards-ui-ux-review.md) cho phạm vi và ảnh.

## Android debug build reuse regression — 04/11/2026

Đổi Android host build tracking, không đổi Dart/app logic. Native checks:

- `flutter build apk --debug --target-platform android-x64 --no-pub` thành công.
- Hai `flutter run -d emulator-5554 --no-resident --no-pub -v` thành công;
  lượt warm cuối Gradle8.6s, install1.893s, sync4.1s, tổng39.739s.
- MainActivity được xác nhận là top resumed activity. Startup vẫn có skipped
  frames; không coi đây là runtime performance sign-off.
- APK không đổi: task copy APK/assets UP-TO-DATE, clean hook SKIPPED.
- APK đích thiếu: tái tạo, SHA-256 bằng bản gốc.
- Entrypoint probe ngoài project: APK thay đổi, hash bản copy khớp packaged APK;
  trở lại entrypoint gốc thành công. Không cài probe lên emulator.
- Packaged APK thiếu: AGP đóng gói lại và Flutter copy đúng output.
- Không chạy clean/xóa dependency cache/sửa SDK/tắt Defender/gỡ Firebase.
  Không chạy lại Dart widget suite vì thay đổi chỉ ở Gradle; lỗi UI baseline
  ghi ở các mục trước không được đánh dấu đã sửa.

Xem [Build performance](build-performance.md) để biết phạm vi debug không flavor,
không split và giới hạn so sánh các lượt đo.


## Rewards static preview - 05/11/2026

Current implementation retains visible mock fixtures and removes local coin
mutations/persistence. Check-in, redemption and deposit registration wait for API.
Earlier transaction-flow evidence above is historical.

Validation for this change:
- flutter pub remove shared_preferences completed dependency resolution.
- dart format lib test completed; flutter analyze: no issues.
- 61 tests passed across rewards_regression_test, activity_screens_test,
  registration_screens_test, activity_view_model_test and registration_view_model_test.
- Debug x64 APK build succeeded. Full suite was not rerun.
- git diff --check passed.
- APK installed successfully on emulator-5554. am start -W timed out; subsequent
  dumpsys confirmed MainActivity as topResumedActivity. No visual startup sign-off.
