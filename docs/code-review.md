# AI Code Review — backend readiness

Ngày 04/11/2026. Đã review local commit `7e9c7bf` bằng **Codex chat assistant**; [output được lưu](../evidence/backend-readiness/ai-review.md). Chưa mở/push PR, không có external approval. Không phải review toàn bộ UI hoặc chứng nhận production.

## Finding decisions

| ID | Loại / vị trí baseline 7e9c7bf | Quyết định và lý do | Fix commit / evidence |
|---|---|---|---|
| CR-01 | Bug, catalog.ts:15,30 | Accepted: terms version import 101–128 ký tự khiến register/redeem API không dùng được; cần khớp contract | `bf5ca34`, test RED→GREEN |
| CR-02 | Validation, catalog.ts:32 | Accepted: preflight phải từ chối catalog rỗng như apply | `ae4bfe4`, subprocess RED→GREEN |
| CR-03 | Bug, queries.ts:43 | Accepted: tìm không dấu phải khớp đ theo contract tiếng Việt | `bd6f39d`, Emulator RED→GREEN |
| CR-04 | Maintainability/contract, backend-integration.md:66 | Modified: sửa docs nullable về đúng schema, không tự mở rộng clear profile | Diff contract trong milestone này |
| CR-05 | Integration/test gap, backend-integration.md:84,172–177 | Modified: thêm owner lookup/allowlist vào handoff; tránh endpoint chưa cần. Native navigation vẫn pending | [Handoff](FRONTEND_HANDOFF.md) |

Ba fixes đầu có commit riêng mang finding ID, hiện local. Cần push để bổ sung links GitHub/PR truy cập được cho hồ sơ nộp; không coi commit chưa publish là evidence online.

## AI tools disclosure trong milestone

- Codex chat assistant: review, viết tests/fixes/docs, chạy và đọc kết quả lệnh.
- Skills hỗ trợ: api-and-interface-design, incremental-implementation, test-driven-development, ponytail-review, security-and-hardening.
- Không nhận đã dùng CodeRabbit/Copilot review; nhóm cần bổ sung tools thực sự dùng bởi các thành viên khác.

## Còn lại

- [ ] Push fixes, gắn links truy cập được; ưu tiên review PR trước merge.
- [ ] Review Flutter/service integration và kiểm notification routing trên Android khi app sẵn sàng.
- [ ] Tổng hợp disclosure AI tools của cả nhóm.

## Template giữ cho lần review Flutter tiếp theo

Các TODO/checklist phía dưới chỉ dành cho review tiếp theo, không phủ nhận backend review local ở trên.

- Change/PR/commit: TODO
- Reviewer / ngày / công cụ (nếu có): TODO
- Scope / assumptions: TODO
- Checks đã thực sự chạy + log: TODO

## Checklist chưa đánh giá

- [ ] View chỉ render và chuyển actions; không chứa business logic/SDK/HTTP.
- [ ] ViewModel quản lý loading/empty/error/data và lifecycle/duplicate actions.
- [ ] Data access đi qua Repository → service interface; SDK types không lọt ra ngoài.
- [ ] Riverpod DI có thể override; không global mutable state/singleton trong UI.
- [ ] Không credentials, mock business data hoặc thành công giả trong runtime.
- [ ] Error message an toàn, retry hợp lý; auth guard không thay thế backend rules.
- [ ] Styling dùng tokens; kiểm tra 360/412dp, text scaling và >=48dp targets.
- [ ] Tests có ý nghĩa, validation được chạy và evidence là thật.
- [ ] Scope không thêm business features/tracking/E2E ngoài yêu cầu.

## Mẫu finding (không phải finding đã phát hiện)

| ID | Severity | File:line | Evidence | Impact | Suggested fix | Owner / status |
|---|---|---|---|---|---|---|
| TODO khi có finding thật | TODO | TODO | TODO | TODO | TODO | TODO |

Kết luận review / follow-up / quyết định merge: TODO sau review thật.
