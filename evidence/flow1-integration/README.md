# Flow 1 integration — 05/11/2026

> **SUPERSEDED — bộ màn riêng bị owner từ chối.** Logs này chỉ giữ lịch sử
> các lần chạy thật trước khi sửa API-only; không là bằng chứng UI hiện tại.
> Xem [flow1-api-only](../flow1-api-only/) cho kết quả sau khi nối lại màn gốc.

Project `prm393-31822`, Functions `asia-southeast1`. Flutter live mode bật
`FIREBASE_ENABLED=true`, không `DEMO_AUTH`. Không deploy/chỉnh backend đợt này.

- [pub get](pub-get.log), [format](format.log), [analyze](analyze.log): đạt,
  analyze không issues.
- [Flutter suite](flutter-test.log): **171/171 PASS**, gồm 22 tests mới cho
  repository/ViewModel/live screens. Tests nền tảng chạy với fake, không cloud.
- [APK build](build-apk.log): debug đạt. Plugin hiện có cảnh báo tương thích KGP
  cho phiên bản Flutter tương lai; không phải lỗi build hiện tại.
- [Native smoke](native-smoke.json): kết quả quan sát trên SM-G996N qua ADB,
  fingerprint APK và giới hạn. Không coi đây là ARTEMIS hoặc automated E2E.
- [Trước](before-native.json) và [sau](after-native.json): callable reads độc lập
  bằng account demo staff. Credentials nằm trong ignored `.local/`, không ở logs.

Đã quan sát guest catalog → login email/password → search Flutter (2 kết quả) →
bookmark → follow → đăng ký `demo-mobile-workshop` → vé/QR. Server giữ đúng 50 xu:
200/0 thành 150 available/50 held, đúng một deposit_hold và một vé active
`EV-1A98EDBA0E05`. Sau cài lại/khởi động lại và logout/login, My Events mở lại cùng
vé; số dư không thay đổi. Không tạo attendance/cộng thưởng để giả hoàn tất flow.

Các thao tác thử để lại một đăng ký demo, follow/bookmark và token/code vé có hạn
trên Firebase. Không hủy đăng ký vì policy hủy sẽ mất cọc. Không gửi email reset
vào mailbox demo, không test login tài khoản Google cá nhân, không chạy check-in,
redemption/FCM hay ARTEMIS. Onboarding lần đầu, signup và Google adapter chưa có
native acceptance của tài khoản trường mới; onboarding/error/retry có widget tests.
