# Bàn giao chạy tiếp ARTEMIS — EVIA Lab 3

Cập nhật: 06/11/2026. Dành cho người nhận source và tiếp tục kiểm thử trên Windows.
Mục tiêu là chạy thật, ghi nhận đúng kết quả và thu bằng chứng để nộp Lab.
**Chưa hoàn tất ARTEMIS. Analytics đang được chủ dự án yêu cầu để lại sau.**

## 1. Đang làm đến đâu?

| Ca | Trạng thái đã có | Việc người nhận cần làm |
|---|---|---|
| TC04 — Search không có kết quả, xóa query để phục hồi | Đạt 3/3 trong một đợt | Chạy lại nếu đổi source/APK/môi trường cần nghiệm thu |
| TC05 — Discover, Events, Rewards, Profile | Đạt 3/3 trong cùng đợt | Tương tự TC04 |
| TC07 — lưu sự kiện, theo dõi CLB, kiểm tra danh sách và hoàn tác | Đạt 1/1 | Cần một đợt đủ 3 lượt |
| TC06 — event/organizer/reward detail và Back | Fail: agent nhầm xu sự kiện với giá voucher, bỏ giờ | Instruction đã sửa; chạy lại |
| TC18 — đăng xuất và auth guard | Fail: ANR khi vào login | Chạy lại khi đủ tài nguyên; đọc trace/log trước khi quy lỗi cho app |
| TC19 — mất mạng, màn lỗi, Retry và phục hồi | Fail: chưa quan sát được Retry | Instruction đã sửa để buộc gửi truy vấn mới khi offline; chạy lại |
| TC02 — mở rồi hủy Google Sign-In | Đã thêm fixture, chưa chạy | Không cần Google account test để hủy; vẫn cần Google flow hoạt động |
| TC14 — không đủ xu đổi quà | Đã thêm fixture, chưa chạy UI | Preflight từng xác nhận 200 xu, quà 500 xu, 0 redemption; driver sẽ đọc lại khi chạy |
| TC03 — Search kèm Analytics | Tạm hoãn | Giữ trong `deferred_cases`, chưa gắn Analytics trong công việc này |
| TC01 — Google login thành công | Chưa có Google account test | Chuẩn bị tài khoản riêng và cấu hình OAuth/SHA |
| TC08–13 — đăng ký, full event, hủy, attendance, daily, đổi quà thành công | Thiếu fixture/reset/verification | Chưa đủ điều kiện chạy; không tự cấp/reset xu hoặc dùng nút attendance demo |
| TC15 — export/upload; TC16 — hai giá trị Remote Config; TC17 — FCM ba trạng thái | Thiếu điều kiện/driver tương ứng | Xác minh feature, quyền và dữ liệu trước; không chỉ thêm expected rồi ghi pass |
| Pro 15–30 phút | Có recorder, chưa có phiên đạt | Chạy riêng, kiểm tra thời gian thao tác thật và review issue |

Bằng chứng đã có: [bảng tổng hợp](../evidence/artemis/README.md).
Đợt đạt 6/6: [20261106T023224Z-3cfd8a66](../evidence/artemis/20261106T023224Z-3cfd8a66/report.md).
Đợt mở rộng có fail: [20261106T024147Z-d723f8b6](../evidence/artemis/20261106T024147Z-d723f8b6/report.md).
Không gộp các lượt rời rạc để tuyên bố một đợt 3/3. Không xóa kết quả fail cũ.

## 2. Người bàn giao cần gửi gì?

1. Source đúng bản hiện tại: `e2e_test/`, patch, lockfile, tài liệu và app tương ứng.
   Tại thời điểm soạn tài liệu, nhiều file đang chưa commit, gồm cả toolkit ARTEMIS.
   **Chỉ clone/pull main chưa chắc có các file này.** Chốt commit hoặc bản source
   bàn giao với chủ dự án trước khi chạy; tài liệu này không tự commit/push code.
