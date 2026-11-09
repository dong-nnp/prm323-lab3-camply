# Test plan — template

> **Interests — 09/11/2026:** hai widget regression tests ở
> `test/widgets/flow1_screens_test.dart` đạt: chọn/lưu đủ 10 danh mục bằng ID
> canonical, nút Continue chỉ bật từ 3 lựa chọn và chờ server; My Interests khôi
> phục tên mới từ ID đã lưu, cho bỏ chọn Gaming/Environment rồi lưu lại.
> Fixtures chỉ nằm trong tests, không cần Firebase account. Các ca trên là kiểm thử
> widget; thay thế giới hạn 8 thẻ ngày 05/11 bên dưới.
> `flutter pub get`, format toàn bộ `lib test`, analyze và `git diff --check` đạt.
> Full suite: **251 đạt, 4 lỗi**; cả 4 tái hiện trên bản sao commit `a063715`
> trước thay đổi: Discover 360dp/chữ 2x overflow, retry mạng của Flow 1/3 và
> `/registration/loading`. Bố cục My Interests 360/412dp, chữ 1x/2x đạt.
> Android thật: build debug arm64 `2004`, `FIREBASE_ENABLED=true`, `DEMO_AUTH=false`
> đạt và cài cập nhật trên Samsung SM-G996N. Đã mở onboarding, kiểm tên mới và
> cuộn thấy đủ 10 thẻ, gồm Gaming/Environment với icon ở hàng cuối. Giữ nguyên
> dữ liệu app; chưa bấm Continue hoặc kiểm lại lưu sở thích trên máy thật.

> **Evibaby — 09/11/2026:** tests mới ở `test/evibaby_test.dart`,
> `functions/test/evibaby.test.mjs`, `functions/test/evibaby_backend.test.mjs`.
> Phạm vi: state/lifecycle/retry, card navigation, chữ lớn/keyboard, public-only
> retrieval, phân trang, xác minh ID, tool budget và quota transaction.
> [Contract, kết quả API thật và giới hạn](evibaby-chat.md). Full Flutter: 251 đạt,
> 4 lỗi tái hiện khi bỏ launcher Evibaby; test chat riêng 7/7 đạt.

> **QR Walk-in để in:** kiểm tra admin tải cùng một PNG trước giờ check-in, app
> mở màn quét trực tiếp từ chi tiết sự kiện, mã chỉ hợp lệ trong khung giờ hiện
> tại và quét lại không cộng xu lần hai. Ca kiểm tra dùng dữ liệu Emulator.

> **Resolve merge — 06/11/2026:** giữ badge streak căn phải và dùng `streakDay`
> từ lịch API mới; gộp tài liệu pytest/Gemini với DeepSeek. `flutter pub get`
> đạt, format 2 file Dart không đổi, `flutter analyze --no-pub` sạch.
> Chạy `flow3_view_model_test.dart` + `flow3_screens_test.dart`: **16 đạt, 1 fail**.
> Test `network error offers retry and never falls back to mock rewards` chưa thấy
> `Rewards offline`: provider giữ `AsyncLoading(error: ..., retrying)` do automatic
> retry. Chạy riêng test này cũng fail; chưa đổi retry policy trong task resolve
> conflict. Chưa build APK/chạy emulator hoặc xác nhận toàn suite đạt.

> **ARTEMIS implementation — 06/11/2026:** suite đã định nghĩa 21 ca/biến thể,
> collect đủ 63 lượt (3/ca); đợt `20261106T023224Z-3cfd8a66` đạt TC04 3/3 và
> TC05 3/3 (6/6 trong 519 giây). Chưa đạt đủ các ca và coverage của đề.
> Đợt tiếp theo `20261106T024147Z-d723f8b6`: TC07 đạt 1/1; TC03/06/18/19 fail.
> Analytics được hoãn theo người dùng. Dừng mở thêm ca khi RAM còn 0.66 GB;
> AVD/host test đã đóng, evidence và dữ liệu test được giữ.
> Chuẩn bị thêm fixture TC02/14; 2 Node tests đạt, preflight chỉ đọc xác nhận
> ca thiếu xu có dữ liệu phù hợp. Guard hoãn TC03 cho 1 skipped, không submit AI.
> Chưa có lượt E2E mới trong đợt chuẩn bị này vì thiếu RAM trước khi mở AVD.
> [Bảng evidence/trạng thái](../evidence/artemis/README.md) là nguồn kết quả hiện tại.
> Có 7 self-check của bộ thu evidence đạt; không tính chúng thành ARTEMIS tests.
> SDK pin kèm bản vá nhập ASCII, account Firebase và AVD EVIA_E2E riêng; logs cũ
> được giữ, lỗi/quota/ANR và AI trả lời suy đoán không được ghi pass. Các ghi chú
> “chưa có E2E” bên dưới là lịch sử trước đợt triển khai này.

> **Registration spinner — 06/11/2026:** chạy riêng test
> `original form loading result and ticket wait for a server receipt`: **1/1 đạt**.
> Xác nhận có spinner thật, form nằm dưới overlay khi submit/chờ vé, không hiện
> skeleton hoặc success sớm; sau response mới mở success/vé. Analyzer 5 file sạch.
> Không chạy full suite hoặc chụp màn hình trong lượt này.

> **Daily schedule API — 06/11/2026:** chạy riêng
> `flutter test --no-pub test/viewmodels/flow3_view_model_test.dart`: **10/10 đạt**.
> Có kiểm tra admin đổi lịch/ngày 8, giữ số xu receipt đã claim và từ chối lịch
> thiếu/âm/sai độ dài. Analyzer 6 file liên quan sạch, `git diff --check` đạt.
> Không chạy lại full suite hoặc native smoke trong lượt nối lịch thưởng này.
> **Merge admin — 06/11/2026:** giữ Analytics theo nguồn, event upload và thông báo trực tiếp cùng Daily Check-in/Crash QA từ nhánh admin. Đã gỡ hàm `claimDaily` trùng, cập nhật fixture lịch thưởng và giữ action/loading/ví qua Flow3. Validation sau sửa: admin 14/14 + build, backend Emulator 85/85 + TypeScript build, Flutter 234/234, `flutter analyze --no-pub lib test` sạch, APK debug build đạt. Chưa chạy APK trên thiết bị, chưa deploy. Logs trong `.local/merge-*.log` (Git ignored).

> **Gửi thông báo trực tiếp — 06/11/2026:** admin 15/15 + build; backend 84/84 Emulator tests + TypeScript build đạt. Browser form/danh sách thật và responsive 360/412px đã kiểm. Callable mới đã deploy; live guards anonymous/staff/invalid payload đạt, chưa gửi push thật trong lượt này. [Evidence](../evidence/admin-notifications/README.md).

