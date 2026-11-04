# Test plan — template

## Cloud release — 04/11/2026

Source giữ nguyên so với 31-test Emulator run. Build TypeScript đạt; deploy 34 Functions/Run latest revisions READY, 2 Scheduler definitions/IAM đúng, 14 indexes READY. **6/6 Callable smoke và 3/3 Firestore Rules smoke đạt**, không authenticated mutations/test users/seed. [Release evidence](backend-release.md). Không coi definition checks là job business execution, OAuth/FCM hoặc UI/E2E proof.

## Backend readiness mới — 04/11/2026

Lệnh `npm --prefix functions run test:emulator`, Node22.23.4 + Java21 JBR + Firebase CLI: build TypeScript và **31/31 tests đạt, 0 fail, 0 skipped**. [Log cuối](../evidence/backend-readiness/emulator-final.log). Flutter không thay đổi, không chạy lại UI/native tests trong milestone này.

Ngoài coverage backend cũ, lượt này kiểm terms version import/API, empty dry-run, tìm kiếm đ/d tiếng Việt, FCM token cap, Rules không cho client đọc/ghi quyền admin, đăng ký lại/tranh slot/vé và QR cũ, admin voucher dùng một lần/revoke/expiry, monthly race/cutoff/onboarding/year rollover và no-show cutoff/idempotency/attended/cancelled event.

Monthly/no-show business functions được gọi trực tiếp trong Emulator tests. Emulator không chạy Cloud Scheduler theo lịch thật; chưa deploy code mới, chưa kiểm IAM/schedule/cost hoặc FCM delivery. Các kết quả 20 tests bên dưới là lịch sử revision trước.

RED→GREEN evidence: [search trước fix](../evidence/backend-readiness/emulator-before-search-fix.log), [search sau fix](../evidence/backend-readiness/search-after-fix.log), [re-registration trước implementation](../evidence/backend-readiness/reregistration-before.log), [voucher trước implementation](../evidence/backend-readiness/voucher-before.log). Không tính các lượt RED là pass.

Trạng thái: có unit/widget tests cho foundation và Evia UI; chưa có E2E ARTEMIS.
Tài liệu này là kế hoạch, không xác nhận pass/fail cho các bước chưa chạy.

## Firebase development setup — run 04/11/2026

SDK: Flutter 3.47.9 / Dart 3.13.7 tại `F:\Mobile_Programing\flutter_evia_lab3`.

| Check | Kết quả thực tế | Log local |
|---|---|---|
| `flutter pub get` | PASS, giữ nguyên dependency constraints/lock | Terminal setup |
| `dart format --output=none --set-exit-if-changed lib test` | PASS, 88 files / 0 changed | `evidence/firebase-setup/dart-format-check.log` |
| `flutter analyze` | PASS, no issues | `evidence/firebase-setup/flutter-analyze.log` |
| `flutter test` | FAIL, 76 pass / 5 fail; Evia UI overflow và ListTile assertion | `evidence/firebase-setup/flutter-test.log` |
| `flutter test test/services/firebase_preparation_test.dart test/viewmodels/bootstrap_view_model_test.dart test/widgets/foundation_app_test.dart` | PASS, 12 tests | `evidence/firebase-setup/firebase-foundation-tests.log` |
| `firebase deploy --only firestore:rules --project evia-lab3-kiet-2026 --non-interactive` | PASS, deny-all Rules compiled/released | `evidence/firebase-setup/firestore-rules-deploy.log` |
| Anonymous REST read `users/probe` | HTTP 403, denied | `evidence/firebase-setup/firestore-access-check.txt` |
| `flutter build apk --debug --dart-define=FIREBASE_ENABLED=true` | PASS after fixing JDK path and cross-drive Kotlin cache | `evidence/firebase-setup/flutter-build-apk.log` |
| `flutter build apk --debug --no-pub` with native config temporarily absent | PASS; native config restored afterwards | `evidence/firebase-setup/flutter-build-without-firebase.log` |
| Native Firebase smoke — Pixel 5 emulator | PASS: `/foundation` displays “Firebase đã khởi tạo”; native init successful | `evidence/firebase-setup/emulator-firebase.png`, `emulator-firebase.xml`, `emulator-startup.log` |
| Native install/start — Samsung SM-G996N | Install/start PASS; native Firebase init successful. Visual check not verified: phone locked | `evidence/firebase-setup/samsung-startup.log` |

Full-suite failures nằm trong `test/widgets/evia_screens_test.dart` (4 layout
cases và 1 navigation case); source UI/test đó chưa thay đổi trong task config.
Không đánh dấu full test suite đạt. Đây không phải emulator security tests,
ARTEMIS results hoặc bằng chứng các dịch vụ Firebase nghiệp vụ đã hoạt động.

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

## Backend Firebase — run thật 04/11/2026

Scope: chỉ `functions/`, Firebase config/Rules/indexes và docs; working-tree run,
chưa có commit/PR, chưa cloud deploy. Không chạy lại toàn bộ Flutter/Dart tests vì task không sửa UI/domain Dart.
Sau cấu hình Auth/SHA thật và sinh lại FlutterFire config, có build APK debug
riêng; xem kết quả bổ sung bên dưới. Kết quả UI cũ không đại diện
cho backend mới và các lỗi cũ chưa được sửa trong task này.

