# Thành tựu tham gia sự kiện — 05/11/2026

> **Cập nhật sau review:** protected API áp dụng FPT identity theo
> [contract mới](PREINTEGRATION_DECISIONS.md). UI có ba trạng thái và claim/loading
> controls, nhưng CampusService vẫn pending; danh sách/claimed/count thật và
> refresh wallet cần adapter SDK ở bước tích hợp. Release 37/41 tests bên dưới
> ghi nhận thời điểm phát hành feature đầu tiên, không phải release mới nhất.

Chủ dự án đã chốt bổ sung lại Event Milestones, thay thế quyết định bỏ tính năng
trước đây. Đây là nguồn xu thưởng thêm bên cạnh thưởng từng sự kiện, Daily,
signup và Monthly Gift. Giao diện Flutter chưa được nối trong task Firebase này.

## Chính sách đã chốt

| ID ổn định | Tên | Check-in hợp lệ | Xu thưởng thêm |
|---|---|---:|---:|
| `first-event` | First Event | 1 | 50 |
| `explorer` | Explorer | 3 | 100 |
| `active-student` | Active Student | 5 | 150 |
| `campus-regular` | Campus Regular | 10 | 300 |
| `campus-star` | Campus Star | 20 | 500 |

- Tiến độ tích lũy suốt thời gian sử dụng, tính cả attendance hợp lệ trước ngày
  phát hành tính năng. Không reset theo ngày/tháng và không có thời hạn nhận.
- Người dùng **bấm Nhận thưởng**, không tự cộng khi xem tiến độ hoặc check-in.
  Tổng năm mốc là 1.100 xu. Mỗi UID/mốc được nhận một lần, không cần nhận theo thứ tự.
- Chỉ tính canonical `attendance` của UID: mode do server xác minh là
  `organizer_scanned_ticket` hoặc `student_scanned_walkin`, `verifiedAt` là timestamp
  hợp lệ không ở tương lai. Backend check-in hiện giữ một document/UID/event.
  Registration, Going, Bookmark, Daily, cancel và no-show không tăng tiến độ.
- Mốc 30 sự kiện → 800 xu trước đó chỉ là ví dụ mở rộng, **không nằm trong bảng chốt**.

## Dữ liệu và quyền

- `milestones/{id}`: `title`, `description`, `metric:verified_events`,
  `requiredEvents`, `rewardCoins`, `sortOrder`, `active`, `version`, timestamps.
  Giá trị khởi tạo từ [policy JSON](../firebase/event-milestones.json); backend
  đọc Firestore, không hard-code năm mốc trong logic/runtime mobile.
- `users/{uid}/milestone_claims/{id}`: snapshot title/description/điều kiện/xu,
  version đã nhận, count lúc nhận, claimedAt. Owner đọc, client không ghi.
- `wallets/{uid}/ledger`: thêm type **`milestone_reward`**, deltaAvailable dương,
  deltaHeld=0. Không refund hoặc trừ cọc trong claim thành tựu.
- Claim + ví + ledger + receipt commit cùng transaction. OperationKind
  `milestone`, operationId = milestone ID, không dùng requestId mới mỗi lần bấm.
  Retry/kết nối lại/thiết bị khác trả receipt cũ; không cộng thêm xu.
- `milestone_admins/{uid}` = `{active:true}` và Firebase Auth custom claim
  `admin:true` cùng bắt buộc để quản lý. Không tự nâng quyền hoặc gán role cho
  tài khoản chưa được chủ dự án chỉ định. Firebase IAM owner vẫn có thể quản lý
  catalog trong Console, nhưng thay đổi phải tăng version và giữ nguyên IDs/
  snapshots; nên dùng API để có audit và optimistic locking. App admin sau này
  gọi API được bảo vệ. Chưa gán milestone-admin role cho tài khoản thật nào.
- `milestone_audit/{id}` lưu người sửa, before/after, action và thời gian,
  server-only. Không để actor UID/audit trong public milestone documents.
- Firestore Rules chỉ public-read definitions active; owner-read claim của mình;
  deny mọi client mutation, cross-UID, đọc role/audit và ghi ví trực tiếp.

## API v1 — region asia-southeast1

### `getEventMilestones({})`

Cần account active đã initialize/onboard. Trả:

```text
verifiedEventCount, totalMilestones, unlockedCount, claimedCount,
currentMilestone, nextMilestone, items[]
```

Mỗi item chứa definition và `progress`, `progressPercent` (0–100),
`remainingEvents`, `unlocked`, `claimed`, `canClaim`, `claimedAt`,
`claimedRewardCoins`. `currentMilestone` là mốc cao nhất đã đạt;
`nextMilestone` là mốc thấp nhất chưa đạt, null nếu đã đạt hết.
Card 3/5 và 60% lấy từ nextMilestone; danh sách lấy items, không ghi số 5 cố định.

Các mốc đã nhận dùng snapshot điều kiện/xu/tên/version lúc nhận để không thay đổi
lịch sử khi admin chỉnh definition. Mốc inactive được ẩn khỏi danh sách hiện tại;
claim/ledger cũ vẫn tồn tại. Danh mục hiện nhỏ, đọc toàn bộ; khi hàng trăm mốc cần
phân trang/projection, không dùng mock để lấp dữ liệu.