2. File cấu hình Android thật `android/app/google-services.json` của project
   `prm393-31822`, package `com.example.prm393_lab03`, qua kênh riêng của nhóm.
   Không lấy JSON của package `com.android.application` trước đây.
3. Nếu dùng lại account đã được cho phép: trao đổi riêng đúng file
   `.local/e2e/test-account.json`. File này chứa credentials của **EVIA E2E**.
   Không dán vào báo cáo, chat công khai hoặc commit Git. Không chạy cùng account
   đồng thời trên hai máy vì fixture/cleanup sẽ tác động cùng dữ liệu test.
4. Người chạy tự cấu hình Gemini API key có quyền sử dụng trên máy mình.
   Không gửi nguyên thư mục `.local`, `.env`, Firebase CLI login cache, Android
   userdata cá nhân, signing keys hoặc toàn bộ database trace để thay cho bàn giao.

Nếu không nhận được file account test, nhờ chủ dự án cấp/chấp thuận account riêng.
**Không chạy `account_fixture.mjs create` để tự tạo thêm account trong project.**
Lệnh `configure` bên dưới chỉ dùng lại account đã có và đã được cho phép.

## 3. Điều kiện máy chạy

- Windows, Git, Python có lệnh `python`, Node.js hỗ trợ `fetch`/`AbortSignal.timeout`.
- Flutter đã kiểm thử: 3.47.9 / Dart 3.13.7; kiểm tra constraint ở `pubspec.yaml`.
- Android SDK có platform-tools, emulator, system image Android 35 x86_64;
  Java/Android toolchain dùng được. Xem [README](../README.md) cho Firebase setup.
- Nên còn khoảng **6 GB RAM trống trước khi mở AVD** trên cấu hình máy đã thử;
  sau khi AVD/host ổn định phải còn ít nhất **2 GB**. Máy cũ có ~15 GB RAM khả dụng
  nhưng vẫn ANR khi chỉ còn 0.5–0.6 GB. Không hạ ngưỡng để ép chạy.
- Người chạy và chủ dự án cần thống nhất việc gửi ảnh/cây giao diện **dữ liệu test**
  sang Gemini. Không mở tài khoản/dữ liệu cá nhân trên AVD test.

Toàn bộ lệnh dưới đây chạy trong PowerShell tại **thư mục gốc repository**.
Không cần Visual Studio C++ workload để chạy kiểm thử Android này.

## 4. Cài trên máy khác

### 4.1. Toolkit và cấu hình cục bộ

```powershell
python e2e_test/manage.py setup
New-Item -ItemType Directory -Force .local/e2e
Copy-Item e2e_test/settings.example.json .local/e2e/settings.json
```

`setup` tải ARTEMIS đúng commit khóa, tạo Python 3.12 riêng, cài dependencies
theo lockfile và áp dụng patch nhập ASCII. Không cần chép `.venv` từ máy cũ.
**Nếu chạy trên máy cũ đã có settings, bỏ lệnh Copy-Item để tránh ghi đè cấu hình.**

Mở `.local/tools/artemis/.env` trên máy và điền `GEMINI_API_KEY`. Không gõ key
vào lệnh lưu trong tài liệu/lịch sử terminal. Model đang cấu hình là
`gemini-3.1-flash-lite`; quota/model khả dụng cần kiểm tra tại lần chạy mới.
Không coi model đã dùng được ở lần cũ là bảo đảm lần sau vẫn dùng được.

Giữ trong `.local/e2e/settings.json`:

```json
{
  "base_url": "http://127.0.0.1:8000",
  "device": "emulator-5556",
  "android_user_id": 0,
  "avd_name": "EVIA_E2E",
  "model": "gemini-3.1-flash-lite",
  "minimum_free_memory_gb": 2,
  "timeout_seconds": 600,
  "deferred_cases": ["TC03"]
}
```

