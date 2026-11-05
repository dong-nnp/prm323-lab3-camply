# Luồng 3 — nhận và đổi Evia Coin

Ngày 06/11/2026. Firebase thật: `prm393-31822`, region `asia-southeast1`.
Chỉ nối API vào các màn Rewards hiện có. Không thêm màn hoặc đổi theme/assets.
Các ghi chú preview/chưa nối Flow 3 trong tài liệu cũ là lịch sử.

## Các màn đã nối

| Màn hiện có | Dữ liệu và thao tác thật |
|---|---|
| Rewards / Earn Coins | Ví, Daily theo ngày Việt Nam; nút nhận chờ server, khóa khi xử lý |
| Event Milestones | Danh sách/tiến độ/version từ server; Chưa đạt / Có thể nhận / Đã nhận; nhận thủ công |
| Redeem Rewards | Catalog, tìm kiếm/lọc, giá, tồn kho và trạng thái từ record |
| Reward Details / Confirm | Điều kiện/giá/version từ server; chờ giao dịch thành công mới chuyển màn |
| Redemption Success | Receipt thật của lần đổi vừa thành công; không suy thành công từ URL |
| My Rewards | Đọc lại các lần đổi đã lưu; Available / Used & Expired |
| Voucher Details | QR/mã thật chỉ được lấy khi có quyền, chưa dùng và chưa hết hạn |
| Coin History | Ledger thật, dấu tăng/giảm, số xu giữ cọc và bộ lọc cũ |

Daily dùng lịch **5/10/15/30/50/70/100**, ngày 8 trở đi 100; bỏ một ngày thì
reset theo server. Monthly Gift tự cấp bởi job có sẵn, không thêm nút nhận.
Thành tựu lấy definition từ Firestore, không hard-code tên/mốc/phần thưởng trong
đường dữ liệu live. Admin có thể thêm/sửa definition qua cơ chế backend có sẵn;
Remote Config không có quyền quyết định giao dịch xu.

Quà vật lý giữ thông tin nhận quà và mã redemption, không tạo QR voucher giả.
Ảnh catalog dùng URL nếu có; thiếu URL giữ ảnh minh họa đã được owner đồng ý.
Thông tin quà demo trên server ghi rõ nhà tài trợ/địa điểm giả lập.

## Call chain và contract

`View → ActivityViewModel/Flow3ViewModel → Flow1Repository → BackendService →
FirebaseBackendService`. Dùng lại repository/service hiện có, không thêm SDK
trong View/ViewModel hoặc dependency mới. `RewardsBackendGate` dùng loading,
error và retry widgets hiện có. Khi Firebase tắt vẫn giữ source preview.

| API | Cách dùng |
|---|---|
| `getAccount` | Profile/wallet và `daily` mới, tương thích các caller cũ |
| `getEventMilestones` | Definition ID/version, tiến độ hợp lệ, trạng thái nhận |
| `getPublicCatalog(kind: rewards)` | Catalog có phân trang |
| `listOwned` | Đọc hết trang redemptions, vouchers và ledger của tài khoản |
| `claimDailyCheckin` | Một lần/ngày theo server |
| `claimEventMilestone` | `milestoneId`, `expectedVersion`; một lần/mốc |
| `redeemReward` | `rewardId`, `requestId`, `expectedPriceCoins`, `expectedTermsVersion` |
| `getOperationStatus` | Khôi phục receipt trước khi gửi lại lần đổi chưa rõ kết quả |
| `getVoucherCode` | Mã/QR do server cấp, không truyền secret vào route |

`getAccount.daily` gồm `dayKey`, `streakDay`, `coins`, `alreadyClaimed`,
`serverTime` (ISO UTC), `timezone: Asia/Ho_Chi_Minh`. Đây là trạng thái cho lần
nhận hôm nay; không ghi xu khi chỉ mở màn. `getAccount` là Function duy nhất cần
deploy cập nhật trong task này; các API khác đã có trên project.

Không cộng/trừ xu lạc quan. Khi giá/terms/tồn kho hoặc milestone thay đổi, đọc
lại dữ liệu và yêu cầu thao tác xác nhận lại. Ví và điều kiện đổi quà đọc cùng
snapshot Rewards mới nhất. Sau thao tác thành công cũng tải lại ví Flow 1.
Đổi tài khoản bỏ state/request của tài khoản trước. Resume/mở lại màn tải dữ
liệu; Daily có timer qua ngày Việt Nam. Màn mã voucher tải lại tối đa mỗi 30
giây hoặc tại hạn dùng, server vẫn quyết định quyền sử dụng cuối cùng.

## Giới hạn và cách demo

Mở **Rewards → Check In / View all milestones / Redeem Rewards**. Đổi quà xong
mở **My Rewards → voucher**, rồi xem **Coin History**. Daily/milestone chỉ nhận
một lần theo quy tắc thật, không reset để demo trên tài khoản cá nhân.
Admin xác nhận dùng voucher bằng công cụ vận hành/API `verifyVoucher` có sẵn;
app sinh viên chưa có màn admin và không được nhúng tài khoản admin.

Request đổi quà chưa rõ kết quả được giữ trong ViewModel của phiên hiện tại.
Sau khi đóng hẳn app, vào My Rewards và Coin History kiểm tra giao dịch trước
khi bấm đổi tiếp: request pending chưa được lưu xuống máy. Các receipt đã ghi
thì được đọc lại từ Firebase sau restart.

Không kiểm chứng chờ job Monthly Gift chạy tự nhiên trong task này; không coi
nút demo attendance là bằng chứng staff quét thật. ARTEMIS và review bên ngoài
không nằm trong lần triển khai này. Xem [evidence](../evidence/flow3-api-only/).
