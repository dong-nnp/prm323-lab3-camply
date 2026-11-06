# EVIA — Google ARTEMIS E2E

Người nhận bàn giao: xem [hướng dẫn chạy tiếp từng bước](../docs/artemis-handoff.md),
gồm setup máy mới, account/config riêng, lệnh chạy và checklist gửi evidence.

Pytest gửi instruction qua SDK `ArtemisClient` thật, đối chiếu các giá trị quan sát
và lưu evidence từng lượt. Có bộ test không đồng nghĩa đã đạt Lab.

Flash trả JSON trong `report_task_status.explanation`, thu từ đúng session trong
DataEngine; không bật Outputter/format inference vốn không được Flash graph dùng.
SDK session metadata không có output thì không tự suy ra dữ liệu từ status.

## Phiên bản và setup

- ARTEMIS SHA: `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`.
- Python host/test 3.12; dependency khóa trong `uv.lock` và lockfile upstream.
- Model dùng cho từng run ghi trong manifest: đã thử Gemini 2.5 Flash (hết quota
  ngày), sau đó Gemini 3.1 Flash Lite. Profile regression `flash`, backend `uiautomator`.
- Launcher tăng thời gian kiểm tra khóa lên 15 giây vì ADB đo được khoảng 5 giây;
  vẫn dùng kiểm tra thật, không giả lập máy đã mở khóa.
- SDK pin kèm `patches/native-ascii-input.patch`: ASCII dùng fallback ADB nhập phím
  thay clipboard/KEYCODE_PASTE chưa ổn định với Flutter. Manifest lưu diff và SHA256;
  không trình bày source đã patch là pristine upstream.
- Chưa có scrcpy: không khẳng định có video; screenshot/trace được lưu khi có thể.

Tại thư mục repo:

```powershell
python e2e_test/manage.py setup
```

Điền `GEMINI_API_KEY` trong `.local/tools/artemis/.env` trên máy. Không gửi key vào
chat hoặc commit. Không lưu raw response `/api/system/readiness`: upstream chứa
credential không che; dùng `manage.py check` để xuất bản allowlist an toàn.

Copy `settings.example.json` sang `.local/e2e/settings.json`. AVD được tạo riêng
trong phiên này là `EVIA_E2E`, serial `emulator-5556`, từ system image Android 35.
Không dùng emulator-5554/user 0 có dữ liệu cũ. Dữ liệu AVD ở `.local/avds`.

Khởi động lại AVD đã tạo:

```powershell
$env:ANDROID_AVD_HOME = Join-Path (Get-Location) '.local/avds'
& "$env:LOCALAPPDATA/Android/Sdk/emulator/emulator.exe" -avd EVIA_E2E -port 5556 -no-snapshot
```

Máy khác: tạo AVD mới tên `EVIA_E2E` bằng Android Studio, không copy userdata cá
nhân; cài APK Firebase thật vào serial test, xác minh AVD name trong settings.

Terminal 1:

```powershell
python e2e_test/manage.py host
```

Terminal 2:

```powershell
python e2e_test/manage.py check
python e2e_test/manage.py collect
python e2e_test/manage.py run --case TC04 --runs 3
```

`collect` chỉ liệt kê, không tính là test pass. `run` bật live, có thể dùng quota/phí
model. Chạy tuần tự; không mở tài khoản cá nhân trên AVD khi agent đang chạy.

## Fixture độc lập

Ngoài TC04 chỉ đọc, mỗi ca cần UID/email test và hai hook argv trong settings:

- `prepare_command`: reset đúng fixture/UID trước mỗi lượt; trả JSON gồm
  `ready: true`, `uid`, `case_id`, `context` và `expected`.
- `verify_command`: đối chiếu server sau lượt chạy; trả `verified: true`, `uid`,
  `case_id` cùng dữ liệu kiểm chứng. Không được chỉ trả true khi chưa kiểm tra.

`context` là thông tin test cần thao tác. `expected` phải có đủ trường trong
`cases.py`, lấy từ fixture/server và độc lập với câu trả lời AI. Hooks là argv do
maintainer cấu hình cục bộ, không phải shell do agent tạo. Đã có driver account
riêng cho TC02/03/05/06/07/14/18/19: reset app chỉ trên AVD test, chuẩn bị kỳ vọng bằng API
thật, đối chiếu wallet và hoàn nguyên save/follow hoặc mạng. Chưa có driver reset
financial fixture cho các giao dịch thành công: các ca cọc/nhận xu/đổi quà thành
công vẫn blocked, không sửa ví đang dùng. TC14 chỉ chọn quà active còn hàng có
giá cao hơn số dư thật; đối chiếu ví/version và toàn bộ ID redemptions trước/sau.
Không cấp xu, không gọi redeem từ fixture. TC02 giữ signed out và hủy Google flow,
không cần Google account test; Google login thành công vẫn cần account riêng.

