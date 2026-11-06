# Dữ liệu và tài khoản vận hành demo — 05/11/2026

> Cập nhật 06/11: admin hiện làm toàn bộ trên [Flutter Web](../admin_flutter/README.md),
> không phân công staff. Claim admin + active profile đủ xác nhận vé/voucher/thành tựu;
> allowlists/assignments trong bảng seed phía dưới là dữ liệu lịch sử, không bắt buộc cho admin.
> Đã có API xác nhận giao quà vật lý. Có thêm CLB smoke test chưa công khai
> `demo-admin-web-smoke`, tạo bằng form thật; không thêm followers/attendance/tiền giả.

Người dùng yêu cầu trực tiếp: tự generate dữ liệu rồi thêm Firebase, sau này sửa;
tự tạo tài khoản vận hành. Yêu cầu này thay thế giới hạn “chưa seed khi thiếu dữ
liệu thật” trong các snapshot trước. Nội dung mới **cố ý là demo được cho phép**,
không đại diện CLB/sự kiện/nhà tài trợ hoặc tài khoản FPT có thật.

Project: `prm393-31822`. Seed batch: `evia-demo-20261105-v1`.
Không thay Rules, Functions, Remote Config hoặc chính sách xu trong task này.

## Dữ liệu đã tạo

| Collection | Số bản ghi | Nội dung |
|---|---:|---|
| interests | 10 | technology, music, arts, sports, volunteer, career, business, gaming, photography, environment |
| organizers | 5 | Công nghệ, Âm nhạc, Sáng tạo, Thể thao và Đội Hoạt động Sinh viên giả lập |
| events | 12 | 11 published, 1 completed; registration/walk-in, live check-in và lịch sắp tới |
| rewards | 5 | Café 200, snack 100, túi 400, cinema 500, hoodie 800 xu; stock/terms/validity đều là demo |
| milestones | 5 có sẵn | Giữ nguyên bảng 1/3/5/10/20 → 50/100/150/300/500, không seed lại |

Source JSON: [firebase/demo-catalog.json](../firebase/demo-catalog.json).
Sự kiện/CLB/quà có tên `[DEMO]`; mọi record mới có `isDemo:true`, `seedBatchId`
và thông báo dữ liệu giả lập. `sourceRef` trỏ tới tài liệu provenance này, không
được hiểu là nguồn xác nhận hoạt động hoặc sponsor thật. Tài liệu/source chưa
được commit/push trong task này; URL GitHub chỉ là địa chỉ dự kiến của tài liệu.

- Counters khởi tạo đúng **0**, không bịa follower, vé đã bán hoặc attendance.
  `demo-full-event` dùng capacity=0 để biểu diễn hết chỗ, không tạo 100 user giả.
  `demo-last-ticket` capacity=1 để thử vé cuối khi tích hợp.
- `demo-live-registration` mở đăng ký và check-in lúc tạo; `demo-live-walkin`
  đang trong cửa sổ check-in. Các cửa sổ này là snapshot ngày tạo, **không tự
  kéo dài mỗi ngày**; khi thử ngày khác cần sửa thời gian hoặc tạo event mới.
- Có các event trong 1–11 ngày tới để thử Discover/My Events/reminders.
- Không seed registration, vé, attendance, redemption, voucher hoặc lịch sử
  nhận thành tựu. Những record đó phải do backend tạo từ thao tác thật.
- Quà chỉ phục vụ demo, không mua/nhận dịch vụ hay hàng hóa thực tế. Cafe giá
  200, stock 100, validDays=30; các giá trị này là dữ liệu server có thể sửa sau.
  Ba loại voucher được admin demo xác nhận; hai quà vật lý chưa có API giao nhận.
- Ảnh/logo URL không được thêm vì chưa có nguồn ảnh; dùng placeholder chuẩn của
  UI khi nối adapter. Không upload ảnh sang đường Storage bị Rules từ chối.

## Tài khoản đã tạo

| UID | Firebase Auth claim | Phạm vi Firestore |
|---|---|---|
| evia-demo-staff-v1 | staff:true | 11 staff_assignments cho 11 events published của batch này; verify_ticket, issue_walk_in |
| evia-demo-admin-v1 | admin:true | voucher_admins và milestone_admins active cho đúng UID này |

