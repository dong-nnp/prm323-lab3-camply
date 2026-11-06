# Kế hoạch ARTEMIS cho Evia

TC03 (Search/Analytics) đã được xóa khỏi suite theo yêu cầu chủ dự án. Yêu cầu
Analytics của đề vẫn là khoảng trống nghiệm thu; evidence lịch sử không bị xóa.

Ngày lập: 06/11/2026. Trạng thái mới: **đã triển khai toolkit và có lượt chạy thật,
chưa hoàn tất nghiệm thu Lab**. Xem [evidence](../evidence/artemis/README.md).
Các mục chuẩn bị dưới đây mô tả kế hoạch ban đầu, không phải tất cả đã hoàn thành.

## 1. Yêu cầu và hiện trạng

Nguồn yêu cầu:

- `D:/PRM393 - Lab 3 Cloud-Enabled Mobile App (Firebase, Patrol, AI Code Review).pdf`, mục 7, trang 8–9 và rubric trang 14.
- `D:/PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf`, trang 23.

Nội dung đề yêu cầu **Google ARTEMIS**, không phải tự thay bằng Patrol dù tên file
PDF có Patrol. Tối thiểu 10 ca pytest, mỗi ca ít nhất 3 lần; bao phủ các flow Lab 2,
nhánh lỗi/thay thế, các tab chính, detail, export/upload, Remote Config và sign-out.
Cần tương tác Android gốc, một ca đối chiếu Analytics, Semantics cho widget chính,
và phiên khám phá Pro 15–30 phút. Không chỉ assert trạng thái SUCCESS.

Repo hiện có unit/widget/backend tests, nhưng `e2e_test/` mới có README chuẩn bị.
Các kết quả tests cũ không phải bằng chứng ARTEMIS. Máy có Python 3.14.7;
chưa tìm thấy `uv` trên PATH ở lần kiểm tra này. ADB/máy ảo đã dùng được trong phiên.

## 2. Các bước triển khai

### Bước 1 — Chốt môi trường và dữ liệu test

1. Tạo checkout ARTEMIS riêng, pin commit thực tế và ghi vào README.
2. Cài `uv`; dùng Python 3.12 trong môi trường riêng nếu dependencies chưa tương thích
   Python 3.14. Kiểm tra Windows setup theo commit đã chọn, không thay cấu hình IDE
   toàn cục chỉ để chạy suite.
3. Cấu hình model hỗ trợ Flash/Pro và API key bằng biến môi trường cục bộ.
   API key là điều kiện để chạy thật; không yêu cầu gửi key qua chat hay commit vào Git.
4. Chạy daemon cục bộ, kết nối `emulator-5554`, kiểm tra SDK/client và một tác vụ
   chỉ đọc. Chốt cách lấy structured output từ SDK của commit đó trước khi viết suite.
5. Build APK Firebase thật, không bật DEMO_AUTH; ghi commit app, APK hash,
   device/API level, ARTEMIS SHA, model và cấu hình chạy vào manifest.
6. Dùng tài khoản Google test riêng; xác nhận OAuth/SHA debug và account picker
   hoạt động. Email/password không thay bằng chứng Google Sign-In/native picker.

**Dữ liệu:** ưu tiên project Firebase test riêng cấu hình tương đương. Nếu dùng
project nhóm, chỉ thao tác trên UID và event/reward test được chỉ định. Không dùng
tài khoản Evia Demo người dùng đang thao tác. Reset fixture riêng trước mỗi ca/lần,
không reset cả database. Các sự kiện test phải có thời gian tương đối với lúc chạy,
đủ chỗ, mức cọc và thưởng biết trước; không phụ thuộc lịch demo tháng 11 cố định.
Giữ credentials trong `.local/`/biến môi trường. Không dùng nút demo để chứng minh
quy trình check-in thật. Không tự đổi Remote Config toàn project đang dùng.

Đầu ra: môi trường hoạt động, fixture/reset có giới hạn rõ, một smoke task có trace.

### Bước 2 — Chuẩn bị app để AI đọc đúng

- Bổ sung Semantics/tooltip còn thiếu cho tab, bookmark/follow, đăng ký/hủy,
  check-in, Daily, đổi quà, export/upload và refresh. Label nêu trạng thái hiện tại.
- Chốt luồng chuẩn: Discover/Search → Event/Organizer; Registration → Ticket/
  My Events; Rewards → History/Reward/Voucher. Đối chiếu traceability Lab 2.
