# Review UI/UX Rewards — 04/11/2026

> Update 05/11/2026: current UI retains mock data for preview. Local coin changes,
> receipt generation and streak persistence are removed. Check-in, redemption and
> deposits wait for API. Transaction test evidence below describes the earlier
> demo implementation, not the current financial behavior.


Phạm vi review ban đầu: 9 route Rewards, source, ảnh render widget và hành vi
presentation trong demo. Findings bên dưới ghi nhận trạng thái trước khi sửa.
Sau yêu cầu sửa lỗi, runtime đã được cập nhật như phần xác minh sau đây;
không tích hợp backend, QR sử dụng thật hoặc thanh toán.

## Xác minh bản sửa — 05/11/2026

| Finding | Kết quả implementation và kiểm tra |
|---|---|
| R01 | Lưu danh sách receipt trong ViewModel; locker có count/empty state; mở đúng mã, không fallback khi mã sai. Tests đổi tote xuyên suốt và chọn tote sau khi lưu cả café+tote đã đạt. |
| R02 | Dùng một giá 250 xu cho café. Test số dư 249 chưa được đổi, check-in tăng số dư rồi đổi trừ đúng 250; đã đổi thì status giữ Already redeemed kể cả đủ tiền lại. |
| R03 | Bản sửa đầu mở đúng `/profile`. Theo tinh chỉnh UI tiếp theo, bỏ avatar header trùng chức năng; test xác nhận tab Profile ở bottom bar vẫn mở ProfileScreen. |
| R04 | Nội dung thuộc từng reward. Tote/hoodie/movie pass không dùng thông tin café; phần fulfillment chưa được xác nhận ghi chưa cấu hình. |
| R05 | Milestone/current/next/remaining tính từ verified events. Test từ 3 → 4 sự kiện xác nhận còn 1 event ở cả header và milestone; dùng Reached thay vì tuyên bố đã claim thưởng. |
| R06 | InkWell tab minHeight 48dp; test đo vùng bấm của cả hai tab đạt. |
| R07 | CoinEntry lưu ngày; ViewModel nhóm/sort lịch sử theo tháng. Test check-in Nov 10 xác nhận xuất hiện nhóm Nov 2026 và Oct 2026. |
| R08 | Cùng header/action/icon bottom bar và màu selected tab; test chuyển tab xác nhận khung ví giữ nguyên rect. |
| R09 | Thêm AppSpacing giữa icon Copy và text; đã xem ảnh render voucher sau sửa. |

Validation sau sửa: `flutter pub get`, `dart format lib test`, `flutter analyze`
đạt. `flutter test --concurrency=1`: **90 đạt / 5 lỗi**, đúng 5 tests trong
`evia_screens_test.dart` đã lỗi trước lượt sửa (overflow/ListTile ngoài Rewards).
Toàn bộ tests Rewards mới đều đạt, gồm café/tote đã lưu ở 360/412dp, chữ 1x/2x.
Capture lại 9 route Rewards: **18 tests đạt** (9 responsive + 9 capture), đã xem
đủ 9 PNG. Capture success/locker/voucher thực hiện redeem café trong test-only
state trước khi chụp; không dùng receipt giả để làm runtime thành công.

Ảnh sau sửa ở `build/rewards-ui-review-fixed/`; ảnh và probe ban đầu
trong `build/rewards-ui-review` là evidence trước sửa, không dùng để chứng minh
bản sửa đạt. Cả hai thư mục đều là build output, có thể mất khi clean.

APK/native smoke sau sửa: `flutter build apk --debug --target-platform android-x64
--no-pub` thành công; ADB `install --no-streaming -r -t` trả `Success`. Mở app trên
`emulator-5554`, đi qua Skip → Rewards → Redeem Rewards → tote → Confirm Redemption:
success hiển thị đúng tote, trừ 400, còn 20 xu, giữ 100 xu deposits. View My Rewards
hiển thị tote, View Reward mở ảnh tote và mã `DEMO-TOTE-001`, không hiện QR café.
Đã chụp/xem ảnh catalog, success, locker và reward trên máy ảo; app vẫn chạy sau
luồng này. Không coi smoke một luồng là native sign-off toàn bộ 9 màn hình.

Sau chỉnh câu chữ QR, kiểm tra voucher responsive + flow + capture: **3 tests đạt**;
đã xem lại ảnh voucher. Bản APK cuối được build lại và cài sau chỉnh câu chữ này.

## Findings

### R01 — P1: Đổi tote nhưng My Rewards vẫn chỉ hiển thị voucher café

- Vị trí: [reward_voucher_screen.dart](../lib/screens/evia/reward_voucher_screen.dart),
  `RewardsLockerScreen` và `RewardVoucherScreen`.
