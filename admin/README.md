# Evia Admin

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
`VITE_FIREBASE_ANALYTICS_ENABLED=true`. Hosting WebUSB cần HTTPS.

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
3. Liên kết Crashlytics với BigQuery. Điền ID đầy đủ của một bảng export
   Android dạng `project.dataset.table` vào `ADMIN_CRASHLYTICS_TABLE`.
   Service account chạy Functions cần `roles/bigquery.jobUser` trên dự án
   chạy truy vấn và `roles/bigquery.dataViewer` trên dataset hoặc bảng.
   Báo cáo truy vấn tối đa 1 GiB mỗi yêu cầu và chọn một bảng batch hoặc
   realtime theo cấu hình.
   [Crashlytics BigQuery export](https://firebase.google.com/docs/crashlytics/bigquery-export)

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
    'getAdminAnalyticsReport', 'getAdminCrashlyticsReport'
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

## Vận hành và nghiệm thu

- **Sự kiện.** Tạo bản nháp, mở **Chi tiết** để sửa hoặc **Xuất bản**. Với sự
  kiện công khai sắp diễn ra, xác minh thông báo bằng tài khoản đã theo dõi
  ban tổ chức trước khi xuất bản.
- **Voucher.** Tạo mẫu mới, mở **Chi tiết → Sửa** để cập nhật và bật/tắt mẫu.
  Nếu bản ghi thay đổi trong lúc chỉnh sửa, tải lại chi tiết để lấy tồn kho
  hiện tại trước khi lưu.
- **Remote Config.** Chọn một ngày từ **Today (Ngày 1)** đến **Ngày 7**, nhập
  số xu và bấm **Xuất bản và áp dụng**. Mở lại **Rewards → Daily Check-in**
  trên mobile và kiểm tra lịch mới cùng số xu cộng vào ví khi điểm danh.
  Từ ngày 8 trở đi, mức thưởng bằng Ngày 7.
- **Analytics.** Thực hiện thao tác trên admin web, chọn khoảng ngày và
  tải báo cáo khi GA4 đã xử lý dữ liệu. Báo cáo xếp theo lượt ghi nhận.
- **Crashlytics.** Đặt `VITE_QA_ANDROID_SERIAL`, cài bản debug Firebase QA,
  mở app, kết nối thiết bị qua USB trong Chrome và bấm **Crash app** một
  lần. Sau khi web xác nhận log fatal, mở lại app để gửi báo cáo. Tải lại
  báo cáo trên web sau khi BigQuery nhận dữ liệu. Kết nối WebUSB phụ thuộc
  driver và việc giao diện ADB có đang bị công cụ khác giữ hay không.

```powershell
$env:ORG_GRADLE_PROJECT_eviaQaCrashlyticsEnabled = 'true'
try {
    flutter build apk --debug --dart-define=FIREBASE_ENABLED=true
} finally {
    Remove-Item Env:ORG_GRADLE_PROJECT_eviaQaCrashlyticsEnabled
}
```
