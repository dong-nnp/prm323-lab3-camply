# Google ARTEMIS + DeepSeek

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
