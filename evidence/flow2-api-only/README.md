# Flow 2 — Tham dự, hủy và notifications

Yêu cầu owner: chỉ nối API vào màn hiện có; sau đó cho phép thêm một nút nhỏ
trên vé để demo đã quét vì chưa có màn staff. Owner đồng ý hỏi quyền Android
khi mở Notifications và yêu cầu dùng Firebase Cloud Messaging.

## Phạm vi

- My Events/lịch đọc `listMyEvents`, ngày Việt Nam; Going, Registered, Attended,
  No-show và xu attendance lấy từ server, không bịa Gate B hoặc giờ check-in.
- Hủy registered: `cancelRegistration`, cùng request ID/receipt khi timeout;
  hoàn floor(cọc × 30%), không cộng xu trước server. Hủy Going dùng
  `setWalkInGoing(false)`, không phải hủy vé và không hoàn cọc.
- Vé QR refresh từ server. Sau check-in hiển thị Attendance confirmed trong ô
  QR cũ, không hiện lỗi QR cho vé đã dùng. Không thêm ô mã dự phòng trên vé.
- Walk-in: camera thật trong khung cũ, nhập mã bằng dialog hiện có;
  `verifyWalkInQr`/`verifyWalkInCode` nhận `expectedEventId` tùy chọn và từ chối
  QR/mã khác sự kiện trước khi ghi attendance/wallet. API cũ vẫn tương thích.
- Inbox: phân trang notification thật, mark-read chờ server, mở event/vé từ
  entity thật. Poll 30 giây khi mở inbox; FCM foreground cũng invalidate inbox.
- FCM: adapter thật, đăng ký thiết bị có Auth; chỉ hỏi quyền khi mở Notifications.
  Restore chỉ dùng quyền đã được cấp. Token refresh được đăng ký lại; logout
  gỡ binding và vô hiệu hóa token trước khi sign out. Chặn đăng ký muộn sau logout.
  Background notification do FCM/Android hiển thị; foreground cập nhật dữ liệu
  trong app. Không thêm dịch vụ push khác hoặc bật Analytics/Crashlytics.

## Nút demo do owner yêu cầu

`demoConfirmAttendance({eventId, requestId})` là callable riêng. User document
phải có **cả** `isDemo:true` và `demoAttendanceEnabled:true`; event phải
`isDemo:true`, published/public. Những field này chỉ server/admin ghi được.
Nút chỉ render trong debug, khi API profile/catalog xác nhận các cờ trên.

Đăng ký phải có vé active thuộc chính UID. Transaction đổi vé thành checked_in,
registration thành attended, hoàn toàn bộ cọc và cấp reward snapshot đúng một
lần. Walk-in dùng reward event. Receipt chống retry/race. Attendance được đánh
dấu `isDemo:true`, `verificationMethod:debug_demo_button`. Demo **bỏ cửa sổ
check-in** để giảng viên xem được sự kiện tương lai; QR/mã thật vẫn kiểm giờ và
quyền staff như trước. Không đưa credentials/quyền staff vào APK.

Chỉ bật cờ cho hai tài khoản vận hành demo có sẵn; tài khoản thật không tự được
bật. Trước phát hành thật, admin bỏ `demoAttendanceEnabled` hoặc đặt false.
Đây là attendance demo có ghi Firebase/xu thật trong dataset demo, không phải
bằng chứng staff đã quét QR hoặc dữ liệu attendance thực tế.

## Kiểm tra

- [Backend Emulator](emulator-tests.log): 59/59 PASS, có flags/Rules/receipt/
  race/cancelled ticket/khác event và guard staff thật.
- [Flutter regression](flutter-test.log): **190/190 PASS**, có kiểm thử modal
  hủy được đóng sau refresh; [kiểm riêng](cancel-native-regression.log).
  Kiểm thử bổ sung ở [widget tests](widget-tests.log),
  [push/widget tests](push-widget-tests.log).
- [Giữ giao diện với cùng dữ liệu](ui-preservation.json): **14/14** phép so sánh
  7 màn/trạng thái × 360/412dp trùng toàn bộ RGBA; [log](ui-preservation.log).
  Đây là kiểm cùng fixtures trước/sau, không phải pixel-match với Figma hoặc
  dữ liệu live; nút demo và camera live là phần owner đã cho phép.
- [Analyze](analyze.log), [format](format.log), [build APK](build-apk.log).
- [APK live cuối](build-live.log) bật rõ FIREBASE_ENABLED=true, DEMO_AUTH=false;
  [SHA-256 bản cài](native-apk.json) trùng file APK live riêng. Đã dừng phiên
  `flutter run` của cùng workspace đang không có define Firebase và cài bản preview,
  tránh cài đè trong lúc kiểm thử. Source vẫn mặc định Firebase disabled.
- [Cloud preflight](functions-before.json) và [sau deploy](functions-after.json):
  **7/7 ACTIVE**, cùng source hash mới, Cloud Run latest-created = latest-ready.
- [Bật demo](demo-access-applied.json) cho đúng hai operator demo có sẵn,
  [backup](demo-access-before.json) và so sánh không đổi field khác.
- [Hủy native](cancellation-native-verification.json): cọc 50 đã hoàn 15,
  available 150 → 165, held 50 → 0. Lần thử đầu phát hiện modal chưa đóng sau
  server success; đã sửa bằng router giữ trước await, điều hướng live về My Events
  và có test hồi quy. Preview giữ thao tác pop và bộ lọc ngày cũ.
  Bản APK live cuối đã thử hủy vé Career cọc 0, modal đóng và My Events về 0;
  [ảnh sau hủy](cancel-returned-my-events.png), [snapshot](native-after-career-cancel.json).
  Sau đó tái đăng ký chính event này bằng API, giữ attendee snapshot/terms server,
  không bịa record vé hoặc sửa ví thủ công, để kiểm nút demo.
- [FCM native](fcm-native-verification.json): Android 14 xin quyền đúng khi mở
  Notifications, đăng ký một thiết bị, notification riêng của operator đến tray,
  bấm mở đúng event. [Hộp quyền](notification-permission.png),
  [màn event đã mở](fcm-opened-event.png). Không gửi broadcast tới user khác.
- [Nút demo native](demo-native-verification.json), [snapshot sau cùng](native-after.json):
  bấm trên vé Career đã đổi ticket sang Attendance confirmed, My Events Attended,
  cộng đúng 80, available 165 → 245, held 0. Nút biến mất sau thành công.
  [My Events sau demo](my-events-attended.png) không chứa QR token/MSSV/credentials.
- [Kết thúc phiên thử](native-session-cleanup.json): logout tài khoản demo trên
  máy, backend còn 0 FCM device của operator; khôi phục nguyên file Auth cache
  mã hóa đã backup trên thiết bị, không sửa sở thích/profile của phiên trước.

## Nguồn SDK

- [Firebase Flutter FCM](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
  và [nhận/mở thông báo](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages).
- Token APIs còn được SDK hỗ trợ nhưng đã deprecated. Giữ token API đồng bộ
  backend đang lưu token và gửi multicast bằng tokens; không trộn token/FID.
  Cần chuyển cả client, schema device và sender sang FID trước khi SDK bỏ API cũ.
- [mobile_scanner](https://pub.dev/packages/mobile_scanner): resolver chọn stable
  7.5.0; preview giữ hình minh họa, chỉ live dùng camera.

Flow 3, màn staff, ARTEMIS và E2E bằng camera quét vật lý chưa được nghiệm thu.