Cả hai có Firebase Auth email/password, profile active, ba interests đã lưu,
onboardingCompleted=true và wallet. **Email/mật khẩu nằm trong file riêng:**
`D:\project\prm323-lab3\prm323-lab3-camply\.local\demo-operators-20261105\TAI_KHOAN_DEMO.txt`.
File checkpoint `accounts.json` cùng thư mục cũng chứa secrets; cả thư mục bị
Git ignore và Windows ACL chỉ cho tài khoản Windows hiện tại truy cập các file.
Không sao chép hai file này vào evidence, Firestore, source hoặc APK.

- Email là định danh demo ngẫu nhiên thuộc đuôi FPT để đi qua policy đã chốt,
  **không phải hộp thư trường được sở hữu hoặc xác minh**. emailVerified=false;
  không gửi verification/reset email/SMS và không dùng Google login cho account này.
- Khi cần đổi mật khẩu, chủ project dùng Firebase Console/Admin API; không gửi
  reset tới địa chỉ giả lập. Thay bằng tài khoản thật được chỉ định trước sử dụng thật.
- Mỗi account được initializeUser cấp 200 xu một lần, có signup_bonus ledger;
  không trực tiếp đặt ví số dư cao hoặc seed lượt check-in để mở thành tựu.
- Không cấp Google Cloud IAM, quyền Firebase Console hoặc billing cho hai account.
  Role trong app không tự tạo màn staff/admin; tooling/UI vận hành vẫn cần nối.
- Account này khác local preview `DEMO_AUTH=true`. Đăng nhập vào backend thật
  chỉ dùng được khi chọn real Auth adapter ở bước tích hợp Flutter tiếp theo.

## Chỉnh sửa sau này

Vào Firebase Console → Firestore Database → Data trong đúng project:

- interests: sửa label/status; giữ ID nếu profile đã chọn.
- events: sửa title, description, venue, schedule, thời gian Timestamp, capacity,
  depositCoins, attendanceRewardCoins và registrationTerms. Không sửa counters
  hay quan hệ cá nhân thủ công. capacity không thấp hơn registeredCount; startAt
  phải trước endAt, cửa sổ check-in hợp lệ, walk-in deposit=0.
- rewards: priceCoins, stockRemaining, status, validDays, usageLocations, termsText
  và termsVersion. Thay điều kiện thì tăng termsVersion; client phải reload/confirm.
  Muốn dùng quà thật cần thay toàn bộ mô tả demo/địa điểm/terms bằng dữ liệu được duyệt.
- milestones: dùng upsertEventMilestone có version/audit. Thêm quyền mới chỉ qua
  người quản lý tin cậy; không cho client tự ghi assignments hoặc custom claims.
- Trước xóa batch: kiểm quan hệ user/ticket/attendance/redemption phát sinh sau
  tích hợp, sao lưu và duyệt đúng danh sách. Script seed **không có auto-delete**.

## Script và kiểm chứng

`functions/scripts/generate-demo-catalog.mjs` tạo JSON theo thời điểm hiện tại;
`functions/scripts/seed-demo.mjs` mặc định **dry-run không network**. Apply chỉ
dùng đúng project đã cho phép, create-only cho catalog; backup exact paths trước
ghi. Sau khi hoàn tất có receipt local `evidence/demo-data/applied.json`, chạy
apply lại cùng batch sẽ **không network/không ghi**, tránh ghi đè nội dung đã sửa.
Không chạy generator rồi apply lại cùng batch để đổi lịch; hãy sửa dữ liệu đã có.

Đã kiểm thực tế:

- 32 catalog records đúng JSON, markers và references; 5 milestone records giữ nguyên.
- Public API trả 10 interests, 5 organizers, 11 published events, 5 rewards;
  Café=200, sự kiện full spotsRemaining=0, vé cuối=1.
- Cả hai email/password sign-in thành công; getAccount có 10 interest options,
  ví available=200/held=0, đúng một signup_bonus, 0 verified attendance.
- Staff bị từ chối API admin; admin bị từ chối chức năng staff. Authorized role
  đi qua kiểm tra quyền rồi dừng ở lỗi input/state có chủ đích, không tạo token,
  notification, giao dịch, voucher hoặc audit giả để thử quyền.
- Assignment documents đúng UID/event/permissions; clients không đọc được role
  documents (HTTP 403). Không nới Rules để demo hoạt động.
- Tests catalog/script thuần Node và schema/dry-run đạt. Không đổi Dart/native/
  runtime backend nên không chạy lại Flutter suite hoặc deploy Functions.

[Logs/metadata](../evidence/demo-data/README.md),
[verification](../evidence/demo-data/verification.json).
