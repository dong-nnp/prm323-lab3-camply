# Analytics Flutter và báo cáo admin — 06/11/2026

> **Báo cáo live đã hoạt động — 06/11/2026:** đã deploy riêng `getAdminAnalyticsReport`. Sáu tổ hợp Android/Web/Theo cấu hình × 7/30 ngày trả HTTP 200; Chrome admin đã hiển thị bảng Android thật, không còn lỗi bộ lọc nguồn. [Bằng chứng](../evidence/analytics-report-live/README.md).

## Phạm vi

Đo hành vi từ app Android để đáp ứng trang 14–16 của hướng dẫn Lab 3.
Tracking đi View → ViewModel → AnalyticsRepository → AnalyticsService →
FirebaseAnalyticsService. Không gọi SDK trong UI, không thêm dependency.
Analytics không quyết định số dư, vé hay attendance chính thức.

Đã nối 11 events: `login`, `sign_up` (email/password), `logout`, `view_event`,
`register_event`, `cancel_registration`, `check_in_event`, `view_reward`,
`redeem_reward`, `generate_report`, `action_error`.
Google sign-in chỉ ghi `login`: contract hiện tại không trả `isNewUser`, nên
không suy đoán Google sign-up. Sáu events còn lại trong analytics-plan vẫn là kế hoạch.

Cập nhật 12/11/2026: đã kích hoạt thêm `upload_report` (`AN-16`) cho tải PDF Coin History lên Cloud Storage và `search` (`AN-04`) cho Search & Explore qua `EviaViewModel` (nâng lên 13/17 events Android; `AN-06/07/10/14` vẫn pending). Nguồn xác minh thực địa bổ sung xem [báo cáo E2E ARTEMIS](../reports/artemis-e2e-report.md).

## Chạy Android

```powershell
flutter run
```

Android debug tự bật Firebase và Analytics khi có `android/app/google-services.json`
hợp lệ. Dùng `--dart-define=ANALYTICS_ENABLED=false` để tắt Analytics khi debug.
Thiếu cấu hình Firebase hoặc chạy `DEMO_AUTH=true` sẽ không chọn real adapter.
Bản profile/release cần bật cả `FIREBASE_ENABLED=true` và `ANALYTICS_ENABLED=true`.
Android build dùng metadata deactivated khi Analytics bị tắt để chặn cả preference
đã lưu từ APK trước. SDK bật collection qua service sau bootstrap thật.
Automatic screen reporting vẫn tắt. Cờ này dành cho build demo đã cho phép;
consent/retention/access production vẫn phải chốt trước khi phát hành.

## Trigger, identity và retry

- Auth session gắn Firebase UID; signed out hoặc session stream lỗi xóa UID.
  Khôi phục session không phát `login`. Email signup phát sau SDK xác nhận;
  Google bị hủy không phát login thành công.
- Chi tiết sự kiện/quà chỉ track khi load thành công ở màn chi tiết, không
  phát theo mỗi rebuild. Reload dữ liệu trong cùng lượt mở chi tiết sự kiện
  không phát thêm `view_event`; mở lại sau dispose có thể phát lượt mới.
- Registration/redemption chỉ track sau backend receipt; dedupe theo request ID
  trong RAM, không gửi request ID lên Analytics. Redemption đã commit nhưng
  refresh lỗi vẫn track thành công một lần; retry receipt không track success lại.
- Attendance lấy baseline từ lần load đầu mỗi account; chỉ track chuyển trạng
  thái mới được app quan sát. Walk-in response và refresh dùng chung dedupe
  theo event ID trong phiên. QA demo attendance có backend xác nhận cũng có
  thể phát event; không dùng nó làm bằng chứng check-in QR thật.
- `action_error` chỉ dùng action/error code trong allowlist; lỗi không biết
  chuyển thành `unexpected`, không gửi SDK message, form hoặc token.
- Queue giữ thứ tự identity/event. Lỗi SDK được log thông báo cố định, không
  làm giao dịch thất bại; nếu identify lỗi, bỏ event đến lần identify thành công.
  Không hứa delivery/exactly-once, không backfill khi app tắt hoặc reinstall.
- Schema chặn event/parameter ngoài danh sách, kiểu sai, free text, số âm và
  chuỗi quá 100 ký tự. Content IDs truyền từ server, không dùng UID người khác.

## Xuất CSV

Màn Coin History thêm nút xuất CSV các giao dịch đã tải, áp dụng bộ lọc đang
hiển thị. Cột `date,kind,coins`; không xuất tên, email, MSSV, voucher/QR.
Đây là bản xuất lựa chọn hiện tại, không tuyên bố toàn bộ ledger.
Android ACTION_CREATE_DOCUMENT cho người dùng chọn nơi lưu; không xin quyền
đọc toàn bộ bộ nhớ. Native giới hạn 5 MiB, ghi ngoài UI thread; chỉ trả thành
công sau đóng output stream. Hủy không phát success; lỗi có thông báo/retry.
Chỉ sau save thành công phát `generate_report` với `report_type=coin_history_csv`
và `file_size_kb:int` làm tròn lên. Chưa upload Storage/PDF; không sửa Storage Rules.