> **Form sự kiện/Storage — 06/11/2026:** admin 12/12 + build, đầy đủ 81/81 backend Emulator tests + TypeScript build đạt. Browser form/preview và 360/412px đã kiểm; Storage Rules đã deploy, upload/download hash thật và cleanup QA đạt. Không tạo event cloud, không đổi Dart/native nên không chạy lại Flutter. [Evidence và giới hạn](../evidence/event-editor/README.md).

> **Analytics — 06/11/2026:** validation mới: Flutter 234/234, analyze sạch, admin 8/8 + build, backend query 2/2 + TypeScript build. APK bật Analytics và mặc định đều build/cold-start trên Android thật. Đã deploy riêng callable Analytics, kiểm API thật và bảng Chrome Android; chưa nghiệm thu parameters của toàn bộ events trong DebugView. [Evidence báo cáo live](../evidence/analytics-report-live/README.md). Tests mới kiểm schema/PII, thứ tự UID/logout, retry receipt không lặp, lỗi SDK không phá business action, baseline attendance, CSV success/cancel/error/đổi account và native channel contract. Node tests kiểm GA4 query/filter và nhãn nguồn; không coi fakes là DebugView/cloud evidence. [Cách nghiệm thu thật](ANALYTICS_INTEGRATION.md).

> **Push Android — 06/11/2026:** 216/216 Flutter tests, 64/64 backend Emulator
> tests, analyze sạch, APK debug build/cài đạt. Banner FCM thật đã thấy khi app
> đang mở và tiến trình đóng; app nền nhận notification hệ thống. Tap foreground
> mở Career, tap cold-start mở Workshop đúng payload. [Evidence/giới hạn](../evidence/push-notifications/).

> **Flow 3 — 06/11/2026:** 213/213 Flutter tests, 62/62 backend Emulator tests,
> analyze sạch, APK debug Firebase thật build đạt. Tests bao phủ Daily chờ server,
> manual milestone claim/reload, đổi quà/khôi phục receipt, giá đổi/refresh lỗi,
> ví mới nhất, locker/QR, voucher used và network retry. Widget test dùng viewport
> thật 360/412dp, chữ 2×, bấm nút xác nhận thật trong test. Giao dịch live dùng
> seeded operator; native và giới hạn tách riêng tại [evidence](../evidence/flow3-api-only/).
> **Evia Admin web.** Kiểm tra tạo, sửa, xuất bản sự kiện và mẫu voucher
> bằng Firestore Emulator. Bộ test bao gồm từ chối user thiếu claim, xung
> đột khi tồn kho thay đổi và giữ các điều kiện của Remote Config. Đã đăng
> nhập trên trình duyệt và tạo, kích hoạt mẫu voucher từ web. Cần nghiệm
> thu FCM, Remote Config, GA4 và Crashlytics BigQuery trên dự án thật.
> [Các bước chạy và nghiệm thu](../admin/README.md).

> **Ticket cache fix — 05/11/2026:** 195/195 Flutter tests đạt; tái hiện vé tồn
> tại nhưng My Events cache rỗng, refresh error có previous data, vé revoked,
> event bị xóa và cancel route không có đăng ký. 14 same-data render comparisons
> trùng RGBA, analyze sạch. [Evidence](../evidence/ticket-cache-fix/).

> **Flow 2 — 05/11/2026:** 59/59 backend Emulator và 190/190 Flutter tests đạt;
> 14/14 ảnh same-data ở 360/412dp trùng RGBA. Đã kiểm 7 Functions READY, hủy 50
> hoàn 15 và push FCM đến Android/open đúng event. Regression modal sau refresh
> đã được thêm. Native proof của nút demo/camera và các giới hạn xem
> [evidence](../evidence/flow2-api-only/); không dùng nút demo làm proof staff quét thật.

> **Mở email mọi domain 05/11/2026:** 57/57 backend Emulator tests và 176/176
> Flutter tests đạt; analyze sạch, APK debug build đạt. Tests Gmail/Outlook/domain
> riêng và malformed email, signup/login/reset, profile/registration, giữ MSSV và
> role guards. [Evidence](../evidence/open-email/). Chưa nghiệm thu Google login
> với tài khoản ngoài trường trên native; không lấy fake tests làm cloud proof.

> **API-only theo owner 05/11/2026:** đã gỡ bộ màn `Flow1Screen` tạo ngoài phạm vi;
> nối Firebase vào các màn gốc, giữ layout/style/assets. Giữ 8 thẻ sở thích;
> Gaming/Environment chờ đội UI. Ảnh cũ làm minh họa khi chưa có URL; vé chỉ hiện
> QR trong ô cũ, chưa có mã dự phòng. [Phạm vi](API_INTEGRATION_PHASES.md) · [Evidence sửa lại](../evidence/flow1-api-only/).
> Các mô tả bộ màn live riêng/kết quả cũ bên dưới là lịch sử, không nghiệm thu bản này.


> **Flow 1 mobile integration 05/11/2026:** **171/171 Flutter tests PASS**, gồm
> 22 tests mới; pub get/format/analyze đạt, APK debug live build đạt. Native smoke
> trên SM-G996N đã đọc catalog, login email/password, search/follow/bookmark,
> đăng ký giữ 50 xu và mở lại vé/QR sau restart/logout/login. [Evidence](../evidence/flow1-integration/).
> Google login, signup/reset email trên native, first-time onboarding trên tài
> khoản mới, Flow 2/3 và ARTEMIS chưa nghiệm thu. Không gộp native smoke với E2E.

> **Demo catalog/operator setup 05/11/2026:** ba tests mới thuần Node tại
> demo_catalog.test.mjs đạt (schema/references/windows/edge capacities/dry-run).
> [Cloud data verification](../evidence/demo-data/verification.json) xác nhận 32
> catalog records, 5 milestones giữ nguyên; hai password sign-ins, profile/ledger
> đúng và sai quyền bị từ chối. Không tạo attendance/redemption để giả tích hợp.
> Không đổi Dart/native/backend handlers nên không chạy lại Flutter/Emulator suite;
> 51/149 ở release trước vẫn là evidence của revision tương ứng, không test mới.