Theo yêu cầu hiện tại, để Analytics lại sau. Chạy các ca đã chuẩn bị mà bỏ TC03:
`deferred_cases: ["TC03"]` trong settings cục bộ cũng chặn submit ca này khi chạy
toàn bộ suite. Chỉ bỏ TC03 khỏi danh sách khi đã tích hợp Analytics và muốn kiểm tra.

```powershell
python e2e_test/manage.py run --case TC02,TC06,TC07,TC14,TC18,TC19 --runs 3
```

Google login cần Google account test; TC11 cần staff/organizer và cửa sổ check-in.
TC15/16/17 cần export/upload UI, hai tham số Remote Config và FCM sender tương ứng.
Thiếu feature thì ghi gap/blocked, không dùng nút debug demo để ghi pass.

## Bằng chứng nộp bài

Raw evidence ở `.local/e2e-evidence/<run-id>/`, bị Git bỏ qua vì có thể có thông tin
đăng nhập test, QR/token và nội dung màn hình. Từng lượt lưu khi thực sự có:

- `instruction.json`, `task.json`: instruction/expected và task ID.
- `agent-result.json`, `observed.json`: kết quả gốc và giá trị đã đọc.
- `fixture-before.json`, `fixture-after.json`: kết quả driver thật.
- `outcome.json`: passed/failed/blocked cùng lý do.
- `after.png`, `trace/`: ảnh và trace khi task đã được tạo.
- `analytics-logcat.txt`: khi case đã tới bước kiểm chứng Analytics.

Cuối suite tự xuất `manifest.json`, `summary.json`, `results.csv`. Tạo bản dễ đọc:

```powershell
python e2e_test/manage.py report .local/e2e-evidence/RUN_ID
python e2e_test/tools/export_evidence.py .local/e2e-evidence/RUN_ID
```

Exporter che key/email/password test trong text và chỉ copy ảnh TC04 khi UI-tree
không chứa giá trị nhạy cảm; ảnh ca khác cần review riêng. Kiểm tra evidence đã
export trong `evidence/artemis/RUN_ID/`, liên kết từ report/slide. Cần trace/ảnh từng lượt và
giải thích các ca fail/flaky; không chỉ nộp bảng pass rate. Giữ log lỗi trước fix.
Thiếu observations/assertions hoặc chưa chạy đủ 3 lượt thì chưa đủ ghi 3/3.

Pass rate là passed / executed; blocked ghi riêng. Chưa thực thi thì `not_run`.
Hash APK workspace không chứng minh APK đã cài: giữ build/install evidence riêng.
Khám phá Pro 15–30 phút là phiên riêng, cần thời gian thật, charter, trace và issues;
không suy từ regression Flash.

Recorder Pro (chưa nghiệm thu phiên khám phá): `python e2e_test/manage.py explore 15`.
Nó kiểm tra thời gian giữa các bước thực tế; kết thúc sớm không được tính đủ 15 phút.
Các ca live chặn khi RAM trống dưới `minimum_free_memory_gb` (mặc định 2 GB).
Đợt tiếp tục trên AVD headless dùng ngưỡng cục bộ 1.25 GB; outcome lưu RAM trước
từng lượt để đánh giá giới hạn môi trường, không coi đổi ngưỡng là sửa ANR.

## Kiểm tra bộ thu evidence (không phải E2E)

```powershell
python e2e_test/tools/self_check.py
node --test e2e_test/tools/account_fixture.test.mjs
```

Self-check kiểm tra output thiếu/sai type/sai giá trị không pass và blocked không
nâng pass rate. Không cộng những self-check này vào số ca ARTEMIS đạt.
## Runner smoke DeepSeek riêng

Phần dưới mô tả runner/scenario được tích hợp từ main. Nó dùng checkout
`.local/artemis` và cấu hình riêng, khác bộ pytest/Gemini ở trên dùng
`.local/tools/artemis`. Không chạy hai bộ đồng thời trên cùng thiết bị; kết quả
smoke DeepSeek dưới đây không thay thế kết quả pytest đã thu ở trên.

ARTEMIS chạy ngoài app Flutter, điều khiển Android qua ADB. Không thêm package
vào `pubspec.yaml`, không đổi UI hay Firebase. Smoke scenario hiện tại chỉ kiểm
tra Welcome → Login và validation, không đăng nhập hoặc ghi dữ liệu nghiệp vụ.

## Cài trên Windows

