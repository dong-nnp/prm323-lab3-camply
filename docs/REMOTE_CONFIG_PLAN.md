# Phạm vi cấu hình từ xa — Evia

Cập nhật: **05/11/2026**. Hai key Event Milestones đã publish lên Firebase;
Flutter Remote Config runtime vẫn pending. Các key Discover/banner bên dưới
vẫn là đề xuất, chưa publish.

Mục tiêu: khoanh vùng biến để Flutter hỗ trợ trước; sau này web admin có thể thay giá trị mà không build lại app. Hiện `RemoteConfigService` vẫn pending.
`firebase/remote-config-defaults.json` có đúng hai key đã chốt:
`event_milestones_enabled=true` và `event_milestones_intro` (nội dung giới thiệu).
[Hợp đồng thành tựu](EVENT_MILESTONES.md) ghi rõ quyền admin và giới hạn.
Số xu/điều kiện/danh sách do Firestore + backend quản lý, không lấy từ client config.

## 1. Các biến dùng Firebase Remote Config

Chỉ bắt đầu bằng hai biến phục vụ Lab 3; hai biến thông báo chung là phần mở rộng khi cần. Tên key dùng chung giữa app, Firebase Console và web admin.

| Key | Kiểu | Default đề xuất | Validation | App cần sử dụng tại đâu | Hành vi khi admin thay đổi |
|---|---|---|---|---|---|
| `discover_featured_enabled` | boolean | `true` | Chỉ true/false | Discover, phần sự kiện nổi bật | Hiện/ẩn phần nổi bật; các sự kiện vẫn tìm thấy qua danh sách/tìm kiếm |
| `catalog_page_size` | integer | `20` | Số nguyên 1–50, khớp giới hạn backend hiện tại | Service/repository khi gọi `getPublicCatalog`; áp dụng đồng nhất cho danh mục được endpoint hỗ trợ | Đổi số bản ghi mỗi trang; vẫn phân trang để không làm mất khả năng truy cập dữ liệu |
| `app_notice_enabled` | boolean | `false` | Chỉ true/false | Banner thông báo chung trong app, nếu triển khai | Bật/tắt banner; không gửi push notification |
| `app_notice_text` | string | `""` | Trim, tối đa 200 ký tự, plain text; bật banner thì nội dung phải không rỗng | Nội dung banner chung | Đổi nội dung banner sau khi app nhận và activate config |

Hai key banner phải được validate/publish cùng nhau. Nội dung rỗng hoặc config không hợp lệ thì không hiện banner. Banner là thông báo hiển thị trong app; muốn đẩy thông báo tới điện thoại vẫn dùng FCM.

Hai biến đầu đủ để chuẩn bị demo yêu cầu ≥2 tham số làm thay đổi hành vi. Chỉ được tính hoàn thành sau khi app thật sử dụng chúng và có evidence trước/sau, không chỉ in giá trị lên màn hình.

## 2. Biến admin quản lý qua backend/Firestore

Những giá trị sau cũng có thể thay từ xa trong tương lai mà không build lại mobile, nhưng backend phải đọc, validate và áp dụng chúng. Không dùng giá trị Remote Config trên điện thoại làm căn cứ cấp xu, cấp vé hoặc cấp quyền.

| Nhóm biến | Nguồn hiện tại | Phạm vi quản lý tương lai và giới hạn |
|---|---|---|
| Thành tựu: tên, mô tả, requiredEvents, rewardCoins, sortOrder, active | `milestones/{id}`, API `upsertEventMilestone` | Admin custom claim + active milestone_admins, expectedVersion và audit; snapshots đã claim không đổi. Metric mới ngoài verified_events vẫn cần backend code |
| Sự kiện: `capacity`, `depositCoins`, `attendanceRewardCoins`, `registrationClosesAt`, `checkInStartAt`, `checkInEndAt`, `status`, `visibility`, `featured` | Event records; schema tại `functions/src/catalog.ts` | Admin sửa qua endpoint có quyền; capacity không được thấp hơn số vé đã cấp. Thay tiền/điều kiện phải có quy tắc cho vé đã cấp, không tự sửa snapshot/ledger cũ |
| Nội dung sự kiện/CLB: title/name, description, venue, schedule, image/logo | Event/organizer records | Quản lý nội dung dữ liệu, không đặt toàn bộ catalog trong Remote Config |
| Phần thưởng: `priceCoins`, `stockRemaining`, `status`, `validDays`, `termsVersion`, `termsText` | Reward records | Backend kiểm tra giá/stock trong transaction; giữ lịch sử redemption/voucher đã phát hành. Café hiện chốt 200 xu, tài liệu này không cho phép tự đổi policy |
| Sở thích: `label`, `status` | Interest records | Quản lý taxonomy được duyệt; xử lý tương thích với hồ sơ đã chọn các ID cũ |
| Signup bonus và daily schedule | `SIGNUP_BONUS_COINS` và `dailyGrant` trong `functions/src/policy.ts` | Hiện hard-code ở backend, chưa đổi được qua admin. Nếu cần cấu hình sau này: thiết kế policy server có version, thời điểm hiệu lực và audit trước; giữ 200 xu/UID, lịch `[5,10,15,30,50,70,100]`, ngày 8+100 và timezone đã chốt cho đến khi có quyết định mới |
| Monthly Gift, admin voucher, no-show, đăng ký lại sau hủy | Đã được chủ dự án chốt, có backend local mới trong [BACKEND_POLICIES.md](BACKEND_POLICIES.md) | Giữ policy ở server có version/audit; không dùng client Remote Config để vượt quyền hoặc quyết định số xu. Jobs/admin changes đã deploy; xem backend-release.md. Remote Config runtime vẫn pending |

