# Analytics plan — Evia

Cập nhật 06/11/2026: đã triển khai 11 events Android sau trong bảng: AN-01/02/03/05/08/09/11/12/13/15/17. AN-02 chỉ xác định email/password signup; Google chỉ log login vì contract chưa trả isNewUser. AN-04/06/07/10/14/16 vẫn pending; bảng 17 dòng là kế hoạch tổng, không phải toàn bộ đã tích hợp. Chưa có ảnh DebugView cho revision này. [Chạy và giới hạn](ANALYTICS_INTEGRATION.md).

AN-15 xuất CSV các giao dịch đang hiển thị trong Coin History, không tạo PDF hoặc upload Storage. `report_type=coin_history_csv`, `file_size_kb:int` làm tròn lên sau native save thành công; hủy không log success.

## Mục tiêu và quy tắc chung

Đo hành trình khám phá → đăng ký → tham dự → đổi thưởng và nơi người dùng gặp trở ngại. Persona/success criterion định lượng cuối cùng phải đối chiếu Lab 2 đã duyệt; không tự tạo KPI hoặc số liệu.

- Dùng recommended events khi phù hợp, như `login`, `sign_up`, `search`.
- Sau login, AnalyticsService set user ID là UID nội bộ không chứa PII; logout clear user ID. Không dùng email/student ID làm user ID.
- Không gửi tên người, email, phone, student ID, địa chỉ cá nhân, nội dung form, auth/FCM tokens, voucher/QR codes, URL tải file hoặc requestId.
- Không gửi nguyên văn truy vấn tự do vì có thể chứa PII. `search_term` chỉ là mã category/sở thích từ allowlist; tìm tự do dùng `free_text_redacted`. Không hash free text để né quy tắc PII.
- Event đi qua ViewModel → AnalyticsService được DI inject; không SDK trong View. Lỗi analytics không quyết định giao dịch thành công/thất bại.
- Success event chỉ phát sau server xác nhận. Retry cùng action/requestId không phát success lần hai trong action đó; không hứa exactly-once xuyên reinstall. Server ledger/receipts mới là nguồn chuẩn cho tiền/vé.
- ID parameters là ID nội dung nghiệp vụ, không UID người khác. `error_code` chỉ lấy từ allowlist, không log exception/message SDK thô.
- Consent, retention và người được truy cập Analytics cần chốt trước khi bật collection production.

## Bảng sự kiện để đội tích hợp sử dụng

Owner triển khai: đội tích hợp Flutter. Mỗi AN-ID cần screenshot DebugView sau tích hợp; backend không tự gửi lại client success events.

