# Chuyển backend sang Firebase của nhóm — 04/11/2026

Người dùng yêu cầu chuyển sang project đã có Blaze, không liên kết billing mới.
Project đích được kiểm tra trực tiếp qua Firebase CLI và Billing API:

| Thành phần | Giá trị |
|---|---|
| Firebase project | `prm393-31822` — display name `evia` |
| Project number | `465411217120` |
| Android app hiện tại | `1:465411217120:android:fdc0b89aaa5078e3286285` |
| Android package | `com.example.prm393_lab03` |
| Firestore | `(default)`, Standard Native, `asia-southeast1` |
| Cloud Functions | Node22, region `asia-southeast1`, codebase `evia` |
| Storage bucket có sẵn | `prm393-31822.firebasestorage.app`, `US-EAST1` |
| Authentication | Google + email/password enabled |

## Phạm vi chuyển

- Trước khi triển khai: project có billing, bucket rỗng, chưa có Firestore hay
  Functions. Rules Storage cũ deny-all được lưu để rollback. Không chuyển tài
  khoản app hoặc record nghiệp vụ, không seed dữ liệu minh họa.
- Tạo Firestore tại Singapore để cùng region backend; giữ bucket sẵn có tại Mỹ,
  không tạo/xóa/chuyển bucket. Region Storage khác Firestore là trạng thái sẵn có
  của project, không phải cấu hình nhầm; cần lưu ý latency khi upload/download.
- Giữ Android app cũ của nhóm (`com.android.application`). App Flutter có package
  khác nên FlutterFire CLI đăng ký thêm app đúng package; không đổi package app.
- File `google-services.json` ở root do nhóm gửi bắt đầu bằng `g{`, JSON không hợp
  lệ. Không sửa hoặc dùng file đó. Config thật được FlutterFire CLI sinh tại
  `android/app/google-services.json` và `lib/firebase_options.dart`, vẫn Git-ignore.
- `firebase.json` và default alias local `.firebaserc` trỏ `prm393-31822`.
  Emulator/tests vẫn dùng `demo-evia-backend`, không chuyển tests sang live project.
- Không sửa màn hình, ViewModel, dữ liệu demo Flutter hoặc bật tracking tự động.

## Tạo lại config trên máy khác

Máy có quyền project dùng FlutterFire CLI, không copy file root bị lỗi:

```powershell
dart pub global run flutterfire_cli:flutterfire configure --project=prm393-31822 --platforms=android --android-package-name=com.example.prm393_lab03 --yes
```

Lệnh reuse app đúng package đã đăng ký, sinh native JSON/options thực. Backend
Callable client dùng region `asia-southeast1`; không thay project tests demo.

## OAuth Android

Fingerprint debug SHA-1 của máy đang bị project cũ giữ. Firebase từ chối cặp
package + SHA trùng giữa hai project. Đã gỡ đăng ký SHA-1 và Android OAuth client
debug tương ứng ở `evia-lab3-kiet-2026`, đăng ký SHA-1/SHA-256 ở project mới và
sinh lại config. JSON của app mới có Android client (type 1) + web client (type 3).
Không xóa project/app/Auth/database cũ hoặc thay signing key của máy.

Android OAuth client cũ có thể restore qua Google Cloud trong 30 ngày, nhưng
cần chuyển fingerprint ngược lại trước để tránh trùng. Chỉ trỏ lại config cũ
không đủ khôi phục Google Sign-In Android. Release/máy khác cần đăng ký đúng
fingerprint signing key; task này không tạo release key.

## Triển khai và giới hạn tài nguyên

Rules Firestore/Storage và composite indexes đã deploy thành công. Cloud Functions
lần đầu gặp độ trễ kích hoạt API/Eventarc và quota CPU khi nhiều hàm khởi động
cùng lúc. Cấu hình được giảm xuống `cpu: gcf_gen1` (256MiB ~1/6 CPU), concurrency
1, minInstances 0, maxInstances 3 **mỗi hàm**; vẫn là Functions gen2. Không yêu
cầu tăng quota và không giữ instance luôn chạy. Đây không phải hard cap hóa đơn.