## Báo cáo admin Vite

`admin/` có nguồn Android/Web/Theo cấu hình backend, nhãn hành vi tiếng Việt
và link Firebase Console. Với sự kiện chưa có bản dịch, bảng tách mã thành các từ.
Android/Web lọc GA4 dimension `platform`
trên toàn property; không giới hạn vào `ADMIN_GA4_STREAM_ID` của web admin cũ.
Nguồn Web bao gồm tất cả web streams, không chỉ admin. Nguồn theo cấu hình
giữ hành vi cũ: lọc stream nếu có, ngược lại toàn property. Phản hồi trả scope
để UI hiển thị nguồn thực tế, kể cả khi kết quả rỗng.

API vẫn yêu cầu admin; client cũ chỉ gửi `{days}` vẫn hoạt động. Top 25 events,
7/30 ngày, `eventCount` và `totalUsers`; không cộng users giữa các hàng hoặc
suy ra funnel/tỷ lệ chuyển đổi từ bảng này. Báo cáo có độ trễ, dùng DebugView
để kiểm tra từng thao tác khi phát triển.

Chọn **Realtime · 30 phút** để xem dữ liệu gần đây qua `runRealtimeReport`.
Web tự tải lại mỗi 30 giây khi trang Analytics đang hiển thị. GA4 cần thời
gian nhận và xử lý sự kiện, nên số liệu vẫn có thể cập nhật sau vài phút.

Sau review code, deploy **riêng** callable đã đổi nếu muốn dùng bộ lọc mới:

```powershell
npm --prefix functions run build
npx --yes firebase-tools@15.30.2 deploy --project prm393-31822 --only functions:evia:getAdminAnalyticsReport
```

Backend cũ có thể từ chối `source`; UI báo cần cập nhật backend. Không deploy
toàn bộ working tree để tránh đưa thay đổi admin khác lên ngoài phạm vi này.
Không sửa GA4 IAM/property, không tạo dữ liệu báo cáo giả. `admin_flutter/`
chưa có bộ chọn nguồn mới và tiếp tục dùng contract `{days}` tương thích cũ.

## Kiểm chứng Lab 3

Validation đã chạy trên source ngày 06/11/2026:

- `flutter pub get`, `dart format lib test` và `flutter analyze`: đạt, không issues.
- `flutter test`: **234/234 đạt**, gồm schema, auth/lifecycle, receipt retry,
  attendance, export cancel/error/đổi account và native channel contract.
  Suite UI hiện có bao phủ live Coin History ở 360/412dp, text scale 2×.
- Functions TypeScript build + `analytics_query.test.mjs`: **2/2 đạt**;
  admin Vite tests **8/8 đạt**, production build đạt; `git diff --check` đạt.
- APK debug bật Firebase/Analytics và APK mặc định đều build thành công.
  Manifest merge xác nhận deactivated false/true tương ứng. Cả hai chế độ
  đã cài và cold-start qua ADB trên SM-G996N (`R3CR60CT0WZ`).
- Sau cập nhật báo cáo live: đã deploy callable và xác nhận bảng Android/7 ngày trong phiên Chrome admin thật. API trả Android 4 dòng, Web 5 dòng tại thời điểm kiểm; không thay GA4 permissions/property. Xem evidence analytics-report-live phía trên.

Logs kiểm tra cuối nằm local ở `build/analytics-verification/` (Git ignored).
Chưa chạy lại toàn bộ backend Emulator suite. Chưa nghiệm thu hộp thoại lưu CSV
thành công trên thiết bị thật, chưa có DebugView screenshots hoặc bằng chứng
GA4 đã nhận đủ 11 events. Những mục này vẫn phải làm khi nghiệm thu Lab 3.

```powershell
adb -s R3CR60CT0WZ shell setprop debug.firebase.analytics.app com.example.prm393_lab03
# Mở Firebase Console → Analytics → DebugView, chọn đúng thiết bị.
# Thao tác từng event, kiểm parameters/user ID và chụp bằng chứng.
adb -s R3CR60CT0WZ shell setprop debug.firebase.analytics.app .none.
```

Kiểm login/logout, xem/đăng ký/check-in sự kiện, xem/đổi quà, lưu CSV và một
nhánh lỗi. Không dùng unit fakes hoặc log gửi lệnh làm evidence cloud đã nhận.
DebugView, báo cáo tổng hợp và native save dialog phải nghiệm thu riêng.

Nguồn: [Analytics API](https://pub.dev/documentation/firebase_analytics/latest/firebase_analytics/FirebaseAnalytics-class.html),
[DebugView](https://firebase.google.com/docs/analytics/debugview),
[GA4 platform dimension](https://developers.google.com/analytics/devguides/reporting/data/v1/api-schema),
[Android document picker](https://developer.android.com/training/data-storage/shared/documents-files).