Toolchain thực tế: Node22.23.4, Java21 JBR, Firebase CLI15.30.2. Chạy từ repo root
với toolchain trên PATH, `FUNCTIONS_DISCOVERY_TIMEOUT=60`:

```powershell
npm --prefix functions run test:emulator
```

Kết quả cuối: TypeScript build đạt, **20 pass / 0 fail / 0 skipped**.
Log: `evidence/backend/emulator-tests.log`. Gồm signup once/interest validation,
last-seat race, cancel once/reopen, quotes/terms/requestId conflicts, scoped staff
QR + revocation, walk-in intent/expiry/replay, daily race/Vietnam midnight/gap/year
rollover, stock race/voucher owner/expiry/physical reward, insufficient balance,
follow races, inbox owner/read cutoff, FCM token reassignment/rotation, catalog
feeds/pagination/My Events, catalog validation/dry-run, real HTTP Callable Auth.

Firestore/Storage tests dùng **Auth Emulator ID token qua REST**, không dùng Admin
SDK để giả vờ kiểm tra Rules. Phủ own/public reads và từ chối cross-UID, direct
wallet/profile/event/attendance writes, private secrets/devices, unfiltered catalog,
PDF wrong type/size/overwrite. Test harness Admin SDK chỉ tạo test fixtures và
assert state trong demo project; có guard project/loopback trước clear dữ liệu.

Một lượt trước phát hiện Storage Emulator coi upload ghi đè như create: thêm
`resource == null` và chạy lại tới pass. Không đánh dấu pass lượt trước lỗi.
FCM thật bị bỏ qua trong Emulator; test token binding không chứng minh delivery.
Emulator không kiểm tra composite index requirements như cloud. Chưa có native
Google OAuth/camera/export/push, cloud Rules/index build/cost/latency evidence.

`npm --prefix functions audit --omit=dev --json`: 6 moderate transitive findings,
0 high/critical, ghi tại `evidence/backend/npm-audit.json`. Chuỗi chủ yếu nằm ở
Firestore SDK → gaxios/rimraf → glob/minimatch; chưa áp dụng breaking override
hoặc `--force`. API không nhận glob pattern/path filesystem từ client; đây không
phải chứng minh hoàn toàn không thể khai thác. Kiểm tra lại SDK upstream trước
production. Audit command exit1 do findings, không phải audit sạch.

Bổ sung cấu hình Android thật: FlutterFire CLI sinh lại config sau khi bật
Google/email-password và thêm debug SHA. `flutter build apk --debug` **PASS**
(assembleDebug 75.9s); log `evidence/backend/flutter-build-apk.log`. Có warning
Kotlin Gradle Plugin từ Firebase plugins hiện có. Chưa cài/chạy lại APK hoặc
đăng nhập trên thiết bị ở lượt này; không suy ra native OAuth pass từ build.
Không sửa UI/Dart business logic; config sinh tự động vẫn Git-ignore.

## Migration project nhóm — 04/11/2026

- Đích `prm393-31822`, billing đã enabled (không liên kết billing mới).
- Chỉ sửa config/triển khai backend, thêm script deploy nhóm 4; không sửa UI.
- Chạy lại `npm --prefix functions run test:emulator`: **20/20 PASS** sau cấu hình
  CPU fractional. Log `evidence/firebase-migration/emulator-tests.log`.
- FlutterFire CLI sinh config mới, native compiled resources xác nhận project ID
  và app ID mới (`compiled-project-check.txt`). `flutter build apk --debug` PASS
  42.6s, còn warning KGP từ plugins hiện có.
- Pixel 5 headless: `flutter run -d emulator-5554 --debug --route=/foundation
  --dart-define=FIREBASE_ENABLED=true --no-resident` PASS. XML + PNG thực tế hiển thị
  Firebase đã khởi tạo (`android-foundation.xml/png`, `android-startup.log`).
  Đây chỉ xác nhận bootstrap; không suy ra login/FCM/ba luồng UI pass.
- Firestore cloud: 14 indexes READY. Anonymous public filtered query 200, unfiltered
  query và private wallet GET 403 (`cloud-rules-smoke.json`). Không tạo test users
  hay seed business data trên project thật.
- Rollout Functions bị quota ở các lượt đầu; logs lỗi được giữ, chỉ đếm revision
  ready + smoke thành công sau khi deploy theo nhóm nhỏ. Xem `firebase-migration.md`
  để biết trạng thái chốt; không dùng Functions API ACTIVE một mình làm bằng chứng
  vì Cloud Run vẫn có thể đang phục vụ revision cũ.

Kết quả migration cuối: **32 Functions ACTIVE + 32 latest Cloud Run revisions READY**,
14 indexes READY. **4/4 HTTP Callable + 3/3 Firestore Rules cloud smoke đạt**.
Logs/JSON thật tại `evidence/firebase-migration/`. Script deploy nhóm 4 đã chạy
đủ 8 nhóm, exit0; đây cũng là validation thực tế cho script, không chỉ AST check.
Không ghi test users/data lên cloud. Không rerun toàn bộ Flutter UI tests.
