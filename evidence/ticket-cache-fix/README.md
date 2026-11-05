# Sửa màn đỏ NOT_REGISTERED — 05/11/2026

Ảnh owner báo `AppException(NOT_REGISTERED): No registration for this event.`
Trước sửa, TicketScreen đọc vé bằng `getTicket` thành công nhưng tiếp tục gọi
`ActivityViewModel.event(id)` dựa vào danh sách My Events trong RAM. Khi danh
sách chưa cập nhật hoặc tạm rỗng, lookup ném lỗi trong build dù vé còn trên server.

## Sửa

- Flow1 ticket provider validate/map event từ chính response `getTicket` sang
  RegisteredEvent presentation. TicketScreen dùng presentation này; trạng thái
  cancelled/revoked cũng từ response vé, không suy ra từ cache My Events.
- Loading/error có previous data vẫn dùng trạng thái sẵn có, không lấy null từ
  `asData` rồi render vé cũ hoặc truy cập cache. Event đã bị xóa trả lỗi qua provider.
- Cancel dialog dùng lookup nullable; không còn registration thì dùng
  AppErrorWidget/retry sẵn có. Không tạo registration/vé giả để tránh lỗi.
- Không đổi bố cục, tokens, assets, chính sách xu hoặc quyền backend.

## Kiểm tra hiện tại

- [RED](red.log): tái hiện đúng NOT_REGISTERED khi server có vé nhưng cache rỗng.
- [Regression slice](regression-tests.log): bản sửa ban đầu đạt 5/5; sau đó bổ sung
  các case refresh lỗi có previous data, vé revoked và event bị xóa vào suite.
- [Flutter toàn bộ](flutter-test.log): **195/195 PASS**.
- [Analyze](analyze.log) sạch; [format](format.log), [pub get](pub-get.log) đạt.
- [Same-data render](ui-preservation.json): **14/14**, 7 màn/trạng thái ở
  360/412dp trùng RGBA với baseline giao diện cũ; [log](ui-preservation.log).
- [APK debug live](build-apk.log), FIREBASE_ENABLED=true, DEMO_AUTH=false.
- [Native smoke](native-smoke.json): APK đã cài lên SM-G996N, hash bản cài trùng
  bản build riêng; app khởi động và process mới không có render exception
  NOT_REGISTERED. Đã mở My Events → View Ticket bằng phiên đăng nhập đang có,
  thấy My Ticket và QR thật; không bấm hủy/nhận xu/check-in. Phiên debug của đúng
  workspace đã tạm dừng để tránh cài đè.

Không đổi Functions/Rules/schema hoặc sửa record nghiệp vụ Firebase thủ công;
không chạy lại Emulator backend. Tình huống cache chậm được tái hiện bằng
test-only fake, không giả rằng đã ép được độ trễ đó trên điện thoại thật.
