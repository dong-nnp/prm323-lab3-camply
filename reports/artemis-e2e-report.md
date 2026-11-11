# Báo cáo Kiểm thử E2E ARTEMIS — EVIA (`TC01`–`TC19`)

> [!IMPORTANT]
> **Trạng thái sửa lỗi: CHƯA SỬA MÃ NGUỒN (Chỉ ghi nhận kết quả & hướng dẫn khắc phục).**
> Toàn bộ 19 test case (21 biến thể) dưới đây được thực thi trên bản build thật (`FIREBASE_ENABLED=true`) mà **không sửa code app (`lib/`, `functions/`, `firebase/`)** trước hoặc sau khi chạy test. Mọi lỗi/vấn đề phát hiện chỉ được ghi nhận kèm phân tích nguyên nhân và phương án sửa ở [Mục 4](#4-tổng-hợp-lỗi--vấn-đề-chưa-sửa-và-hướng-dẫn-khắc-phục).

---

## 1. Thông tin phiên kiểm thử

- **Ngày thực hiện:** `2026-11-11` (`14:23:29` → `18:10:04` `+07:00`)
- **Ứng dụng mục tiêu:** EVIA (`com.example.prm393_lab03`, `versionName=0.1.0`, `FIREBASE_ENABLED=true`)
- **Thiết bị vật lý:** Samsung Galaxy A13 (`SM-A135F`, Serial `R58T80PE55F`, Android 14, không lắp SIM — dùng Wi-Fi)
- **Tài khoản kiểm thử Android:** `phuc250805@gmail.com` (`Phuc Tran Dinh`)
- **Admin Web đối ứng:** `https://admin-evia.vercel.app/` (kiểm thử chéo qua Chrome MCP)
- **Công cụ điều phối:** Google ARTEMIS (`Flash` mặc định cho 18 TCs; `Pro` cho `TC19` + `Flash` xác minh bổ sung)
- **Thư mục ảnh chứng cứ của phiên chạy:** [`evidence-2026-11-11/`](evidence-2026-11-11/) (`40` ảnh đã đối chiếu trực quan theo từng bước trace)
- **Phạm vi báo cáo:** Phản ánh toàn bộ **phiên hồi quy đầy đủ ngày `2026-11-11`** (`19/19` TCs với `FIREBASE_ENABLED=true`).

---

## 2. Thời gian chạy kiểm thử (`Test Duration`)

| Chỉ số thời gian | Giá trị quan sát thực tế | Ghi chú / Phạm vi tính |
| --- | --- | --- |
| **Tổng thời gian phiên làm việc (Wall-clock)** | **`3 giờ 46 phút 35 giây`** | Từ trace đầu tiên `14:23:29` (`f8832ee0`) đến trace cuối `18:10:04` (`94e8d1c9`) ngày `2026-11-11`. |
| **Khoảng tạm dừng đổi model / chờ quota** | **`79 phút 29 giây`** | Từ `15:03:53` (lỗi quota ở `065b49ce` — `TC08`) đến `16:23:22` (`e4dddd4c`). |
| **Thời gian vận hành liên tục thực tế (Wall-clock trừ thời gian nghỉ)** | **`~2 giờ 27 phút`** | Bao gồm toàn bộ thời gian ARTEMIS chạy trên thiết bị, thao tác chuẩn bị/xác minh trên Admin Web (`#events`, `#checkin`, `#config`), `adb` và kiểm tra log. |
| **Tổng thời gian ARTEMIS chạy thực tế (toàn bộ `41` traces)** | **`4,665.1 giây` (`77 phút 45.1 giây`)** | Cộng dồn `end_time - start_time` trong `status.json` của cả `41` traces (gồm `2` pre-check ban đầu, các lần chạy thử/bị hủy và các lần chạy chính thức). |
| **Tổng thời gian ARTEMIS của riêng các traces hiệu lực (`TC01`–`TC19`)** | **`3,374.2 giây` (`56 phút 14.2 giây`)** | Tính tổng `24` traces hiệu lực (kể cả `23bbc0ca` chuẩn bị trạng thái *I'm Going* cho `TC17`), loại trừ `2` pre-check ban đầu và các lần retry/cancelled trước đó. |

---

## 3. Tổng kết Pass / Failed (`19` Test Cases / `21` biến thể)

> Lưu ý cách đếm: Bộ test [`e2e_test/cases.py`](../e2e_test/cases.py) có **19 Test Cases (`TC01`–`TC19`)**, riêng **`TC17`** kiểm thử trên **3 trạng thái vòng đời push (`foreground`, `background`, `terminated`)**, nâng tổng số biến thể thực thi lên **21 biến thể**.

| Nhóm kết quả | Số Test Case (`19` TCs) | Số biến thể (`21` biến thể) | Danh sách cụ thể |
| --- | --- | --- | --- |
| **PASSED hoàn toàn** | **15** | **17** | `TC01`, `TC02`, `TC04`, `TC05`, `TC06`, `TC07`, `TC08`, `TC09`, `TC10`, `TC12`, `TC13`, `TC14`, `TC16`, `TC17` (`foreground`, `background`, `terminated`), `TC18` |
| **PASSED kèm vấn đề phụ** (`PARTIAL / UX / BACKEND BUG`) | **3** | **3** | **`TC03`** (Search PASS / thiếu Analytics `'search'`), **`TC11`** (QR Check-in PASS / Admin Web nhập tay ticket HTTP `404`), **`TC19`** (Offline error & recovery PASS / UX `EviaSkeleton` đè `AppErrorWidget`) |
| **FAILED** | **1** | **1** | **`TC15`** (Lưu CSV nội bộ SAF PASS, nhưng upload lên Firebase Cloud Storage **FAILED**) |
| **Tổng cộng** | **19** | **21** | **18 / 19 TCs đạt luồng chính trên app; 1 / 19 TC FAILED (`TC15`); 4 điểm cần sửa (`TC15`, `TC11`, `TC03`, `TC19`)** |

---

## 4. Tổng hợp lỗi / vấn đề (CHƯA SỬA) và hướng dẫn khắc phục

**Tất cả 4 vấn đề dưới đây đều CHƯA ĐƯỢC SỬA trong repository.**

### 4.1. `TC15` [FAILED] — Lưu CSV cục bộ chạy được, nhưng upload Firebase Cloud Storage chưa được tích hợp

- **Hiện tượng quan sát:**
  - Nút xuất CSV trên `Coin History` tạo file local thành công qua Android Storage Access Framework (`/sdcard/Download/evia-coin-history.csv`, dung lượng `388` bytes, UTF-8 BOM `\ufeffdate,kind,coins`, 10 giao dịch), UI báo `"Đã lưu báo cáo CSV (10 giao dịch đã tải)."`.
  - Tuy nhiên **không có thao tác upload nào lên Firebase Cloud Storage (`reports/{uid}/...`)**.
- **Nguyên nhân gốc rễ đã kiểm chứng trong code:**
  1. Tại [`lib/core/providers/service_providers.dart`](../lib/core/providers/service_providers.dart#L85-L87), `storageServiceProvider` vẫn đang trỏ vào `_pendingServicesProvider` ([`PendingFirebaseServices`](../lib/services/pending_firebase_services.dart#L21-L30), trả lỗi `firebase_service_pending`).
  2. [`ReportExportRepository`](../lib/repositories/report_export_repository.dart#L7-L21) và [`ReportExportViewModel`](../lib/viewmodels/report_export_view_model.dart#L39-L50) hiện chỉ gọi `ReportExportService.saveCsv(bytes)` qua MethodChannel Android rồi ghi analytics `'generate_report'`, chưa gọi hợp đồng [`StorageService.upload(...)`](../lib/services/storage_service.dart#L3-L8).
  3. Tại [`firebase/storage.rules`](../firebase/storage.rules#L18-L27), nhánh `/reports/{uid}/{fileName}` hiện chỉ cho phép `contentType == 'application/pdf'` và tên file khớp `[A-Za-z0-9_-]+[.]pdf` (tối đa 5 MB); mọi định dạng khác bị rule cuối `allow read, write: if false;` từ chối.
- **Trạng thái:** **Chưa sửa.**
- **Hướng dẫn sửa:**
  1. Tạo adapter `FirebaseStorageService` implement [`StorageService`](../lib/services/storage_service.dart#L3-L8) sử dụng `firebase_storage` (đã khai báo `firebase_storage: ^14.0.1` trong [`pubspec.yaml`](../pubspec.yaml#L19)).
  2. Chuyển [`storageServiceProvider`](../lib/core/providers/service_providers.dart#L85-L87) sang trả về `FirebaseStorageService` khi `realBackendEnabledProvider` là `true`.
  3. Mở rộng [`ReportExportRepository`](../lib/repositories/report_export_repository.dart) / [`ReportExportViewModel`](../lib/viewmodels/report_export_view_model.dart) để gọi `StorageService.upload(path: 'reports/$uid/$fileName', bytes: ..., contentType: ...)` song song hoặc kết hợp xuất local SAF, kèm hiển thị trạng thái lỗi rõ ràng nếu upload thất bại.
  4. Nếu giữ định dạng `.csv` khi upload lên Cloud Storage, cập nhật [`firebase/storage.rules`](../firebase/storage.rules#L18-L24) cho phép `text/csv` và `[A-Za-z0-9_-]+[.]csv` (hoặc tạo PDF theo rule `.pdf` hiện có), rồi chạy `firebase deploy --only storage`.

---

### 4.2. `TC11` [PASSED QR / BUG ADMIN WEB] — Nhập tay Ticket Number trên Admin Web bị HTTP `404`

- **Hiện tượng quan sát:**
  - Check-in bằng QR (`verifyRegisteredTicket`) chạy thành công (lần 1 HTTP `200`, `coinsGranted: 60`, `depositRefunded: 50`; lần 2 HTTP `409 ALREADY_CHECKED_IN`), app cập nhật `Attendance confirmed` và ví lên `160 coins`.
  - Khi kiểm tra luồng nhập tay số vé `EV-0136E01E5D6C` trên Admin Web `#checkin`, trình duyệt gọi `https://asia-southeast1-prm393-31822.cloudfunctions.net/verifyAdminTicketNumber` và gặp lỗi **HTTP `404` (`net::ERR_FAILED`)**.
- **Nguyên nhân gốc rễ đã kiểm chứng trong code:**
  - Hàm `verifyAdminTicketNumber` **đã được cài đặt và export sẵn** trong mã nguồn tại [`functions/src/events.ts`](../functions/src/events.ts#L150-L169) và [`functions/src/index.ts`](../functions/src/index.ts#L62) (ngay cạnh `verifyRegisteredTicket` ở dòng 61 vốn đang hoạt động bình thường). Việc endpoint Cloud Functions trả về HTTP `404` cho thấy bản Cloud Functions hiện đang chạy trên Firebase project `prm393-31822` **chưa được deploy lại** sau khi bổ sung hàm này.
- **Trạng thái:** **Chưa sửa.**
- **Hướng dẫn sửa:**
  1. Kiểm tra lại cấu hình region (`asia-southeast1`) và build TypeScript trong thư mục `functions/`.
  2. Chạy `firebase deploy --only functions:verifyAdminTicketNumber` (hoặc `firebase deploy --only functions`) để xuất bản endpoint còn thiếu lên project `prm393-31822`.
  3. Mở Admin Web `#checkin`, nhập tay một mã vé `EV-...` hợp lệ để xác nhận trả HTTP `200` (hoặc `409 ALREADY_CHECKED_IN` nếu vé đã quét).

---

### 4.3. `TC03` [PASSED SEARCH / GAP ANALYTICS] — `Search & Explore` chưa bắn sự kiện Firebase Analytics `'search'`

- **Hiện tượng quan sát:**
  - Gõ `"Flutter"` trả kết quả `"2 events found"` đúng dữ liệu Firestore/backend.
  - Tuy nhiên khi theo dõi Logcat (`FA-SVC`) và kiểm tra mã nguồn, thao tác tìm kiếm không phát sự kiện `'search'` lên Firebase Analytics (trong khi `view_event` và `view_reward` ở `TC06` vẫn log bình thường qua `FA-SVC`).
- **Nguyên nhân gốc rễ đã kiểm chứng trong code:**
  1. [`AnalyticsEvents._schema`](../lib/models/analytics_events.dart#L3-L22) hiện chưa định nghĩa sự kiện `'search'` (nếu gọi `analytics.track('search', ...)` trực tiếp, [`AnalyticsEvents.validate`](../lib/models/analytics_events.dart#L57-L60) sẽ ném `ArgumentError`).
  2. [`EviaExploreScreen`](../lib/screens/evia/explore_screen.dart#L52-L80) và [`flow1SearchProvider`](../lib/viewmodels/flow1_view_model.dart#L242-L245) hiện không đọc hoặc gọi `analyticsRepositoryProvider`.
- **Trạng thái:** **Chưa sửa.**
- **Hướng dẫn sửa:**
  1. Thêm `'search'` vào `AnalyticsEvents._schema` (với tham số không chứa PII như `category`, `result_count` theo quy định tại dòng 1 file [`analytics_events.dart`](../lib/models/analytics_events.dart#L1)).
  2. Kết nối `analyticsRepositoryProvider` trong ViewModel phụ trách tìm kiếm để gọi `track('search', ...)` khi kết quả tìm kiếm trả về hợp lệ.
  3. Cập nhật [`docs/analytics-plan.md`](../docs/analytics-plan.md) và kiểm tra lại với Firebase DebugView / Logcat `FA-SVC`.

---

### 4.4. `TC19` [PASSED / UX NOTE] — `EviaSkeleton` xếp trên `AppErrorWidget` đẩy nút `'Thử lại'` xuống ngoài màn hình

- **Hiện tượng quan sát:**
  - Khi tắt Wi-Fi (`svc wifi disable`) và tìm `"EVIA_OFFLINE_6f0a9dc2"`, app hiển thị đúng thông báo lỗi từ `FirebaseBackendService`: `"Cannot reach the service. Check your connection and retry."`.
  - Tuy nhiên, khi trạng thái loading và error xuất hiện cùng nhau trên `EviaExploreScreen`, phần khung xương `EviaSkeleton()` chiếm nửa trên màn hình và đẩy `AppErrorWidget` cùng nút **`Thử lại`** xuống quá chiều cao màn hình ban đầu (`y > 2408` khi chưa cuộn). Ngoài ra, khi bật lại Wi-Fi (`svc wifi enable`), provider tự động tải lại danh sách trước khi người dùng kịp bấm nút `Thử lại`. (Ở một lần test full-screen error độc lập, nút `'Thử lại'` hiện rõ giữa màn hình tại `[400,567][600,624]` và phục hồi về `Discover` khi bấm sau lúc có mạng).
- **Nguyên nhân gốc rễ đã kiểm chứng trong code:**
  - Tại [`lib/screens/evia/explore_screen.dart`](../lib/screens/evia/explore_screen.dart#L247-L253), hai lệnh `if` đứng nối tiếp nhau nên có thể render cùng lúc:
    ```dart
    if (remote?.isLoading == true && remote?.hasValue != true)
      const EviaSkeleton(),
    if (remote?.hasError == true)
      AppErrorWidget(
        message: ExceptionMapper.map(remote!.error!).message,
        onRetry: () => ref.invalidate(flow1SearchProvider(input)),
      ),
    ```
- **Trạng thái:** **Chưa sửa.**
- **Hướng dẫn sửa:**
  1. Đổi cấu trúc điều kiện thành ưu tiên hiển thị lỗi rõ ràng (không xếp chồng `EviaSkeleton()` phía trên `AppErrorWidget`):
     ```dart
     if (remote?.hasError == true && remote?.isLoading != true)
       AppErrorWidget(...)
     else if (remote?.isLoading == true && remote?.hasValue != true)
       const EviaSkeleton(),
     ```
  2. Kiểm tra lại trên màn 360dp và 412dp để nút **`Thử lại`** (`AppStrings.retry` trong [`status_widgets.dart`](../lib/widgets/status_widgets.dart#L58-L60)) luôn hiển thị trọn vẹn không cần cuộn.

---

### 4.5. Ghi chú cấu hình ARTEMIS (`artemis.jsonc` — ngoài phạm vi app EVIA)

- Trong quá trình chạy, tác vụ `TC08` lúc `14:56` (`065b49ce`, `432.8s`) gặp giới hạn Free Tier (`20 req/ngày`) của model `gemini-3-flash-preview` được cấu hình cho `hopper` / `chunking` / `Pro` trong `artemis.jsonc`, gây gián đoạn `~79 phút`. Có thể đổi model dự phòng trước các đợt chạy dài tiếp theo (chưa sửa file cấu hình).

---

## 5. Kết quả chi tiết từng Test Case (`TC01`–`TC19`) kèm ảnh chứng cứ

### Bảng tóm tắt nhanh

| TC | Nội dung kiểm thử | Trace ID hiệu lực | Model | Thời gian hiệu lực (cả retry nếu có) | Trạng thái | Ghi chú chính |
| --- | --- | --- | --- | --- | --- | --- |
| **TC01** | Google Sign-In (`phuc250805@gmail.com`) | `8d179375` | Flash | `62.6s` | **PASSED** | Hiện picker Google native, vào `Discover`, greeting + `100 coins`. |
| **TC02** | Hủy Google Sign-In Picker (`BACK`) | `408dd619` | Flash | `45.2s` | **PASSED** | Hiện `"Google sign-in was cancelled."`, `signed_in=False`. |
| **TC03** | Search & Explore + Analytics | `c3b37ab8` | Flash | `39.8s` | **PASSED / GAP** | Search `"Flutter"` ra `"2 events found"`; **chưa log Analytics `'search'`**. |
| **TC04** | Search không khớp & Clear khôi phục | `b8d939ac` (`+ d50acf87`) | Flash | `70.0s` (`202.9s`) | **PASSED** | `"EVIA_NO_MATCH_6f0a9dc2"` -> `"0 events found"`, bấm xóa ra `Suggested Events`. |
| **TC05** | Điều hướng Bottom Navigation Tabs | `8760190e` | Flash | `55.3s` | **PASSED** | Đi qua `Discover` -> `Events` -> `Rewards` -> `Profile` (`phuc250805@gmail.com`). |
| **TC06** | Chi tiết Event, Organizer, Reward & Back | `5e599f06` | Flash | `206.2s` | **PASSED** | Xác minh 3 màn chi tiết và quay lại đúng luồng; log `FA-SVC` `view_event`/`view_reward`. |
| **TC07** | Save Event, Follow Organizer, Undo & Reload | `01913502` + `9c364333` | Flash | `230.0s` | **PASSED** | Lưu + theo dõi hiển thị đúng, sau khi bỏ lưu/hủy theo dõi và reload về `0`. |
| **TC08** | Đăng ký sự kiện có cọc Coin (`50 coins`) | `e4dddd4c` + `90acf51c` (`+ 065b49ce`) | Flash | `381.7s` (`814.5s`) | **PASSED** | `100 -> 50 available / 50 held`, sinh vé `EV-0136E01E5D6C`, `Upcoming 1`. |
| **TC09** | Từ chối sự kiện đã hết vé (`0 spots left`) | `1df86f72` (`+ 82809e4a, 1c447dac`) | Flash | `122.1s` (`364.1s`) | **PASSED** | `[DEMO] Workshop đã đóng số lượng vé`, nút `Registration Full` disabled, ví giữ nguyên `50/50`. |
| **TC10** | Hủy đăng ký & hoàn cọc 30% (`+15 coins`) | `0cfbb0ef` + `a53044a2` | Flash | `360.0s` | **PASSED** | `110 -> 125 available / 0 held`, `Coin History` ghi `+15 coins`, vé bị thu hồi, không hoàn trùng. |
| **TC11** | Check-in QR & thưởng Coin + Admin Web | `b7e43924` + `dc7a050c` (+ Chrome MCP) | Flash | `139.4s` | **PASSED / BUG** | QR `verifyRegisteredTicket` OK (`Attended`, `+60 coins`, `160` tổng, lần 2 `409`); **nhập tay HTTP `404`**. |
| **TC12** | Daily Check-In & chặn nhận trùng trong ngày | `28a8e3d2` | Flash | `58.9s` | **PASSED** | `125 -> 130 coins`, nút chuyển `Checked In Today · +5 coins` disabled, giữ nguyên sau chuyển tab. |
| **TC13** | Đổi thưởng tạo Voucher & trừ Coin | `fcc4064d` | Flash | `116.9s` | **PASSED** | Đổi `[DEMO] Combo nước và bánh` (`100 coins`), còn `30 coins`, voucher `Available (1)`. |
| **TC14** | Từ chối đổi quà khi không đủ Coin | `31744963` + `d4d52279` | Flash | `109.2s` | **PASSED** | `[DEMO] Áo hoodie Evia` (`800 coins`) disabled `'Not enough coins'` khi ví còn `30`. |
| **TC15** | Xuất CSV lịch sử Coin & Cloud Storage | `50d8a6b7` | Flash | `79.3s` | **FAILED** | Local SAF `/sdcard/Download/evia-coin-history.csv` (`388` bytes) OK; **Cloud Storage chưa cài đặt**. |
| **TC16** | Remote Config cập nhật live không rebuild | `51d316f5` + `f80afbe4` | Flash | `115.7s` | **PASSED** | Banner `Event Milestones` đổi live `"hello"` -> `"TC16 live config test"` và khôi phục về `"hello"`. |
| **TC17** | Push Notification (`foreground` / `background` / `terminated`) | `23bbc0ca` + `5dc350dd` + `b753de0b` + `c243ca29` + `47cee4c9` + `57000c9e` (`+ b11a22c3, b6492dac`) | Flash | `495.6s` (`612.7s`) | **PASSED** | Cả 3 trạng thái hiện shade `Lịch sự kiện thay đổi`, bấm vào đúng `[DEMO] Một ngày campus xanh` (`FG`/`BG`/`TERM-test`) và lưu vào inbox. |
| **TC18** | Sign out & kiểm tra Auth Guard | `4d0e5597` (`+ 2900b06d`) | Flash | `86.5s` (`233.9s`) | **PASSED** | Đăng xuất không còn cache user cũ; Guest bấm route bảo vệ (`Profile`) chuyển về `"Welcome back!"`. |
| **TC19** | Lỗi mạng Offline & khôi phục kết nối | `ac91fb8a` (`Pro`) + `22b0579b` + `94e8d1c9` | Pro + Flash | `599.8s` | **PASSED / UX** | Hiện đúng `"Cannot reach the service. Check your connection and retry."` và hồi phục sau bật Wi-Fi; **UX note về `EviaSkeleton`**. |

---

### Chi tiết chứng cứ & ảnh chụp màn hình từng Test Case

#### TC01 — Google Sign-In (`PASSED`, `62.6s`, Trace `8d179375-e553-4228-bfed-644458b82d7b`)
- **Kết quả:** Chạm `Log in` -> `Continue with Google` -> xuất hiện native Google account picker -> chọn `phuc250805@gmail.com` -> vào màn `Discover` với dòng chào `"Hey Phuc Tran Dinh! 👋"`, số dư `"100 coins"`, đủ 4 tab `Discover`, `Events`, `Rewards`, `Profile`.
- **Ảnh chụp màn hình:**

| Picker tài khoản Google native | Màn Discover sau khi đăng nhập thành công |
| :---: | :---: |
| ![TC01 Google Picker](evidence-2026-11-11/tc01-google-picker.jpg) | ![TC01 Discover Signed In](evidence-2026-11-11/tc01-discover-signed-in.jpg) |

---

#### TC02 — Hủy Google Sign-In Picker (`PASSED`, `45.2s`, Trace `408dd619-e02f-4468-aef4-a9781c44b181`)
- **Kết quả:** Mở Google account picker rồi nhấn nút hệ thống `BACK`. App quay lại màn `Welcome back!`, hiển thị thông báo đỏ `"Google sign-in was cancelled."` và giữ trạng thái chưa đăng nhập (`signed_in=False`).
- **Ảnh chụp màn hình:**

![TC02 Google Sign-In Cancelled](evidence-2026-11-11/tc02-google-cancelled.jpg)

---

#### TC03 — Search & Explore + Analytics (`PASSED SEARCH / GAP ANALYTICS`, `39.8s`, Trace `c3b37ab8-3d00-457f-a9d3-c11fb433381e`)
- **Kết quả:**
  - **Tìm kiếm (PASS):** Gõ `"Flutter"` vào `Search & Explore` trả về `"2 events found"`: `[DEMO] Workshop Flutter đang mở check-in` và `[DEMO] Flutter và Firebase từ cơ bản`.
  - **Analytics (GAP — CHƯA SỬA):** Không ghi nhận sự kiện `'search'` lên Firebase Analytics (xem chi tiết ở [Mục 4.3](#43-tc03-passed-search--gap-analytics--search--explore-chưa-bắn-sự-kiện-firebase-analytics-search)).
- **Ảnh chụp màn hình:**

![TC03 Search Flutter Results](evidence-2026-11-11/tc03-search-flutter.jpg)

---

#### TC04 — Search không có kết quả & khôi phục (`PASSED`, `70.0s` hiệu lực / `202.9s` gồm lần thử trước, Trace `b8d939ac-467b-4ed1-8d84-a565b2ea3728`)
- **Kết quả:** Nhập chuỗi không tồn tại `EVIA_NO_MATCH_6f0a9dc2` hiển thị `"0 events found"` + `"No events found"`. Chạm nút `X` (`Clear search`) xóa truy vấn và khôi phục danh sách `Suggested Events`.
- **Ảnh chụp màn hình:**

| Trạng thái `0 events found` | Khôi phục `Suggested Events` sau khi xóa truy vấn |
| :---: | :---: |
| ![TC04 No Match](evidence-2026-11-11/tc04-search-nomatch.jpg) | ![TC04 Search Recovered](evidence-2026-11-11/tc04-search-recovered.jpg) |

---

#### TC05 — Điều hướng Bottom Navigation Tabs (`PASSED`, `55.3s`, Trace `8760190e-d82e-4362-a1b5-40089faa16b3`)
- **Kết quả:** Điều hướng tuần tự qua cả 4 tab `Discover` -> `Events` -> `Rewards` -> `Profile`, dừng lại tại tab `Profile` hiển thị đúng tên `Phuc Tran Dinh` và email `phuc250805@gmail.com`.
- **Ảnh chụp màn hình:**

![TC05 Profile Tab Selected](evidence-2026-11-11/tc05-profile-tab.jpg)

---

#### TC06 — Xem chi tiết Event, Organizer, Reward & nút Back (`PASSED`, `206.2s`, Trace `5e599f06-4870-4e86-a708-6b3f3daaaca1`)
- **Kết quả:** Mở chi tiết sự kiện `[DEMO] Giao lưu Badminton` (`Nov 11, 2026 · 16:00`), bấm xem nhà tổ chức `[DEMO] CLB Thể thao Evia`, điều hướng Back về `Discover`, mở tiếp phần thưởng `[DEMO] Combo nước và bánh` (`100 coins`) rồi quay lại `Rewards`. `FA-SVC` ghi nhận live event `view_event` và `view_reward`.
- **Ảnh chụp màn hình:**

| Event Detail | Organizer Detail | Reward Detail |
| :---: | :---: | :---: |
| ![TC06 Event Detail](evidence-2026-11-11/tc06-event-detail.jpg) | ![TC06 Organizer Detail](evidence-2026-11-11/tc06-organizer-detail.jpg) | ![TC06 Reward Detail](evidence-2026-11-11/tc06-reward-detail.jpg) |

---

#### TC07 — Save Event, Follow Organizer, Undo & Reload (`PASSED`, `230.0s`, Trace `01913502-8e05-4d4f-aa1f-3dd01cd1232f` + `9c364333-a6d5-4fd9-b5a9-14ec4f43afb7`)
- **Kết quả:** Đánh dấu lưu `[DEMO] Giao lưu Badminton` và theo dõi `[DEMO] CLB Thể thao Evia`, xác minh xuất hiện tại `Saved Events` (`1 saved events`) và `Followed Organizers` (`1 Active`); sau đó bỏ lưu + hủy theo dõi và thoát ra mở lại để xác nhận trạng thái bền vững (`0 saved events`, `0 Active`).
- **Ảnh chụp màn hình:**

| Saved Events (1) | Followed Organizers (1) | Sau khi Undo & Reload (0) |
| :---: | :---: | :---: |
| ![TC07 Saved Events](evidence-2026-11-11/tc07-saved-events.jpg) | ![TC07 Followed Organizers](evidence-2026-11-11/tc07-followed-organizers.jpg) | ![TC07 Undo Reload Empty](evidence-2026-11-11/tc07-undo-reload-empty.jpg) |

---

#### TC08 — Đăng ký sự kiện có giữ cọc Coin (`PASSED`, `381.7s` hiệu lực / `814.5s` gồm trace lỗi quota `065b49ce`, Trace `e4dddd4c-6e57-4fbb-b380-6a5af35995c7` + `90acf51c-f36f-4800-b626-dc8232d115bc`)
- **Kết quả:** Đăng ký `[DEMO] Giao lưu Badminton` (cọc `50 coins`), tick đồng ý điều khoản cọc -> ví chuyển từ `100 available / 0 held` thành `50 available / 50 held`, tạo vé QR `EV-0136E01E5D6C` dưới mục `Upcoming (1)`.
- **Ảnh chụp màn hình:**

| Ví `50 available / 50 In Deposits` | Vé điện tử QR `EV-0136E01E5D6C` |
| :---: | :---: |
| ![TC08 Wallet Held](evidence-2026-11-11/tc08-wallet-held.jpg) | ![TC08 Ticket QR](evidence-2026-11-11/tc08-ticket-qr.jpg) |

---

#### TC09 — Từ chối đăng ký sự kiện đã đầy (`PASSED`, `122.1s` hiệu lực / `364.1s` gồm các lần kiểm tra trước khi Admin chỉnh `capacity=0`, Trace `1df86f72-ae5f-4b35-8683-ed82b68185f3`)
- **Kết quả:** Mở `[DEMO] Workshop đã đóng số lượng vé` (`demo-full-event`), giao diện hiển thị `0 spots left`, nút CTA `Registration Full` bị khóa (disabled), không sinh vé mới và ví giữ nguyên `50 available / 50 held`.
- **Ảnh chụp màn hình:**

![TC09 Registration Full Disabled](evidence-2026-11-11/tc09-registration-full.jpg)

---

#### TC10 — Hủy đăng ký & hoàn cọc 30% (`PASSED`, `360.0s`, Trace `0cfbb0ef-814a-471d-bb83-edae215e2685` + `a53044a2-aa4c-4a45-8a3b-622344415d95`)
- **Kết quả:** Đăng ký thêm `[DEMO] Workshop tư duy thiết kế` (cọc `50 coins`, ví `160 -> 110 available / 50 held`), mở hộp thoại `Cancel Registration?` và xác nhận `Yes, Cancel`. Số dư hoàn 30% thành `125 available / 0 held`, `Coin History` ghi `"Cancellation refund · 30% +15 coins"`, vé bị thu hồi (`Upcoming 2 -> 1`, `Past 1`), không hoàn tiền lặp lần hai (`refunded_twice=False`).
- **Ảnh chụp màn hình:**

| Hộp thoại xác nhận hoàn 30% | `Coin History` ghi nhận `+15 coins` & hết giữ cọc |
| :---: | :---: |
| ![TC10 Cancel Dialog](evidence-2026-11-11/tc10-cancel-dialog.jpg) | ![TC10 Coin History Refund](evidence-2026-11-11/tc10-coin-history-refund.jpg) |

---

#### TC11 — Check-in QR & cộng thưởng Coin (`PASSED QR / BUG ADMIN WEB 404`, `139.4s` ARTEMIS + Admin Web Chrome MCP, Trace `b7e43924-5d31-414f-abb9-87c656bf8f35` + `dc7a050c-456e-4d5e-b3f2-846227904cd6`)
- **Kết quả:**
  - **QR Check-in (PASS):** Dùng mã QR vé `EV-0136E01E5D6C` trên Android gửi tới callable `verifyRegisteredTicket` (lần 1 HTTP `200`: `coinsGranted: 60, depositRefunded: 50`; lần 2 HTTP `409 ALREADY_CHECKED_IN`). Trên app vé chuyển thành `Attendance confirmed`, ví tăng từ `50 available / 50 held` lên `160 available / 0 held`.
  - **Admin Web nhập tay số vé (BUG — CHƯA SỬA):** Form nhập tay `EV-...` gọi `verifyAdminTicketNumber` gặp HTTP `404` trên endpoint Cloud Functions (xem [Mục 4.2](#42-tc11-passed-qr--bug-admin-web--nhập-tay-ticket-number-trên-admin-web-bị-http-404)).
- **Ảnh chụp màn hình:**

| QR trước khi scan | Vé chuyển `Attendance confirmed` | Ví sau check-in: `160 coins` |
| :---: | :---: | :---: |
| ![TC11 Ticket QR](evidence-2026-11-11/tc11-ticket-qr.jpg) | ![TC11 Ticket Attended](evidence-2026-11-11/tc11-ticket-attended.jpg) | ![TC11 Rewards 160](evidence-2026-11-11/tc11-rewards-160.jpg) |

---

#### TC12 — Daily Check-In & chặn nhận trùng trong ngày (`PASSED`, `58.9s`, Trace `28a8e3d2-fa06-4e8f-8948-3dff62422a95`)
- **Kết quả:** Bấm `Check In · +5 coins`, ví tăng từ `125 -> 130 coins`, nút chuyển thành trạng thái disabled `'Checked In Today · +5 coins'` và vẫn giữ nguyên trạng thái khóa sau khi chuyển tab qua lại (`second_grant=False`).
- **Ảnh chụp màn hình:**

![TC12 Daily Check-In Completed](evidence-2026-11-11/tc12-daily-checkin.jpg)

---

#### TC13 — Đổi thưởng tạo Voucher & trừ Coin (`PASSED`, `116.9s`, Trace `fcc4064d-d610-4aeb-801f-1d63b61fe536`)
- **Kết quả:** Chọn đổi `[DEMO] Combo nước và bánh` (`100 coins`), xác nhận tại modal `Confirm Redemption` (`130 - 100 = 30 coins`), voucher được tạo trong `My Rewards` dưới tab `Available (1)` và nút Back trả về đúng màn `Rewards`.
- **Ảnh chụp màn hình:**

| Modal xác nhận đổi quà (`130 -> -100`) | Voucher xuất hiện tại `My Rewards -> Available (1)` |
| :---: | :---: |
| ![TC13 Confirm Redemption](evidence-2026-11-11/tc13-confirm-redemption.jpg) | ![TC13 My Rewards Voucher](evidence-2026-11-11/tc13-my-rewards-voucher.jpg) |

---

#### TC14 — Từ chối đổi quà đắt hơn số dư Coin (`PASSED`, `109.2s`, Trace `31744963-6db8-4632-9123-3b9490e920dc` + `d4d52279-6586-48af-a004-19890865d641`)
- **Kết quả:** Mở `[DEMO] Áo hoodie Evia` (`800 coins`) khi ví hiện còn `30 coins` -> nút bấm khóa ở trạng thái disabled `'Not enough coins'`, không thể đổi, danh sách voucher `Available (1)` không đổi.
- **Ảnh chụp màn hình:**

![TC14 Not Enough Coins Disabled](evidence-2026-11-11/tc14-not-enough-coins.jpg)

---

#### TC15 — Xuất báo cáo lịch sử Coin & Cloud Storage (`FAILED`, `79.3s`, Trace `50d8a6b7-46d8-4d42-8572-11d4832949bd`)
- **Kết quả:**
  - **Xuất file cục bộ SAF (Đạt phần phụ):** Lưu thành công `/sdcard/Download/evia-coin-history.csv` (`388` bytes, 10 giao dịch), app hiển thị `"Đã lưu báo cáo CSV (10 giao dịch đã tải)."`.
  - **Firebase Cloud Storage (FAILED — CHƯA SỬA):** Không upload lên bucket `reports/{uid}/...` vì `storageServiceProvider` vẫn trỏ `PendingFirebaseServices` (`firebase_service_pending`) và `firebase/storage.rules` chỉ cho phép `.pdf` (xem chi tiết ở [Mục 4.1](#41-tc15-failed--lưu-csv-cục-bộ-chạy-được-nhưng-upload-firebase-cloud-storage-chưa-được-tích-hợp)).
- **Ảnh chụp màn hình:**

![TC15 Local CSV Export Only](evidence-2026-11-11/tc15-local-csv-export.jpg)

---

#### TC16 — Remote Config cập nhật live không cần rebuild APK (`PASSED`, `115.7s`, Trace `51d316f5-9d72-4412-922b-722a2951b8b3` + `f80afbe4-cc0d-4f2b-9551-882d59b81164`)
- **Kết quả:** Trước khi đổi trên Firebase Console / Admin Config, banner đầu màn `Event Milestones` hiển thị `"hello"`. Sau khi publish cấu hình mới và mở lại mà **không rebuild APK (`app_rebuilt=False`)**, banner tự cập nhật live thành `"TC16 live config test"` (sau đó đã khôi phục lại giá trị `"hello"`).
- **Ảnh chụp màn hình:**

| Trước khi cập nhật (`"hello"`) | Sau khi publish live (`"TC16 live config test"`, không rebuild) |
| :---: | :---: |
| ![TC16 Before Hello](evidence-2026-11-11/tc16-before-hello.png) | ![TC16 After Live Config](evidence-2026-11-11/tc16-after-live-config.jpg) |

---

#### TC17 — Push Notification theo 3 trạng thái (`foreground`, `background`, `terminated`) (`PASSED 3/3`, `495.6s` hiệu lực / `612.7s` tổng cả retry)
- **Chuẩn bị (`23bbc0ca`, `102.7s`):** Chọn `I'm Going` trên `[DEMO] Một ngày campus xanh` (`demo-green-campus`) để thiết bị đăng ký nhận cập nhật lịch/địa điểm qua FCM.
- **Biến thể `TC17_foreground` (`5dc350dd`, `67.8s`):** Đang mở app, sửa địa điểm sang `[DEMO] Sảnh sinh viên (FG-test)` trên Admin Web -> nhận thông báo Android shade lúc `17:32` (`Lịch sự kiện thay đổi` / `Sự kiện bạn tham gia vừa cập nhật thời gian hoặc địa điểm.`) -> chạm vào mở đúng `[DEMO] Một ngày campus xanh` với địa điểm `FG-test` -> lưu trong inbox `Notifications` (`Today · 5 new`).
- **Biến thể `TC17_background` (`b753de0b`, `88.5s`):** Đưa app ra nền, sửa sang `[DEMO] Sảnh sinh viên (BG-test)` -> shade `17:37` -> chạm mở đúng `[DEMO] Sảnh sinh viên (BG-test)` -> lưu trong inbox (`Today · 6 new`).
- **Biến thể `TC17_terminated` (`c243ca29` + `47cee4c9` + `57000c9e`, `236.6s`):** Tắt hẳn tiến trình EVIA (`force-stop`), sửa sang `[DEMO] Sảnh sinh viên (TERM-test)` -> shade `17:42` -> chạm khởi động lạnh mở đúng `[DEMO] Sảnh sinh viên (TERM-test)` -> lưu trong inbox (`Today · 7 new`) và Back về `Discover` (đã khôi phục địa điểm gốc `[DEMO] Sảnh sinh viên` sau test).
- **Ảnh chụp màn hình:**

| Foreground: Shade | Foreground: Inbox (`5 new`) | Background: Shade (`17:37`) | Background: Event Detail (`BG-test`) |
| :---: | :---: | :---: | :---: |
| ![TC17 FG Shade](evidence-2026-11-11/tc17-fg-shade.jpg) | ![TC17 FG Inbox](evidence-2026-11-11/tc17-fg-inbox.jpg) | ![TC17 BG Shade](evidence-2026-11-11/tc17-bg-shade.jpg) | ![TC17 BG Event](evidence-2026-11-11/tc17-bg-event-detail.jpg) |

| Terminated: Shade (`17:42`) | Terminated: Event Detail (`TERM-test`) | Terminated: Inbox (`7 new`) |
| :---: | :---: | :---: |
| ![TC17 Term Shade](evidence-2026-11-11/tc17-term-shade.jpg) | ![TC17 Term Event](evidence-2026-11-11/tc17-term-event-detail.jpg) | ![TC17 Term Inbox](evidence-2026-11-11/tc17-term-inbox.jpg) |

---

#### TC18 — Sign out & Auth Guard (`PASSED`, `86.5s` hiệu lực / `233.9s` gồm trace trước, Trace `4d0e5597-54b8-4a3a-b5e0-f4085567cac7`)
- **Kết quả:** Từ màn `Profile`, bấm `Log Out` đưa app về `Welcome to Evia!`; sau đó đi qua `Explore as Guest` và chạm vào route cần xác thực (`Profile`), Auth Guard chặn và điều hướng thẳng tới màn `"Welcome back!"` (`guard_blocks=True`), không hiển thị dữ liệu người dùng cũ.
- **Ảnh chụp màn hình:**

| Sau khi `Log Out` (`Welcome to Evia!`) | Auth Guard chuyển về `"Welcome back!"` khi Guest vào `Profile` |
| :---: | :---: |
| ![TC18 Logged Out](evidence-2026-11-11/tc18-welcome-logged-out.jpg) | ![TC18 Auth Guard Redirect](evidence-2026-11-11/tc18-auth-guard-redirect.jpg) |

---

#### TC19 — Offline Error State & Network Recovery (`PASSED / UX NOTE`, `599.8s`, Trace `ac91fb8a` [`Pro`, `490.9s`] + `22b0579b` [`Flash`, `46.2s`] + `94e8d1c9` [`Flash`, `62.7s`])
- **Kết quả:**
  - Tắt Wi-Fi (`svc wifi disable`) và tìm kiếm `"EVIA_OFFLINE_6f0a9dc2"`, app hiển thị thông báo lỗi mạng chuẩn từ [`FirebaseBackendService`](../lib/services/firebase_backend_service.dart#L80): `"Cannot reach the service. Check your connection and retry."`.
  - Khi bật lại Wi-Fi (`svc wifi enable`), màn kết quả tự hồi phục về `"0 events found"`; ở lần thử màn full-screen lỗi khác hiển thị nút `'Thử lại'` ở giữa `[400,567][600,624]` và phục hồi sạch về `Discover` (`30 coins`) sau khi bấm `'Thử lại'` (Ghi chú: agent Flash `94e8d1c9` tự báo `failed` do timeout đánh giá ngay sau tap, trong khi ảnh live chụp trực tiếp trên thiết bị xác nhận app đã hồi phục về `Discover`).
  - **UX Note (CHƯA SỬA):** Trên `EviaExploreScreen`, `EviaSkeleton()` hiển thị phía trên `AppErrorWidget` làm nút `'Thử lại'` bị đẩy xuống khỏi khung hình đầu (xem [Mục 4.4](#44-tc19-passed--ux-note--eviaskeleton-xếp-trên-apperrorwidget-đẩy-nút-thử-lại-xuống-ngoài-màn-hình)).
- **Ảnh chụp màn hình:**

| Lỗi Offline trên Search (`Cannot reach the service...`) | Full-screen lỗi hiển thị nút `'Thử lại'` | Khôi phục sạch về `Discover` (`30 coins`) |
| :---: | :---: | :---: |
| ![TC19 Offline Search Error](evidence-2026-11-11/tc19-offline-search-error.jpg) | ![TC19 Retry Button Error](evidence-2026-11-11/tc19-retry-button-error.jpg) | ![TC19 Network Recovered](evidence-2026-11-11/tc19-network-recovered.jpg) |

---

## 6. Phụ lục: Danh sách toàn bộ 41 ARTEMIS Traces ngày `2026-11-11`

> Đối soát trực tiếp từ `E:\Desktop\artemis\artemis\traces\<trace_id>\status.json` (`Start`/`End` theo múi giờ `+07:00`, tổng = **`4,665.1 giây`**).

| # | Trace ID (8 ký tự đầu) | Bắt đầu | Kết thúc | Thời lượng (s) | Model | Trạng thái trace | Phân loại / TC |
| --- | --- | --- | --- | ---: | --- | --- | --- |
| 1 | `f8832ee0` | `14:23:29` | `14:24:39` | `70.1` | Flash | completed | Pre-check trạng thái đầu phiên |
| 2 | `6a0643bd` | `14:25:13` | `14:26:14` | `61.3` | Flash | completed | Pre-check danh sách sự kiện/tài khoản |
| 3 | `2900b06d` | `14:29:18` | `14:31:46` | `147.4` | Flash | cancelled | `TC18` (phần 1: log out) |
| 4 | `4d0e5597` | `14:31:57` | `14:33:23` | `86.5` | Flash | completed | **`TC18` (hiệu lực — Auth Guard)** |
| 5 | `408dd619` | `14:33:55` | `14:34:40` | `45.2` | Flash | completed | **`TC02` (hiệu lực)** |
| 6 | `d50acf87` | `14:35:21` | `14:37:34` | `132.9` | Flash | completed | `TC04` (lần đầu) |
| 7 | `b8d939ac` | `14:38:41` | `14:39:51` | `70.0` | Flash | completed | **`TC04` (hiệu lực)** |
| 8 | `8d179375` | `14:40:22` | `14:41:25` | `62.6` | Flash | completed | **`TC01` (hiệu lực)** |
| 9 | `c3b37ab8` | `14:42:24` | `14:43:04` | `39.8` | Flash | completed | **`TC03` (hiệu lực)** |
| 10 | `8760190e` | `14:44:25` | `14:45:21` | `55.3` | Flash | completed | **`TC05` (hiệu lực)** |
| 11 | `5e599f06` | `14:46:08` | `14:49:34` | `206.2` | Flash | completed | **`TC06` (hiệu lực)** |
| 12 | `01913502` | `14:49:54` | `14:52:36` | `162.3` | Flash | completed | **`TC07` (hiệu lực — Save/Follow/Undo)** |
| 13 | `9c364333` | `14:55:08` | `14:56:16` | `67.7` | Flash | completed | **`TC07` (hiệu lực — Reload Verify)** |
| 14 | `065b49ce` | `14:56:40` | `15:03:53` | `432.8` | Flash | failed | `TC08` (dừng do đụng quota Free Tier) |
| 15 | `e4dddd4c` | `16:23:23` | `16:27:31` | `247.6` | Flash | cancelled | **`TC08` (hiệu lực — gửi form đăng ký)** |
| 16 | `90acf51c` | `16:28:11` | `16:30:25` | `134.1` | Flash | completed | **`TC08` (hiệu lực — xác minh vé & ví)** |
| 17 | `82809e4a` | `16:32:37` | `16:35:20` | `162.4` | Flash | completed | `TC09` (trước khi chỉnh hết vé) |
| 18 | `1c447dac` | `16:36:18` | `16:37:37` | `79.6` | Flash | failed | `TC09` (retry trước khi cập nhật cache) |
| 19 | `1df86f72` | `16:38:40` | `16:40:42` | `122.1` | Flash | completed | **`TC09` (hiệu lực)** |
| 20 | `b7e43924` | `16:48:52` | `16:50:13` | `81.1` | Flash | completed | **`TC11` (hiệu lực — mở QR vé)** |
| 21 | `dc7a050c` | `16:51:22` | `16:52:20` | `58.3` | Flash | completed | **`TC11` (hiệu lực — kiểm tra sau scan)** |
| 22 | `0cfbb0ef` | `16:53:23` | `16:58:09` | `286.5` | Flash | completed | **`TC10` (hiệu lực — đăng ký & hủy)** |
| 23 | `a53044a2` | `17:05:20` | `17:06:33` | `73.5` | Flash | completed | **`TC10` (hiệu lực — xác minh số dư & Past)** |
| 24 | `28a8e3d2` | `17:07:24` | `17:08:23` | `58.9` | Flash | completed | **`TC12` (hiệu lực)** |
| 25 | `fcc4064d` | `17:08:51` | `17:10:48` | `116.9` | Flash | completed | **`TC13` (hiệu lực)** |
| 26 | `31744963` | `17:11:11` | `17:11:57` | `46.0` | Flash | completed | **`TC14` (hiệu lực — nút disabled)** |
| 27 | `d4d52279` | `17:12:47` | `17:13:50` | `63.2` | Flash | completed | **`TC14` (hiệu lực — xác minh voucher không đổi)** |
| 28 | `50d8a6b7` | `17:14:41` | `17:16:00` | `79.3` | Flash | completed | **`TC15` (hiệu lực — local CSV OK, Storage FAIL)** |
| 29 | `51d316f5` | `17:17:01` | `17:17:47` | `46.1` | Flash | completed | **`TC16` (hiệu lực — before config)** |
| 30 | `f80afbe4` | `17:20:46` | `17:21:56` | `69.6` | Flash | completed | **`TC16` (hiệu lực — after live publish)** |
| 31 | `b11a22c3` | `17:24:12` | `17:26:09` | `117.1` | Flash | cancelled | `TC17` (chuẩn bị lần 1) |
| 32 | `23bbc0ca` | `17:29:40` | `17:31:22` | `102.7` | Flash | completed | **`TC17` (hiệu lực — I'm Going setup)** |
| 33 | `b6492dac` | `17:32:44` | `17:34:12` | `87.3` | Flash | cancelled | `TC17_foreground` (kéo shade lần 1) |
| 34 | `5dc350dd` | `17:34:39` | `17:35:47` | `67.8` | Flash | completed | **`TC17_foreground` (hiệu lực)** |
| 35 | `b753de0b` | `17:37:43` | `17:39:11` | `88.5` | Flash | completed | **`TC17_background` (hiệu lực)** |
| 36 | `c243ca29` | `17:42:53` | `17:44:35` | `101.4` | Flash | completed | **`TC17_terminated` (hiệu lực — tap shade cold start)** |
| 37 | `47cee4c9` | `17:45:37` | `17:46:32` | `54.6` | Flash | completed | **`TC17_terminated` (hiệu lực — verify Event Detail)** |
| 38 | `57000c9e` | `17:47:33` | `17:48:53` | `80.6` | Flash | completed | **`TC17_terminated` (hiệu lực — verify Inbox)** |
| 39 | `ac91fb8a` | `17:54:08` | `18:02:19` | `490.9` | Pro | completed | **`TC19` (hiệu lực — Pro offline & recovery)** |
| 40 | `22b0579b` | `18:06:02` | `18:06:49` | `46.2` | Flash | completed | **`TC19` (hiệu lực — kiểm tra viewport/cuộn)** |
| 41 | `94e8d1c9` | `18:09:01` | `18:10:04` | `62.7` | Flash | failed | **`TC19` (bấm `Thử lại`, xác nhận hồi phục bằng `adb` live)** |