> **Sau review trước tích hợp 05/11/2026:** baseline Flutter 141/141 đạt trước
> sửa; suite sau sửa **149/149 đạt**, analyze không issues, pub get/format đạt.
> Backend mới **51/51 Emulator tests PASS**, 0 fail/skipped. [Logs mới](../evidence/preintegration/).
> APK debug build đạt; chưa cài lại thiết bị hoặc chạy native Firebase E2E.
> Tests kiểm FPT domain/MSSV ở hai phía, manual code expiry/rate/staff/race/retry,
> publication/update/reminder routing/dedupe/stale updates, onboarding không Skip/
> chờ server, claim không optimistic và UI thiếu service không giả thành công.
> Không chạy mobile Firebase E2E hoặc gửi notification/cấp xu thử trên cloud.

> **Event Milestones 05/11/2026:** backend suite mới **41/41 PASS**, 0 fail/skipped:
> [log](../evidence/event-milestones/emulator-tests-release.log). Bao gồm historical
> attendance, loại pending/future/invalid mode, manual claim, race/retry, đủ 5 mốc
> tổng +1.100, giữ held balance, admin roles/version/edit/snapshot/audit, Rules và
> schema validation; cả registered-ticket và walk-in integration cập nhật progress.
> Không thay Dart/native; không chạy lại Flutter tests/build cho task backend này.
> Cloud evidence và giới hạn: [feature contract](EVENT_MILESTONES.md).

> **Mô phỏng UI 05/11/2026:** debug + `DEMO_AUTH=true` hiện cho phép mô phỏng
> giữ/hoàn cọc, check-in, daily reward và đổi thưởng. `ActivityViewModel` quản lý
> presentation state tạm trong RAM từ fixtures đã được cho phép, không gọi backend.
> `/profile/demo` chỉ đăng ký khi cờ bật, cho mở 44 màn/trạng thái và reset ví 2.000 xu.
> Các mô tả “không mutation” phía dưới vẫn áp dụng khi cờ tắt; không dùng demo này
> làm evidence tích hợp thật. Xem hướng dẫn mới trong README.


> 05/11/2026: theo yêu cầu xem UI, thêm DemoAuthenticationService qua DI khi debug + DEMO_AUTH=true; mặc định vẫn pending. Login đi View → EviaViewModel → AuthenticationRepository → AuthenticationService, session stream cập nhật guard; logout xóa session. Không tích hợp Firebase Auth thật. Xem tài khoản/lệnh chạy trong README.
> Test mới: sai mật khẩu không mở guard, đăng nhập/đăng xuất qua ViewModel, session cho listener mới và unsupported operations. Kết quả chỉ ghi sau khi chạy.


## Cloud release — 04/11/2026

Source giữ nguyên so với 31-test Emulator run. Build TypeScript đạt; deploy 34 Functions/Run latest revisions READY, 2 Scheduler definitions/IAM đúng, 14 indexes READY. **6/6 Callable smoke và 3/3 Firestore Rules smoke đạt**, không authenticated mutations/test users/seed. [Release evidence](backend-release.md). Không coi definition checks là job business execution, OAuth/FCM hoặc UI/E2E proof.

## Backend readiness mới — 04/11/2026

Lệnh `npm --prefix functions run test:emulator`, Node22.23.4 + Java21 JBR + Firebase CLI: build TypeScript và **31/31 tests đạt, 0 fail, 0 skipped**. [Log cuối](../evidence/backend-readiness/emulator-final.log). Flutter không thay đổi, không chạy lại UI/native tests trong milestone này.

Ngoài coverage backend cũ, lượt này kiểm terms version import/API, empty dry-run, tìm kiếm đ/d tiếng Việt, FCM token cap, Rules không cho client đọc/ghi quyền admin, đăng ký lại/tranh slot/vé và QR cũ, admin voucher dùng một lần/revoke/expiry, monthly race/cutoff/onboarding/year rollover và no-show cutoff/idempotency/attended/cancelled event.

Monthly/no-show business functions được gọi trực tiếp trong Emulator tests. Emulator không chạy Cloud Scheduler theo lịch thật; chưa deploy code mới, chưa kiểm IAM/schedule/cost hoặc FCM delivery. Các kết quả 20 tests bên dưới là lịch sử revision trước.

RED→GREEN evidence: [search trước fix](../evidence/backend-readiness/emulator-before-search-fix.log), [search sau fix](../evidence/backend-readiness/search-after-fix.log), [re-registration trước implementation](../evidence/backend-readiness/reregistration-before.log), [voucher trước implementation](../evidence/backend-readiness/voucher-before.log). Không tính các lượt RED là pass.
## Sign Up branding match — 05/11/2026

Logo và tagline khôi phục đúng kích thước/style Login, không thêm collage.
Khi bàn phím hiện, thu logo và ẩn tagline. 10 Signup/Login widget tests đạt;
analyze/diff check đạt. Đã cập nhật và xem ảnh `build/signup-review/signup-390.png`.

## Sign Up action order correction — 05/11/2026

Theo yêu cầu sửa tiếp theo, đặt Terms sau bốn fields và Google sau Create Account.
Giữ header nhỏ/không collage. 7 Signup widget tests đạt, gồm kiểm tra thứ tự mới;
ảnh `build/signup-review/signup-390.png` đã cập nhật. Diff check đạt. Các mô tả
Google ở trên form trong mục lịch sử bên dưới không còn áp dụng.

## Sign Up compact layout — 05/11/2026

Bỏ collage/tagline, logo nhỏ, subtitle rút gọn, Google trước các fields. Consent
dùng chung nằm gần Google. Không đổi font/tap target hoặc business validation.
Signup widget/VM và Login keyboard: 18 tests đạt; analyze/diff check đạt. Capture
mới ở 390×844 kiểm tra Google và Log In thấy được khi mở màn hình. Các mô tả
collage ở những lượt trước bên dưới là evidence lịch sử, không phải layout hiện tại.

## Sign Up horizontal collage — 05/11/2026

Theo ảnh điều chỉnh tiếp theo, đổi riêng collage Sign Up sang ba ảnh ngang,
chồng nhẹ và nghiêng; giữ Login gốc. Analyze/diff check đạt. Chạy Signup widgets
và Login keyboard: 10 tests đạt. Đã xuất/xem lại `build/signup-review/signup-390.png`.

## Sign Up / Create Account — 05/11/2026

- `/signup` thay placeholder bằng form thật. ViewModel tests kiểm tra required,
  email/confirmation/terms, policy lấy từ adapter, chống submit lặp, email conflict,
  verification, Google và dispose khi request pending. Không dùng runtime mocks.
- Widget tests: 360×640, 390×1200 (capture toàn form), 412×844 text 2x;
  keyboard inset 300dp, bốn fields không mất text, collage khoảng 110–127dp,
  không status bar giả/Student ID, checkbox chưa chọn, password toggle độc lập,
  Log In mở màn cũ. Backend pending báo lỗi và không tự chuyển màn.
