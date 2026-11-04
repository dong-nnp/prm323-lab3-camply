# Hợp đồng bàn giao cho đội giao diện — không yêu cầu đổi layout

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
| Auth/onboarding | Auth SDK → `initializeUser` → `getAccount` → `saveInterests` khi cần | Auth cancelled/failed, ≥3 valid interests, account disabled. Không suy ra login thật từ nút Continue |
| Discover/search | `getPublicCatalog`, `getEvent`, `getOrganizer`, follow/bookmark | Trang rỗng có cursor chưa phải empty toàn bộ; `following`/`recommended` cần auth/onboarding |
| Đăng ký/hủy/đăng ký lại | Event detail → confirm quote/terms → `registerForEvent` → `getTicket`; cancel qua `cancelRegistration` | `EVENT_FULL`, `QUOTE_CHANGED`, `TERMS_CHANGED`, `INSUFFICIENT_COINS`. Hủy mất cọc; đăng ký lại tính cọc mới và cạnh tranh slot hiện còn |
| My Events/ticket | `listMyEvents` → `getTicket({eventId})` → `getTicketQr` | Phân biệt registered/cancelled/attended/no_show. Vé cũ đã revoked không được hiện như vé active |
| Check-in | Registered: staff scan `verifyRegisteredTicket`; walk-in: student scan `verifyWalkInQr` | `QR_INVALID`, `OUTSIDE_CHECKIN_WINDOW`, `ALREADY_CHECKED_IN`, `FORBIDDEN_STAFF`; không parse QR để tự cấp xu |
| Ví/daily/monthly | `getAccount`, `listOwned(kind:ledger)`, `claimDailyCheckin` | Monthly tự cộng ngày 1, không có nút claim; `grantMonthlyGift` trả `AUTOMATIC_ONLY`. No-show chỉ mất held, không trừ thêm available |
| Rewards/voucher | `getReward` → `redeemReward` → `getVoucherCode` cho owner | `PRICE_CHANGED`, `TERMS_CHANGED`, `OUT_OF_STOCK`, `EXPIRED`, `USED`; không lưu QR/code vào logs/analytics |
| Admin sử dụng voucher | Quét QR `evia:voucher:<voucherId>:<code>` → gửi phần code vào `verifyVoucher` | Chỉ admin được cấp quyền xác nhận; status used là cuối, không trừ xu lần nữa. Giao diện admin nằm ngoài task hiện tại |
| Inbox/FCM | Permission → `registerDevice`; token refresh đăng ký lại; sign-out gỡ installation → Auth logout | Backend có inbox; nhận push ba trạng thái và navigation cần verify trên Android thật |

## Hợp đồng notification và đích điều hướng

FCM `data` có `notificationId`, `entityType`, `entityId`, đều string. Không coi payload là nguồn cấp quyền; sau auth đọc lại owner record và xác minh ID/type.

| entityType | entityId là gì | Cách resolve được phép |
|---|---|---|
| `ticket` | **ticketId**, không phải eventId | Service dùng authenticated Firestore read `tickets/{ticketId}` của owner để lấy eventId, sau đó `getTicket({eventId})`. Không truyền ticketId vào tham số eventId |
| `redemption` | redemptionId | Service đọc owner record `redemptions/{id}` để lấy rewardId/voucherId và mở detail tương ứng |
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