- Tái hiện: số dư 420 → đổi tote 400 → success hiển thị tote → View My Rewards.
- Locker luôn có `Available (1)`, ảnh/tên café; voucher luôn dùng mã và QR mẫu café.
  Probe xác nhận `redeem('tote')` thành công nhưng locker không có tên tote.
- Ảnh hưởng: mất dấu phần thưởng vừa đổi, hiển thị sai phần thưởng sau giao dịch.
- Đề xuất: locker và voucher đọc danh sách receipt từ ViewModel; điều hướng bằng
  ID của phần thưởng/receipt, cập nhật count, có empty state.

### R02 — P1: Giá café thay đổi từ 200 thành 250 xu giữa các bước

- Vị trí: [activity_mock_data.dart](../lib/data/mock/activity_mock_data.dart),
  `catalogCost: 200`, `redeemCost: 250`; `_RewardCard` dùng catalogCost,
  details/confirm và ViewModel dùng redeemCost.
- Tái hiện: đọc giá café trong catalog → mở details/confirm → giá tăng 50 xu.
  Probe so sánh hai giá thất bại: actual 200, expected 250.
- Với số dư 200–249, nhãn Eligible cũng có thể bật dù không đủ tiền đổi thực tế.
  Catalog chỉ xét số dư, không xét `redeemed`, nên nhãn còn có thể sai sau đổi thưởng.
- Đây là mâu thuẫn thiết kế Figma đã được ghi trong design traceability, không phải
  thay đổi mới. Cần chốt giá trước khi thống nhất; không tự chọn 200 hay 250.
- Đề xuất: dùng cùng giá và cùng presentation state cho catalog/details/confirm.

### R03 — P2: Nút Profile trong catalog mở màn hình đăng nhập

- Vị trí: [rewards_screen.dart](../lib/screens/evia/rewards_screen.dart),
  IconButton tooltip `Profile`, `context.push('/')`.
- Probe bấm nút xác nhận route thực tế `/`, trong khi route profile là `/profile`.
- Ảnh hưởng: hành vi khác nút Profile trên bottom bar, làm gián đoạn việc đổi thưởng.
- Đề xuất: thống nhất đích điều hướng với bottom bar và chính sách demo hiện tại.

### R04 — P2: Nội dung chi tiết dùng cho café cả khi chọn merchandise

- Vị trí: [reward_details_screen.dart](../lib/screens/evia/reward_details_screen.dart),
  Reward Information, Terms & Conditions và How to Redeem.
- Probe mở `/rewards/detail?id=tote` vẫn thấy `Participating campus cafés`.
  Các bước sử dụng cũng yêu cầu đưa voucher cho cashier ở café.
- Ảnh hưởng: người đổi túi/hoodie không biết nhận hàng ở đâu; hướng dẫn sai ngữ cảnh.
- Đề xuất: dữ liệu hướng dẫn/địa điểm/điều khoản theo từng phần thưởng; nội dung chưa
  được xác nhận cần thể hiện rõ, không tự suy đoán địa điểm nhận hàng.

### R05 — P2: Milestone có tiến độ và mô tả mâu thuẫn sau check-in

- Vị trí: [milestones_screen.dart](../lib/screens/evia/milestones_screen.dart),
  `_MilestoneRow`, `milestone.description`; mô tả fixture cố định trong mock data.
- Tái hiện bằng probe: check-in demo làm verified events từ 3 → 4; header hiển thị
  4 events/còn 1 event, nhưng Active Student vẫn ghi `Attend 2 more events`.
- Claim/next goal/count unlocked cũng được gán cố định theo index thay vì tiến độ.
  Không suy diễn đã tái hiện tới 5 events: flow demo hiện chỉ thêm được một event.
- Đề xuất: ViewModel tính milestone presentation từ verified events và trạng thái
  nhận thưởng; UI chỉ render state này.

### R06 — P2: Vùng bấm tab Rewards thấp hơn yêu cầu accessibility

- Vị trí: [activity_widgets.dart](../lib/widgets/activity_widgets.dart), `ActivityTabs`.
- Probe ở viewport 390dp, text scale 1x đo InkWell của Earn Coins:
  **175 × 42dp**, thấp hơn yêu cầu repository **48 × 48dp**.
- Đề xuất: đặt minHeight 48dp cho phần tương tác; vẫn cho phép giãn theo cỡ chữ lớn.

### R07 — P2: Coin History nhóm giao dịch tháng 11 dưới tiêu đề tháng 10

- Vị trí: [coin_history_screen.dart](../lib/screens/evia/coin_history_screen.dart),
  nhãn cố định `Oct 2026` và `OCTOBER 2026 · RECENT`.