- Chuẩn bị fixture số dư, lịch daily, policy đăng ký, reward stock, file và trạng thái
  auth cho từng ca. Mong đợi lấy từ fixture hoặc response server, không lấy từ điều
  AI tự đoán và không hard-code số xu tài khoản người dùng.
- Với native interaction, kiểm tra có màn hình Android thật trong trace.

### Bước 3 — Viết ca kiểm thử

Mỗi ca có ID, flow/screens, điều kiện đầu, instruction tự nhiên, output schema,
assertions, reset/cleanup và evidence. Bảng dưới là phạm vi đề xuất cho Evia;
không phải danh sách đã chạy hoặc đã đạt.

| ID | Ca / màn hình | Điều kiện đầu và thao tác chính | Kết quả phải đối chiếu |
|---|---|---|---|
| TC01 | Google login | Signed out, Google test account; mở Login, chọn Google và account | Account picker Android xuất hiện; đúng account test; tới Discover; bottom bar hiện |
| TC02 | Hủy Google login | Signed out; mở Google picker rồi hủy | Không có session; còn Login; không truy cập được dữ liệu cá nhân |
| TC04 | Search rỗng | Tìm từ khóa chắc chắn không tồn tại | Empty state đúng; không còn card kết quả cũ; sửa từ khóa tìm lại được |
| TC05 | Các tab chính | Signed in; lần lượt Discover, Events, Rewards, Profile | Đúng tiêu đề/tab selected; Back không rơi sai luồng; account không đổi |
| TC06 | Các detail | Mở event, organizer và reward fixture | Đúng ID/tên/giá/ngày giờ theo fixture; Back về đúng màn xuất phát |
| TC07 | Save và Follow | Ban đầu chưa saved/followed; lưu event, follow CLB, mở danh sách; bỏ lưu/bỏ follow | Icon/trạng thái cập nhật; đúng item trong Saved/Following; tải lại vẫn đúng |
| TC08 | Đăng ký và giữ cọc | Event còn chỗ, số dư đủ; đi hết form → xác nhận → vé | Chỉ một registration/ticket; available giảm D, held tăng D; mở vé không tự điểm danh |
| TC09 | Đăng ký lỗi | Event fixture hết chỗ; thử đăng ký | Có lỗi phục hồi được; không cấp vé, không giữ/trừ xu |
| TC10 | Hủy đăng ký | Có vé active, cọc D; mở Cancel, xác nhận | Vé bị hủy; held giảm D; hoàn `floor(D × 30%)` theo policy hiện có; lịch sử đúng |
| TC11 | Check-in thật | Vé active, đang trong cửa sổ check-in; có organizer/staff test và QR/code hợp lệ | Attendance được server xác nhận, vé checked-in, hoàn cọc đúng một lần; quét lại không cộng thêm |
| TC12 | Daily Check-in | UID chưa claim ngày server hiện tại; lịch thưởng biết trước | Xu tăng đúng policy; nút đã claim; bấm lại/reload không cộng lần hai |
| TC13 | Đổi quà | Số dư đủ, reward còn stock; xem detail → confirm → My Rewards/voucher | Trừ đúng giá một lần; có receipt; đúng reward và trạng thái voucher; Back về Rewards |
| TC14 | Đổi quà thiếu xu | Số dư thấp hơn giá reward | Thông báo/CTA đúng; không trừ xu, không tạo receipt |
| TC15 | Export và Storage | Có nội dung xuất và account test; tạo file rồi upload | File phản ánh nội dung đang xem, có progress/URL; object ở path thuộc UID test; tải/đọc được file |
| TC16 | Remote Config | Môi trường test, 2 key ảnh hưởng UI đã xác định | Ghi giá trị trước/sau; fetch/refresh thấy thay đổi hành vi tương ứng mà không rebuild |
| TC17 | Push + Android native | Account test, permission được chuẩn bị; gửi message có ID riêng | Xin quyền nếu cần; nhận/lưu đúng message; mở notification shade, bấm tới đúng entity |
| TC18 | Logout và guard | Signed in, đã tải dữ liệu; logout rồi thử Back/protected route | Không còn dữ liệu account cũ; protected route bị chặn; hiển thị signed-out state |
| TC19 | Offline và retry | Signed in; tắt mạng qua Android rồi mở/tải dữ liệu; bật lại và Retry | Lỗi có hướng dẫn, không spinner vô hạn/crash; retry phục hồi dữ liệu |

