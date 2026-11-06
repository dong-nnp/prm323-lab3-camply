# ARTEMIS — bằng chứng thực thi Evia

Ngày cập nhật: 06/11/2026. **Chưa đủ điều kiện ghi hoàn tất ARTEMIS Lab 3.**

## Đã làm và đã xác minh

- Cài Python 3.12.16, ARTEMIS commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`,
  remote SDK cùng commit, pytest và `uv.lock`.
- Có 21 ca/biến thể, collect 63 lượt. Đây là số dự kiến, không phải số pass.
- Có 7 self-check offline của parser/so sánh/bảng kết quả/thu trace đạt;
  không gộp vào E2E.
- Build APK Firebase debug x64 thành công; cài và khởi động trên AVD test riêng
  `EVIA_E2E`, `emulator-5556`. Máy ảo cũ được trả user 0 rồi tạm đóng để giảm RAM;
  dữ liệu cũ không bị xóa.
- [Preflight đã lọc credential](setup/preflight.json) đối chiếu SHA256 APK trên
  thiết bị và file workspace trùng nhau; [versions](setup/versions.json) ghi bản
  công cụ thật. Preflight vẫn báo thiếu RAM, không phải ready/pass E2E.
- Chủ tài khoản cho phép gửi màn hình test sang Gemini và tạo đúng một account
  Firebase `EVIA E2E`. Login/setup/backend verification dùng account này; credentials
  chỉ nằm ở `.local`, không đưa vào repo. Chưa có Google account test.

## Kết quả đã export

Run [20261106T013827Z-049dd5bd](20261106T013827Z-049dd5bd/report.md):

| Ca | Lượt đã thực thi | Kết quả | Giới hạn |
|---|---|---|---|
| TC04 — Search rỗng và phục hồi | 3 | 1 pass / 2 fail | Hai lượt ANR trong môi trường thiếu RAM; chưa ổn định 3/3 |
| TC05 — bốn tab | 1 hoàn tất; 1 bị hủy/chặn | 1 pass; 1 blocked | Lượt tiếp theo dừng khi RAM trống <0.5 GB; chưa chạy đủ 3 lượt hoàn tất |

Đợt [20261106T021747Z-615529da](20261106T021747Z-615529da/report.md) đã chạy
đủ 6 lượt: TC04 đạt 1/3, TC05 đạt 0/3. Một lượt Search thao tác sai; một lượt
Search và ba lượt tab bị bộ đọc từ chối định dạng báo cáo. Giữ nguyên cả 5 fail.
Bộ đọc sau đó được sửa để nhận đúng một JSON trong lời giải thích và chuẩn hóa
xuống dòng của empty message; vẫn kiểm tra giá trị, kiểu dữ liệu và UI-tree gốc.
Đợt chạy lại dùng bản sửa được ghi riêng.

Đợt chạy lại [20261106T023224Z-3cfd8a66](20261106T023224Z-3cfd8a66/report.md)
đạt **6/6** sau 519 giây: **TC04 3/3, TC05 3/3**. Các lượt TC05 đều có
đối chiếu backend sau thao tác. Đây là hai ca đạt đủ ba lượt trong đợt này,
không phải toàn bộ 21 ca/biến thể đã đạt. Không cộng lượt cũ để thay đổi kết quả.

Đợt mở rộng [20261106T024147Z-d723f8b6](20261106T024147Z-d723f8b6/report.md)
chạy 5 lượt trong 1.022 giây, đạt 1/5:

| Ca | Kết quả | Quan sát thực tế |
|---|---|---|
| TC03 — Search/Analytics | Fail | Agent gặp lỗi đăng nhập, chưa tới bước xác minh Analytics; người dùng sau đó yêu cầu để Analytics lại sau |
| TC06 — chi tiết và Back | Fail | Agent báo chuỗi `80` thay vì giá voucher 200 từ API; đã làm rõ instruction cho lượt sau, chưa chạy lại |
| TC07 — save/follow và undo | Pass 1/1 | Backend xác nhận đúng tài khoản test, ví không đổi và quan hệ đã được gỡ sau undo; chưa đủ 3 lượt |
| TC18 — logout/guard | Fail | Agent ghi nhận hộp thoại App Not Responding tại login; chưa đủ căn cứ quy nguyên nhân cho app |
| TC19 — offline/retry | Fail | Có thao tác Android Settings, báo thấy lỗi và phục hồi; `retry_visible = null`, không tính pass |

Cleanup của cả năm lượt hoàn tất; Wi-Fi trên AVD được xác nhận đã bật lại.
Cuối đợt RAM trống còn khoảng 0.66 GB, nên không mở thêm ca và đã đóng đúng AVD
EVIA_E2E/ARTEMIS host do agent tạo, giữ userdata/evidence. Trước lượt tiếp theo cần
giải phóng thêm RAM; ngưỡng cục bộ được trả về mặc định 2 GB. Chưa chạy Pro.

TC04 pass chỉ khi JSON AI khớp **và** UI-tree gốc chứng minh nonce ở ô nhập,
empty result xuất hiện, cuối cùng đã xóa query và trở lại Suggested Events.
TC05 pass có structured observations đúng 4 tab, kèm API kiểm tra wallet account
E2E không thay đổi: available 200, held 0, version 1.

Mỗi case/run có task ID, outcome, steps, UI-tree, agent result, trace/log khi có.
Ảnh Guest TC04 đã export; ảnh login/profile TC05 giữ trong raw evidence cục bộ để
review privacy trước khi đưa vào báo cáo. Không coi ảnh bị lược bỏ là đã đính kèm.
`export-manifest.json` ghi hash các file, text đã che key/email/password test.

## Các vấn đề phát hiện và xử lý

1. **Timeout ADB:** check khóa 1 giây quá ngắn trên máy này (dumpsys đo ~5 giây).
   Launcher cho phép 15 giây, giữ kiểm tra thực tế; không ép trạng thái unlocked.
2. **Android multi-user:** UIAutomator không khởi động ổn trong user phụ, chuyển
   sang AVD mới. Không dùng ảnh/dữ liệu phiên cá nhân làm test input.
3. **Agent SUCCESS không đáng tin:** một lượt trả completed nhưng giải thích
   “would likely” thay cho bước phục hồi. Harness đánh fail; không đổi thành pass.
4. **Flash output:** SDK host commit này chỉ trả metadata session; report Flash
   thực tế nằm trong DataEngine `report_task_status`. Collector lấy đúng session,
   không đoán output hoặc lấy kết quả phiên khác. Không export toàn SQLite DB.
5. **Nhập Flutter:** clipboard + KEYCODE_PASTE có thể báo dispatched dù chữ chưa
   vào field. Bản vá một dòng dùng fallback phím ADB cho ASCII, lưu diff/hash.
6. **Quota:** Gemini 2.5 Flash trả RESOURCE_EXHAUSTED, quota
   GenerateRequestsPerDayPerProjectPerModel-FreeTier (20). Gemini 2.5 Flash Lite
   trả 404; đã xác minh Gemini 3.1 Flash Lite hoạt động và ghi model vào manifest.
   Không đổi quota/billing hoặc tạo key/account để tăng quota.
7. **Tài nguyên:** RAM máy nhiều thời điểm 95–96%, còn 0.5–0.6 GB, Android launcher
   và app có ANR. Chưa đủ căn cứ quy hết cho Evia. Harness mới chặn lượt live khi
   RAM trống dưới ngưỡng cấu hình (mặc định 2 GB). Đợt tiếp tục dùng AVD headless,
   GPU auto, 720×1600 và ngưỡng cục bộ 1.25 GB; mỗi outcome ghi RAM thật.

Cuối đợt đầu, RAM xuống khoảng 0.26 GB và không còn task đang chạy. Đã đóng AVD test
và ARTEMIS host do agent tạo để trả tài nguyên; giữ userdata và toàn bộ evidence.
Đợt tiếp tục đã khởi động lại AVD/host sau khi người dùng giải phóng RAM; không
tự đóng ứng dụng đang làm việc của người dùng.

Các run chẩn đoán trước nằm ở `.local/e2e-evidence/`, giữ nguyên kết quả lịch sử;
run export là snapshot, không viết lại fail thành pass sau khi sửa harness.

## Còn thiếu để nộp đúng đề

Đợt chuẩn bị tiếp theo: thêm fixture TC02 (hủy Google, không đăng nhập) và TC14
(không đủ xu). Preflight chỉ đọc Firebase xác nhận account E2E có 200 xu, quà
active còn hàng giá 500 xu, 0 redemption. Có 2 Node tests cho chọn fixture/chặn
baseline thiếu trang đạt; 7 self-check Python vẫn đạt, collect 63 lượt. Đây
không phải lượt E2E mới. Instruction TC06 yêu cầu đủ ngày/giờ và giá ở reward
detail; TC19 yêu cầu gửi truy vấn mới khi offline và đọc Retry thật.

Guard `deferred_cases` đã kiểm tra bằng lệnh chọn riêng TC03: **1 skipped**, lý do
hoãn trong cấu hình; không submit task, không gửi màn hình và không tính pass.
Pytest có cảnh báo không ghi được cache do quyền thư mục; guard vẫn được thực thi.

RAM đo khi chưa mở AVD chỉ khoảng 2.0–2.9 GB; đang chờ giải phóng thêm tài nguyên,
chưa mở host/AVD hay gửi thêm màn hình sang model trong đợt chuẩn bị này.

Lần thử khởi động kế tiếp sau khi người dùng đóng bớt ứng dụng: RAM trước boot
3.91 GB, sau khi AVD boot xong còn 0.54–0.57 GB (máy có 14.92 GB RAM khả dụng).
Chưa submit test hay gửi màn hình sang Gemini; đã đóng đúng AVD/host vừa tạo.
Ước tính 4–5 GB trước boot chưa đủ trên cấu hình hiện tại: nên có khoảng 6 GB
trống trước boot và kiểm tra còn ít nhất 2 GB sau khi máy ảo ổn định. Không hạ
ngưỡng để ép test chạy hoặc ghi kết quả pass khi chưa thực thi.

- Đủ tài nguyên, chạy lại từng ca 3 lần, phân loại app/tool/model/environment.
- Hoàn thiện reset/verification fixture cho registration, cancellation, attendance,
  daily và redemption; không reset ví/vé account người dùng đang dùng.
- Google account test/OAuth và native picker evidence.
- Export/Storage UI, hai Remote Config giá trị hiển thị và FCM ba trạng thái phải
  được xác minh trước ca tương ứng; không thay bằng màn demo hoặc success giả.
- Một ca có Analytics Logcat/DebugView; app hiện còn gap instrumentation nên
  bật debug mode tự nó không đủ chứng minh event đã phát.
  Người dùng yêu cầu để Analytics lại sau trong đợt tiếp tục; không triển khai
  adapter hay chạy lại TC03 lúc này. Lượt đã chạy trước yêu cầu vẫn giữ nguyên.
- Phiên Pro 15–30 phút thực sự, review issues và liên kết evidence. Recorder đã có,
  chưa chạy/hoàn thành phiên này.

Hướng dẫn đầy đủ: [e2e_test/README.md](../../e2e_test/README.md).
