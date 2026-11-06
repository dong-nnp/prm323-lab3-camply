# Tạo sự kiện gọn và tải ảnh lên Storage — 06/11/2026

Áp dụng cho portal Vite `admin/`. Không đổi app sinh viên hoặc portal Flutter.

## Luồng tạo

1. Chọn Tạo sự kiện, nhập tên/mô tả; chọn danh mục và ban tổ chức bằng tên.
2. Chọn ảnh JPG/PNG/WebP tối đa 5 MB nếu cần; xem trước ngay trên form.
3. Nhập giờ bắt đầu/kết thúc, địa điểm; tùy chọn số chỗ, cọc và xu thưởng.
4. Lưu bản nháp. Ảnh được tải lên Firebase Storage trước, có trạng thái phần
   trăm; sau đó backend lưu URL ảnh cùng sự kiện. Xuất bản vẫn là thao tác riêng.

Không phải nhập ID, URL nguồn HTTPS, phiên bản điều khoản, điều khoản đăng ký
hoặc lịch JSON. ID được sinh một lần khi mở form và giữ khi retry. Nguồn tạo
tự trỏ đến bản ghi events trong Firebase Console của dự án đang cấu hình.

Điều khoản cho sự kiện mới dùng policy hiện hành: hủy hoàn 30% cọc làm tròn
xuống, no-show mất cọc; version `evia-standard-v1`. Backend vẫn validate điều
khoản/quote như cũ, không bỏ consent trong luồng đăng ký sinh viên.
Khi sửa sự kiện đã có, giữ nguyên sourceRef, nội dung/version điều khoản,
schedule và ảnh cũ trừ khi chọn ảnh mới. Không xóa dữ liệu ẩn trong form.

Tùy chọn thêm chứa phạm vi, địa chỉ chi tiết, giờ check-in, hạn đăng ký và tags.
Khi tạo mới, bỏ trống giờ check-in sẽ dùng giờ bắt đầu/kết thúc sự kiện.
Sự kiện cũ giữ cửa sổ check-in đang có; nếu đổi lịch, kiểm tra lại phần này.
Danh mục lấy từ interests đang hoạt động; ban tổ chức từ catalog công khai,
có phân trang và nút retry khi tải thất bại. Không tạo lựa chọn giả khi offline.

## Storage

`admin/.env.local` cần `VITE_FIREBASE_STORAGE_BUCKET` từ cấu hình Web app thật.
Máy hiện tại đã lấy bucket từ google-services.json đang có, không suy đoán tên.
Ví dụ file mẫu: [admin/.env.example](../admin/.env.example).

- Adapter dùng Firebase Storage Web SDK đã nằm trong dependency firebase.
- Tệp lưu dưới `event-images/{adminUid}/{uuid}.jpg|png|webp`; không dùng tên tệp
  cá nhân và không ghi đè. Kiểm MIME/size ở client và Storage Rules.
- Chỉ admin có profile `accountStatus:active` được tạo/đọc/xóa ảnh trong thư mục
  của mình. Student/staff/anonymous/admin bị khóa hoặc thiếu profile bị từ chối.
  List, ghi đè, SVG, MIME/suffix sai, tệp rỗng/quá 5 MB đều bị chặn.
- URL download là capability URL dùng hiển thị ảnh sự kiện trong app; người có
  link có thể xem ảnh. Chỉ tải ảnh bìa phù hợp cho việc hiển thị này.
- Rules cho PDF reports giữ nguyên, các đường dẫn khác tiếp tục deny all.
- Rules cần đọc profile trong Firestore. Đã cấp riêng role chính thức
  `roles/firebaserules.firestoreServiceAgent` cho Firebase Storage service agent
  của dự án. Role chỉ có `datastore.entities.get`; không cấp role cho người dùng.
  Firebase CLI chế độ non-interactive đã bỏ qua bước cấp quyền, vì vậy quyền
  này được kiểm tra và bổ sung riêng, rồi xác minh upload thật.

Ảnh cũ không tự xóa khi thay ảnh. Nếu save lỗi/timeout, giữ ảnh đã upload để
retry vì server có thể đã commit; retry cùng tệp không upload lại. Đóng form
sau một lần save lỗi có thể để lại ảnh chưa được tham chiếu; dọn theo reference
nếu số lượng tích lũy đáng kể. Không tự xóa ảnh có thể đang được sự kiện sử dụng.

## Validation và giới hạn

- Admin: 12/12 tests, Vite production build đạt.
- Backend: đầy đủ 81/81 tests trên Auth/Firestore/Functions/Storage Emulators đạt,
  gồm ba tests Rules mới và regression quyền PDF reports. TypeScript build đạt.
- Browser thật: form không có sáu technical inputs; dropdown có dữ liệu thật,
  chọn ảnh hiển thị preview; walk-in ẩn/disable cọc; advanced mở/đóng đúng.
  Không tràn ngang ở 360px/412px; trả viewport về mặc định sau kiểm tra.
- Đã deploy riêng Storage Rules lên project thật. Firebase SDK upload ảnh PNG
  845.219 byte, metadata đúng MIME/size; download không cần đăng nhập có hash
  khớp nguồn; đã xóa ảnh QA và xác minh object không còn. Không tạo/sửa event cloud.
- Không đổi Dart/native/dependency nên không chạy lại Flutter/APK. Chưa thực
  hiện tạo rồi xuất bản một sự kiện mới trên cloud từ form này.
- Audit admin `--omit=dev` báo 4 high ở nhánh Firebase Firestore/gRPC hiện có;
  không thêm dependency hoặc downgrade Firebase theo gợi ý audit. Portal này
  không import Firestore SDK; việc nâng cấp/xử lý advisory cần lượt riêng.

[Ảnh form thật](../evidence/event-editor/simple-event-form.png),
[kết quả upload thật](../evidence/event-editor/storage-verification.json),
[quyền service agent](../evidence/event-editor/storage-service-permission.json).
Logs emulators nằm local trong `.local/event-editor-checks/` (Git ignored).

Nguồn API: [Storage upload](https://firebase.google.com/docs/storage/web/upload-files),
[quyền Rules liên dịch vụ](https://firebase.google.com/docs/rules/manage-deploy),
[role Firestore Service Agent cho Rules](https://docs.cloud.google.com/iam/docs/roles-permissions/firebaserules).
