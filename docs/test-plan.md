# Test plan — template

Trạng thái: có unit/widget tests cho foundation; chưa có E2E ARTEMIS.
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

## Mẫu test case tiếp theo

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
