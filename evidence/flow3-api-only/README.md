# Flow 3 — API vào giao diện gốc

Ngày 06/11/2026 theo giờ Việt Nam. Branch làm việc `KietDM/feat/backend`;
bằng chứng ghi nhận trước commit, chưa push. [Contract/cách demo](../../docs/FLOW3_INTEGRATION.md).

## Phạm vi và thiết kế

- Nối ví, Daily, manual milestone claim, catalog/đổi quà, locker/voucher và ledger.
- Không thêm màn Rewards mới. Giữ theme, assets fallback, thứ tự và các vùng UI.
- Owner đồng ý chỉ bổ sung Flexible/xuống dòng ở các hàng tràn chữ 2×.
- Dialog xác nhận giữ layout gốc. Sửa helper test MediaQuery có `size` thật:
  kích thước 0 trước đó khiến test nhìn thấy nút nhưng vùng nhận chạm sai.
- Màn voucher dùng QR thật trong ô cũ, chỉ cho chủ sở hữu khi chưa dùng/hết hạn.

## Validation local đã chạy

| Kiểm tra | Kết quả |
|---|---|
| `dart format lib test` | Đạt |
| `flutter analyze` | No issues found |
| `flutter test --reporter expanded` | 213/213 đạt |
| Backend Node 22/Java 21, `npm --prefix functions run test:emulator` | 62/62 đạt |
| `flutter build apk --debug --target-platform android-arm64 --dart-define=FIREBASE_ENABLED=true --dart-define=DEMO_AUTH=false` | Đạt |
| `git diff --check` | Đạt |

Logs đầy đủ giữ tại ignored `.local/flow3-*`. Không coi tests fake là giao dịch
Firebase thật. Tests mới: `test/viewmodels/flow3_view_model_test.dart` (7 ca),
`test/widgets/flow3_screens_test.dart` (6 ca), backend test `getAccount` Daily.

Tests kiểm mutation chờ server/chặn trùng, reload trạng thái claim, timeout đổi
quà rồi recover receipt, refresh lỗi sau commit không đổi thêm, giá thay đổi
không trừ xu, wallet refresh quyết định đủ xu, physical reward không lấy secret,
voucher used không QR, lỗi mạng/retry và không fallback business data giả.
Daily có test giữ response pending, xác nhận spinner hiện trước khi server trả
kết quả. Weak listener đồng bộ presentation khi Flow3 đổi state, không tự tải
catalog Rewards khi feature chưa được mở.
Tám route live ở 360/412dp với chữ 2× dùng viewport thật, không overflow.
Widget path catalog → details → confirm (tap thật) → success → invalidate state
→ locker → voucher QR → history đạt với service fake trong test.

Lần Emulator đầu bị timeout discovery Function 10 giây, không nhận là pass.
Chạy lại với `FUNCTIONS_DISCOVERY_TIMEOUT=60` đạt 62/62. Không thay runtime
timeout nghiệp vụ. APK build còn cảnh báo Built-in Kotlin từ toolchain/plugin
hiện có; build thành công, không nâng dependency ngoài phạm vi.

## Firebase thật

Chỉ deploy cập nhật `getAccount` trên `prm393-31822`, `asia-southeast1`, Node22.
[Metadata](function-after.json) xác nhận ACTIVE, latestCreatedRevision bằng
latestReadyRevision. Không đổi Rules hoặc deploy lại các API không thay đổi.

[Smoke JSON đã bỏ secrets](live-smoke.json): tài khoản seeded demo staff dùng
API có quyền như user, seeded admin xác nhận voucher. Không đổi tài khoản owner.

1. Daily nhận 5, gửi lại trả cùng receipt.
2. Claim `first-event` nhận 50, gửi lại trả cùng receipt.
3. Đổi Café 200 với cùng request ID hai lần, chỉ một debit ledger.
4. Lấy QR/mã do server cấp, admin xác nhận `used`; replay không dùng hai lần.
5. Sau `used`, `getVoucherCode` từ chối. Redemptions/vouchers cùng trạng thái.
6. Ví seeded operator: 245 → 100 = 245 + 5 + 50 − 200, held = 0.

Đây là smoke qua callable HTTPS thật, tách biệt với thao tác UI trên điện thoại.
Không lưu token/password/voucher secret vào evidence hoặc route.

## Giới hạn

APK cuối đã cài thành công trên SM-G996N, giữ phiên đăng nhập. Ví thật hiển thị
310 xu, held 0; Daily ngày 1 thưởng 5 và milestone 2 sự kiện. Native chỉ mở màn
để đọc dữ liệu, không bấm nhận/đổi bằng tài khoản owner. Giao dịch live ở trên
thực hiện riêng qua HTTPS bằng operator, không gọi đó là toàn bộ native E2E.
Ảnh [Rewards](native-rewards.png), [milestones/Ready to claim](native-milestones.png),
hash APK tại [validation](validation.json).

- Chưa nhận hoàn tất ARTEMIS hoặc external AI/PR review.
- Chưa chờ Monthly Gift chạy tự nhiên; chỉ dùng job đã có.
- Tài khoản admin thao tác qua API/công cụ vận hành, chưa có màn admin trong app.
- Request pending chỉ giữ trong phiên ViewModel; sau khi kill app phải kiểm
  My Rewards/history trước khi đổi lại. Receipt đã commit vẫn đọc lại từ server.
- Không claim layout live trùng pixel Figma: dữ liệu server thay text dài/ngắn.
- Các lỗi Flow 2 chẩn đoán trước task không thuộc phạm vi sửa Flow 3.