- Hai tests dùng service fake trong tests: chỉ sau auth stream phát session thật
  của fixture mới chuyển Interests hoặc Discover theo personalization; kết quả
  từ hàm createAccount riêng lẻ không đủ để navigate.
- 32 tests liên quan đã đạt: Sign Up widget/VM, Login keyboard, Welcome, Firebase
  preparation. Sau tinh chỉnh cuối, chạy lại 15 Signup widget/VM tests đều đạt.
  Không cộng lượt chạy lại thành case mới. Format/analyze/diff check đạt.
- Debug APK x64 build thành công. Đã xem ảnh widget
  `build/signup-review/signup-390.png`; không claim native smoke hay backend thật.
- Chưa có adapter auth/Google thật, policy mật khẩu hoặc legal URL production.
  Pending adapter ném lỗi rõ ràng, không thành công giả. Không chạy full suite.

## Login keyboard layout — 05/11/2026

- `login_keyboard_test.dart`: 390×844, 360×640 và reduced motion, mô phỏng
  viewInsets.bottom=300dp. Focus đơn lẻ không collapse; mở bàn phím thu logo,
  vùng collage cao 0, ô đang nhập vẫn trong viewport. Email Next đến Password
  không hiện lại collage; đóng bàn phím giữ text và các field elements.
- 15 tests đạt trong login_keyboard_test + welcome_screen_test; đã chạy thêm
  3 tests keyboard sau bổ sung preload ảnh, tất cả đạt. Không tính lượt chạy
  lại thành test case mới. Analyze, format và diff check đạt.
- Đã xem `build/login-keyboard-review/login-keyboard-insets-300dp.png`; đây là
  ảnh widget với keyboard inset mô phỏng, không phải ảnh bàn phím native thật.
- Không chạy lại full suite/native build cho thay đổi bố cục Dart này.

## Welcome → Login transition — 05/11/2026

Giữ nguyên Login UI, thêm slide + fade khi push và reverse khi pop; reduced motion
bỏ cả hai. Đã chạy format, analyze (không lỗi), `git diff --check` và toàn bộ
`welcome_screen_test.dart`: 12 tests đạt. Hai test mới kiểm tra frame trung gian
tiến/lùi, Welcome element được giữ lại sau Back, và reduced motion không slide.
Không build lại native vì chỉ thay routing/animation Dart; chưa đo FPS trên thiết bị.

## S01 Welcome — 05/11/2026

- `welcome_screen_test.dart`: 390×844, 360×640, 412×844/360×640 với text 2x;
  đúng hai asset riêng, ba actions thật, touch target >=48dp, scroll trên màn thấp.
  Get Started mở Sign Up unavailable, Log In mở Login, Guest mở Discover Guest.
  Private deep links/Follow guest đến Login, organizer công khai vẫn xem được.
  Hai test signed-in vào `/` xác nhận bypass Welcome theo personalization.
- `guest_access_test.dart`: không thay collections, đăng ký/Going/waitlist hoặc
  tiền khi chưa xác nhận session. Test fixtures cho các flow cần tài khoản cũ
  được override signed-in chỉ trong tests, không tạo session ở runtime.
- Đã chạy 47 test liên quan Welcome/guest/S00/startup/guard/ViewModels/Rewards,
  tất cả đạt; chạy thêm 2 test bypass Welcome trực tiếp đều đạt (49 tests tổng).
- pub get, format, analyze và diff check đạt; không thêm dependency.
- Đã build/cài APK debug x64 với hero asset mới. Ảnh widget đã xuất và xem tại
  `build/welcome-review/welcome-390-844.png` và `welcome-360-640.png`.
  Đã mở lạnh app và xem ảnh máy ảo `build/welcome-review/native-welcome.png`:
  S00 chuyển đến S01, cả ba actions nằm trên vùng navigation hệ thống.
  Chỉ bundle hero/logo, không bundle reference screenshot làm UI.
- Chưa tích hợp đăng ký/đăng nhập thật hoặc profile persistence. Sign Up báo
  unavailable rõ ràng. Auth/profile routing dùng contracts/state thật hiện có;
  fixtures không được coi là evidence dịch vụ backend.
- Không chạy full suite/iOS; các lỗi ListTile/overflow baseline chưa sửa trong
  task S01. Kết quả lịch sử bên dưới giữ nguyên theo phạm vi từng lượt chạy.

## S00 assembly animation — lượt sửa tiếp theo 05/11/2026

Thay fade toàn ảnh bằng các lớp tách trực tiếp từ logo chính thức. Kết quả của
lượt sửa này (không thay thế các bằng chứng lịch sử ở mục dưới):

- `python tool/derive_splash_layers.py`: ghép ba lớp trùng từng pixel RGBA nguồn.
- pub get không thêm dependency; format và analyze đạt; `git diff --check` đạt.
- 12 tests đạt trong `splash_logo_test.dart`, `splash_screen_test.dart` và
  `startup_view_model_test.dart`. Kiểm tra vị trí vé A→B→C thật sự dịch trái,
  mask via tăng từ 0 đến một phần rồi 100%, vị trí cuối giữ nguyên đến 1150ms.
  Các nhánh auth/startup và reduced motion vẫn đạt.
- Đã xuất và xem frame A300/B600/C800/D950/D1150; ảnh ghép tại
  `build/splash-assembly-review/assembly-frames.png`. Khung B cho thấy vé đang
  dịch trái và chữ via chưa hiện đủ. Không dùng storyboard làm ảnh runtime.
- APK debug x64 build/cài thành công lên emulator-5554; kiểm tra trong APK có
  đúng ba PNG mới (bytes khớp source) và code widget assembly.
  Không chạy lại toàn suite. Native splash và
  routing không thay đổi trong lượt sửa animation này.

## S00 Splash — 05/11/2026

- `startup_view_model_test.dart`: chờ bootstrap/auth, unavailable/signed out,
  signed in chưa/đã xử lý personalization, lỗi initialization/auth, user isolation.
- `splash_screen_test.dart`: đúng PNG gốc, căn giữa ở 360/412dp, không text/nút,
  chỉ điều hướng sau startup, thay route thay vì đẩy Splash vào back stack,
  reduced motion, signed-in Interests/Discover và Skip đến Discover.
- Auth thật và profile adapter vẫn pending. Tests dùng overrides chỉ trong tests;
  không coi đây là xác nhận login hoặc lưu personalization backend thật.
- Đã chạy pub get (không thêm dependency), format, analyze không lỗi. Bộ test
  scoped 22 tests đạt: Splash/startup, auth guard, Evia ViewModel và foundation.
