# Code review — template

Trạng thái: chưa thực hiện AI Code Review. Không có findings hoặc approvals
được tạo sẵn. Checklist sau dành cho reviewer dùng khi có thay đổi thực tế.

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