- Bằng chứng source: `ActivityViewModel.checkIn` thêm giao dịch `Event check-in · Nov 10`
  vào cùng danh sách, trong khi header không đọc thời gian của giao dịch.
- Ảnh hưởng: nhãn thời gian không khớp giao dịch sau thao tác trong demo.
- Đề xuất: model lưu ngày giao dịch; ViewModel nhóm và cung cấp nhãn thời gian đúng.
  Finding này từ source, không có probe riêng hay kiểm tra lịch sử production.

### R08 — P3: Header/tab/bottom bar đổi phong cách giữa Earn và Redeem

- Vị trí: [rewards_screen.dart](../lib/screens/evia/rewards_screen.dart), header,
  `activeColor`/`activeForeground`, asset set của ActivityBottomBar.
- Hai ảnh render xác nhận Earn dùng selected tab trắng/chữ xanh, Redeem dùng nền xanh/
  chữ trắng; icon Rewards/Profile đổi hình; Profile trên header chỉ có ở catalog.
  Header catalog cao hơn và đẩy khung ví xuống khi chuyển tab.
- Khung ví hiện đã cùng widget và cùng thiết kế; vấn đề còn lại ở shell xung quanh.
- Đề xuất: cùng một shell và quy tắc selected state cho hai tab; giữ kích thước header
  nhất quán nếu cần hiện/ẩn action. Đây là đề xuất nhất quán UX, không phải lỗi overflow.

### R09 — P3: Icon Copy dính sát chữ trên My Voucher

- Vị trí: [reward_voucher_screen.dart](../lib/screens/evia/reward_voucher_screen.dart),
  TextButton chứa ActivityIcon và Text('Copy') không có spacing ở giữa.
- Ảnh render `15.png` xác nhận glyph Copy và chữ bị dính, giảm khả năng đọc.
- Đề xuất: thêm khoảng cách theo AppSpacing; giữ nguyên vùng bấm tối thiểu.

## Validation thực tế

- `flutter test test/widgets/activity_screens_test.dart --concurrency=1 --name rewards`
  với capture bật: **18 đạt** = 9 responsive tests + 9 captures.
- Responsive tests kiểm tra mỗi route ở 360/412dp, text scale 1x/2x;
  không có exception layout trong những trạng thái mặc định đã kiểm tra.
- Đã mở và xem cả 9 PNG ở viewport 390dp, chiều cao reference từng màn hình.
- `flutter test test/widgets/activity_screens_test.dart test/viewmodels/activity_view_model_test.dart --concurrency=1`:
  **26 đạt**, gồm flow đổi café → success → locker → voucher, tìm kiếm và check-in.
- Sáu probe bổ sung kiểm tra kỳ vọng UX của R01–R06: **6 thất bại**, xác nhận
  từng finding. Các probe chỉ dùng khi review, đã được chuyển ra khỏi test suite;
  không sửa production code để làm chúng pass.
- `git diff --check`: đạt trước khi lập báo cáo; kiểm tra lại khi bàn giao.
- Không chạy lại toàn bộ suite hoặc build APK vì lượt này chỉ review và ghi tài liệu.
  Không coi kết quả scoped tests là toàn bộ ứng dụng không còn lỗi.

## Evidence cục bộ và coverage

Ảnh/asset metadata và bản probe dùng để tái hiện được lưu tại
`build/rewards-ui-review/` (build output, không commit; có thể mất khi clean).
Probe source: `review_probes.dart.txt`; để chạy lại, copy vào `test/` với đuôi `.dart`.
Các capture là widget render, không phải screenshot native Android của cả 9 route.

| Route | PNG | Đánh giá chính |
|---|---|---|
| `/rewards` | `11.png` | R06, R08; không overflow ở 4 cấu hình responsive |
| `/rewards/catalog` | `10.png` | R02, R03, R08; tìm kiếm hiện có đạt |
| `/rewards/locker` | `9.png` | R01; nội dung/count cố định |
| `/rewards/detail` | `14.png` | R02, R04; probe bổ sung `?id=tote` |
| `/rewards/confirm` | `13.png` | R02; café tính số dư 420 − 250 = 170 đúng |
| `/rewards/success` | `12.png` | R01 ở bước đi tiếp; receipt có tên/cost/balance |
| `/rewards/voucher` | `15.png` | R01, R09; Copy action có code, QR là mẫu demo |
| `/rewards/milestones` | `16.png` | R05; kiểm tra thêm trạng thái sau check-in |
| `/rewards/history` | `17.png` | R07; filters có trong ViewModel tests |

Không xem phần card nằm dưới màn hình đầu hoặc pill category cuối chỉ hiện một phần
là lỗi: các vùng tương ứng hỗ trợ scroll. Chưa đo contrast, screen reader hoặc hiệu
năng Android; không có kết luận pass cho các hạng mục đó.
