# Evibaby — tư vấn sự kiện qua DeepSeek

Yêu cầu ngày 09/11/2026: bong bóng chat ở góc dưới phải Discover, phía trên
thanh điều hướng. Evibaby tự xưng linh vật Evia, dùng tiếng Việt dễ thương,
tư vấn theo dữ liệu thật, nhắc phạm vi khi khách hỏi ngoài Evia/sự kiện.
Card nhỏ trong hội thoại mở `/event/about?event=<id>` hiện có.

## Luồng và quyền

`EvibabyChat → EvibabyViewModel → EvibabyRepository → BackendService →
FirebaseBackendService → chatWithEvibaby → DeepSeek`.

- Backend cấp ba tools: `search_events`, `get_event`, `get_app_guide`.
- Hai tools sự kiện chỉ gọi `getPublicCatalog(kind=events)` và `getEvent` với
  actor null; giữ điều kiện published/public hiện có. Không đọc ví, vé, QR,
  attendee, profile hoặc dữ liệu quản trị vào ngữ cảnh AI.
- Bỏ sự kiện đã kết thúc. Search duyệt tối đa 6 trang × 12 bản ghi mỗi lần;
  trả `hasMore/nextCursor` để model đọc tiếp hoặc nói rõ giới hạn. Không xem
  trang rỗng có cursor là toàn bộ catalog không có kết quả.
- Nội dung gửi model giới hạn 1.200 ký tự/chuỗi, 5 phần tử/list (kể cả các
  trường lồng nhau). `contextTruncated=true` yêu cầu model nói rõ chưa có toàn
  bộ chi tiết; card dẫn tới dữ liệu đầy đủ trong app.
- Model chỉ trả JSON `{reply,eventIds,outOfScope}`; tối đa 3 card. Mỗi ID phải
  đã được tra cứu trong lượt này; backend đọc lại record công khai trước khi
  trả card. Card dùng record thật, không dùng ảnh/tên/URL do model sinh.
- Số chỗ và điều kiện có thể đổi sau câu trả lời; màn chi tiết/đăng ký kiểm lại.
  Cọc xu không được diễn giải thành giá tiền; thiếu phí vé thì báo chưa có dữ liệu.
- Guide nằm tại `functions/src/evibaby.ts`, tổng hợp từ code đăng ký/hủy,
  accounts/rewards/maintenance. Cập nhật guide khi các luồng/chính sách này đổi.
  Daily không hard-code phần thưởng theo cấu hình; chỉ hướng tới màn Rewards.
- System prompt quy định nhân vật, phạm vi và xem mô tả/lịch sử là dữ liệu
  không đáng tin. Quyền đọc được giới hạn bằng code, không dựa vào prompt.
  Phát hiện nội dung ngoài phạm vi vẫn phụ thuộc model, cần kiểm thử API thật.

## Cấu hình

