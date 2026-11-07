# Evia Admin

> **Typography Inter — 07/11/2026:** web dùng Inter self-host trong
> `public/fonts/inter/`, kèm SIL OFL 1.1. Bốn mức 400/500/600/700; banner 40px/700,
> tiêu đề trang 28–30px/700, section 20px/600, card 16px/600, sidebar 14px/500
> và active 600, body/button 14px. Màu chữ `#17243B`, `#475569`, `#64748B`,
> accent `#1769F5`. Nguồn [Inter chính thức](https://github.com/rsms/inter/tree/353b61b9f4430d5f420d56605a6e7993e0941470).

> **Admin Login reference — 07/11/2026:** trang đăng nhập dùng bố cục hai cột,
> nền cong xanh/mint, logo EVIA và `3D Calendar and Event Ticket Icon.png` từ assets.
> `src/login.css` giữ style login trong phạm vi riêng. Bổ sung hiện/ẩn mật khẩu,
> spinner và thông báo lỗi mạng; Firebase adapter, session và admin claim guard
> tiếp tục qua các hàm hiện có. Playwright kiểm tra tại 1648×928, 1440×900,
> 1024×768, 390×844 với phản hồi Auth giả lập trong browser; build và 14 tests đạt.

> **Giao diện EVIA — 07/11/2026:** dùng xanh chính `#2457F5`, nền `#F8F9FC`,
> card trắng, viền và bán kính theo tokens mobile. Logo lấy từ asset EVIA hiện có.
> Sidebar, nút, biểu mẫu, bảng và dialog dùng cùng style, hỗ trợ màn hình nhỏ.
> Kiểm tra bố cục cục bộ ở 1440/768/360px và form editor, login; build và 14 tests đạt.

> **Gửi thông báo trực tiếp:** mở Thông báo → chọn tài khoản → nhập nội dung → Gửi thông báo. Không cần tạo sự kiện; cần tài khoản active đã đăng ký thiết bị nhận push. [Cách demo/API](../docs/ADMIN_NOTIFICATIONS.md).

> **Form sự kiện — 06/11/2026:** không nhập ID, nguồn, điều khoản/version hay JSON; dropdown lấy catalog thật. Ảnh JPG/PNG/WebP ≤5 MB tải lên Firebase Storage, cần `VITE_FIREBASE_STORAGE_BUCKET` trong `.env.local`. [Luồng tạo, Rules và validation](../docs/ADMIN_EVENT_EDITOR.md).

> **Analytics Android/Web — 06/11/2026:** bộ chọn nguồn mới cần deploy riêng `getAdminAnalyticsReport`. Android/Web đọc toàn bộ stream của platform tương ứng; nguồn theo cấu hình giữ stream cũ. Tracking sinh viên được bật trong build Flutter bằng `ANALYTICS_ENABLED=true`. [Hướng dẫn](../docs/ANALYTICS_INTEGRATION.md).

Admin web vận hành sự kiện, voucher và các dịch vụ Firebase trong cùng một
giao diện. Xem [phạm vi và API quản trị](../docs/ADMIN_WEB_PLAN.md).

## Chạy web

Dùng Node.js 24.12 trở lên cho admin web. Chạy từ thư mục gốc của repo.

```powershell
npm --prefix admin ci
npm --prefix admin run dev
```

Nếu chưa có `admin/.env.local`, sao chép `admin/.env.example` rồi điền cấu hình
Firebase **Web app** của dự án có Functions Evia tại `asia-southeast1`. Bật
Email/Password và dùng tài khoản có custom claim `admin: true`. Để thu thập
Analytics từ web, điền Measurement ID và bật
`VITE_FIREBASE_ANALYTICS_ENABLED=true`.

## Cấu hình backend live một lần

1. Cấp quyền đọc và xuất bản Remote Config cho service account chạy
   Functions, chẳng hạn `roles/cloudconfig.admin` trên dự án.
   [Firebase Remote Config](https://firebase.google.com/docs/remote-config/automate-rc)
2. Bật Google Analytics Data API. Thêm email service account chạy
   Functions làm **Viewer** của GA4 property. Điền numeric Property ID
   vào `ADMIN_GA4_PROPERTY_ID`. Điền numeric Stream ID vào
   `ADMIN_GA4_STREAM_ID` nếu chỉ muốn báo cáo stream admin. Báo cáo dùng
   toàn property khi bỏ trống Stream ID.
   [GA4 Data API](https://developers.google.com/analytics/devguides/reporting/data/v1/quickstart)

Đặt các biến backend theo [file mẫu](../functions/.env.example) trong
`functions/.env.<project-id>` trước khi deploy. Functions dùng thông tin
xác thực của service account trên Google Cloud. Có thể lấy email chính
xác từ cấu hình của function đã deploy. Sau khi cấu hình xong, deploy các
callable admin vào cùng dự án với Evia. Chạy từ thư mục gốc bằng Node 22.
Đoạn dưới deploy riêng các API mới, mỗi đợt tối đa bốn function.

```powershell
$adminFunctions = @(
    'listAdminEvents', 'getAdminEvent', 'createEvent', 'updateEvent',
    'publishEvent', 'listAdminRewards', 'getAdminReward', 'createReward',
    'updateReward', 'getAdminRemoteConfig', 'publishAdminRemoteConfig',
    'getAdminAnalyticsReport', 'getAdminWalkInQr', 'verifyWalkInQr', 'verifyAdminTicketNumber'
)
for ($i = 0; $i -lt $adminFunctions.Count; $i += 4) {
    $end = [Math]::Min($i + 3, $adminFunctions.Count - 1)
    $selector = ($adminFunctions[$i..$end] | ForEach-Object { "functions:evia:$_" }) -join ','
    npx --yes firebase-tools@15.30.2 deploy --project prm393-31822 --only $selector
    if ($LASTEXITCODE -ne 0) { break }
}
```

## Chạy với Firebase Emulator

Chạy backend và web trong hai terminal. Backend cần Node 22 và Java.

```powershell
npm --prefix functions ci
npm --prefix functions run build
npx --yes firebase-tools@15.30.2 emulators:start --only auth,firestore,functions --project demo-evia-backend
```

```powershell
$env:VITE_FIREBASE_EMULATORS = 'true'
npm --prefix admin run dev
```

Dùng tài khoản Auth Emulator có claim `admin: true`. Có thể kiểm tra sự kiện,
voucher và luồng tạo inbox trong Emulator. Các trang Remote Config, Analytics
và Crashlytics báo cần dự án Firebase thật khi web nối Emulator.

## Khôi phục phiên khi tải lại trang

Web hiển thị loading trong khi Firebase khôi phục phiên và xác minh claim
`admin`. Dashboard chỉ hiện sau khi xác minh thành công. Khi chưa đăng nhập,
thiếu quyền hoặc xác minh thất bại, web hiển thị form cùng thông báo tương ứng.
Kiểm tra trình duyệt bằng auth mô phỏng đã bao phủ startup, F5, admin, đăng xuất,
thiếu quyền, kết quả phiên cũ và lỗi observer. Build và 15 unit tests đã đạt.

## Vận hành và nghiệm thu

- **Sự kiện.** Tạo bản nháp, mở **Chi tiết** để sửa hoặc **Xuất bản**. Với sự
  kiện công khai sắp diễn ra, xác minh thông báo bằng tài khoản đã theo dõi
  ban tổ chức trước khi xuất bản.
- **QR check-in Walk-in.** Mở **Sự kiện → Chi tiết → Tải QR (.png)** ở sự kiện
  Walk-in công khai đã xuất bản. Có thể tải trước giờ check-in để in hoặc chiếu.
  Khi quét bằng Evia, máy chủ dùng khung giờ check-in hiện tại của sự kiện và
  chỉ ghi nhận tham dự, cộng xu một lần cho mỗi tài khoản.
- **Quét vé đăng ký trước.** Mở tab **Check in**, chọn sự kiện đang mở check-in,
  rồi bấm **Bật camera**. Trên Evia, sinh viên mở QR vé và đưa vào khung quét.
  Web dùng camera trên `localhost` hoặc HTTPS. Máy chủ xác nhận vé qua
  `verifyRegisteredTicket`, ghi nhận tham dự, hoàn cọc và cộng xu theo vé.
  Khi vé hết hạn, sinh viên mở lại QR vé trong app.
  Khi không quét được, nhập **Ticket No.** (dạng `EV-…`) ở cạnh camera rồi bấm
  **Xác nhận check-in**. Firebase cần callable `verifyAdminTicketNumber`. Chức
  năng dành cho admin, áp dụng cùng khung giờ và chỉ xác nhận vé của sự kiện đang mở.
- **Voucher.** Tạo mẫu mới, mở **Chi tiết → Sửa** để cập nhật và bật/tắt mẫu.
  Nếu bản ghi thay đổi trong lúc chỉnh sửa, tải lại chi tiết để lấy tồn kho
  hiện tại trước khi lưu.
- **Remote Config.** Chọn một ngày từ **Today (Ngày 1)** đến **Ngày 7**, nhập
  số xu và bấm **Xuất bản và áp dụng**. Mở lại **Rewards → Daily Check-in**
  trên mobile và kiểm tra lịch mới cùng số xu cộng vào ví khi điểm danh.
  Từ ngày 8 trở đi, mức thưởng bằng Ngày 7.
- **Analytics.** Thực hiện thao tác trên admin web, chọn khoảng ngày và
  tải báo cáo khi GA4 đã xử lý dữ liệu. Báo cáo xếp theo lượt ghi nhận.
- **Crashlytics.** Dùng `npm --prefix admin run dev:android-qa -- emulator-5554`
  trên Windows để bật nút **Crash Android QA** trên Web Admin cục bộ. Dùng
  **Open Firebase Crashlytics** để xem lỗi Android trong Console. Xem
  [hướng dẫn kiểm thử Crashlytics](../docs/EVIA_Crashlytics_Implementation.md).
