# Checklist hoàn thành Lab 3 — Evia

Cập nhật: **04/11/2026**. Dùng để theo dõi từ hiện trạng đến lúc nộp bài.

- `[x]`: đã có implementation/evidence trong phạm vi mô tả; không có nghĩa toàn bộ nhóm đã xong.
- `[ ]`: chưa làm, mới làm một phần hoặc chưa đủ bằng chứng xác nhận.
- Chỉ tick khi đạt điều kiện và ghi được log, screenshot, trace hoặc commit liên quan.
- Backend hoạt động riêng không chứng minh app đã tích hợp. Không dùng UI mock làm bằng chứng dữ liệu thật.

Đề gốc: [PRM393 Lab 3](../PRM393%20-%20Lab%203%20Cloud-Enabled%20Mobile%20App%20%28Firebase%2C%20Patrol%2C%20AI%20Code%20Review%29%20%281%29.pdf).
Theo dõi kỹ thuật và chính sách nghiệp vụ: [IMPLEMENTATION_TRACKER.md](IMPLEMENTATION_TRACKER.md).
Nếu thông tin lịch sử trong tracker khác kết quả mới, đối chiếu evidence mới nhất trước khi cập nhật.

## 1. Thiết kế, phạm vi và kiến trúc

- [x] Có source Flutter với MVVM, Riverpod, go_router, service contracts và DI.
- [x] Có tokens/theme và các widget dùng lại cho button, input, loading/empty/error, responsive layout.
- [x] Có source và mapping Figma cho 44 màn hình/trạng thái Evia.
- [ ] Hoàn thiện traceability cho từng màn hình, cả 3 flow và component: route/widget/nguồn dữ liệu/trạng thái.
- [ ] Đối chiếu đủ thiết kế Lab 2 đã duyệt: persona, success criterion, navigation, DESIGN.md và flutter-handoff.md.
- [ ] Ghi mọi thay đổi thiết kế cùng lý do; cập nhật Figma để khớp app theo scope được duyệt.
- [x] Bổ sung sequence bootstrap thực tế và bảng ViewModel → dependencies/service vào architecture.md; business integration vẫn pending.
- [ ] Kiểm tra toàn bộ flow thật tuân thủ View → ViewModel → Repository → Service → SDK; không business logic/SDK trong View.
- [ ] Mỗi màn hình tải dữ liệu có state loading/empty/error/data rõ ràng, retry và dependency có thể override trong tests.

Tham chiếu: [design-traceability.md](design-traceability.md), [architecture.md](architecture.md).

## 2. Backend, dữ liệu thật và các flow trên app

- [x] Có backend nghiệp vụ riêng: tài khoản, follow/bookmark, đăng ký/hủy, QR, ví/ledger, daily, đổi thưởng và notifications.
- [x] Evidence migration ghi nhận 32 Functions đã deploy, 14 indexes READY và Rules đã release trên `prm393-31822`.
- [x] Evidence backend ghi nhận 20/20 Emulator tests đạt, có kiểm tra phân quyền, race và idempotency.
- [ ] Chốt nguồn dữ liệu sự kiện/CLB/phần thưởng và taxonomy sở thích được duyệt; đưa dữ liệu thật vào backend.
- [ ] Nối Flutter với backend qua real adapters; thay các providers pending tương ứng.
- [ ] Loại mock/hard-coded business data khỏi bản nộp; test fixtures chỉ phục vụ tests.
- [ ] Hoàn thiện khám phá/tìm kiếm/lọc/chi tiết, follow và bookmark với dữ liệu thật.
- [ ] Hoàn thiện đăng ký/hủy, Event Full, đặt cọc, vé và My Events với dữ liệu thật.
- [ ] Hoàn thiện QR check-in thật, camera và công cụ verifier có quyền phù hợp.
- [ ] Hoàn thiện ví, lịch sử xu, daily, đổi thưởng và voucher với backend thật.
- [ ] Hoàn thiện profile/sở thích/danh sách thông báo thật theo phạm vi đã chốt.
- [ ] Cả 3 flow Lab 2 chạy end to end, gồm nhánh thay thế, lỗi/phục hồi và Back; mọi màn hình Final UI đều truy cập được.
- [ ] Mỗi màn hình tải dữ liệu xử lý được offline, permission denied, empty và lỗi server bằng thông báo rõ ràng.
- [ ] Đồng bộ UI demo với scope hiện tại: không Waitlist/milestones, walk-in chỉ QR, Café 200 xu, tối thiểu 3 sở thích không Skip.
- [x] Chốt Monthly Gift, admin voucher tại nhà tài trợ, no-show và đăng ký lại; xem [BACKEND_POLICIES.md](BACKEND_POLICIES.md).
- [x] Triển khai/kiểm thử các policy mới trên Emulator, gồm đăng ký lại với vé mới, monthly/no-show jobs và admin voucher.
- [x] Deploy revision mới: 34 Functions/Run revisions READY; 2 Scheduler jobs ENABLED, timezone/target/IAM đã verify. Không manual job hoặc cấp voucher-admin role; chưa có business execution evidence trên dữ liệu thật.
- [x] Chuẩn bị [quy trình dữ liệu thật](DATA_READINESS.md) và [handoff frontend](FRONTEND_HANDOFF.md); chưa có dataset được duyệt.

