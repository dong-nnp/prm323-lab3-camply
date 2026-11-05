# Mở email mọi domain — 05/11/2026

Owner bỏ giới hạn email @fpt.edu.vn/@fe.edu.vn. App và backend nhận mọi địa chỉ
đúng định dạng; trim/lowercase, tối đa 254 ký tự. MSSV vẫn hai chữ + sáu số.
Không thêm xác minh email/sinh viên, không đổi quyền staff/admin, không bỏ Auth.

## Thay đổi

- Server `identity.ts`: validator `emailAddress` dùng syntax Zod, không domain
  allowlist. `authenticated()` vẫn kiểm Firebase Auth actor và email hợp lệ;
  lỗi `EMAIL_REQUIRED`. initializeUser/profile/registration dùng cùng validator.
- Client giữ utility `FptIdentity` (tên legacy, còn chứa format MSSV); email
  grammar khớp validator Zod cài trong repo. Email/password, Google, reset,
  signup/login/profile/registration bỏ giới hạn domain. Giữ wire key
  `universityEmail` để không phá contract; label hiện có đổi thành Email.
- Không đổi layout/style/assets, không thêm màn hoặc tính năng ngoài scope.
- Participant requirements demo đã thay câu bắt buộc email FPT bằng email hợp lệ.
  Đã backup, dùng updateTime precondition và field mask trước ghi cloud; không sửa
  giá cọc, terms hoàn 30%, lịch, số vé, wallet, role hoặc records người dùng.

## Validation

- [RED](red-test.log): Gmail bị validator cũ từ chối trước khi sửa.
- [Build backend](build.log), [Emulator](emulator-tests.log): **57/57 PASS**,
  0 fail/skipped. Gmail initialize/profile/register, transport Firebase Auth
  qua Emulator, phần lớn suite dùng alice@gmail.com/bob@outlook.com/staff@yahoo.com.
  Quyền staff/admin, wallet/idempotency và policy hoàn cọc 30% vẫn qua checks.
- [Flutter](flutter-test.log): **176/176 PASS**; [analyze](analyze.log) sạch,
  [format](format.log)/[pub get](pub-get.log) đạt. Kiểm provider khác nhau,
  malformed email, normalizing, MSSV giữ nguyên và signup/login/reset qua VM.
- [APK debug](build-apk.log): build thành công, FIREBASE_ENABLED=true, không DEMO_AUTH.
  KGP warning của plugins hiện có là cảnh báo tương thích Flutter tương lai.
- [Native negative login](native-email-validation.json): địa chỉ thử ở reserved
  `example.org` đi qua validation và nhận lỗi credential từ Firebase Auth.
  Không tạo account, không gửi email. Đây không phải bằng chứng login thành công
  hoặc Google consent của một tài khoản ngoài trường.

## Rollout

Có 36 callable exports: 32 dùng guard/identity, 4 public không đọc email
(getEvent/getOrganizer/getReward/getServerInfo). Chỉ cập nhật 32 callable theo
8 nhóm × 4 để tránh quota startup CPU. 5 trigger/scheduler không đổi.
[Preflight](functions-before.json) và các deploy-batch logs/JSON ghi nhận từng nhóm.
[Kiểm tra sau deploy](functions-after.json) xác nhận **32/32 ACTIVE**, cùng source
hash mới; Cloud Run latest-created = latest-ready, khớp revision của Functions.

[Kế hoạch dữ liệu](requirements-plan.json), [backup trước ghi](requirements-before.json)
và [kiểm tra sau ghi](requirements-applied.json) xác nhận **12/12** sự kiện demo
đã nhận câu yêu cầu email hợp lệ. Chỉ đổi `participantRequirements` và `updatedAt`;
các field khác được đối chiếu bằng dữ liệu thực và giữ nguyên.

Không tạo Auth account ngoài trường trên production, không gửi email reset hoặc
mail xác minh, không sửa tài khoản demo hay custom claims để giả proof. Gmail
native/Google account consent chưa nghiệm thu; tests backend dùng Emulator.
