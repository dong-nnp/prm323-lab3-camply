# Evia Firebase backend

Readiness local 04/11/2026: [policy/jobs](../docs/BACKEND_POLICIES.md), [frontend handoff](../docs/FRONTEND_HANDOFF.md), [approved data preparation](../docs/DATA_READINESS.md). Source có 34 exports (thêm 2 scheduled Functions), **chưa deploy revision mới**; snapshot cloud vẫn 32. Suite mới 31/31 đạt trong Emulator; không phải proof Cloud Scheduler/FCM delivery thật.

Node.js 22, TypeScript, Firebase Functions v2 + Admin SDK. Region:
`asia-southeast1`. Client không trực tiếp sửa dữ liệu nghiệp vụ.

Từ repository root, dùng Node22 và Java21+ trên PATH:

```powershell
npm --prefix functions ci
npm --prefix functions run build
npm --prefix functions run test:emulator
npm --prefix functions run serve
```

Cần Firebase CLI; tests chỉ chạy demo project + loopback Emulators. `serve`
không seed dữ liệu. Auth/Firestore/Functions/Storage ports: 9099/8080/5001/9199.
Không chạy `test:emulator` cùng lúc với `serve`.

API requests/responses, data import, staff permissions, Flutter adapter handoff,
deployment approval và các giới hạn: [backend-integration.md](../docs/backend-integration.md).
Project nhóm hiện tại: `prm393-31822` (Blaze), đã được người dùng chọn để triển khai.
Luôn dùng `--project prm393-31822`; xem `docs/firebase-migration.md` cho trạng thái
và evidence. Không commit key/ADC.

Deploy Functions lên project nhóm: `.\functions\scripts\deploy-dev.ps1` từ root,
Node22 trên PATH. Script kiểm tra đúng project và deploy 4 hàm/lượt, dừng nếu lỗi;
không đổi dữ liệu app. Tránh deploy cả codebase đồng thời trên quota khu vực hiện tại.