Đây là các trường cần kiểm tra trong file mẫu, không phải yêu cầu xóa các trường
`cases`, UID/email hay hooks đã có. Đặt file account E2E được cấp vào
`.local/e2e/test-account.json`, đặt Google Services JSON đúng vị trí, rồi chạy:

```powershell
node e2e_test/tools/account_fixture.mjs configure
```

Lệnh xác thực đúng UID test và ghi lại đường dẫn hook theo máy mới. Không chép
nguyên settings máy cũ vì có đường dẫn tuyệt đối. Driver hiện khóa đúng project,
package, AVD và serial ở trên; không tùy tiện đổi để dùng máy ảo cá nhân.

### 4.2. Tạo máy ảo riêng và cài app thật

Máy mới: dùng Android Studio Device Manager tạo AVD **EVIA_E2E**, Android 35,
Google APIs/Google Play x86_64. Không copy userdata máy ảo cá nhân.
Mở bằng terminal riêng, chọn port 5556:

```powershell
$emulator = Join-Path $env:LOCALAPPDATA 'Android/Sdk/emulator/emulator.exe'
& $emulator -avd EVIA_E2E -port 5556 -no-snapshot
```

Máy cũ có AVD trong workspace: thêm lệnh sau **trước khi mở emulator**:

```powershell
$env:ANDROID_AVD_HOME = Join-Path (Get-Location) '.local/avds'
```

Máy mới tạo AVD bằng Android Studio thường dùng thư mục AVD mặc định; không đặt
biến trên trỏ vào thư mục workspace rỗng. Không mở hai bản AVD cùng lúc.

Tại terminal khác, chờ Android boot xong, mở khóa màn hình và kiểm tra:

```powershell
$adb = Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe'
& $adb devices
& $adb -s emulator-5556 emu avd name
& $adb -s emulator-5556 shell getprop sys.boot_completed
```

Kỳ vọng: serial `emulator-5556` trạng thái `device`, AVD name `EVIA_E2E`, boot `1`.
Nếu cần giảm độ phân giải trên AVD test, giữ kích thước logic gần 411dp:

```powershell
& $adb -s emulator-5556 shell wm size 720x1600
& $adb -s emulator-5556 shell wm density 280
```

Build/cài bản Firebase thật từ source nhận bàn giao:

```powershell
flutter pub get
flutter build apk --debug --target-platform android-x64 --dart-define=FIREBASE_ENABLED=true
& $adb -s emulator-5556 install -r build/app/outputs/flutter-apk/app-debug.apk
```

Không bật `DEMO_AUTH`, không dùng APK từ source cũ không rõ build flags.
Không cần giữ `flutter run`/`flutter attach` trong lúc ARTEMIS điều khiển app.
Nếu build/cài thất bại, xử lý trước; chưa tính là đã chạy E2E.

## 5. Chạy tiếp trên máy đã chuẩn bị

Máy cũ đã có account/config/APK: bỏ các bước cài lại không cần thiết, mở đúng AVD
và host rồi kiểm tra readiness. Sau reboot/rebuild vẫn kiểm tra serial và APK.

**Terminal host:**

```powershell
python e2e_test/manage.py host
```

Giữ terminal này mở. Console cục bộ tại `http://127.0.0.1:8000`.

**Terminal test:**

```powershell
python e2e_test/manage.py check
python e2e_test/tools/self_check.py
node --test e2e_test/tools/account_fixture.test.mjs
python e2e_test/manage.py collect
```

- `check` cần ready, đúng AVD/account và đủ RAM. Kiểm tra thêm
  `apk.same_apk_installed = true`; nếu false/thiếu, cài lại đúng APK rồi kiểm tra.
- Không mở/lưu raw `/api/system/readiness`: upstream có thể trả credential không che.
  Dùng `manage.py check`, đã lọc các trường an toàn.
