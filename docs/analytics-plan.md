# Analytics plan — template

Trạng thái: chưa triển khai tracking. Analytics auto collection đang tắt trong
Android manifest; không có observer hoặc `logEvent` call trong UI/ViewModel.

## Quyết định cần xác nhận

- TODO: mục tiêu đo lường, người duyệt, môi trường và thời hạn lưu dữ liệu.
- TODO: quy tắc consent, dữ liệu được phép thu thập, giới hạn tham số.
- TODO: điểm gọi trong ViewModel/service, retry và chống phát event trùng.
- Không đưa email, tên, student ID, nội dung nhạy cảm hoặc secrets vào event.

| User action / screen ID | Event name | Trigger chính xác | Parameters + kiểu | Dữ liệu bị loại | Owner | Test / DebugView evidence |
|---|---|---|---|---|---|---|
| TODO sau khi xác định flow | TODO | TODO | TODO | TODO | TODO | Chưa thực hiện |

TODO: triển khai `AnalyticsService` thật qua provider; kiểm tra event ở môi
trường dev trước khi chủ động bật collection. Bảng này không phải log events
đã gửi hoặc bằng chứng tích hợp.