### `claimEventMilestone({milestoneId, expectedVersion})`

Lấy version từ item chưa nhận. Backend đọc lại definition, xác minh attendance,
trạng thái active và version trước khi cấp xu. Trả
`{milestoneId, coinsGranted, claimedAt, wallet}`.

Lỗi: `UNAUTHENTICATED`, `ONBOARDING_REQUIRED`, `MILESTONE_NOT_FOUND`,
`MILESTONE_INACTIVE`, `MILESTONE_NOT_UNLOCKED`, `MILESTONE_CHANGED`,
`MILESTONE_CONFIG_INVALID`. Config đổi trả MILESTONE_CHANGED/currentVersion:
tải lại danh sách và cho người dùng xem mức mới trước khi nhận.

Retry cùng milestone ID luôn trả receipt lần nhận đầu, kể cả definition đã đổi
version sau đó. Wallet trong receipt là snapshot lúc giao dịch; lấy getAccount/
wallet stream để cập nhật số dư hiện tại, không tự cộng coinsGranted ở app.
Khôi phục kết quả: `getOperationStatus({operationKind:'milestone',operationId:id})`.

### `upsertEventMilestone({milestone, expectedVersion})`

Chỉ admin có quyền như trên và app profile active. Milestone input gồm
`id,title,description?,metric,requiredEvents,rewardCoins,sortOrder?,active?`.
Tạo mới dùng expectedVersion=0; sửa dùng version hiện tại. Version conflict
trả `VERSION_CONFLICT` để tránh ghi đè thay đổi của admin khác.

Admin có thể thêm mốc, sửa metadata/điều kiện/xu hoặc ẩn bằng active=false mà
không build lại app, trong loại metric đã hỗ trợ. Thay đổi kinh tế chỉ ảnh hưởng
người **chưa nhận**; snapshots đã nhận không đổi. Giữ cùng ID thì không được nhận
lại; ID mới nghĩa là một thành tựu khác. Không xóa/reuse ID để reset payout.
Thêm kiểu mục tiêu như “3 CLB khác nhau” cần logic mới, không chỉ cấu hình.

## Remote Config

Hai keys client template và defaults:

| Key | Giá trị ban đầu | Vai trò |
|---|---|---|
| `event_milestones_enabled` | `true` | Hiện/ẩn khu vực thành tựu trong UI |
| `event_milestones_intro` | `Complete event milestones to earn extra Evia Coin.` | Nội dung giới thiệu |

Xu/điều kiện/list ở Firestore. Remote Config không có quyền cấp tiền, và cờ UI
tắt không thu hồi claim cũ hoặc thay backend authorization. Muốn ngừng nhận một
mốc dùng active=false qua backend. App cần fetch/activate và service/DI khi nối UI;
publish keys trên Firebase chưa khiến UI demo hiện tại tự dùng chúng.

## Phát hành và validation

Project đích **prm393-31822**, codebase evia. Feature thêm 3 callables và mở rộng
getOperationStatus; các Functions/jobs cũ khác giữ deployment hiện có. Publish
năm definitions owner-approved là dữ liệu policy thật, không phải seed events/
users/attendance. Không cấp xu hoặc tạo tài khoản thử nghiệm trên cloud.

**Đã phát hành và kiểm tra cloud ngày 05/11/2026:**

- TypeScript build + Emulator **41/41 PASS**, không skip:
  [log release](../evidence/event-milestones/emulator-tests-release.log).
- Selective deploy 3 Functions mới và getOperationStatus; **37/37 Functions
  ACTIVE**. Bốn Functions thay đổi có Cloud Run latest created = latest ready,
  terminal condition SUCCEEDED. Không redeploy hai scheduled jobs hoặc Functions
  khác; vì vậy không yêu cầu cả 37 Functions có cùng source hash.
- Rules đã release; composite attendance index **READY**. Truy vấn aggregate
  đúng filter UID/mode/verifiedAt chạy trên cloud, probe UID không tồn tại trả 0;
  không tạo user hoặc attendance giả để test.
- Năm policy documents đúng IDs/ngưỡng/xu, public active reads HTTP 200;
  ghi client trực tiếp bị từ chối HTTP 403. Ba API mới từ chối anonymous HTTP 401.
- Hai keys Remote Config đã validate và publish **client template version 1**,
  có backup template/catalog trống trước khi apply; merge bằng ETag, không force.
- Production dependency audit: **6 moderate, 0 high/critical**; giữ dependencies
  hiện có, không force-upgrade trong task này. `git diff --check` đạt.

Metadata và giới hạn chính xác:
[cloud-verification.json](../evidence/event-milestones/cloud-verification.json),
[các logs/script](../evidence/event-milestones/README.md).
Nhận thưởng có Auth thật trên mobile, Flutter integration/Remote Config fetch,
giao diện admin và cấp admin role chưa thực hiện. Claim tích cực được kiểm chứng
trên Emulator; không lấy deployment, public smoke hoặc ảnh demo làm mobile E2E.