FCM trigger có retry, payload generic; inbox deterministic là nguồn dữ liệu khi
push chưa đến. CLI cấu hình cleanup container images cũ sau 1 ngày để hạn chế
tích lũy dung lượng. Không xóa dữ liệu ứng dụng khi cleanup build artifacts.

Các lượt rollout đồng thời ban đầu bị quota vì revision cũ còn dùng CPU đầy đủ
và startup boost. Chỉ các Functions mới tạo trong task (preflight xác nhận chưa có
Functions sẵn) được reset; không xóa database/Auth/bucket/data. Sau đó triển khai
qua script từng nhóm 4 hàm để CPU khởi động nằm trong quota 20 CPU khu vực.

Lệnh đích luôn explicit:

```powershell
firebase deploy --project prm393-31822 --only firestore:rules,firestore:indexes,storage --non-interactive
.\functions\scripts\deploy-dev.ps1
```

`--force` xác nhận failure-policy retry cho trigger đã có trong source. Preflight
xác nhận không có functions cũ để CLI vô tình xóa. Không dùng force để bỏ qua
lỗi compile, quyền truy cập hoặc tests.

## Bằng chứng và rollback

`evidence/firebase-migration/`: preflight metadata, auth/config/SHA checks, logs
deploy từng lượt, build/startup và smoke test thật. Lượt lỗi được giữ riêng,
không tính là pass. Không ghi access/refresh token, OAuth secret hoặc private key.
Đã kiểm tra: 14 composite indexes đều READY; cloud Rules public-filtered query
trả 200, unfiltered/private-wallet query trả 403. Bộ 20 Emulator tests chạy lại
đạt; APK debug build và Pixel 5 startup Firebase Core đạt. **32/32 Functions ACTIVE**, **32/32 Cloud Run latest revisions READY**. API smoke
thật đạt 4/4: getServerInfo/getPublicCatalog 200, getAccount/initializeUser không
đăng nhập trả 401 UNAUTHENTICATED. Xem `deployment-status.json` + `cloud-smoke.json`.

Bản sao config local và Storage Rules cũ: `.firebase/migration-backup/` (ignored).
Nếu cần dừng phát hành, giữ nguyên data, chặn client bằng Rules phù hợp và xem
log lỗi; không xóa project/database để rollback. Khôi phục Rules từ bản đã lưu
chỉ khi đã đánh giá tác động quyền truy cập. Có thể chọn lại project cũ bằng CLI
và FlutterFire, nhưng phải xử lý OAuth như trên. Chưa thực hiện thử rollback live.

API cho frontend không đổi: [backend-integration.md](backend-integration.md).
UI vẫn cần nối service adapters theo MVVM; Firebase Core khởi động không có nghĩa
Google login/camera/FCM hoặc ba luồng UI đã tích hợp xong. Monthly/cashier vẫn khóa.

Nguồn: [Firebase OAuth conflict](https://support.google.com/firebase/answer/6401008),
[CPU/scaling configuration](https://firebase.google.com/docs/functions/manage-functions).

## Kết quả chốt

- Chuyển cấu hình và triển khai lên `prm393-31822` hoàn tất; không chỉ Emulator.
- Deploy cuối dùng 8 nhóm, mỗi nhóm 4 Functions, đều exit0.
  Log tổng `evidence/firebase-migration/deploy-batched.log`, từng nhóm trong
  `deploy-20261104-220819/`. Những lượt lỗi trước đó không được tính là pass.
- Control-plane check đối chiếu Functions ACTIVE với Cloud Run latestReady ==
  latestCreated và CONDITION_SUCCEEDED cho đủ 32 services; không dựa vào
  Firebase dashboard/ACTIVE một mình. Worker đúng document-created trigger.
- 20/20 Emulator tests, 14 indexes READY, 7/7 cloud read/auth-denial smoke checks,
  APK debug + startup Core trên Pixel 5 đạt. Screenshot dashboard project nhóm:
  `evidence/firebase-migration/team-functions-dashboard.png`.
- Chưa tạo tài khoản test thật, chưa login Google trong app, chưa thử push thật,
  chưa import catalog/sở thích và chưa nối UI. Không claim Lab 3 hoàn thành.
- Source/diff vẫn ở working tree, chưa commit hoặc mở PR.