- APK debug x64 đã build và cài thành công. `am start -W` timeout, nhưng
  `topResumedActivity` là MainActivity và ảnh native sau startup đã được xem:
  app đến Welcome. Không thấy Flutter/AndroidRuntime error trong đoạn log đã đọc.
- Đã xem ảnh widget `build/splash-review/splash-360.png`: đúng logo, một e trong
  vé + via, hai tia lime, nền/căn giữa đúng. Ảnh không chứng minh độ mượt native.
- Bản sao PNG Android có SHA-256 khớp file nguồn. APK chứa cả asset Flutter,
  PNG native, splash_icon và code splash_screen; không dựa vào APK cũ.
- Không chạy toàn suite hoặc iOS (repository không có iOS host). Các lỗi UI
  baseline ghi bên dưới chưa được coi là đã sửa bởi task này.
- Chạy thêm hai flow cũ trong `evia_screens_test.dart`: validation sở thích/login
  đạt; Skip/Search/Filters/Follow thất bại vì 3 assertions `ListTile background
  color or ink splashes may be invisible`, thuộc lỗi UI baseline đã ghi nhận.
  Test flow này được đặt entry Welcome rõ ràng để kiểm tra độc lập với animation
  S00 (đã có test riêng), không bỏ qua hay che assertion.

Trạng thái tại thời điểm mục lịch sử này: có unit/widget tests, chưa có ARTEMIS.
Các đợt sau đã thêm pytest ARTEMIS và runner DeepSeek với smoke scenario
Welcome/Login/validation; xem [trạng thái từng bộ chạy](../e2e_test/README.md).
CLI thành công không tự xác nhận scenario pass; đối chiếu từng check và trace.
Tài liệu này là kế hoạch, không xác nhận pass/fail cho các bước chưa chạy.

## Firebase development setup — run 04/11/2026

SDK: Flutter 3.47.9 / Dart 3.13.7 tại `F:\Mobile_Programing\flutter_evia_lab3`.

| Check | Kết quả thực tế | Log local |
|---|---|---|
| `flutter pub get` | PASS, giữ nguyên dependency constraints/lock | Terminal setup |
| `dart format --output=none --set-exit-if-changed lib test` | PASS, 88 files / 0 changed | `evidence/firebase-setup/dart-format-check.log` |
| `flutter analyze` | PASS, no issues | `evidence/firebase-setup/flutter-analyze.log` |
| `flutter test` | FAIL, 76 pass / 5 fail; Evia UI overflow và ListTile assertion | `evidence/firebase-setup/flutter-test.log` |
| `flutter test test/services/firebase_preparation_test.dart test/viewmodels/bootstrap_view_model_test.dart test/widgets/foundation_app_test.dart` | PASS, 12 tests | `evidence/firebase-setup/firebase-foundation-tests.log` |
| `firebase deploy --only firestore:rules --project evia-lab3-kiet-2026 --non-interactive` | PASS, deny-all Rules compiled/released | `evidence/firebase-setup/firestore-rules-deploy.log` |
| Anonymous REST read `users/probe` | HTTP 403, denied | `evidence/firebase-setup/firestore-access-check.txt` |
| `flutter build apk --debug --dart-define=FIREBASE_ENABLED=true` | PASS after fixing JDK path and cross-drive Kotlin cache | `evidence/firebase-setup/flutter-build-apk.log` |
| `flutter build apk --debug --no-pub` with native config temporarily absent | PASS; native config restored afterwards | `evidence/firebase-setup/flutter-build-without-firebase.log` |
| Native Firebase smoke — Pixel 5 emulator | PASS: `/foundation` displays “Firebase đã khởi tạo”; native init successful | `evidence/firebase-setup/emulator-firebase.png`, `emulator-firebase.xml`, `emulator-startup.log` |
| Native install/start — Samsung SM-G996N | Install/start PASS; native Firebase init successful. Visual check not verified: phone locked | `evidence/firebase-setup/samsung-startup.log` |

Full-suite failures nằm trong `test/widgets/evia_screens_test.dart` (4 layout
cases và 1 navigation case); source UI/test đó chưa thay đổi trong task config.
Không đánh dấu full test suite đạt. Đây không phải emulator security tests,
ARTEMIS results hoặc bằng chứng các dịch vụ Firebase nghiệp vụ đã hoạt động.

## Phạm vi foundation

| Loại | Trường hợp | Test source |
|---|---|---|
| Unit | Bootstrap loading/empty/data/error, retry, chống gọi lặp, dispose | `test/viewmodels/bootstrap_view_model_test.dart` |
| Unit | Lỗi không lộ chi tiết nội bộ, timeout message | `test/core/exception_mapper_test.dart` |
| Unit | Guard public/protected với các trạng thái auth | `test/app/authentication_guard_test.dart` |
| Unit | Chưa cấu hình không cần native SDK; pending auth không giả thành công | `test/services/firebase_preparation_test.dart` |
| Widget | App root 360/412dp, text scale 1x/2x, button >=48dp, error/retry | `test/widgets/foundation_app_test.dart` |

Lệnh: `flutter pub get`, `dart format --output=none --set-exit-if-changed lib test`,
`flutter analyze`, `flutter test`. Native smoke: `flutter run -d DEVICE_ID`
khi chưa thêm Firebase config. Không cần Firebase account cho unit/widget tests.

## Evia — lần triển khai 04/11/2026

- `test/widgets/evia_screens_test.dart`: 9 route ở 360/412dp, text scale 1x/2x;
  Skip → guest → search → filters; follow/unfollow; minimum interests; login
  không giả thành công. Foundation tests dùng override route `/foundation`.
- `test/viewmodels/evia_view_model_test.dart`: search/category/filter draft/apply,
  reset, lịch sử deduplicate, bookmark/follow và date/time/custom range.
- Đã tải và kiểm tra đủ 131 asset files, không rỗng; XML root kích thước SVG đã đọc.
- `flutter pub get`, format, analyzer và `git diff --check`: xem kết quả run bàn giao.
- `flutter test`: **bị chặn trước khi chạy test**. Windows Application Control
  từ chối chạy `dartaotruntime.exe` (frontend compiler) ở cả SDK Downloads và SDK
  được ghi trong README. Không thay đổi chính sách bảo mật trên máy.
- Chưa chạy được widget render, screenshots hoặc native smoke; không coi static
  analysis là xác nhận visual fidelity hay responsive pass.

Sau khi môi trường cho phép Flutter compiler, chạy `flutter test`; để xuất hình
tham chiếu app vào thư mục scratch, đặt biến môi trường `EVIA_CAPTURE_DIR` rồi
chạy `flutter test test/widgets/evia_screens_test.dart --plain-name "render all requested frames"`.
Capture test dùng font Roboto từ Flutter SDK nếu có `FLUTTER_ROOT`. Đối chiếu
từng hình với node Figma trong design traceability trước khi visual sign-off.

