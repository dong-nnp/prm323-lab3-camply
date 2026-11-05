# Backend release — 04/11/2026

> **Release tiếp sau review 05/11/2026:** 41 Functions ACTIVE cùng hash, 41 Cloud
> Run latest revisions READY; FPT guard/manual code/event notifications đã deploy.
> [Contract/release mới](PREINTEGRATION_DECISIONS.md),
> [cloud evidence](../evidence/preintegration/cloud-verification.json).
> 51/51 backend và 149/149 Flutter tests đạt; mobile integration vẫn pending.

> **Release bổ sung 05/11/2026:** Event Milestones thêm 3 callables, cập nhật
> getOperationStatus, Firestore Rules/index, publish 5 policies và 2 Remote Config
> keys. [Contract/evidence mới](EVENT_MILESTONES.md). Phần dưới giữ nguyên
> evidence release 34 Functions ngày 04/11; không phải số lượng hiện tại.

Trạng thái: **deploy và cloud checks đã xác minh đạt**; docs/evidence đã push và xác minh remote tại commit `a76de1f`. Project `prm393-31822`, region `asia-southeast1`, nhánh `KietDM/feat/backend`.

## Phạm vi và authorization

Người dùng yêu cầu deploy backend mới và push GitHub sau khi đã được thông báo hai scheduled Functions sẽ tạo Cloud Scheduler resources. Không tạo tài khoản test, seed catalog hoặc cấp voucher-admin role trong lượt release này. Không gọi thủ công Monthly Gift/no-show để chứng minh deployment.

- Source revision chuẩn bị deploy: `baaa372`, gồm policy implementation `01082cd` và các fixes `bf5ca34`, `ae4bfe4`, `bd6f39d`.
- Baseline cloud kiểm tra đầu lượt: 32 Functions; mục tiêu 34 (thêm monthlyGiftSchedule và noShowSchedule).
- Build Node22.23.4/TypeScript đạt. Suite gần nhất trên cùng source: 31/31 Emulator tests đạt; không chạy lại để tạo kết quả cloud giả.
- Audit dependencies production: 6 moderate, 0 high/critical; chưa có audit sạch, không force-upgrade dependencies ngoài scope.
- GitHub branch đã có sẵn đến `baaa372` khi kiểm tra đầu lượt; push cuối dành cho release docs/evidence và links review.

## Rollout

Lệnh thực thi: `functions/scripts/deploy-dev.ps1`, Node22 trên PATH, `FUNCTIONS_DISCOVERY_TIMEOUT=60`. Deploy từng nhóm 4 Functions; dừng nếu bất kỳ nhóm nào lỗi. Không đổi Rules/data schema hay UI trong release này.

Log thực thi: [deploy batches](../evidence/firebase-migration/deploy-20261104-233102/).

## Điều kiện kiểm tra sau deploy

| Check | Trạng thái |
|---|---|
| 34 Functions ACTIVE | PASS, cùng source hash `8f455915647abb7a9dba1ba6537bde5dd499ad2d` |
| Cloud Run latest-created revision = latest-ready và Ready | PASS, 34/34 services, Functions revision khớp revision đang phục vụ |
| Monthly job enabled, cron 00:00 ngày 1, Asia/Ho_Chi_Minh | PASS, cron `0 0 1 * *`; lần kế tiếp 01/12/2026 00:00 giờ Việt Nam |
| No-show job enabled mỗi giờ, Asia/Ho_Chi_Minh | PASS, `every 60 minutes` |
| Scheduler OIDC service account/target phù hợp; không public invoker | PASS, target/audience khớp URL Cloud Functions, deadline 540s; service IAM chỉ cấp runtime service account, project không có broad public bindings |
| Callable public reads và auth-denial smoke | PASS 6/6 sau khi deploy hoàn tất; không authenticated mutations |
| Firestore public/private Rules smoke | PASS 3/3; 14 composite indexes READY |
| GitHub source và release evidence | PASS, remote tip khớp `a76de1f` sau push; source deploy vẫn là baaa372 |

Evidence được lưu tại [backend-release](../evidence/backend-release/). Không chỉ dùng Functions ACTIVE để kết luận: Cloud Run có thể chưa phục vụ revision mới.

## Snapshot dữ liệu và kết quả

Read-only aggregation ghi nhận `users=0`, `wallets=0`, `registrations=0`, `vouchers=0`; catalog public cũng rỗng. Không tạo test users, cấp role hoặc seed dữ liệu. Không gọi thủ công các jobs.

Cả 9 nhóm deploy exit0, 34 exports khớp revision/hash nguồn. API Cloud Scheduler ban đầu chưa enabled và đã được Firebase CLI bật theo yêu cầu deploy. Hai lịch ENABLED, lastAttemptTime còn null tại snapshot; chưa dùng kết quả chạy tự nhiên làm bằng chứng. Kiểm tra URL chấp nhận endpoint Cloud Functions chuẩn (khác alias Cloud Run), không sửa Scheduler để khớp giả định của checker.

## Ranh giới evidence

Kiểm tra Scheduler definition/IAM không chứng minh job đã chạy theo lịch. Kiểm tra đọc công khai và từ chối anonymous không chứng minh các nghiệp vụ với tài khoản thật, native Google OAuth, FCM delivery, file export hoặc UI integration đã đạt. Các business transactions được xác minh trên Emulator; data thật vẫn chưa được duyệt.

## Nếu cần rollback

Tạm dừng các Scheduler jobs trước khi khôi phục source backend đã biết ổn định; giữ nguyên wallet, ledger, grant receipts, registration history và voucher-used records. Không reset/xóa database để rollback code, không tự hoàn/cấp xu hàng loạt. Các mutation đã hoàn tất cần được đối soát trước khi xử lý bù. Không thực hiện rollback trong lượt này nếu chưa có lỗi cần xử lý.

GitHub release evidence: [a76de1f](https://github.com/dong-nnp/prm323-lab3-camply/commit/a76de1f615e8ec91db02bdaf8ac8338346496f93). Commit checklist xác nhận push có thể mới hơn commit evidence này; không thay runtime đã deploy.