Tham chiếu: [backend-integration.md](backend-integration.md), [firebase-migration.md](firebase-migration.md), [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md).

## 3. Firebase Authentication

- [x] Đã có cấu hình Firebase thật; evidence ghi nhận Google/email-password providers và debug SHA được cấu hình.
- [ ] Google Sign-In hoạt động trên Android với tài khoản test riêng.
- [ ] App điều hướng theo auth state; bảo vệ các route cần đăng nhập, guest chỉ dùng chức năng được phép.
- [ ] Hủy đăng nhập, lỗi mạng và đăng nhập thất bại đều có thông báo.
- [ ] Sign-out xóa state/dữ liệu cục bộ của người dùng; không lộ dữ liệu tài khoản trước khi đổi tài khoản.
- [ ] Hoàn thiện email/password signup/sign-in/reset theo scope bổ sung của dự án.
- [ ] Lưu ảnh signed-out/signed-in và Firebase Auth Users tab làm evidence.

## 4. Tạo file và Cloud Storage

- [x] Có Storage Rules và evidence Emulator tests quyền sở hữu, loại/kích thước file, chống overwrite.
- [ ] Tạo ít nhất 1 file từ nội dung thật người dùng đang xem, ví dụ PDF summary.
- [ ] Upload theo đường dẫn riêng từng UID; hiển thị tiến trình và download URL.
- [ ] Xử lý lỗi tạo file/upload, mất mạng và permission denied; cho phép thử lại hợp lý.
- [ ] Xác minh upload/read thật và từ chối truy cập chéo tài khoản theo policy.
- [ ] Lưu ảnh luồng app và file list trong Firebase Console.

## 5. Push notification — FCM

- [x] Có backend inbox, device token binding và trigger gửi thông báo; chưa chứng minh delivery thật.
- [ ] App xin quyền notification trên Android 13+ và xử lý trường hợp bị từ chối.
- [ ] Đăng ký/cập nhật token, xử lý token refresh và sign-out/đổi tài khoản.
- [ ] Nhận push thật khi app ở foreground, background và terminated.
- [ ] Có notification center lưu thông báo trong app và trạng thái đã đọc.
- [ ] Bấm push mở đúng màn hình, có kiểm tra auth/quyền truy cập.
- [ ] Lưu evidence gửi từ Firebase Console và nhận ở cả 3 trạng thái app.

Web admin soạn/gửi notification là **phần mở rộng tương lai**, không phải điều kiện bắt buộc của Lab 3. Checklist này không yêu cầu xây web admin.

## 6. Analytics, Crashlytics, Remote Config và khu demo

