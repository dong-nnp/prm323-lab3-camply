# Hợp đồng bàn giao cho đội giao diện — không yêu cầu đổi layout

> **Flow 2 — 05/11/2026:** đã nối API vào My Events/lịch/hủy/vé/check-in/inbox;
> thêm Firebase Cloud Messaging. Owner cho phép riêng nút demo nhỏ trên vé trong
> debug và xin quyền Android khi mở Notifications. Các styles/tokens/assets giữ
> nguyên. Nút demo chỉ dùng account/event được server bật, ghi trạng thái/xu thật
> trong dataset demo. [Giới hạn và evidence](../evidence/flow2-api-only/).

> **Email mở rộng 05/11/2026:** owner bỏ giới hạn domain email. Mọi địa chỉ
> đúng định dạng đều được đăng ký/đăng nhập/tham gia. MSSV vẫn hai chữ + sáu số;
> quyền staff/admin và điều kiện sự kiện giữ nguyên. [Contract](PREINTEGRATION_DECISIONS.md).

> **API-only theo owner 05/11/2026:** đã gỡ bộ màn `Flow1Screen` tạo ngoài phạm vi;
> nối Firebase vào các màn gốc, giữ layout/style/assets. Giữ 8 thẻ sở thích;
> Gaming/Environment chờ đội UI. Ảnh cũ làm minh họa khi chưa có URL; vé chỉ hiện
> QR trong ô cũ, chưa có mã dự phòng. [Phạm vi](API_INTEGRATION_PHASES.md) · [Evidence sửa lại](../evidence/flow1-api-only/).
> Các mô tả bộ màn live riêng/kết quả cũ bên dưới là lịch sử, không nghiệm thu bản này.


> **Flow 1 đã có adapter trong source 05/11/2026:** xem
> [API_INTEGRATION_PHASES.md](API_INTEGRATION_PHASES.md). Live dùng ID/catalog
> server, chọn hoặc bỏ qua sở thích, follow/bookmark, registration receipt và vé.
> Các ghi chú pending phía dưới vẫn áp dụng cho Flow 2/3 và instrumentation.

> **Dataset đã sẵn sàng để nối 05/11/2026:** [DEMO_DATA.md](DEMO_DATA.md) có
> 10 interests, 5 CLB, 12 events, 5 rewards (Café `demo-cafe`=200), 5 milestones
> và hai Auth operators staff/admin. Fetch dữ liệu server, không map bằng title
> hoặc ID fixture cũ. Reward category IDs: food_drinks/merchandise/experiences;
> labels và ảnh placeholder map tại presentation. Lịch live là snapshot, có expiry.

> **Sau review 05/11/2026:** [quyết định/contract mới](PREINTEGRATION_DECISIONS.md)
> chốt email domain mở, mã check-in dự phòng và notifications. UI đã sửa policy và
> claim/loading controls. CampusRepository/CampusService có saveInterests và
> claimEventMilestone; concrete SDK adapter vẫn pending, không giả thành công.
> Dữ liệu/versions/claimed/count thật phải load từ server ở bước tích hợp tiếp theo.

Ngày 04/11/2026. **Backend mới đã deploy: 34 Functions ACTIVE, 34 Cloud Run latest revisions READY, 2 scheduled jobs ENABLED**. Monthly Gift/no-show/re-registration/admin voucher đã có trên cloud; [release evidence](backend-release.md). Chưa nối Flutter hoặc thay files trong `lib/`. Native/authenticated flow acceptance vẫn cần làm khi tích hợp.

## Dùng chung

- Firebase HTTPS Callable, region `asia-southeast1`; dùng [API contract](backend-integration.md) và schemas `functions/src/` làm nguồn chính.
- Không truyền UID/role/balance/grant amount; Auth context và server là nguồn tin cậy. Firestore Timestamp qua Callable là ISO UTC; parse nullable rõ ràng.
- Giữ một `requestId` cho một lần xác nhận và mọi retry của lần đó. Đăng ký lại sau hủy là action mới, **phải tạo requestId mới**, không gọi lại ID đăng ký trước.
- Không optimistic cộng/trừ xu hoặc tạo vé. Sau success đọc account/related data mới; receipt retry có thể chứa wallet snapshot cũ.
- Adapter SDK → service interface → repository → ViewModel → UI; provider override được trong tests. Chưa thêm Dart models/adapters vì đội frontend đang sở hữu phần đó.

## Điểm nối theo flow

