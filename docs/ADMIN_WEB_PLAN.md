# Phạm vi admin web Evia

Admin web dùng Firebase Authentication. Các callable quản trị kiểm tra claim
`admin: true` ở backend. Xem [hướng dẫn chạy và cấu hình](../admin/README.md).

| Mục | Thao tác trong Evia Admin | Backend |
|---|---|---|
| Sự kiện | Xem mọi trạng thái, tạo bản nháp, sửa, xuất bản | `listAdminEvents`, `getAdminEvent`, `createEvent`, `updateEvent`, `publishEvent` |
| Voucher | Xem danh sách và chi tiết phần thưởng, tạo voucher đang tắt, sửa và đổi trạng thái voucher | `listAdminRewards`, `getAdminReward`, `createReward`, `updateReward` |
| Thông báo | Xuất bản sự kiện công khai hoặc cập nhật lịch | `eventNotifications` tạo inbox và `deliverNotification` gửi FCM theo điều kiện hiện có |
| Remote Config | Chỉnh xu thưởng từng ngày trong chuỗi Daily Check-in | `getAdminRemoteConfig`, `publishAdminRemoteConfig` |
| Analytics | Xem 25 sự kiện có lượt ghi nhận cao nhất trong 7 hoặc 30 ngày | `getAdminAnalyticsReport` đọc GA4 Data API |
| Crashlytics | Thử crash Android QA cục bộ trên Windows và mở Firebase Console | Trình kiểm thử Windows gọi ADB cục bộ |

Sự kiện cần ban tổ chức tồn tại. Khi xuất bản công khai, ban tổ chức phải
được công khai và sự kiện chưa bắt đầu. Hình thức tham dự, phạm vi hiển thị
và ban tổ chức được khóa khi xuất bản. Cập nhật lịch và địa điểm vẫn có thể
kích hoạt thông báo theo quy tắc hiện tại. Để cập nhật bản ghi đã thay đổi
do lượt đăng ký hoặc đổi thưởng, tải lại chi tiết trước khi lưu.

Khi thay nội dung điều khoản, cập nhật phiên bản điều khoản. Tắt mẫu voucher
áp dụng cho lượt đổi mới. Giá, điều khoản và hạn dùng của voucher đã cấp
được đọc từ dữ liệu lưu lúc đổi. Mobile Rewards vẫn cần nối các API catalog
và đổi thưởng hiện có để hiện mẫu thật trong luồng đó.

Web chỉnh từng mục của `daily_checkin_rewards` với ETag. Backend áp dụng
lịch đã xuất bản vào Firestore để mobile đọc qua `getAccount` và cộng xu qua
`claimDailyCheckin`. Từ ngày 7 trở đi dùng mức của ngày 7. Nếu bước áp dụng
lỗi, tải lại và bấm xuất bản với cùng giá trị để đồng bộ.
[Kế hoạch Remote Config](REMOTE_CONFIG_PLAN.md)

Nút Crash Android QA chỉ hiện cho admin trong phiên Vite cục bộ dành cho QA.
Sau khi app gửi lỗi, mở Firebase Console để đối chiếu báo cáo Android.
[Hướng dẫn kiểm thử](EVIA_Crashlytics_Implementation.md)

Nghiệm thu trên Emulator cho đăng nhập, quyền API, catalog, xuất bản và
inbox. Nghiệm thu trên dự án thật cho FCM, phiên bản Remote Config, GA4 Data
API và Crashlytics trên Firebase Console.