Base URL được người dùng cung cấp: `https://api.deepseek.com`. Tên gọi sản phẩm
`DeepSeek-V4.1-Flash-1017` dùng API ID `deepseek-flash` theo
[changelog chính thức](https://api-docs.deepseek.com/updates/).
Đã xác nhận API ID này bằng key thật ngày 09/11/2026. Alias có thể được nhà cung cấp
nâng cấp về sau.

1. Thêm `EVIBABY_BASE_URL=https://api.deepseek.com` và
   `EVIBABY_MODEL=deepseek-flash` vào `functions/.env` (Git ignore). Xem
   `functions/.env.example`; giữ các biến admin reporting khác nếu có.
2. Emulator: tạo `functions/.secret.local` với `EVIBABY_API_KEY=<key thật>`.
   File này đã bị Git ignore, không nhúng key vào Flutter hoặc Remote Config.
3. Cloud: từ root, dùng `firebase functions:secrets:set EVIBABY_API_KEY
   --project prm393-31822`, nhập key qua prompt; triển khai riêng
   `firebase deploy --only functions:evia:chatWithEvibaby --project prm393-31822`.
   Không triển khai toàn bộ Functions chỉ để bật chat.
4. App dùng Firebase thật (`FIREBASE_ENABLED=true`, không `DEMO_AUTH`).
   Người dùng đăng nhập bằng tài khoản active. Bản chưa có Firebase hoặc endpoint
   chưa triển khai hiển thị lỗi có thể thử lại, không giả câu trả lời AI.

Secret local chỉ dùng cho Emulator; không tự chuyển thành secret cloud.
Đã cấu hình key thật trong Secret Manager, xác nhận API model và triển khai riêng
callable vào project nhóm. Không đưa key vào Flutter hoặc source bundle.
App Check tuân theo `ENFORCE_APP_CHECK` của backend hiện có; chưa thay chế độ này.
HTTPS transport của callable có IAM public như các callable khác; handler vẫn
bắt buộc Firebase Auth và tài khoản active trước khi giữ quota/gọi DeepSeek.
Smoke chưa đăng nhập phải trả JSON HTTP 401 `UNAUTHENTICATED`, không phải HTML 403.
`firebase.json` loại `.env*` và `*.local` khỏi gói source; các biến non-secret vẫn
được CLI nạp vào runtime trước khi đóng gói. Git ignore và deploy ignore là hai lớp riêng.

## Giới hạn, dữ liệu và lỗi

- 5 lượt/phút, 60 lượt/ngày/tài khoản; toàn project 500 lượt/ngày theo ngày
  Việt Nam, giữ bằng Firestore transaction server-only tại `evibaby_usage`.
  Request đã giữ quota vẫn tính nếu nhà cung cấp lỗi; không liên quan ví xu.
- Mỗi lượt tối đa 4 model requests, 6 tool calls, 1.000 output tokens/request,
  timeout model tổng 45 giây; callable 60 giây, client 65 giây.
- Chỉ gửi câu hỏi, tối đa 10 tin nhắn gần nhất và dữ liệu công khai cần tư vấn
  tới DeepSeek. Chat UI thông báo việc gửi nội dung tới dịch vụ AI. Server Evia
  không lưu transcript hoặc log prompt/output; chính sách lưu của nhà cung cấp
  không do app kiểm soát. Usage chỉ chứa bộ đếm và mốc thời gian.
- Lịch sử/draft giữ trong RAM khi đóng/mở sheet; xóa khi đổi tài khoản hoặc
  kết thúc phiên ứng dụng. Không cập nhật state từ request của tài khoản cũ.
- Chặn gửi trùng khi chờ; lỗi giữ draft cho retry. Không cấu hình, hết quota,
  mất mạng, JSON sai, ID bịa và sự kiện bị gỡ đều không tạo card thành công giả.
- Không thêm dependency, đăng ký/hủy/đổi thưởng tự động, vector database,
  Analytics events, quyền database hoặc thay đổi chính sách nghiệp vụ.

## Kiểm thử

- `functions/test/evibaby.test.mjs`: provider giả, validation, allowlist tools,
  phân trang, ID bịa, off-topic, JSON/lỗi provider, tool budget và quota.
- `functions/test/evibaby_backend.test.mjs`: Firestore Emulator thật, loại bỏ
  private/draft/past, đọc lại card và transaction quota đồng thời, giữ nguyên ví.
- `test/evibaby_test.dart`: fake BackendService, state/context, retry, dispose,
  đổi account, 360/412dp, text scale 2, keyboard inset, đóng/mở và card navigation.

Những tests dùng fake provider không chứng minh model thật giữ đúng phạm vi,
giọng điệu hoặc thực hiện tool calling. Cần key thật để kiểm ít nhất: gợi ý
sự kiện + hỏi tiếp, hướng dẫn hủy, câu hỏi ngoài phạm vi và thử đổi vai trò.
Kết quả lệnh/build/runtime thực tế được ghi khi bàn giao, không suy từ checklist.

## Validation thực tế 09/11/2026

- `flutter pub get`, `dart format lib test`, `flutter analyze --no-pub` và
  `git diff --check`: đã đạt.
- `test/evibaby_test.dart`: 7/7 đạt, gồm 360/412dp với chữ 2x và keyboard inset.
- Toàn bộ Flutter suite: **251 đạt, 4 lỗi**. Chạy lại đúng 4 ca khi bỏ import và
  launcher Evibaby khỏi Discover vẫn lỗi: Discover 360dp/chữ 2x overflow;
  Flow 1/3 network-error retry; `/registration/loading`. Đã khôi phục launcher
  sau đối chiếu; không sửa các lỗi ngoài phạm vi này.
- Toàn bộ backend suite trên Auth/Firestore/Functions/Storage Emulator:
  **100/100 đạt** (Node 24 trên host, Java 21). Sau bổ sung budget/context tests,
  riêng backend unit Evibaby **11/11 đạt trên Node 22.23.4**; 2 tests tích hợp
  Firestore thật đã đạt trong lần chạy toàn suite.
- `npm audit --omit=dev --audit-level=high`: không có high/critical, còn 6
  moderate ở dependencies gián tiếp có sẵn; không nâng dependencies trong task.
- DeepSeek thật dùng public catalog Firebase thật: **5/5 ca đạt** — gợi ý có
  card, hỏi tiếp, chính sách hủy/hoàn 30%, ngoài phạm vi, yêu cầu đổi vai trò.
  Lần đầu thấy model đọc UTC thành giờ Việt Nam; đã thêm `localTimes` định dạng
  ở server và chạy lại đủ 5 ca, kiểm giờ phản hồi đúng với timestamp sự kiện.
- `flutter build apk --debug --target-platform android-arm64 --build-number 2003
  --dart-define=FIREBASE_ENABLED=true`: đạt; đã cài cập nhật trên Samsung.
- Trên Samsung: mở bubble, nhập với bàn phím, gọi callable thật nhận 2 card,
  bấm card mở đúng `[DEMO] Đêm nhạc sinh viên Evia`, quay lại và mở chat vẫn giữ
  2 card. Không thực hiện đăng ký/hủy/đổi thưởng khi kiểm tra.
- Callable `chatWithEvibaby` ACTIVE, clean revision `chatwithevibaby-00002-vaw`;
  HTTP smoke không đăng nhập trả 401 qua auth guard. Chưa chạy ARTEMIS cho chat.
- Lượt đóng gói đầu có file local trong source riêng tư của project; đã thay
  bằng bundle loại các file đó, xóa đúng hai source object generations và image
  version của lượt đầu, giữ revision hiện tại. Người dùng chọn tiếp tục dùng key
  hiện có. Không ghi key trong repo, chat hoặc tài liệu.

Có thể tắt tư vấn bằng cách để trống `EVIBABY_MODEL` và deploy lại riêng callable;
handler báo chưa cấu hình trước khi trừ quota hoặc gọi model. Không cần thay dữ liệu
sự kiện, ví, vé hoặc Firebase Rules để rollback tính năng này.

Nguồn API: [DeepSeek tool calls](https://api-docs.deepseek.com/guides/tool_calls/),
[JSON output](https://api-docs.deepseek.com/guides/json_mode/),
[Firebase secrets](https://firebase.google.com/docs/functions/config-env#secret_parameters).