## Mẫu test case tiếp theo

## My Events / Rewards — kết quả kiểm tra bổ sung 04/11/2026

`test/widgets/activity_screens_test.dart` có 18 route, mỗi route kiểm tra 360/412dp
và text scale 1x/2x. Có thêm flow tests cho Keep/Cancel Registration và đổi café
→ receipt → locker → voucher. `test/viewmodels/activity_view_model_test.dart`
kiểm tra chọn ngày/calendar draft, year boundary, cancellation counts, daily
reward một lần, redemption một lần, insufficient balance, deposits giữ nguyên,
history filters và mã check-in sai/lặp.

Lệnh scoped: `flutter test test/widgets/activity_screens_test.dart test/viewmodels/activity_view_model_test.dart --concurrency=1`.
Lượt có thêm `EVIA_ACTIVITY_CAPTURE_DIR` xuất 18 PNG + asset geometry JSON vào
scratch, gồm **44 tests đạt**: 18 responsive, 3 user flows (kể cả catalog search),
18 captures, 5 VM tests.
Không cần Firebase credentials, network hoặc camera/emulator cho các tests này.

`flutter pub get`, `dart format --output=none --set-exit-if-changed lib test`,
`flutter analyze` đã chạy. Assets mới: 230/230 tồn tại và không rỗng.

Lượt baseline toàn bộ suite trước khi thêm nhóm mới phát hiện 5 tests lỗi ở
`evia_screens_test.dart` do overflow trong Discover/Following preview của nhóm
màn hình trước. Không quy các lỗi đó thành lỗi của 18 màn hình mới, và không
đánh dấu toàn bộ suite pass từ scoped run. Xem kết quả bàn giao cho lần full run
cuối: **46 đạt, 5 lỗi**, đều 5 tests cũ nói trên; các tests My Events/Rewards có
trong full run đều đạt. Catalog-search regression test được bổ sung và xác minh
qua scoped run sau đó. Chưa chạy native Android smoke hoặc Firebase/camera
backend integration.

| ID | Requirement / design ID | Layer | Preconditions | Steps | Expected | Automation source | Status |
|---|---|---|---|---|---|---|---|
| TODO | TODO | Unit/widget/native/E2E | TODO | TODO | TODO | TODO | Chưa thực hiện |

## Mẫu ghi nhận run thật (để trống đến khi chạy)

- Commit / build: TODO
- Thiết bị / Android API / viewport / text scale: TODO
- Môi trường Firebase: TODO
- Lệnh / timestamp / người chạy: TODO
- Kết quả thực tế và đường dẫn log/screenshot: Chưa ghi nhận trong template
- Defects / follow-up: TODO

TODO: native Google Sign-In cancel/failure, Storage Rules deny/allow theo quyền,
FCM permission/token/background delivery, Remote Config fetch/cache, Analytics
DebugView. Xem [ca kiểm thử Crashlytics](EVIA_Crashlytics_Implementation.md)
để nghiệm thu Web Admin và Android QA trên Firebase. Xác nhận công cụ
Google ARTEMIS trước khi thêm E2E vào `e2e_test/`.

## Đợt 3 — Registration / Profile

Scoped command: `flutter test test/widgets/registration_screens_test.dart test/viewmodels/registration_view_model_test.dart`.
Set `EVIA_FLOW_CAPTURE_DIR` tới thư mục scratch để xuất 17 PNG và geometry JSON.
Lượt cuối **46 tests đạt**: 17 responsive (360/412dp, scale 1x/2x), 17 captures,
3 UI flows và 9 ViewModel tests. UI flows phủ detail → register → loading →
success → ticket, sửa lỗi form, mark all notifications read. VM tests phủ identity
validation/consent, debit một lần, chặn pending submit trùng, failed/full giữ form
và ví, waitlist/walk-in không giữ coin, dispose/invalidate trong pending request,
saved filters/remove, interests tối thiểu 3 và notification unread count.

`flutter pub get`, format check và `flutter analyze` đều thành công. Full suite
sau khi thêm nhóm mới: **76 đạt / 5 lỗi**, vẫn đúng 5 tests cũ ở
`test/widgets/evia_screens_test.dart` (Discover/Following overflow). Không sửa
mismatch ngoài phạm vi. Scoped tests đợt 3 đạt sau lượt tinh chỉnh layout cuối.
180 local exports không rỗng; audit SVG native root dimensions/callsite/geometry
trong cả 17 capture không có mismatch. Không phải pixel-diff hoặc Android visual
sign-off. APK debug biên dịch thành công; Gradle in cảnh báo native-access/KGP
của Firebase plugins hiện có. Chưa kiểm thử real registration/backend/camera.

## Backend Firebase — run thật 04/11/2026

Scope: chỉ `functions/`, Firebase config/Rules/indexes và docs; working-tree run,
chưa có commit/PR, chưa cloud deploy. Không chạy lại toàn bộ Flutter/Dart tests vì task không sửa UI/domain Dart.
Sau cấu hình Auth/SHA thật và sinh lại FlutterFire config, có build APK debug
riêng; xem kết quả bổ sung bên dưới. Kết quả UI cũ không đại diện
cho backend mới và các lỗi cũ chưa được sửa trong task này.

Toolchain thực tế: Node22.23.4, Java21 JBR, Firebase CLI15.30.2. Chạy từ repo root
với toolchain trên PATH, `FUNCTIONS_DISCOVERY_TIMEOUT=60`:

```powershell
npm --prefix functions run test:emulator
```

Kết quả cuối: TypeScript build đạt, **20 pass / 0 fail / 0 skipped**.
Log: `evidence/backend/emulator-tests.log`. Gồm signup once/interest validation,
last-seat race, cancel once/reopen, quotes/terms/requestId conflicts, scoped staff
QR + revocation, walk-in intent/expiry/replay, daily race/Vietnam midnight/gap/year
rollover, stock race/voucher owner/expiry/physical reward, insufficient balance,
follow races, inbox owner/read cutoff, FCM token reassignment/rotation, catalog
feeds/pagination/My Events, catalog validation/dry-run, real HTTP Callable Auth.

Firestore/Storage tests dùng **Auth Emulator ID token qua REST**, không dùng Admin
SDK để giả vờ kiểm tra Rules. Phủ own/public reads và từ chối cross-UID, direct
wallet/profile/event/attendance writes, private secrets/devices, unfiltered catalog,
PDF wrong type/size/overwrite. Test harness Admin SDK chỉ tạo test fixtures và
assert state trong demo project; có guard project/loopback trước clear dữ liệu.

