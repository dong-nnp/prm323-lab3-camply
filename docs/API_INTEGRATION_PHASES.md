# Các giai đoạn gắn API Evia

> **Flow 2 — 05/11/2026:** đã nối hủy/Going, lịch/My Events, check-in QR/mã
> walk-in và inbox vào màn gốc; FCM adapter thật được chọn khi live. Owner cho
> phép thêm nút nhỏ xác nhận đã quét trên vé trong debug để demo, thay màn staff.
> Nút gọi callable riêng, chỉ account/event demo do server bật; không đổi guard
> staff của QR thật. [Phạm vi, kiểm tra và giới hạn](../evidence/flow2-api-only/).
> Flow 3 đã nối ngày 06/11/2026: [contract, demo và giới hạn](FLOW3_INTEGRATION.md).
> Các ghi chú “hủy/check-in/rewards chưa nối” bên dưới là snapshot Flow 1.

> **Sửa phạm vi theo owner 05/11/2026:** chỉ nối API vào các màn hiện có.
> Đã gỡ `Flow1Screen` và route replacement. Không tạo/sắp xếp lại màn, không đổi
> theme/tokens/style/assets. Trường hợp thiếu thiết kế hỏi owner trước khi làm.
> Owner chốt giữ 8 thẻ sở thích (Gaming/Environment chờ đội UI), giữ ảnh minh họa
> khi chưa có URL, tạm chỉ hiện QR trong ô cũ, chưa hiển thị mã dự phòng.
> [Evidence mới](../evidence/flow1-api-only/) thay evidence bộ màn riêng trước đó.

Theo yêu cầu 05/11/2026, triển khai lần lượt từng flow. Firebase backend hiện tại
là `prm393-31822`; Functions ở `asia-southeast1`. Kết quả cloud trước đây không
thay thế kiểm thử app. Không deploy lại backend trong đợt gắn adapter Flow 1.

| Giai đoạn | Phạm vi | Điều kiện bàn giao |
| --- | --- | --- |
| 1 — Khám phá và đăng ký | Auth, onboarding, Discover/Explore/filter, organizer/follow, saved events, đăng ký giữ cọc, vé cá nhân | Dữ liệu callable; onboarding lưu thành công mới đi tiếp; receipt và retry không giữ cọc hai lần; vé đọc lại được |
| 2 — Tham dự | My Events/lịch, hủy hoàn 30% cọc làm tròn xuống, QR/mã walk-in, check-in, inbox + FCM; nút demo vé do owner yêu cầu | Contract và settlement kiểm bằng tests/cloud/native; staff thật và camera quét vật lý báo riêng, không lấy nút demo làm proof |
| 3 — Nhận/đổi xu | Wallet/history, Daily, milestones manual claim, catalog/đổi quà/locker/voucher | Giá/điều kiện server; claim/redemption idempotent; UI ba trạng thái thành tựu |

## Giai đoạn 1 trong source

- `FirebaseAuthenticationService` dùng Firebase Auth/Google Sign-In và gọi
  `initializeUser`. Nhận mọi email đúng định dạng; không coi email là xác minh sinh viên.
- `Flow1Repository` qua `BackendService` → `FirebaseBackendService`; SDK chỉ
  nằm trong `services/`. Models không chứa SDK types. Providers chọn adapter thật
  khi `FIREBASE_ENABLED=true` và demo auth tắt.
- `Flow1ViewModel` tải catalog, profile/ví read-only, follow/bookmark/My Events
  từ server. Interest dùng canonical IDs; tối thiểu ba, không Skip.
- `Flow1RegistrationViewModel` gửi giá/terms version từ event vừa đọc; server
  có quyền quyết định. Sau timeout, giữ nguyên input/request ID, tra receipt trước
  khi gửi lại. Lỗi giá/terms yêu cầu đọc lại và đồng ý lại.
- Router giữ `EviaDiscoverScreen`, `EviaExploreScreen`, `EviaInterestsScreen`,
  `EventDetailsScreen`, `RegistrationFormScreen`, `RegistrationResultScreen`,
  `TicketScreen`, organizer/following/profile/saved/My Events gốc. Chỉ thay bindings,
  data và actions trong các vùng đã có. Loading/error/retry dùng component có sẵn.
- ViewModels hiện có map JSON/domain thành presentation models hiện có; SDK chỉ ở
  service. Đăng ký thông qua controller receipt/retry đã kiểm; không cộng/trừ ví
  lạc quan, không suy ra thành công từ URL. Profile/interest/follow/bookmark chờ server.
- Vé render QR server vào đúng ô SVG cũ 208×208; chưa thêm ô mã dự phòng. Token
  refresh mỗi 60 giây, không tự đánh dấu attendance. Going không giữ vé/cọc.
- My Events và profile/ví chỉ đọc phần cần Flow 1. Hủy/check-in/rewards chưa gắn,
  không mutation xu/attendance giả. Giao diện Flow 2/3 giữ nguyên, chưa nghiệm thu.

Chạy trên Android đã có cấu hình FlutterFire thật:

```powershell
& 'F:\Mobile_Programing\flutter_evia_lab3\bin\flutter.bat' run -d R3CR60CT0WZ --dart-define=FIREBASE_ENABLED=true
```

Không thêm `DEMO_AUTH=true` vào lệnh này. Mặc định `FIREBASE_ENABLED=false`
vẫn chạy source preview không gọi SDK từ Dart. Tài khoản mock trong README không
đăng nhập Firebase; tài khoản vận hành ở private local file dẫn trong
[DEMO_DATA.md](DEMO_DATA.md).

## Validation và giới hạn

Fixtures chỉ ở `test/`; unit/widget tests không cần Firebase credentials. Tests
mới kiểm pagination có trang rỗng/cursor lỗi, filter theo ngày Việt Nam, mutation
chờ server/chặn trùng/retry, đổi tài khoản, FPT validation, timeout receipt, giá
đổi, onboarding không Skip, guest routing, hết vé, vé/QR server và lỗi mạng.
Logs sửa API-only ở [evidence/flow1-api-only](../evidence/flow1-api-only/).

Đối chiếu same-data trước/sau: 34/34 ảnh render của 17 màn/trạng thái ở 360/412dp
trùng RGBA. Đây là so sánh màn gốc trong repo với bản nối API, không phải so sánh
Figma và không yêu cầu dữ liệu live dài/ngắn có kích thước text giống fixture.

Adapter Google đã có trong source; chỉ ghi nhận login Google end-to-end khi có
kết quả tài khoản trường thật trên thiết bị. Email reset chỉ gửi khi người dùng
bấm nút, không thử gửi vào email demo không có mailbox. Catalog demo chưa có ảnh
nên giữ ảnh minh họa cũ theo owner; khi có URL, gắn vào ô ảnh hiện có. Chưa xác nhận live layout khớp từng pixel Figma; chưa hoàn
tất ARTEMIS hoặc cả ba flow.

Request chưa rõ kết quả giữ trong ViewModel khi ở biểu mẫu. Nếu đóng app, mở lại
event/My Events để đọc đăng ký; server từ chối đăng ký trùng còn hiệu lực. Chưa
thêm hàng đợi offline hoặc lưu request xuống máy.