- 7 self-check Python và 2 Node tests chỉ kiểm tra toolkit; không cộng vào E2E.
  `collect` hiện liệt kê 63 lượt dự kiến, không có nghĩa 63 lượt đã chạy.

Chạy thử **một lượt** ca thiếu xu để xác nhận login/fixture/model hoạt động:

```powershell
python e2e_test/manage.py run --case TC14 --runs 1
```

Đọc outcome/trace. Nếu fail hoặc blocked, xử lý nguyên nhân trước khi chạy dài.
Nếu đủ điều kiện, chạy đợt nghiệm thu ba lượt mỗi ca:

```powershell
python e2e_test/manage.py run --case TC02,TC06,TC07,TC14,TC18,TC19 --runs 3
```

Có thể tách từng ca để dễ theo dõi, ví dụ `--case TC07 --runs 3`. Chạy tuần tự,
không mở hai lệnh test cùng lúc. Driver sẽ xóa dữ liệu **app trên AVD test** trước
mỗi lượt, đăng nhập account E2E qua UI; TC07 có cleanup save/follow, TC19 bật lại mạng.
TC14 không cấp xu, không gọi redeem trong fixture; verify ví/version và redemption IDs.

Khi cần regression lại các ca đã đạt:

```powershell
python e2e_test/manage.py run --case TC04,TC05 --runs 3
```

Không chạy toàn bộ suite để mong các ca thiếu fixture tự hoạt động. Giữ TC03
trong `deferred_cases`; guard đã được xác minh sẽ skip trước khi submit AI.

## 6. Thu bằng chứng và gửi lại

Mỗi đợt in đường dẫn `.local/e2e-evidence/<RUN_ID>`; đây là đường dẫn cần dùng,
không chọn thư mục chỉ dựa vào thời gian sửa file. Trong PowerShell:

```powershell
$runPath = '.local/e2e-evidence/THAY_BANG_RUN_ID_VUA_CHAY'
python e2e_test/manage.py report $runPath
python e2e_test/tools/export_evidence.py $runPath
```

Exporter tạo `evidence/artemis/<RUN_ID>/`, không ghi đè snapshot đã có. Giữ:

- `report.md`, `results.csv`, `summary.json`, `manifest.json` và export hash manifest.
- Từng lượt: instruction, task ID, observed, outcome, fixture before/after/cleanup
  khi có, trace/steps và UI-tree gốc. Fail cũng là evidence, cần giữ nguyên.
- Ảnh có thể có account/credentials/QR. Export tự động chỉ cho ảnh Guest TC04
  đạt điều kiện; ảnh ca khác còn ở raw evidence và cần review/che dữ liệu riêng
  trước khi chia sẻ. Không tuyên bố ảnh đã được đính kèm nếu exporter đã bỏ qua.

`passed` cần giá trị quan sát đúng và các bước xác minh đạt. `failed` là đã chạy
nhưng không đạt. `blocked`/`skipped`/`not_run` không được tính pass. Task AI trả
SUCCESS chưa đủ; ví dụ báo sai giá voucher vẫn bị harness đánh fail.

Nếu thiếu `fixture-after.json` do fail sớm thì không nói backend đã được xác minh.
Không tự thêm ảnh, số liệu, kết quả hoặc tick checklist chưa làm.

Gửi lại nhóm:

```text
Source commit/bản source nhận bàn giao:
APK SHA256 + xác nhận APK đã cài trùng workspace:
Máy/AVD/model + RAM trước chạy:
Run ID và lệnh đã chạy:
Ca nào đạt đủ 3 lượt; ca nào fail/blocked:
Nguyên nhân và đường dẫn step/ảnh/log liên quan:
Đường dẫn evidence đã review dữ liệu nhạy cảm:
Cleanup mạng/save/follow đã xong hay cần xử lý:
```

## 7. Pro 15–30 phút và các ca chưa sẵn sàng

Chỉ chạy khi không có regression task hoạt động và máy đủ tài nguyên:

