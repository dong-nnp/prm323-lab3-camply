# Evia — đối chiếu Figma với database

Ngày kiểm tra: **04/11/2026**. Đây là cập nhật thiết kế dữ liệu, chưa phải code,
migration, seed hoặc triển khai schema lên Firebase.

**Cập nhật sau xác nhận của owner cùng ngày:** không Waitlist; hết vé thì đóng,
hủy thành công mới trả chỗ; Daily 5/10/15/30/50/70/100 rồi 100/ngày; Café 200 xu;
Google + email/password; tối thiểu 3 sở thích bắt buộc. Bỏ toàn bộ milestones,
FD-09/10 và nhập mã walk-in (chỉ QR). FD-08 tạm hoãn, FD-12 chưa chốt.
Các bảng source bên dưới vẫn phản ánh Figma tại thời điểm đọc; không coi dữ liệu
prototype là dữ liệu thật hay chính sách đã được duyệt.

Nguồn trực tiếp: [page màn hình cuối](https://www.figma.com/design/JQtHz2tigJtvvjVBsx03kx/Campus-Event-App--Copy-?node-id=2083-272),
file `JQtHz2tigJtvvjVBsx03kx`, page `2083:272`.
Figma session: `f20f719b-09e9-45a8-ab15-f9ee786c0737`.

Đã đọc **44/44 frame**, tổng cộng **1.342 text nodes đang hiển thị** qua Figma
Plugin API. Đã xem thêm ảnh của 6 frame: Filters, About, Location, Registration
Default, My Ticket và Reward Details. Không gọi đây là visual review đủ 44 màn.
Ảnh Schedule và Going bị timeout khi export; nội dung text của cả hai đã đọc đủ.
Không sửa node nào trong Figma; không thay đổi dữ liệu/Rules trên cloud.

Evidence local: [nhóm 1](../evidence/figma-database/screens-1.json),
[nhóm 2](../evidence/figma-database/screens-2.json),
[nhóm 3](../evidence/figma-database/screens-3.json),
[nhóm 4](../evidence/figma-database/screens-4.json). Mỗi text có node ID để đối chiếu.
Ảnh PNG cùng thư mục dùng node ID làm tên; không lưu URL asset hết hạn.
Tên người, ID sinh viên, địa điểm, số dư và mã vé/voucher trong evidence là
**nội dung prototype**, không phải dữ liệu thật hoặc input cho seed.

## Những bổ sung vào schema

Các field/type/ownership được định nghĩa tại
[DATABASE_DESIGN.md v1.2, mục 1.3](DATABASE_DESIGN.md#13-field-contracts-confirmed-necessary-by-the-final-screen-review).

| Nhóm | Khoảng trống trước đây | Bổ sung đề xuất |
|---|---|---|
| Event Detail | Chỉ description, thời gian và map venue tổng quát | Subtitle, doors-open, timezone, benefits, requirements, timeline schedule; địa chỉ/gate, hướng dẫn check-in, tiếp cận và di chuyển |
| Explore/eligibility | `audience:M` chưa định nghĩa | Audience descriptive; xác minh/verified-only filters tạm hoãn theo FD-08, không giả verified hoặc bypass event đang hạn chế |
| Discovery/Following | Chưa có featured/tagline/count contracts | Featured do publisher đặt; taxonomy IDs/tags; loại/mô tả ngắn CLB, follower count server quản lý |
| Walk-in Going | Không có nơi lưu ý định tham gia | `users/{uid}/event_intents/{eventId}`; không tạo vé, giữ chỗ, cọc hay xu |
| Registration | Thiếu phone, snapshot và điều khoản | Optional phone, attendee snapshot riêng tư, terms version và acceptedAt từ server; lỗi theo field và kiểm tra lại giá cọc |
| Ticket/attendance | Thiếu ticket number/gate | Display reference, attendee snapshot, gate xác minh; không thêm seat/tier/pass-type inventory |
| Rewards/voucher | Thiếu nơi sử dụng/terms/fulfillment; hash lẫn metadata | Một giá chuẩn, terms/version/steps/locations, reward snapshot; tách `voucher_secrets` khỏi metadata owner đọc được |
| Notifications | Chỉ payload và target chung | Loại notification, entity target allowlist, dedup, mark-all-read cutoff; device token riêng tư và unlink khi logout |
| Calendar/history | Query theo registeredAt không đủ | Upcoming/Past dựa thời gian sự kiện, hợp nhất registration/Going/attendance; tháng và nhóm giao dịch là derived/query state |

## Truy vết đủ 44 frame

Node IDs được đọc lại trong phiên này, không lấy IDs cũ làm bằng chứng hiện tại.
Các tên dưới đây rút gọn; tên gốc và text đầy đủ có trong evidence JSON.

| Node | Màn hình/trạng thái | Dữ liệu hoặc hành vi cần đáp ứng |
|---|---|---|
| `2083:456` | Discover signed-in | Interests → recommendations; featured, followed organizers, upcoming, wallet balance |
| `2083:826` | Explore results | Search events/organizers, category/audience/date, soonest, số kết quả; loại waitlist |
| `2083:993` | Explore idle | Recent search local, suggested events; remaining spots được tính |
| `2083:1143` | Discover guest | Chỉ public/published; không cá nhân hóa bằng dữ liệu riêng của UID |
| `2083:1438` | Advanced filters | Date/time/duration/audience/eligibility/mode/capacity; không lưu filter draft vào business database |
| `2083:1582` | Following — Their Events | Organizer filter + soonest; suggested organizers; Follow không phải registration |
| `2083:1873` | Following — Organizers | Tagline/kind, follower và upcoming counts; thông báo khi CLB có sự kiện mới |
| `2083:4509` | Login | Google + email/password sign-up/sign-in/reset; credentials ở Firebase Auth, không lưu trong users |
| `2088:2` | Interests onboarding | Bắt buộc ít nhất 3 distinct canonical interest IDs để complete/save; bỏ Skip |
| `2083:6080` | Organizer profile | Description đầy đủ, type/kind, Follow, upcoming/past event lists và counts |
| `2083:5523` | Event About | Benefits, audience/requirements, doors-open, free admission khác Coin deposit |
| `2083:4752` | Event Schedule | Ordered timeline, thời điểm, stage/location, mô tả và schedule note |
| `2083:5137` | Event Location | Venue/address/gate, map coordinates có nguồn, instructions, accessibility/transit |
| `2083:5709` | Registration default | Họ tên/ID/email bắt buộc, phone tùy chọn, snapshot, terms acceptance, quote cọc |
| `2083:5329` | Registration validation | Field errors + thiếu consent; chưa giữ chỗ/trừ xu khi validation lỗi |
| `2083:5029` | Registration legacy | Student details; email ticket delivery/fixed reminder đã bị loại khỏi scope |
| `2083:4627` | Validation legacy | Không suy đoán ID format hoặc university domains từ ví dụ |
| `2083:5987` | Registration loading | Trạng thái ViewModel; requestId ổn định, không tạo registration state loading |
| `2083:6200` | Registration failed | Giữ form trong phiên retry; không lưu PII draft lên cloud hoặc báo success giả |
| `2083:5931` | Event Full | Không thay đổi capacity/wallet/ticket; loại bỏ đề xuất Join Waitlist |
| `2083:4961` | Registration success | Held deposit và ticket từ receipt thật; số dư không lấy từ prototype |
| `2083:5861` | Walk-in Going | Lưu intent, vào My Events; không vé/cọc/seat; chỉ xác minh QR mới thưởng |
| `2083:273` | My Events upcoming | Registration + intent, event dates/counts; nội dung có waitlist cần loại bỏ |
| `2083:1776` | Walk-in scanner | Event window + authenticated QR; bỏ Enter code, liên hệ staff nếu quét lỗi |
| `2083:2012` | Past empty date | Empty projection của query ngày; không phải document riêng |
| `2083:2170` | Past selected date | Attendance state/gate/awarded coins thật; không có feedback bonus |
| `2083:2345` | My Ticket | Attendee snapshot/student ID/ticket number; không seat/tier fields; QR không dùng display ID làm secret |
| `2083:2481` | Monthly calendar | Local date selection/markers; đổi thành UTC range theo event timezone |
| `2083:2795` | Cancel confirmation | Revoke ticket + forfeiture theo quyết định đã chốt; không tự triển khai assigned seats |
| `2083:2931` | All past | Event time và verified check-in; past không đồng nghĩa attended; không có seasonal targets |
| `2083:3108` | Upcoming selected date | Canonical event start/end, references hợp nhất và đúng số lượng |
| `2089:154` | Profile | Private profile fields, bookmark/follow/inbox references và logout cleanup |
| `2089:296` | My Interests | Save tối thiểu 3 distinct canonical IDs; không cho sửa eligibility/verified flag |
| `2091:440` | Saved Events | Bookmark relation; upcoming/past từ canonical event, không copy venue/ngày khác nhau |
| `2092:607` | Notifications | Entity link, unread/new, mark all read; loại reminder nghiệp vụ khỏi scope, giữ FCM lab |
| `2083:3267` | My Rewards locker | Owned redemptions, status/expiry; Available và Used/Expired là projections |
| `2083:3327` | Reward catalog | One server price, category/search, stock, affordability từ available coins |
| `2083:3522` | Earn Coins | Wallet/held/daily theo bảng chốt; bỏ milestones và Complete Missions |
| `2083:3788` | Redemption success | Receipt, price snapshot, actual resulting wallet, voucher reference và expiry |
| `2083:3865` | Confirm redemption | Quote/terms preconditions, held balance không bị trừ khi đổi quà |
| `2083:3959` | Reward details | Validity, usage locations, terms, ordered redemption steps, fulfillment type |
| `2083:4059` | Voucher & QR | Owner-only code retrieval; private secret; operator verification cập nhật used một lần |
| `2083:4156` | Event milestones | Owner bỏ toàn bộ feature: không progress/claim/API/coins; UI cần loại màn này |
| `2083:4356` | Coin History | Immutable ledger, month/type filters, source labels; không cộng hoàn cọc vào tiền thưởng |

## Mâu thuẫn và giới hạn cần giữ rõ

| ID | Quan sát trực tiếp | Cách xử lý trong thiết kế database |
|---|---|---|
| FD-01 | Waitlist ở `2083:826`, `2083:1438`, `2083:273`, `2083:5931` | **CHỐT:** không Waitlist. Hết vé thì đóng; cancellation commit trả một chỗ để đăng ký mới, xử lý atomic/chống trùng. Chưa chốt cùng user đăng ký lại sau hủy |
| FD-02 | `2083:3522` hiển thị Daily 5/5/10/10/15/15/20 | Giữ bảng được chốt 5/10/15/30/50/70/100, ngày 8+100; không seed bảng cũ |
| FD-03 | `2083:4156` có milestone +50/+100/+150/+300/+500 và Claimed | **BỎ TOÀN BỘ:** không có feature cột mốc, kể cả progress, claim và thưởng xu |
| FD-04 | Café 200 ở catalog `2083:3327`, nhưng 250 ở detail/confirm/success | **CHỐT 200 xu cho Café voucher.** Giá nằm trong server reward record, không hard-code trong màn hình và không áp dụng cho tất cả quà |
| FD-05 | Campus Music có Oct 24/26/Nov 7, nhiều venue, ID và mức reward khác nhau | **ĐÃ LÀM RÕ:** toàn bộ dữ liệu Figma chỉ minh họa UI. Không cần chọn ngày/venue mẫu làm dữ liệu thật; không tự seed |
| FD-06 | About `2083:5523` lặp ngày vào slot giờ và địa điểm | **DESIGN TEAM SẼ SỬA.** Schema dùng typed start/end/venue; không sửa Figma trong task này |
| FD-07 | Login có password/reset/signup; trước đây scope chỉ Google | **MỞ RỘNG:** Google + email/password đăng ký/đăng nhập/quên mật khẩu; credentials ở Firebase Auth, không lưu password/hash/reset token trong Firestore |
| FD-08 | Form ghi Account verified; filters nói verified student/club | **TẠM HOÃN:** chưa triển khai xác minh hoặc verified-only filter; không hiển thị verified giả; không đổi Follow thành membership |
| FD-09 | Email ticket delivery, reminder 2–3 ngày, feedback +20, missions, seasonal 1/4 | **KHÔNG CÓ NGHIỆP VỤ:** loại các tính năng này, không tạo jobs/grants/counters. Auth reset emails và FCM lab vẫn riêng biệt trong scope |
| FD-10 | Cancel backdrop có Row C/Seat 14; ticket có General | **KHÔNG CÓ NGHIỆP VỤ:** không assigned seats/VIP/ticket tiers; chỉ giới hạn số lượng vé |
| FD-11 | Walk-in scanner có Enter code | **CHỐT QR-ONLY TRƯỚC MẮT:** bỏ nút/endpoint nhập mã; quét lỗi thì retry/liên hệ staff, không cộng xu qua thao tác tự xác nhận |
| FD-12 | Voucher đổi trạng thái sau verification nhưng chưa có cashier flow | Cần operator role/scope và secure code protocol trước khi tuyên bố dùng quà end-to-end |
| FD-13 | Profile nói ít nhất 3 interests; onboarding có Skip | **BẮT BUỘC ít nhất 3 sở thích khác nhau** để complete/save. Không Skip bước này; Guest vẫn được xem public events |

## Query và kiểm thử cần hoàn thiện khi implementation

- My Events cần hợp nhất ba nguồn theo event ID. Query theo `registeredAt` hiện
  có trong plan không đủ cho calendar. Chốt bounded server query/read model và
  reschedule propagation trước khi tạo indexes; không tải mọi event về client.
- Full-text search, xếp hạng Popular/Recommended, taxonomy và ranh giới Morning/
  Afternoon/Evening/Duration chưa được Figma định nghĩa đủ để chốt thuật toán.
- Giá/terms thay đổi phải trả lỗi trước side effects. Việc backend lấy giá đúng
  không cho phép trừ mức giá mới mà người dùng chưa xác nhận.
- Giữ các invariants ở DATABASE_DESIGN và thêm acceptance cases FIG-01…FIG-07.
  Những ca này là **kế hoạch, chưa chạy**, không được đánh dấu PASS.

Việc tiếp theo nhỏ nhất là duyệt các chính sách còn OPEN và triển khai schema /
Rules / Emulator tests theo từng use case. Tài liệu này không cấp quyền seed,
thay Rules cloud, bật billing hay triển khai toàn bộ backend.