Remote Config phía client không chứa secrets, credentials, role/staff permissions, QR signing secrets hoặc số dư/ledger. Không cho admin tùy ý đổi Firebase project, endpoint, auth guard hay Security Rules qua config app.

## 3. Hợp đồng Flutter khi tích hợp

- Adapter Remote Config trong service layer gọi SDK; DI inject qua interface. ViewModel nhận presentation state, View chỉ render.
- Nạp hai defaults milestone đã chốt từ `firebase/remote-config-defaults.json` khi nối SDK. Các key đề xuất Discover/banner chỉ thêm khi task triển khai chúng; defaults/publish không chứng minh runtime đã hỗ trợ.
- Validate kiểu/range trước khi áp dụng. Dùng giá trị hợp lệ đã activate gần nhất; nếu chưa có thì dùng in-app default. Lỗi mạng/fetch không làm app kẹt hoặc crash.
- Fetch lúc khởi động/resume theo chính sách cache; nếu tích hợp real-time updates thì cũng cần activate và cập nhật state. Không hứa mọi điện thoại đổi tức thì, nhất là khi offline hoặc app đã đóng.
- Áp dụng snapshot mới ở ranh giới an toàn: trước khi tải trang danh mục mới; reset cursor/danh sách khi đổi page size để tránh ghép các trang không nhất quán. Không thay giữa transaction đang xác nhận.
- Cờ hiện/ẩn chỉ điều khiển UI. Backend vẫn thực thi quyền và policy; app cũ hoặc client sửa đổi không được vượt quyền.
- Hiển thị giá trị đang áp dụng, nguồn default/remote và thời điểm cập nhật trong Firebase demo area để kiểm tra.
- Chỉ thay những hành vi đã được code hỗ trợ. Thêm loại tính năng mới hoặc sửa logic vượt hợp đồng vẫn cần bản build mới; không dùng config để tải/chạy code tùy ý.
- `FIREBASE_ENABLED` hiện là compile-time flag; không chuyển nó thành Remote Config vì app phải bootstrap Firebase trước khi fetch được config.

## 4. Hợp đồng web admin tương lai

Luồng: **web admin → backend kiểm tra quyền → validate → publish Firebase Remote Config → app fetch/activate → cập nhật UI**.

- Browser admin không giữ service-account key hoặc tự publish bằng credentials đặc quyền. Backend dùng quyền IAM tối thiểu để quản lý template.
- Backend chỉ cho sửa whitelist key ở mục 1; kiểm tra giá trị và cặp banner. Không cung cấp editor tùy ý cho toàn bộ template.
- Đọc template hiện tại, merge đúng keys cần sửa, validate và publish với ETag; khi có conflict thì tải lại/cho xem thay đổi, không ghi đè mù các cấu hình khác.
- Admin xem giá trị hiện tại, preview thay đổi, người sửa, thời gian và version đã publish; có lịch sử và rollback. Hoàn nguyên phải qua validation giống publish.
- Thay đổi event/reward/policy ở mục 2 dùng endpoint nghiệp vụ riêng với authorization/audit; không trộn với publish Remote Config.
- Web admin chưa thuộc implementation Lab 3 hiện tại. Trước khi có web, Firebase Console có thể điều chỉnh cùng các key đã được app hỗ trợ.

## 5. Checklist triển khai và nghiệm thu

- [ ] Tích hợp typed config model/service/DI; chốt hai keys đầu và defaults, không đổi policy nghiệp vụ.
- [ ] Nối Discover và phân trang catalog vào config thật; xử lý offline/invalid values và cập nhật state.
- [ ] Có tests cho defaults, validation/range, fetch failure và UI đổi theo giá trị; không đòi credentials ở unit/widget tests.
- [ ] Publish hai keys trên Firebase Console, đổi giá trị, lưu ảnh/video trước–sau trên cùng APK không build lại.
- [ ] Nghiệm thu đổi page size không mất/nhân đôi dữ liệu và tắt featured không chặn truy cập sự kiện.
- [ ] Nếu triển khai banner: kiểm tra text dài/text scale, config cặp invalid và không nhầm banner với FCM.
- [ ] Khi làm web admin: triển khai quyền backend, whitelist, ETag conflict handling, audit và rollback; kiểm tra người không có quyền bị từ chối.

## Tài liệu liên quan

- [Checklist Lab 3](LAB3_CHECKLIST.md)
- [Backend integration contract](backend-integration.md)
- [Các quyết định nghiệp vụ hiện tại](PROJECT_CONTEXT.md)
- Firebase: [Modify Remote Config programmatically](https://firebase.google.com/docs/remote-config/automate-rc), [Client template versioning](https://firebase.google.com/docs/remote-config/templates/client), [Parameters and conditions](https://firebase.google.com/docs/remote-config/parameters).
