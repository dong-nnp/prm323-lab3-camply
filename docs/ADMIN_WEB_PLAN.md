# Phạm vi admin web Evia

Admin web dùng Firebase Authentication. Các callable quản trị kiểm tra claim
`admin: true` ở backend. Xem [hướng dẫn chạy và cấu hình](../admin/README.md).

| Mục | Thao tác trong Evia Admin | Backend |
|---|---|---|
| Sự kiện | Xem mọi trạng thái, tạo bản nháp, sửa, xuất bản | `listAdminEvents`, `getAdminEvent`, `createEvent`, `updateEvent`, `publishEvent` |
| Voucher | Xem danh sách và chi tiết phần thưởng, tạo voucher đang tắt, sửa và đổi trạng thái voucher | `listAdminRewards`, `getAdminReward`, `createReward`, `updateReward` |
| Thông báo | Xuất bản sự kiện công khai hoặc cập nhật lịch | `eventNotifications` tạo inbox và `deliverNotification` gửi FCM theo điều kiện hiện có |
| Remote Config | Đọc, xem trước và xuất bản hai giá trị mặc định Event Milestones | `getAdminRemoteConfig`, `publishAdminRemoteConfig` |
| Analytics | Xem 25 sự kiện có lượt ghi nhận cao nhất trong 7 hoặc 30 ngày | `getAdminAnalyticsReport` đọc GA4 Data API |
| Crashlytics | Kiểm thử crash trên Android QA và xem 25 mục lỗi gần nhất trong 7 hoặc 30 ngày | `getAdminCrashlyticsReport` truy vấn BigQuery Crashlytics export |

Sự kiện cần ban tổ chức tồn tại. Khi xuất bản công khai, ban tổ chức phải
được công khai và sự kiện chưa bắt đầu. Hình thức tham dự, phạm vi hiển thị
và ban tổ chức được khóa khi xuất bản. Cập nhật lịch và địa điểm vẫn có thể
kích hoạt thông báo theo quy tắc hiện tại. Để cập nhật bản ghi đã thay đổi
do lượt đăng ký hoặc đổi thưởng, tải lại chi tiết trước khi lưu.

Khi thay nội dung điều khoản, cập nhật phiên bản điều khoản. Tắt mẫu voucher
áp dụng cho lượt đổi mới. Giá, điều khoản và hạn dùng của voucher đã cấp
được đọc từ dữ liệu lưu lúc đổi. Mobile Rewards vẫn cần nối các API catalog
và đổi thưởng hiện có để hiện mẫu thật trong luồng đó.

Backend chỉ cho web xuất bản mặc định của `event_milestones_enabled` và
`event_milestones_intro`. Nếu template đã được cập nhật sau lần tải,
web yêu cầu tải lại. Các nhóm, điều kiện và giá trị theo điều kiện được giữ
trong template. Flutter áp dụng cấu hình khi mở Event Milestones trong chế
độ Firebase live. [Kế hoạch Remote Config](REMOTE_CONFIG_PLAN.md)

Crash QA dùng WebUSB và ADB trên Android debug có serial đã cấu hình.
Web xác minh tiến trình dừng và log fatal đúng package/PID. Báo cáo xuất hiện
sau khi app gửi lỗi và dữ liệu được đồng bộ vào bảng BigQuery đã chọn.
[Hướng dẫn Crashlytics export](https://firebase.google.com/docs/crashlytics/bigquery-export)

Nghiệm thu trên Emulator cho đăng nhập, quyền API, catalog, xuất bản và
inbox. Nghiệm thu trên dự án thật cho FCM, phiên bản Remote Config, GA4 Data
API và Crashlytics BigQuery sau khi cấu hình quyền chạy Functions.