TC17 có 3 biến thể riêng: foreground, background, terminated. Chạy từng biến thể
3 lần. Tổng đề xuất: **20 ca/biến thể thực thi × 3 = 60 lượt**, chưa gồm smoke và
khám phá. Có thể chia thành nhiều buổi; không chạy đồng thời trên cùng emulator.

### Bước 4 — Chạy và thu bằng chứng

1. Chạy smoke TC04 trước để kiểm tra device, SDK, labels và structured output.
2. Chạy từng nhóm Auth/Search, Events, Rewards, Firebase; sửa case/app khi cần.
3. Chạy mỗi ca/biến thể 3 lần, độc lập và không dựa vào thứ tự. Thay đổi xu/cọc,
   daily và voucher phải reset UID/fixture test trước mỗi lượt.
4. Với mỗi lượt lưu: test/run ID, thời gian, trace/task ID, instruction, output gốc,
   expected/actual, screenshot hoặc replay liên quan, Logcat cần thiết và kết luận.
5. Pass chỉ khi agent hoàn thành **và** các giá trị báo cáo khớp expected. Kiểm tra
   bổ sung backend/console khi UI không đủ chứng minh không trừ xu hai lần hoặc
   upload thành công. Thiếu trường output thì fail/inconclusive, không tự điền.
6. Phân loại app bug, timing, instruction mơ hồ, lỗi model/tool hoặc môi trường.
   Ca không đạt 3/3 ghi flaky/failure và nguyên nhân. Giữ các lượt fail trước fix;
   không thay bằng log pass hoặc cộng lượt chạy lại thành ca mới.
7. Phiên Pro riêng 15–30 phút: điều hướng Back, keyboard, vuốt danh sách, cancel,
   mất mạng/khôi phục, thao tác liên tiếp; ghi issue, bước tái hiện và evidence.
   Không bấm demo attendance, test crash hoặc đổi cấu hình ngoài phạm vi phiên.

## 3. Files dự kiến

```text
e2e_test/
  README.md             # setup, version pin, lệnh và điều kiện chạy
  pyproject.toml        # pytest/async SDK dependency, không thêm Patrol vào Flutter
  uv.lock               # khóa dependency thực tế khi setup
  conftest.py           # client, device, profile, reset fixture, thu evidence
  test_auth.py
  test_discovery.py
  test_events.py
  test_rewards.py
  test_firebase.py
  test_navigation.py
evidence/artemis/<run-id>/
  manifest.json
  results.csv           # test ID, số lượt, pass rate, thời gian trung bình, lý do
  traces/               # trace/output/screenshot hoặc replay của từng lượt
  exploratory.md
```

Cập nhật `docs/test-plan.md`, README và phần E2E trong architecture khi triển khai.
Không thêm API key, email/password hoặc screenshot chứa thông tin riêng vào Git.

## 4. Điều kiện nghiệm thu

- Pin công cụ/SDK theo commit thật; có lệnh setup/chạy tái lập được.
- Có Semantics, ca độc lập, assertions trên dữ liệu và native interaction thật.
- Đủ lượt chạy và evidence theo bảng; có Analytics và khám phá Pro.
- Các lỗi/chặn được ghi trung thực; không coi widget tests hoặc agent SUCCESS
  đơn thuần là E2E pass.
- Google OAuth, model key, fixture reset, FCM sender, Storage và 2 key Remote Config
  phải được xác minh trước ca tương ứng. Thiếu thì ghi blocked, không thay bằng mock.
- TC11 cần thiết bị/phiên organizer và cửa sổ check-in phù hợp; nếu chưa chuẩn bị
  được thì giữ blocked, không dùng nút debug demo để ghi pass.

## 5. Tham chiếu kỹ thuật đã đối chiếu

- https://github.com/google/artemis — Windows startup, Flash/Pro, device tooling.
- https://github.com/google/artemis/blob/main/packages/artemis-client/README.md —
  SDK Python `ArtemisClient`, daemon/client và API submit/wait/run.
- https://github.com/google/artemis/blob/main/pyproject.toml — Python >=3.12.

Link main chỉ là tài liệu tham khảo lúc lập kế hoạch; lúc triển khai phải thay bằng
commit permalink đã chọn. Chưa pin SHA hoặc khẳng định SDK/output schema đã chạy.
