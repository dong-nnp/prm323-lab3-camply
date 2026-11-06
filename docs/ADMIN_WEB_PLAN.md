# Evia Admin — phạm vi 06/11/2026

> **Thông báo Vite:** thêm `sendAdminNotification({uid,body,requestId})`, gửi nội dung tùy ý tới một active user có device, không yêu cầu event/demo flag. API demo cũ giữ tương thích. [Contract và demo](ADMIN_NOTIFICATIONS.md).

> **Tạo sự kiện gọn/ảnh Storage — 06/11/2026:** Vite `admin/` bỏ các ô kỹ thuật owner nêu, tự điền policy và giữ dữ liệu cũ khi edit. Ảnh tải trực tiếp lên prefix Storage riêng cho active admin; Rules và quyền cross-service đã triển khai. Không đổi contract create/update event hoặc portal Flutter. [Phạm vi/evidence](ADMIN_EVENT_EDITOR.md).

> **Analytics live — 06/11/2026:** đã deploy bộ lọc Android/Web, xác minh 6 tổ hợp nguồn/khoảng ngày, caller cũ và auth guards; UI Chrome hiển thị 4 loại hành vi Android. [Bằng chứng](../evidence/analytics-report-live/README.md).

> **Analytics Vite — 06/11/2026:** `admin/` thêm nguồn Android/Web/Theo cấu hình backend, nhãn hành vi và DebugView link. Callable giữ `{days}` tương thích cho admin Flutter và nhận thêm `source` tùy chọn. [Triển khai và giới hạn](ANALYTICS_INTEGRATION.md).

Portal mới viết bằng [Flutter Web](../admin_flutter/README.md). Vite `admin/`
vẫn được giữ; chưa thay Hosting/công cụ Android Crash QA cũ. Không sửa UI sinh viên.
Chủ dự án chốt **một admin làm hết, không phân công staff**.

| Mục | Thao tác | API |
|---|---|---|
| Auth | Email/password, guard admin | Firebase Auth, `getOperatorContext` |
| CLB | Xem, tạo/sửa, công khai/ẩn, giữ followerCount | `listAdminRecords`, `upsertOrganizer` |
| Sự kiện | Nháp, sửa, xuất bản; lịch/địa điểm/cọc/thưởng/số vé/điều khoản/lịch hoạt động | `listAdminEvents`, `getAdminEvent`, `createEvent`, `updateEvent`, `publishEvent` |
| Người tham gia | Đăng ký và attendance theo event | `listAdminRecords` |
| Check-in | Quét QR/nhập mã vé, phát QR walk-in có hạn | `listOperatorEvents`, `verifyRegisteredTicket`, `verifyRegisteredCode`, `issueWalkInQr` |
| Quà/voucher | Tạo đang tắt, sửa, bật/tắt; giá/stock/hạn/địa điểm/điều khoản | `listAdminRewards`, `getAdminReward`, `createReward`, `updateReward` |
| Bàn giao | Xác nhận voucher/quà vật lý một lần | `verifyVoucher`, `confirmPhysicalReward` |
| Thành tựu | Tạo/sửa, bật/tắt có version | `listAdminRecords`, `upsertEventMilestone` |
| Thông báo | Inbox, kết quả FCM, gửi thử một UID demo | `listAdminRecords`, `sendAdminDemoNotification` |
| Người dùng/ví | Hồ sơ, số dư, ledger chỉ đọc | `listAdminRecords`, `getAdminUser` |
| Remote Config | Đọc/xem trước/xuất bản hai defaults milestones | `getAdminRemoteConfig`, `publishAdminRemoteConfig` |
| Analytics | Top 25 events 7/30 ngày | `getAdminAnalyticsReport` |
| Crashlytics | BigQuery report 7/30 ngày khi có cấu hình | `getAdminCrashlyticsReport` |

## Contract mới

Callable mới yêu cầu claim `admin:true`, profile active. Các thao tác qua operation
receipts như bàn giao quà/voucher còn yêu cầu hoàn tất onboarding. Không API tự cấp
role/cộng trừ ví. Rules giữ nguyên; ghi qua server SDK sau kiểm quyền. Legacy staff
backend còn tương thích, nhưng admin check-in/phát QR trực tiếp không cần assignment.
Voucher/thành tựu dùng admin claim và active profile, không còn yêu cầu allowlist
`voucher_admins`/`milestone_admins`. Documents cũ không quyết định quyền admin này.

- `getOperatorContext({})`: UID/displayName/capabilities; từ chối staff.
- `listAdminRecords({kind,cursor?,limit?,eventId?,uid?})`: `items,nextCursor`;
  kind = organizers/milestones/users/participants/attendance/redemptions/notifications/ledger.
  Limit 1–50, default 20. Participants/attendance cần eventId; ledger cần UID.
  UID có thể lọc notifications/redemptions. Field allowlist không trả device token,
  voucher secret, role docs hoặc raw operation receipts.
- `getAdminUser({uid})`: profile và wallet chỉ đọc.
- `upsertOrganizer({organizer,expectedRevision})`: null để tạo, revision để sửa;
  audit server, giữ followerCount. Revision cũ trả `CATALOG_CHANGED`.
- `listOperatorEvents({cursor?,limit?})`: sự kiện để admin mở check-in.
- `sendAdminDemoNotification({uid,eventId,requestId})`: chỉ active user và public
  published event đều `isDemo:true`, có device. Retry cùng request không tạo inbox mới.
  Trả `queued`, không tuyên bố điện thoại đã hiển thị; không broadcast tùy ý.
- `confirmPhysicalReward({redemptionId,requestId})`: physical/issued/chưa hết hạn;
  transaction đánh dấu used/usedBy/usedAt, receipt retry, không ghi thêm debit.

Sự kiện mới phải nháp; quà mới phải inactive. Published event khóa organizer,
visibility, participationMode. Capacity không thấp hơn số đăng ký; quà khóa loại.
Thay điều khoản phải tăng version. Revision chặn ghi đè stock/counter; giữ snapshots.

Thông báo mới/đổi lịch/nhắc trước ba ngày dùng backend hiện có. Sau gửi,
`pushDispatch` có successCount/failureCount/completedAt/status (`accepted_by_fcm`
hoặc `no_delivery`). Đây là kết quả FCM, không phải biên nhận hiển thị Android.

Remote Config chỉ sửa `event_milestones_enabled` và `event_milestones_intro`, có
ETag, giữ conditional values/nhóm. Tiền/quyền vẫn do backend quyết định.
Snapshot admin Flutter trước cập nhật Analytics live: Remote Config đọc được; Analytics trả 0 dòng; Crashlytics trả
`CRASHLYTICS_NOT_CONFIGURED` vì chưa có bảng export, không hiển thị dữ liệu giả.

Nghiệm thu: [evidence/admin-flutter](../evidence/admin-flutter/).
