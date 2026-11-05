# Chuẩn bị dữ liệu thật và nhập catalog

> **Cập nhật theo yêu cầu trực tiếp 05/11/2026:** owner yêu cầu tự generate và
> thêm database để sửa sau. Đã tạo 32 catalog records demo (10 sở thích, 5 CLB,
> 12 sự kiện, 5 quà) và hai Auth operators có quyền app. Café demo giá 200,
> stock/validity/địa điểm/terms giả lập có nhãn rõ. [DEMO_DATA.md](DEMO_DATA.md)
> ghi exact scope/evidence/cách sửa; các ghi chú chưa seed bên dưới là lịch sử.
> Dataset thật và quyền sử dụng thương mại vẫn chưa được xác nhận.

> **Sau review 05/11/2026:** owner chưa có stock/nhà tài trợ/địa điểm/validity/
> terms cho Café; chỉ chuẩn bị giá 200, **không tạo reward record cloud**.
> Dữ liệu sở thích/CLB/sự kiện/quà vẫn chờ duyệt, không lấy Figma làm dữ liệu thật.
> Nhập danh mục sở thích active là điều kiện để hoàn thành onboarding FPT.

> **05/11/2026:** năm definitions thành tựu trong
> [event-milestones.json](../firebase/event-milestones.json) đã được owner chốt
> và publish như policy thật. Không seed users/attendance/coins. Nguồn dữ liệu
> sự kiện/CLB/sở thích/phần thưởng bên dưới vẫn cần chuẩn bị riêng.

Ngày 04/11/2026. Chủ dự án xác nhận **chưa có nguồn dữ liệu thật**. Không có seed production, không dùng nội dung Figma làm dữ liệu thật. Checklist dưới đây chuẩn bị để nhập khi dữ liệu được duyệt; không đánh dấu hoàn thành catalog.

## Hồ sơ cần thu thập

| Nhóm | Thông tin cần chuẩn bị | Nguồn/người duyệt |
|---|---|---|
| Sở thích | ID ổn định, label, active/inactive; ít nhất 3 mục active để onboarding hoạt động | Danh mục do chủ dự án duyệt |
| CLB/organizer | ID, tên, mô tả, published, logo có quyền dùng | CLB hoặc người quản lý nội dung |
| Sự kiện | Organizer ID, title/description/category/tags, thời gian/timezone/địa điểm, lịch/check-in, hình có quyền dùng, loại registration/walk_in, capacity/cọc/thưởng, terms/version | Đơn vị tổ chức xác nhận thông tin và quyền công bố |
| Phần thưởng/voucher | ID, nhà tài trợ và địa điểm sử dụng trong nội dung/usageLocations, giá/stock, điều kiện, hạn dùng, các bước đổi/nhận, hình có quyền dùng | Nhà tài trợ/chủ dự án duyệt. Café hiện chốt 200 xu; không suy ra giá cho phần thưởng khác |

Mỗi record có `sourceRef` HTTPS đến nguồn được duyệt. Ghi người duyệt, ngày duyệt, quyền dùng ảnh và nội dung vào hồ sơ bàn giao riêng; URL đúng định dạng không tự chứng minh dữ liệu chính xác hay quyền sử dụng.

## Định dạng và validation

Schema thực thi: [catalog.ts](../functions/src/catalog.ts). Root JSON gồm `organizers`, `events`, `rewards`, `interests`; chỉ cần các mảng có dữ liệu, nhưng tổng phải có ít nhất 1 record.

- ID: chữ/số/`_`/`-`, 1–128 ký tự; không dùng title làm khóa thay đổi theo nội dung.
- Terms versions của event/reward tối đa 100 ký tự để tương thích request API.
- Timestamp là ISO-8601 UTC; timezone là IANA timezone hợp lệ. Chốt giờ thực tế trước khi đổi sang UTC.
- Không đưa `registeredCount`, `followerCount`, tài khoản, mật khẩu, ví, vé hoặc attendance vào catalog. Server khởi tạo counters bằng 0.
- Tối đa 100 records mỗi nhóm trong một lần import; không ID trùng trong cùng nhóm. Event cần organizer có sẵn hoặc cùng lần import.
- `sourceRef` bắt buộc HTTPS. Kiểm tra quyền sử dụng và nội dung trước khi apply, không chỉ chạy schema.
- Stock/capacity/coin là số nguyên không âm. `capacity:null` là unlimited. Walk-in không giữ deposit.
- `validDays` nếu có là 1–365 và tính N×24 giờ từ lúc redeem; bỏ trống không expiry. Phải được nhà tài trợ duyệt trước khi phát hành.
- Không nhập dữ liệu thật nhạy cảm vào fixture tests. Không commit danh sách sinh viên, email hay credentials.

## Quy trình nhập

1. Chủ dự án nhận dữ liệu từ các nguồn ở bảng trên và duyệt JSON theo schema.
2. Build TypeScript và chạy dry-run; bước này không đọc/ghi network:

   ```powershell
   npm --prefix functions run build
   node functions/scripts/import-catalog.mjs --project demo-evia-backend --input approved.json
   ```

3. Kiểm tra counts/validation; dry-run kiểm cấu trúc, **không kiểm được organizer đã có trên database**. Reference được kiểm tiếp trong transaction khi apply.
4. Với Emulator đang chạy, thử import vào demo và đọc catalog qua Callable. Không dùng cùng dataset để giả evidence cloud.
5. Trước apply cloud, xác nhận project `prm393-31822`, dữ liệu cụ thể và quyền ghi. Cần ADC ở ngoài Git; Firebase CLI login không tự thay thế Admin SDK ADC.
6. Apply create-only qua script với `--apply`; toàn bộ transaction atomic, ID đã tồn tại thì từ chối, không ghi đè. Không coi script này là công cụ update/delete catalog.
7. Lưu nguồn/người duyệt, counts và kết quả kiểm tra, không ghi credentials hoặc dữ liệu cá nhân trong evidence.

**Chưa chạy apply cloud trong lượt chuẩn bị này.** Không có JSON production seed vì chưa có dữ liệu được duyệt.

## Bàn giao và nghiệm thu

- [ ] Có ≥3 interests active được duyệt; category/tags sự kiện dùng taxonomy đã thống nhất.
- [ ] Có dữ liệu đủ để trình diễn ba flow, không suy diễn từ Figma.
- [ ] Sponsor/usageLocations/terms/expiry của voucher được duyệt và rõ cho người sử dụng.
- [ ] Dry-run và Emulator import đạt; sửa reference/validation trước khi xin apply cloud.
- [ ] Cloud apply được phê duyệt và kiểm tra qua public/owner API đúng quyền.

Tham chiếu: [API contract](backend-integration.md), [checklist](LAB3_CHECKLIST.md).