- [x] Viết analytics plan 17 events, map flow/trigger/questions/typed parameters và quy tắc không PII; chưa tracking runtime.
- [x] Plan phủ sign-in/sign-out, search, các loại detail, export/upload; dùng recommended names khi phù hợp. Evidence runtime vẫn pending.
- [ ] Tích hợp Analytics thật, set user ID sau login và có DebugView evidence cho từng event.
- [ ] Crashlytics nhận 1 non-fatal từ error path thật và 1 test crash, kèm user ID và ít nhất 1 custom key.
- [ ] Lưu evidence dashboard cho cả non-fatal và test crash.
- [ ] Remote Config có ≥2 tham số làm thay đổi hành vi nhìn thấy được, cùng in-app defaults và xử lý lỗi fetch.
- [x] Khoanh vùng key/config contract để chuẩn bị web admin: [REMOTE_CONFIG_PLAN.md](REMOTE_CONFIG_PLAN.md). Mới là tài liệu; chưa có runtime integration.
- [ ] Tích hợp `discover_featured_enabled` và `catalog_page_size` theo config contract; banner chung là phần mở rộng khi cần.
- [ ] Đổi giá trị trên Console áp dụng vào app không build lại; lưu ảnh trước/sau và giá trị Console.
- [ ] Có Firebase demo area: notification center, export/upload, Remote Config và các test actions Crashlytics.
- [ ] Mỗi Firebase service xử lý failure case bằng thông báo, không crash.

Tham chiếu: [analytics-plan.md](analytics-plan.md), [REMOTE_CONFIG_PLAN.md](REMOTE_CONFIG_PLAN.md).

## 7. UI/UX, accessibility và kiểm thử Flutter

- [ ] Sửa 5 tests đang lỗi: 4 ca responsive overflow và 1 ca navigation gặp assertion ListTile.
- [ ] Đối chiếu Figma–app bằng ảnh/render thật cho toàn bộ màn hình; ghi nhận deviations.
- [ ] Kiểm tra 360dp/412dp, text scaling, SafeArea, keyboard và scroll; không cắt chữ/overflow.
- [ ] Kiểm tra contrast, touch target ≥48dp, body ≥14sp; trạng thái không chỉ thể hiện bằng màu.
- [ ] Bổ sung/kiểm tra Semantics labels ở controls quan trọng phục vụ accessibility và ARTEMIS.
- [ ] Kiểm tra screens dùng theme tokens/shared components, không hard-code styles trái quy tắc.
- [ ] Chạy validation sau tích hợp: pub get, format, analyze và toàn bộ Flutter tests.
- [ ] Build APK và smoke test trên Android; xác minh app vẫn khởi động khi chưa bật Firebase.
- [ ] Lưu log theo commit/build; kiểm thử hành vi lỗi/retry, auth guard, lifecycle và submissions trùng.

Kết quả kiểm tra gần nhất trong chat ngày 04/11/2026: `flutter analyze --no-pub` đạt; `flutter test --no-pub --reporter compact` **76 đạt / 5 lỗi**. Chưa phải kết quả sau các thay đổi tương lai.

## 8. Google ARTEMIS E2E

- [ ] Cài/cấu hình Python 3.12+, uv, ADB, thiết bị, model API key; pin ARTEMIS commit trong README.
- [ ] Viết ≥10 test cases với ID, flow/screens, precondition, instruction và expected result.
- [ ] Phủ cả 3 flow và nhánh thay thế/lỗi, sign-in/out, search/primary action, top-level tabs, mỗi loại detail, export/upload, Remote Config.
- [ ] Có ít nhất 1 error-path test và 1 native interaction.
- [ ] Có pytest suite trong e2e_test/, conftest.py và cấu hình dependencies; dùng ArtemisClient, test độc lập thứ tự.
- [ ] Assert structured values agent quan sát được, không chỉ status SUCCESS.
- [ ] Mỗi test chạy ≥3 lần bằng Flash profile; có trace/screenshot/replay từng run, pass rate và thời gian trung bình.
- [ ] Điều tra và ghi lại nguyên nhân/fix cho flaky, failed hoặc skipped cases.
- [ ] Có ít nhất 1 test kiểm tra analytics event qua Logcat/DebugView.
- [ ] Chạy exploratory Pro profile 15–30 phút và ghi các vấn đề tìm thấy.
- [ ] Dùng Google test account riêng; giữ credentials/model key ngoài repository.