| ID / flow | Event | Trigger chính xác | Parameters và kiểu | Câu hỏi sản phẩm |
|---|---|---|---|---|
| AN-01 / Auth | `login` | Auth SDK xác nhận login thành công, một lần mỗi action | `method:string` (`google`/`password`) | Phương thức nào được dùng để đăng nhập? |
| AN-02 / Auth | `sign_up` | Auth SDK xác nhận tài khoản mới, không suy ra chỉ từ `initializeUser.created` | `method:string` | Người dùng mới đến qua phương thức nào? |
| AN-03 / Auth | `logout` | Sign-out và clear state hoàn tất | Không cần parameters | Có bao nhiêu lượt chủ động đăng xuất? |
| AN-04 / Flow 1 | `search` | Submit tìm kiếm, phát khi lần tải logic đó kết thúc hoặc lỗi | `search_term:string` đã redact, `loaded_count:int`, `has_more:int` (0/1), `outcome:string` (`data`/`empty`/`error`) | Tìm kiếm nào có nội dung hiển thị hoặc gặp lỗi? |
| AN-05 / Flow 1 | `view_event` | Load event detail thành công, một lần mỗi lần vào màn | `event_id:string`, `participation_mode:string` | Sự kiện nào được mở nhiều? |
| AN-06 / Flow 1 | `view_organizer` | Load organizer detail thành công | `organizer_id:string` | CLB nào thu hút lượt xem? |
| AN-07 / Flow 1 | `follow_organizer` | Server xác nhận thay đổi follow/unfollow | `organizer_id:string`, `following:int` (0/1) | Lượt xem CLB có chuyển thành follow không? |
| AN-08 / Flow 1 | `register_event` | `registerForEvent` trả receipt thành công | `event_id:string`, `deposit_coins:int` | Bao nhiêu lượt xem chuyển thành đăng ký? |
| AN-09 / Flow 1 | `cancel_registration` | Server xác nhận hủy | `event_id:string` | Sự kiện nào có nhiều lượt hủy? |
| AN-10 / Flow 2 | `view_ticket` | Owner load vé thành công | `event_id:string`, `ticket_state:string` | Người đăng ký có tìm được vé không? |
| AN-11 / Flow 2 | `check_in_event` | Student flow nhận attendance đã được server xác nhận | `event_id:string`, `mode:string` (`registered`/`walk_in`) | Bao nhiêu lượt check-in được xác nhận trong app? |
| AN-12 / Flow 3 | `view_reward` | Load reward detail thành công | `reward_id:string`, `price_coins:int` | Phần thưởng nào được quan tâm? |
| AN-13 / Flow 3 | `redeem_reward` | Server xác nhận đổi thưởng, không phải chỉ mở dialog | `reward_id:string`, `cost_coins:int`, `fulfillment_type:string` | Lượt xem chuyển thành đổi thưởng thế nào? |
| AN-14 / Flow 3 | `view_voucher` | Owner load voucher detail thành công | `reward_id:string`, `voucher_state:string` | Người dùng có mở phần thưởng đã nhận không? |
| AN-15 / Export | `generate_report` | Tạo file thành công từ nội dung đang xem | `report_type:string`, `file_size_kb:int` | Bao nhiêu lượt tạo báo cáo thành công? |
| AN-16 / Storage | `upload_report` | Upload hoàn tất, object tồn tại | `report_type:string`, `file_size_kb:int` | File đã tạo có upload thành công không? |
| AN-17 / Các flow | `action_error` | Action kết thúc với lỗi hiển thị, không phát mỗi rebuild | `action:string`, `error_code:string` từ allowlist | Lỗi nào cản hoàn thành flow? |

`loaded_count` là số kết quả app đã tải và hiển thị khi kết thúc action, **không phải tổng toàn catalog**. Trang rỗng có `nextCursor` chưa chứng minh không có kết quả. App phải phân biệt “chưa tải hết” và “không có kết quả”.

Registered check-in do staff thực hiện: mobile sinh viên chỉ phát AN-11 khi quan sát chuyển trạng thái attendance lần đầu trong phiên, không mỗi lần mở My Events. Có thể thiếu khi app không mở; không dùng event này làm thống kê attendance chính thức. Không log UID sinh viên từ thiết bị staff/admin.

## Theo dõi admin web

Admin web dùng Firebase Analytics Web SDK để ghi `admin_event_saved`,
`admin_event_published`, `admin_voucher_saved` và `admin_remote_config_published`
sau phản hồi thành công của backend. Crash QA cục bộ không tự ghi Analytics. Trang Analytics gọi backend để đọc báo cáo GA4
theo sự kiện trong 7 hoặc 30 ngày. Vite admin chọn Android/Web trên toàn GA4 property; chỉ nguồn Theo cấu hình backend mới áp dụng numeric Stream ID. Admin Flutter vẫn gửi contract cũ, dùng stream cấu hình nếu có. [Kế hoạch admin web](ADMIN_WEB_PLAN.md).

## Verification — cập nhật 06/11/2026

- [x] Unit tests schema/repository kiểm allowlist/types, loại tham số nhạy cảm và lỗi SDK không phá action.
- [x] Fake AnalyticsService kiểm trigger success/error, không phát lặp khi retry cùng action/receipt.
- [x] Tests session/UID/logout và SDK failure; kiểm chứng SDK/UID trong DebugView vẫn chưa thực hiện.
- [ ] DebugView dev build xác nhận từng AN-ID/parameters và error-path, lưu evidence theo build/thiết bị.
- [ ] Ít nhất một ARTEMIS test sau này kiểm event trong Logcat/DebugView.

Nguồn: [Google recommended events](https://developers.google.com/analytics/devguides/collection/ga4/reference/events), [quy tắc không gửi PII](https://support.google.com/analytics/answer/6366371/).
