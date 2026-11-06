# Ảnh minh họa sự kiện demo

12 JPEG được chọn từ Pexels theo yêu cầu người dùng ngày 06/11/2026, rộng tối đa
1280px. `manifest.json` ghi event ID, file, mô tả và URL nguồn; giấy phép:
https://www.pexels.com/license/. Ảnh stock chỉ minh họa chủ đề, không phải ảnh
thực tế của các sự kiện EVIA. Thư mục này không được bundle vào APK.

Ảnh đã được upload lên bucket `prm393-31822.firebasestorage.app`, dưới
`events/<event-id>/cover-<content-hash>.jpg`. Firestore giữ `imageUrl` tương ứng;
URL download-token dùng để hiển thị ảnh catalog. Không thay ACL hoặc Storage Rules.
Thông tin đăng nhập Firebase CLI và backup trước khi cập nhật chỉ lưu local.

Kiểm tra file mà không gọi mạng, từ repository root:

```powershell
node functions/scripts/upload-event-images.mjs
```

Upload/cập nhật bằng tài khoản quản trị đã đăng nhập `firebase login`, cung cấp
đường dẫn thư mục package Firebase CLI 15.35.0 (có `lib/auth.js`):

```powershell
node functions/scripts/upload-event-images.mjs --apply --firebase-cli PATH_TO_FIREBASE_TOOLS
```

Helper chỉ nhận project/bucket đã xác định và event ID demo trong manifest;
kiểm tra toàn bộ documents trước khi upload, tạo object theo hash không ghi đè,
và cập nhật `imageUrl`/`updatedAt` trong một commit có điều kiện phiên bản.
Không tạo sự kiện, sửa ví hoặc đăng ký. Sau commit, helper đọc lại documents,
kiểm tra URL tải ảnh và đồng bộ URL vào `firebase/demo-catalog.json`.

Upload lặp lại tái sử dụng object cùng hash. Khi đổi ảnh sẽ tạo phiên bản mới;
object cũ được giữ lại. Token download không dùng để cấp quyền upload hay quản trị.