```powershell
python e2e_test/manage.py explore 15
```

Recorder Pro **chưa được nghiệm thu end-to-end**; có thể còn vướng cấu hình
model/SDK. Kết thúc sớm hoặc lỗi không được tính đủ 15 phút. Đọc
`exploratory-status.json`, thời gian giữa các bước thật, original trace và
`exploratory.md`; người review phải ghi issue/tái hiện/mức độ dựa trên quan sát.
Chưa review thì không ghi đã có findings. Với Pro, không dùng bảng report Flash
để kết luận hoàn tất; ảnh Pro cũng cần review riêng trước khi chia sẻ.

TC01 cần Google test account, Google provider và SHA của signing key **máy mới**
được đăng ký đúng Firebase project. Google flow bị lỗi cấu hình thì sửa cấu hình,
không đổi sang email/password để tuyên bố đã chứng minh Google Sign-In.

TC08–13/15–17 cần người triển khai hoàn thiện fixture/UI/permissions tương ứng:
reset đúng dữ liệu test và đối chiếu backend độc lập. Không dùng account sinh viên
thật, sửa ví/vé thật hoặc đổi Remote Config chung để làm test pass. Analytics
TC03 chờ tích hợp sau theo chủ dự án.

## 8. Lỗi thường gặp và dừng phiên

| Hiện tượng | Xử lý |
|---|---|
| RAM <2 GB sau boot, Android ANR | Dừng mở lượt mới; đóng AVD/host test để trả RAM, chuyển máy mạnh hơn hoặc giải phóng ứng dụng rồi đo lại |
| Không thấy emulator-5556 | Kiểm tra AVD name/port/boot; không đổi sang serial của máy cá nhân |
| `Missing prepare/verify` | Kiểm tra account file và chạy lại `configure`; nếu ca chưa được driver hỗ trợ thì ghi blocked |
| Email/password sai | Kiểm tra đúng file E2E và việc agent nhập/focus; không in password ra log hoặc thử account cá nhân |
| TC06 sai giá/thiếu giờ | Đọc trace: cần reward detail thật, giá dạng số JSON, ngày và giờ đầy đủ; không sửa expected cho khớp AI |
| TC19 thiếu Retry | Phải gửi request mới khi offline, chờ error và quan sát Retry thật; chỉ tắt Wi-Fi/đọc Android indicator chưa đủ |
| Quota/404/model unavailable | Ghi đúng lỗi provider, dừng/retry theo quota; không bịa kết quả, không tạo key/account để né quota |
| Pytest cache Access denied | Có thể dùng thêm `-p no:cacheprovider`; cảnh báo cache không biến skipped thành passed |

Để dừng bình thường, đợi lượt hiện tại hoàn tất, đọc cleanup và kiểm tra Wi-Fi/data
đã bật lại trên AVD test. Nếu bị ngắt trước cleanup, chỉ với đúng EVIA_E2E:

```powershell
node e2e_test/tools/account_fixture.mjs cleanup TC19
node e2e_test/tools/account_fixture.mjs cleanup TC07
```

Không force-kill ngay khi agent đang sửa save/follow hoặc tắt mạng nếu có thể
dừng có kiểm soát. Xem task trên console, dừng task còn chạy rồi kiểm tra cleanup;
thiếu cleanup phải ghi lại để người tiếp theo xử lý.

Sau khi không còn task, `Ctrl+C` ở terminal host, đóng cửa sổ AVD test hoặc dùng
`adb -s emulator-5556 emu kill` **sau khi đã xác minh AVD name là EVIA_E2E**.
Không xóa userdata/evidence và không đóng ứng dụng đang làm việc của người khác.

Tham chiếu: [toolkit README](../e2e_test/README.md), [kế hoạch](artemis-plan.md),
[test plan](test-plan.md), [kết quả thực tế](../evidence/artemis/README.md).