Một lượt trước phát hiện Storage Emulator coi upload ghi đè như create: thêm
`resource == null` và chạy lại tới pass. Không đánh dấu pass lượt trước lỗi.
FCM thật bị bỏ qua trong Emulator; test token binding không chứng minh delivery.
Emulator không kiểm tra composite index requirements như cloud. Chưa có native
Google OAuth/camera/export/push, cloud Rules/index build/cost/latency evidence.

`npm --prefix functions audit --omit=dev --json`: 6 moderate transitive findings,
0 high/critical, ghi tại `evidence/backend/npm-audit.json`. Chuỗi chủ yếu nằm ở
Firestore SDK → gaxios/rimraf → glob/minimatch; chưa áp dụng breaking override
hoặc `--force`. API không nhận glob pattern/path filesystem từ client; đây không
phải chứng minh hoàn toàn không thể khai thác. Kiểm tra lại SDK upstream trước
production. Audit command exit1 do findings, không phải audit sạch.

Bổ sung cấu hình Android thật: FlutterFire CLI sinh lại config sau khi bật
Google/email-password và thêm debug SHA. `flutter build apk --debug` **PASS**
(assembleDebug 75.9s); log `evidence/backend/flutter-build-apk.log`. Có warning
Kotlin Gradle Plugin từ Firebase plugins hiện có. Chưa cài/chạy lại APK hoặc
đăng nhập trên thiết bị ở lượt này; không suy ra native OAuth pass từ build.
Không sửa UI/Dart business logic; config sinh tự động vẫn Git-ignore.

## Migration project nhóm — 04/11/2026

- Đích `prm393-31822`, billing đã enabled (không liên kết billing mới).
- Chỉ sửa config/triển khai backend, thêm script deploy nhóm 4; không sửa UI.
- Chạy lại `npm --prefix functions run test:emulator`: **20/20 PASS** sau cấu hình
  CPU fractional. Log `evidence/firebase-migration/emulator-tests.log`.
- FlutterFire CLI sinh config mới, native compiled resources xác nhận project ID
  và app ID mới (`compiled-project-check.txt`). `flutter build apk --debug` PASS
  42.6s, còn warning KGP từ plugins hiện có.
- Pixel 5 headless: `flutter run -d emulator-5554 --debug --route=/foundation
  --dart-define=FIREBASE_ENABLED=true --no-resident` PASS. XML + PNG thực tế hiển thị
  Firebase đã khởi tạo (`android-foundation.xml/png`, `android-startup.log`).
  Đây chỉ xác nhận bootstrap; không suy ra login/FCM/ba luồng UI pass.
- Firestore cloud: 14 indexes READY. Anonymous public filtered query 200, unfiltered
  query và private wallet GET 403 (`cloud-rules-smoke.json`). Không tạo test users
  hay seed business data trên project thật.
- Rollout Functions bị quota ở các lượt đầu; logs lỗi được giữ, chỉ đếm revision
  ready + smoke thành công sau khi deploy theo nhóm nhỏ. Xem `firebase-migration.md`
  để biết trạng thái chốt; không dùng Functions API ACTIVE một mình làm bằng chứng
  vì Cloud Run vẫn có thể đang phục vụ revision cũ.

Kết quả migration cuối: **32 Functions ACTIVE + 32 latest Cloud Run revisions READY**,
14 indexes READY. **4/4 HTTP Callable + 3/3 Firestore Rules cloud smoke đạt**.
Logs/JSON thật tại `evidence/firebase-migration/`. Script deploy nhóm 4 đã chạy
đủ 8 nhóm, exit0; đây cũng là validation thực tế cho script, không chỉ AST check.
Không ghi test users/data lên cloud. Không rerun toàn bộ Flutter UI tests.
## Rewards UI/UX regression — 05/11/2026

`test/widgets/rewards_regression_test.dart` kiểm tra tote → confirm → success →
locker → đúng mã, nhiều receipt và chọn đúng món, mã không tồn tại, empty states,
header/khung ví không nhảy khi chuyển tab, vùng bấm tối thiểu 48dp, Profile mở đúng
màn hình, milestone sau check-in và lịch sử khác tháng. Có kiểm tra café/tote đã
lưu ở cả 360/412dp, text scale 1x/2x. VM tests thêm ngưỡng 249/250 xu, debit đúng
giá, chống đổi lặp sau khi kiếm thêm xu và lọc nhóm lịch sử theo tháng.

`flutter pub get`, `dart format lib test`, `flutter analyze` đạt.
`flutter test --concurrency=1`: **90 đạt / 5 lỗi**, các lỗi đều ở
`evia_screens_test.dart`, cùng 5 tests đã lỗi trước sửa Rewards; không ghi toàn bộ
suite đạt. Toàn bộ tests Rewards mới đạt.

Capture riêng 9 route Rewards sau sửa: **18 tests đạt** (9 responsive và 9
captures); đã xem đủ 9 ảnh. Capture success/locker/voucher gọi redeem café trong
test-only state; runtime chưa có receipt thì render empty state. Không nhầm fixture
capture với reward/backend thật. APK debug x64 đã build/cài thành công. Native smoke
trên emulator-5554: Skip → Rewards → đổi tote 400 → số dư 20 → My Rewards → đúng
ảnh/mã tote đã đạt. Xem [báo cáo Rewards](rewards-ui-ux-review.md) cho phạm vi và ảnh.

## Android debug build reuse regression — 04/11/2026

Đổi Android host build tracking, không đổi Dart/app logic. Native checks:

- `flutter build apk --debug --target-platform android-x64 --no-pub` thành công.
- Hai `flutter run -d emulator-5554 --no-resident --no-pub -v` thành công;
  lượt warm cuối Gradle8.6s, install1.893s, sync4.1s, tổng39.739s.
- MainActivity được xác nhận là top resumed activity. Startup vẫn có skipped
  frames; không coi đây là runtime performance sign-off.
- APK không đổi: task copy APK/assets UP-TO-DATE, clean hook SKIPPED.
- APK đích thiếu: tái tạo, SHA-256 bằng bản gốc.
- Entrypoint probe ngoài project: APK thay đổi, hash bản copy khớp packaged APK;
  trở lại entrypoint gốc thành công. Không cài probe lên emulator.
- Packaged APK thiếu: AGP đóng gói lại và Flutter copy đúng output.
- Không chạy clean/xóa dependency cache/sửa SDK/tắt Defender/gỡ Firebase.
  Không chạy lại Dart widget suite vì thay đổi chỉ ở Gradle; lỗi UI baseline
  ghi ở các mục trước không được đánh dấu đã sửa.

