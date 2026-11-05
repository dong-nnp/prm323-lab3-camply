# Sửa Flow 1 theo phạm vi API-only — 05/11/2026

Owner yêu cầu giữ giao diện của đội UI. Đã xóa `Flow1Screen`, bỏ route replacement,
dùng lại Discover/Explore/Interests/Event Details/Organizer/Registration/Result/
Ticket/Profile/Saved/My Events hiện có. Không đổi theme/tokens/assets, không thêm
layout hoặc màn business khác. Loading/error/retry dùng components có sẵn.

Bindings đi View → ViewModel hiện có → Repository → BackendService → Firebase SDK.
Controller receipt/retry dùng lại dưới RegistrationViewModel để tránh double hold.
Số xu, canonical IDs, giá/terms, profile, follow/bookmark và vé lấy từ server.
Result thành công phải đọc được vé; URL `/success` tự nó không chứng minh đăng ký.

## Quyết định owner

- Giữ đúng 8 thẻ sở thích cùng label/icon hiện có. Map sang ID server; không xóa
  sở thích Gaming/Environment đã có trên profile khi lưu. Đội UI bổ sung 2 thẻ sau.
- Khi chưa có URL, giữ ảnh minh họa cũ. Khi có URL, dùng đúng ô ảnh hiện có.
- Chỉ render QR do server cấp trong ô vé cũ 208×208; chưa hiện mã dự phòng.
- Thiếu trường/thiết kế ở bước sau phải hỏi owner, không tự tạo màn thay thế.

## Kết quả thực tế

- [pub get](pub-get.log), [format](format.log), [analyze](analyze.log): đạt;
  analyze không issues. [Flutter suite](flutter-test.log): **172/172 PASS**.
- [Live screen tests](live-screen-tests.log): 11 tests trên các class màn gốc,
  canonical data/interest IDs, guest redirect, server save, receipt/retry,
  full event, success guard, filter, QR slot và lỗi mạng. Fixtures chỉ trong tests.
- [Render comparison](ui-preservation.json), [log](ui-preservation.log): **34/34**
  ảnh render bằng nhau từng byte RGBA, 17 màn/trạng thái × 360/412dp.
- [APK debug](build-apk.log): build thành công, cài và khởi động SM-G996N.
  Các plugin hiện có cảnh báo KGP cho Flutter tương lai; không phải lỗi build.
- Native qua ADB: login email/password, Discover gốc, search Flutter trả 2 kết
  quả catalog, My Events gốc, vé `EV-1A98EDBA0E05` và QR thật trong ô cũ.
  Đã gặp lỗi mạng lúc điện thoại chưa nối Wi-Fi; sau owner kết nối lại đã đọc được
  dữ liệu. Không biến lỗi mạng thành dữ liệu/thành công giả.
- [Trước](before-native.json)/[sau](after-native.json): independent callable reads
  bằng account demo staff. Wallet **150 available/50 held**, version 2, một
  registration và một deposit_hold giữ nguyên. Không tạo thêm đăng ký, attendance,
  reward hoặc thay backend/cloud config trong lần sửa API-only. Đọc vé có tạo
  short-lived QR token/code theo backend; không ghi token/code vào evidence.

## Cách đối chiếu giao diện và giới hạn

Baseline lấy từ các màn gốc trong working tree ở đầu lượt sửa, trước khi nối API
vào chúng; không lấy `Flow1Screen` làm baseline và không reset về Git HEAD có thể
làm mất code đội UI. Bản sao ở ignored `.local/api-only-before-repair/` và probe
ở `.local/ui-preservation/`; bản baseline để compile nằm ngoài repo trong Temp.
Chỉ điều chỉnh callback baseline `updateProfile` sang await để khớp kiểu async mới,
không đổi render code. Hai lần render dùng cùng fixtures/session/theme, chờ asset
decode hoàn tất, capture toàn viewport 884dp. Kết quả lưu trong JSON nêu trên.

Đây là bằng chứng giữ giao diện **khi cùng dữ liệu**, không phải kiểm pixel Figma.
Dữ liệu server khác title/date/price/count nên text dài/ngắn và số card có thể khác.
Chưa chạy Google login, signup tài khoản mới, email reset, staff scan hoặc ARTEMIS
trên native. Registration receipt/loading/result kiểm ở widget tests; native lần
sửa này mở lại vé sẵn có, không nhận đã đăng ký thêm qua các màn sửa.
Flow 2/3 chưa nối; màn gốc của chúng giữ nguyên, không coi dữ liệu preview là API.