Cần Git, ADB trong PATH, Python >= 3.12 và [uv](https://docs.astral.sh/uv/).
Chạy từ repository root:

```powershell
git clone https://github.com/google/artemis.git .local/artemis
git -C .local/artemis checkout 351ca8422f7b5b54e80a9c1ce03a222e02415b6b
uv sync --project .local/artemis --python 3.12 --no-dev --locked
```

Nếu checkout đã tồn tại, bỏ lệnh clone. Revision trên là source đã đối chiếu
khi tích hợp; cần kiểm tra lại CLI/config khi nâng cấp. Máy hiện tại có uv local
tại `.local/uv/bin/uv.exe`; có thể dùng đường dẫn này thay `uv`.
Nếu uv báo lỗi Python minor-version link, đặt
`$env:UV_PYTHON_INSTALL_DIR = "$PWD/.local/python"` trước lệnh sync.

Tạo file `.local/artemis/.env` (đã được Git ignore) và điền key tại máy:

```dotenv
OPENAI_API_KEY=<DeepSeek API key của bạn>
OPENAI_BASE_URL=https://api.deepseek.com
```

Tên biến `OPENAI_API_KEY` do adapter tương thích OpenAI của Artemis yêu cầu.
Không gửi key vào chat, không commit file này. Config versioned
`artemis.deepseek.json` chọn `deepseek-flash` có vision. DeepSeek Pro hiện không
hỗ trợ ảnh. API có tính phí; screenshots/UI text của phiên test được gửi tới
nhà cung cấp AI. Chỉ dùng thiết bị/tài khoản QA.

## Kiểm tra và chạy

Cài APK debug muốn kiểm thử theo README gốc, mở khóa điện thoại và bật USB
debugging. Script không build/cài APK, không xóa data hoặc đăng xuất session.

```powershell
adb devices -l
./e2e_test/run-artemis.ps1 -DeviceSerial '<serial từ adb>' -CheckOnly
./e2e_test/run-artemis.ps1 -DeviceSerial '<serial từ adb>'
```

`-CheckOnly` kiểm tra thiết bị, schema config bằng `check_config.py` và CLI,
không gọi AI, không xác nhận key hợp lệ.
Runner dùng standalone để không dùng nhầm daemon/model config đang chạy.
Config/helper/keep-awake environment overrides chỉ tồn tại trong lúc script chạy.
Không cài helper APK tự động; Artemis dùng hierarchy fallback của upstream.
Flash Explorer đặt `pro` để không dùng object detector Gemini ER mặc định.
Giới hạn Flash 20 lượt trong config để tránh vòng thao tác không giới hạn.
Tắt `flash.step_summarizer`: bản upstream này khởi tạo summarizer bằng Gemini
trực tiếp dù operator dùng DeepSeek. Smoke ngắn không cần nén ảnh lịch sử;
nếu mở rộng bài chạy dài, cần adapter summarizer hỗ trợ provider tương ứng.
Đây là cấu hình thử nghiệm DeepSeek: khả năng grounding/click phải được đo trên
app thật, không mặc định tương đương Gemini ER.

Trace lưu trong `.local/artemis-runs/<timestamp>/`, chưa commit vì có thể chứa
thông tin trên thiết bị. **Exit code 0 của CLI không phải assertion E2E pass**:
Flash không có Checker độc lập. Đọc từng kết quả và đối chiếu screenshots/trace;
BLOCKED hoặc thiếu evidence không được tính là PASS. Chỉ chép evidence đã xem
xét và loại thông tin nhạy cảm vào `evidence/` khi cần báo cáo Lab 3.

Không thay thế `flutter analyze`/`flutter test`; chưa bao gồm login thật, đăng ký
sự kiện, hủy vé, ví, đổi thưởng, push hoặc ARTEMIS trong CI/MCP toàn máy.

## Validation thực tế — 06/11/2026

- `uv sync --no-dev --locked` đạt với Python 3.12 trong `.local/python`.
- `run-artemis.ps1 -DeviceSerial R3CR60CT0WZ -CheckOnly` đạt: schema model
  routing, giới hạn 20 lượt, ADB và CLI flags được kiểm tra trên bản đã cài.
- Thiết bị không tồn tại bị runner từ chối trước khi gọi AI.
- PowerShell parser, JSON và `git diff --check` cho files thuộc task đạt.
- Lần đầu chạy thật thất bại vì Flash visual step summarizer gọi Gemini trực
  tiếp; đã tắt summarizer cho smoke ngắn. `check_config.py` nay khởi tạo FlashRunner
  với mock device services và từ chối mọi lần khởi tạo visual summarizer.
- Chạy lại: 1 request `deepseek-flash` thành công (7.701 prompt tokens theo log).
  Artemis báo đang ở Discover với session đã đăng nhập, dừng **BLOCKED** theo
  scenario; chưa chạy các bước validation Login. Session upstream ghi `failed`,
  không phải app test pass hoặc lỗi API. Trace compiler báo 0 images/0 steps,
  chưa có screenshot evidence để nghiệm thu UI. Log local:
  `.local/artemis-retry.log`; không đưa log vào Git.
- Không đổi Dart/native/dependency Flutter nên không chạy lại Flutter suite.

Nguồn: [Google ARTEMIS](https://github.com/google/artemis),
[DeepSeek Vision](https://api-docs.deepseek.com/guides/vision/),
[DeepSeek models](https://api-docs.deepseek.com/quick_start/pricing/).