Tham chiếu: [test-plan.md](test-plan.md), [e2e_test/](../e2e_test/).

## 9. AI Code Review

- [x] Review backend local bằng Codex, [lưu output](../evidence/backend-readiness/ai-review.md); chưa review PR/Flutter.
- [x] Ghi 5 findings gắn baseline file:line, gồm bug/validation/contract/integration gap.
- [x] Có quyết định/lý do từng finding trong code-review.md.
- [x] Sửa CR-01/02/03, mỗi finding một commit riêng có ID; ghi hashes local vào record.
- [x] Xác minh fix commits đã có trên remote và bổ sung links GitHub vào review record; chưa tạo PR/approval.
- [ ] Khai báo tất cả AI tools đã dùng và mục đích sử dụng.

Tham chiếu: [code-review.md](code-review.md). Checklist này không thay thế AI review record.

## 10. Hoàn tất hồ sơ và nộp bài

- [x] Source/backend/config được phép chia sẻ, docs và evidence đã commit/push lên nhánh KietDM/feat/backend; xác minh remote a76de1f. Chưa merge hoặc tạo PR.
- [ ] Kiểm tra không commit secrets, service-account keys, API keys bí mật, signing keys hoặc dữ liệu cá nhân.
- [ ] Đối chiếu tên repo yêu cầu `PRM393_Lab03_<StudentID>` với giảng viên trước khi đổi tên repo hiện tại.
- [ ] README có topic/API, cách chạy app/tests, versions, AI tools, video link và bản đồ deliverables.
- [ ] Report PDF **8–12 trang** tại `report/Lab03_<StudentID>.pdf`, đủ nội dung mục 9 của đề và evidence cho từng claim.
- [ ] Slides PDF **12–15 slide** tại `slides/Lab03_<StudentID>_slides.pdf`, đủ chủ đề, ảnh so sánh, Firebase, tests và review.
- [ ] Video **5–10 phút**: login, 3 flow và lỗi, export/upload, push, đổi Remote Config không rebuild, Crashlytics, ARTEMIS và review fix.
- [ ] Evidence Console khớp project ID trong cấu hình app; tránh dùng ảnh project cũ làm evidence project hiện tại.
- [ ] Kiểm tra repo/report/slides/video mở được trong cửa sổ riêng tư.
- [ ] Chuẩn bị giải thích ViewModel, quyết định review; chạy ARTEMIS và đổi Remote Config trực tiếp khi giảng viên yêu cầu.
- [ ] Xác nhận các placeholders của đề như hạn nộp, số commits/ngày và quy định làm nhóm với giảng viên.

## Thứ tự thực hiện đề xuất

1. Chốt nguồn dữ liệu/chính sách → Auth thật → nối dữ liệu và 3 flow.
2. Sửa UI/test failures → export/upload → FCM.
3. Analytics plan/tracking → Crashlytics → Remote Config → demo area.
4. Validation Android → ARTEMIS → AI review và fix commits.
5. Report → slides → video → kiểm tra quyền truy cập và nộp.

## Nhật ký cập nhật

| Ngày | Mục hoàn thành/thay đổi | Commit/build | Evidence hoặc blocker |
|---|---|---|---|
| 04/11/2026 | Tạo checklist từ đề và kiểm tra hiện trạng trong chat | Working tree | [Tracker](IMPLEMENTATION_TRACKER.md), [test plan](test-plan.md), [migration](firebase-migration.md); chưa chạy lại tests ở lượt tạo tài liệu |
| 04/11/2026 | Deploy backend policy revision + 2 Scheduler jobs; 34 Functions/Run revisions, 6/6 Callable + 3/3 Rules smoke đạt | Source baaa372 | [Release](backend-release.md); không seed/test users hoặc chạy job thủ công |
| 04/11/2026 | Push release evidence và xác minh remote | a76de1f | [Release](backend-release.md), branch KietDM/feat/backend; không merge main |