Xem [Build performance](build-performance.md) để biết phạm vi debug không flavor,
không split và giới hạn so sánh các lượt đo.


## Rewards static preview - 05/11/2026

Current implementation retains visible mock fixtures and removes local coin
mutations/persistence. Check-in, redemption and deposit registration wait for API.
Earlier transaction-flow evidence above is historical.

Validation for this change:
- flutter pub remove shared_preferences completed dependency resolution.
- dart format lib test completed; flutter analyze: no issues.
- 61 tests passed across rewards_regression_test, activity_screens_test,
  registration_screens_test, activity_view_model_test and registration_view_model_test.
- Debug x64 APK build succeeded. Full suite was not rerun.
- git diff --check passed.
- APK installed successfully on emulator-5554. am start -W timed out; subsequent
  dumpsys confirmed MainActivity as topResumedActivity. No visual startup sign-off.

### Validation tài khoản mock — 05/11/2026

- `flutter pub get`, `dart format lib test`, `flutter analyze`: đạt.
- 12 tests tập trung (demo auth, auth guard, EviaViewModel, login keyboard): đạt.
- `flutter test`: 128 đạt, 5 lỗi trong `evia_screens_test.dart` (layout overflow,
  ListTile Material assertion và flow UI). Chưa sửa nhóm UI này trong task tài khoản.
- `flutter build apk --debug --dart-define=DEMO_AUTH=true --target-platform android-arm64 --no-pub`: đạt.
- Chưa xác nhận thao tác đăng nhập thủ công trên thiết bị; không coi unit tests là native E2E.

### Validation mô phỏng UI — 05/11/2026 (mới nhất)

- `flutter pub get`, `dart format lib test`, `flutter analyze`, `git diff --check`: đạt.
- `flutter test`: **141/141 đạt**. Bao gồm giữ/hoàn cọc và đăng ký lại, chặn
  thao tác trùng/thiếu xu/guest, daily/check-in một lần, receipt đúng phần thưởng,
  reset, gallery chỉ bật khi demo và tra được đủ 44 routes.
- Widget flow demo: Confirm Registration → Registration Successful, ví còn 1.900;
  Reset demo → 2.000. Gallery/Discover/Explore/Following kiểm ở 360dp/412dp,
  gồm text scale 2×. Sửa ListTile thiếu Material và Row overflow gặp trong lượt này;
  test Following dùng auth fake để thực sự render protected screens.
- `flutter build apk --debug --dart-define=DEMO_AUTH=true --target-platform android-arm64 --no-pub`: đạt.
- Kết quả này thay cho 5 lỗi UI được ghi ở lượt tài khoản mock trước đó.
- Chưa kiểm chứng từng thao tác bằng tay trên điện thoại; widget tests không phải
  native E2E. Không chạy Google/QR camera/email/backend nghiệp vụ thật.

## Luồng Discover, Search và Following — 05/11/2026

Đã kiểm tra Skip mở Discover Guest, Search & Explore mở cùng route, Filter
mở riêng và Apply giữ truy vấn. Mở kết quả sang Schedule, đổi Location và
quay lại giữ đúng danh sách. Their Events lấy đăng ký xác nhận trong phiên.
Organizers lấy trạng thái Follow. Guest được chuyển tới Login khi mở Following.
Đã kiểm tra đổi tài khoản và màn hình ở 360/412dp với cỡ chữ 1x/2x.

Full suite đạt 132 test trước khi siết danh sách Their Events để chỉ nhận
đăng ký xác nhận. Sau thay đổi cuối, 31 test liên quan Evia và Registration
đạt, gồm kiểm tra Going không xuất hiện trong Their Events. Analyze sạch.
Các ca đăng nhập dùng phiên kiểm thử, không xác nhận tích hợp auth/backend thật.

### Validation hợp nhất `origin/main` vào backend — 05/11/2026

- Hợp nhất điều hướng Discover Guest, Search, Schedule và Their Events với
  adapters Firebase hiện có; giữ onboarding lưu server, không Waitlist, hoàn
  cọc 30% làm tròn xuống và bản sửa vé không phụ thuộc cache My Events.
- `flutter pub get`, `dart format lib test`, `flutter analyze`: đạt.
- `flutter test`: **200/200 đạt**, gồm hai ca hồi quy mới cho Their Events đọc
  đăng ký server/mở đúng ID và widget tóm tắt nhận ảnh URL.
- `flutter build apk --debug --dart-define=FIREBASE_ENABLED=true --dart-define=DEMO_AUTH=false --target-platform android-arm64 --no-pub`: đạt.
- Chưa cài/chạy lại bản merge trên điện thoại và chưa kiểm tra Firebase trực tiếp
  trong lượt này. Không thay đổi hay deploy Functions/Rules.

### Nút demo cố định trên vé — 05/11/2026

- Test hồi quy kiểm nút bấm được ngay, nằm ngoài vùng cuộn, khóa khi đang chờ
  server và đổi QR sang confirmed sau thành công; tài khoản chưa bật demo không
  thấy nút. `flutter test`: **200/200 đạt**; format/analyze sạch.
- APK debug bật Firebase thật, tắt local demo auth: build/cài thành công trên
  SM-G996N. Đã mở đúng vé owner gửi và thấy nút ở footer; không bấm xác nhận
  trên vé này để owner tự demo. Không ghi attendance hoặc sửa ví trong lượt này.
- Bật thêm quyền demo server cho đúng chủ vé, kiểm tra các field hồ sơ khác giữ
  nguyên. Không thay đổi Functions/Rules hoặc quyền staff/admin.

## Flutter Admin — 06/11/2026

- Web độc lập: format/analyze và 11/11 tests đạt; auth guard signed-out/staff,
  pending/retry, schema mapping/giờ VN, rendered sections 360/412/1440 với text 2×.
- Backend full Emulator suite 76/76 đạt; admin không cần staff assignment hoặc
  allowlist voucher/milestone, giữ security/receipt/stock/counter checks.
- Mobile regression: analyze, 218/218 tests đạt; không đổi code app sinh viên.
- Release web build đạt. Đăng nhập/read và tạo CLB chưa công khai đã kiểm trong
  browser trên Firebase thật. Không claim đã quét camera/push portal end-to-end.
- Cloud status và giới hạn Analytics/Crashlytics/Hosting ghi tại
  [evidence/admin-flutter](../evidence/admin-flutter/).


## AI filters — 09/11/2026

AI filters có regression tests ở test/ai_filter_test.dart. Xem docs/ai-feature.md cho phạm vi và các evidence cloud/ARTEMIS còn thiếu.
