# Gợi ý bộ lọc AI

Filter Events có ô nhập và bản gợi ý Gemini. Use suggestion chỉ cập nhật draft;
người dùng sửa rồi Apply Filters. Giữ các trường audience/policy/availability
đã chọn. Không ghi database hoặc đăng ký sự kiện.

## Cấu hình thật

1. Trong Firebase Console của app, bật Firebase AI Logic với Gemini Developer API.
2. Đăng ký Android App Check. Debug dùng AndroidDebugProvider, đăng ký debug token
   của thiết bị trong Console. Release dùng Play Integrity. Enforce App Check cho AI Logic.
3. Publish Remote Config `ai_filters_enabled=true`, `ai_filters_model` là tên model
   hiện được project hỗ trợ, `ai_filters_prompt` từ remote-config-defaults.json.
   Defaults cố ý tắt AI và để trống model khi chưa cấu hình dịch vụ.
4. Chạy app Android với FIREBASE_ENABLED=true. Không nhúng Gemini key.

Remote Config được fetch trước mỗi request, tuân theo cache 12 giờ release của
adapter hiện có (debug không cache). Tắt bằng Remote Config có hiệu lực sau fetch
thành công, có thể bị trễ trên release. Fetch thất bại thì AI báo lỗi và giữ lọc thủ công.
Không triển khai cloud bằng thay đổi source này. Project hiện hữu từng dùng Blaze,
chi phí/quota AI phải kiểm tra trên chính project trước khi demo nhiều lượt.

## Dữ liệu và giới hạn

Chỉ từ khóa trong vocabulary cố định được gửi, không gửi nguyên câu, hồ sơ,
email, UID, ảnh hoặc dữ liệu đăng ký. Nội dung nhập chỉ giữ trong phiên màn hình.
Vocabulary hỗ trợ một số từ tiếng Việt/Anh, có thể mất ý phủ định hoặc từ đồng nghĩa.
Người dùng phải kiểm tra bản gợi ý. Chưa hỗ trợ mọi câu tự nhiên hoặc category mới
ngoài vocabulary. Đây là giới hạn cần mở rộng nếu taxonomy/catalog thay đổi.

Gemini trả JSON cho Category, Date, Time, Duration theo enum. Repository từ chối
JSON lỗi, thiếu trường hoặc enum ngoài danh sách. Today/Tomorrow/This weekend
được đổi sang custom date range theo ngày địa phương trên thiết bị. Thời lượng
chỉ theo ba mức hiện có, không biểu diễn chính xác yêu cầu dưới hai giờ.
Quota, mạng, timeout, App Check hoặc cấu hình lỗi đều giữ bộ lọc thủ công.

Analytics ghi ai_request, ai_result_accepted, ai_error qua repository hiện có,
không chứa prompt hoặc output. Accepted ghi khi bấm Use suggestion, không ghi
lại khi người dùng bấm nhiều lần. Collection tuân theo cờ Analytics hiện có.

## Validation và evidence

Tests dùng fake/local state kiểm parser, privacy vocabulary, ngày cuối tuần,
draft/Apply và giao diện 360/412dp với text scale 2. Kết quả lệnh thực tế được báo
khi bàn giao. Chưa có 3 input/output Gemini thật, chưa chạy ARTEMIS 3 lượt,
chưa có bằng chứng Remote Config kill switch hoặc Analytics DebugView cho tính năng.
Không dùng kết quả test giả lập làm evidence Gemini thật.

## Kết quả validation 09/11/2026

- flutter pub add / pub get và dart format hoàn thành.
- flutter analyze đạt.
- 8/8 tests riêng AI đạt, gồm chặn request trùng và dispose trong khi request pending.
- Full suite trước khi thêm hai test lifecycle cuối: 242 đạt, 4 lỗi trong
  evia_screens_test (Discover overflow), flow3_screens_test và registration/loading.
  Chưa chạy baseline checkout để khẳng định các lỗi này có sẵn.
- APK debug Android arm64 bật Firebase build thành công.
- Chưa gọi Gemini thật hoặc thiết lập cloud App Check/Remote Config trong lượt này.

APK build-number 2002 đã cài cập nhật thành công trên Samsung R3CR60CT0WZ.
Đã mở và xem Filter Events có AI filter assistant trên thiết bị thật.
Đây là kiểm tra hiển thị, chưa phải lần gọi Gemini thành công.