| Flow | Trình tự gọi | State và lỗi quan trọng |
|---|---|---|
| Auth/onboarding | Auth SDK → `initializeUser` → `getAccount` → `saveInterests` khi cần | Auth cancelled/failed, account disabled, Continue với số sở thích tùy ý hoặc Skip giữ lựa chọn đã lưu. |
| Discover/search | `getPublicCatalog`, `getEvent`, `getOrganizer`, follow/bookmark | Trang rỗng có cursor chưa phải empty toàn bộ; `following`/`recommended` cần auth/onboarding |
| Đăng ký/hủy/đăng ký lại | Event detail → confirm quote/terms → `registerForEvent` → `getTicket`; cancel qua `cancelRegistration` | `EVENT_FULL`, `QUOTE_CHANGED`, `TERMS_CHANGED`, `INSUFFICIENT_COINS`. Hủy hoàn 30% cọc làm tròn xuống; đăng ký lại tính cọc mới và cạnh tranh slot hiện còn |
| My Events/ticket | `listMyEvents` → `getTicket({eventId})` → `getTicketQr` | Phân biệt registered/cancelled/attended/no_show. Vé cũ đã revoked không được hiện như vé active |
| Check-in | Registered: staff scan `verifyRegisteredTicket`; walk-in: student scan `verifyWalkInQr` | `QR_INVALID`, `OUTSIDE_CHECKIN_WINDOW`, `ALREADY_CHECKED_IN`, `FORBIDDEN_STAFF`; không parse QR để tự cấp xu |
| Mã check-in dự phòng | QR response có manualCode; `verifyRegisteredCode` cho staff / `verifyWalkInCode` cho student | CODE_INVALID, CODE_EXPIRED, CODE_RATE_LIMITED; giữ requestId khi retry, recover verify-ticket/verify-walkin receipt |
| Ví/daily/monthly | `getAccount`, `listOwned(kind:ledger)`, `claimDailyCheckin` | Monthly tự cộng ngày 1, không có nút claim; `grantMonthlyGift` trả `AUTOMATIC_ONLY`. No-show chỉ mất held, không trừ thêm available |
| Thành tựu | `getEventMilestones({})` → `claimEventMilestone({milestoneId,expectedVersion})` | 1/3/5/10/20 → 50/100/150/300/500. Người dùng bấm Nhận thưởng; không tự cộng khi mở màn hình. MILESTONE_CHANGED yêu cầu tải lại. [Chi tiết](EVENT_MILESTONES.md) |
| Rewards/voucher | `getReward` → `redeemReward` → `getVoucherCode` cho owner | `PRICE_CHANGED`, `TERMS_CHANGED`, `OUT_OF_STOCK`, `EXPIRED`, `USED`; không lưu QR/code vào logs/analytics |
| Admin sử dụng voucher | Quét QR `evia:voucher:<voucherId>:<code>` → gửi phần code vào `verifyVoucher` | Chỉ admin được cấp quyền xác nhận; status used là cuối, không trừ xu lần nữa. Giao diện admin nằm ngoài task hiện tại |
| Inbox/FCM | Permission → `registerDevice`; token refresh đăng ký lại; sign-out gỡ installation → Auth logout | Backend có inbox; nhận push ba trạng thái và navigation cần verify trên Android thật |

## Hợp đồng notification và đích điều hướng

FCM `data` có `notificationId`, `entityType`, `entityId`, đều string. Không coi payload là nguồn cấp quyền; sau auth đọc lại owner record và xác minh ID/type.

| entityType | entityId là gì | Cách resolve được phép |
|---|---|---|
| `ticket` | **ticketId**, không phải eventId | Service dùng authenticated Firestore read `tickets/{ticketId}` của owner để lấy eventId, sau đó `getTicket({eventId})`. Không truyền ticketId vào tham số eventId |
| `redemption` | redemptionId | Service đọc owner record `redemptions/{id}` để lấy rewardId/voucherId và mở detail tương ứng |
| `event` | eventId | Load lại event; dùng cho new_event, schedule_updated, event_reminder. Không chọn màn qua tên/ID mock cố định |
| Giá trị không hỗ trợ/record không còn | Không tin ID/URL tùy ý | Mở notification center và hiển thị trạng thái phù hợp; không mở link tùy ý từ payload |

Chưa có Callable lookup theo ticketId/redemptionId; nếu đội tích hợp muốn chỉ dùng Callable, cần thống nhất bổ sung endpoint thay vì tự đoán. Các reads ở trên được Rules cho owner, SDK chỉ dùng trong service.

Push là tín hiệu, không thay cho database. Retry gửi có thể lặp; deduplicate in-app theo notificationId, Android tag hiện dùng cùng ID. Không cam kết FCM exactly-once. Payload generic không chứa mã voucher/QR, PII hoặc số dư. Console test không tự tạo inbox record; backend notification trigger mới gắn inbox với push.

## Config, Analytics và ranh giới công việc

- Dùng [REMOTE_CONFIG_PLAN.md](REMOTE_CONFIG_PLAN.md) cho keys/defaults, không để client config quyết định tiền/vé/quyền.
- Gắn events theo [analytics-plan.md](analytics-plan.md), không raw free-text search/PII.
- Dữ liệu thật theo [DATA_READINESS.md](DATA_READINESS.md); hiện chưa có catalog được duyệt. Không lấp dữ liệu rỗng bằng mock trong submitted build.
- Frontend chịu trách nhiệm visual states và native SDK integration; backend cung cấp contract, auth/Rules và transaction tests. Hai đội cần nghiệm thu ba flow cùng nhau sau khi nối.

## Checklist lúc nối

- [ ] Xác nhận backend revision, project config, Auth SHA và region.
- [ ] Kiểm tra models/ISO dates/nullability, API errors và pagination đúng contract.
- [ ] Kiểm tra account switch/sign-out clear state, requestId retry và action mới.
- [ ] Kiểm tra notification routing bằng owner reads, không lẫn ticketId/eventId.
- [ ] Chạy backend suite, Flutter suite và native smoke; sau đó mới ARTEMIS.
