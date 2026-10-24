# Design traceability — template

Trạng thái: foundation có token mapping; chưa triển khai UI/flows Lab 2.
Các mục TODO không phải kết quả review hoặc bằng chứng kiểm thử.

## Nguồn đã tham chiếu

- Dự án liền kề: `../prm323-lab2-camply/handoff/flutter-handoff.md`, mục 3 và 5.
- Dự án liền kề: `../prm323-lab2-camply/design/DESIGN.md`, màu/type/spacing/radius.
- Chỉ tham chiếu tài liệu, không sao chép event/student prototype data.

| Design rule/token | Source code foundation | Ghi chú / TODO |
|---|---|---|
| Primary #2457F5, pressed #1745D5, soft #EAF0FF | `lib/theme/app_tokens.dart`, `app_theme.dart` | Đã map vào theme |
| Surface, background, text, border, semantic colors | `lib/theme/app_tokens.dart` | Chưa có semantic status components nghiệp vụ |
| Type 28/24/20/16/14, line-height theo DESIGN.md | `lib/theme/app_theme.dart` | Roboto/system fallback; TODO bundle Inter được cấp phép |
| Spacing 4/8/12/16/24/32/40/48 | `AppSpacing` | Screen gutter 16dp |
| Radius 8/12/16/20/999 | `AppRadius` | Button/input dùng 12dp |
| Flat depth | `AppElevation.none` | TODO map CSS shadows khi cần floating UI |
| >=48dp touch, >=14sp body | `AppSizes`, `AppTheme`, reusable widgets | Tests chỉ kiểm tra button foundation; audit phần còn lại khi có UI |
| 360/412dp, text scaling | `ResponsiveBody` | Xem test source; không phải visual sign-off Lab 2 |

## Mẫu bổ sung khi triển khai màn hình thật

| Screen/component ID | Link/node thiết kế | Yêu cầu / states | Widget/ViewModel | Test ID | Evidence thật | Gap / owner |
|---|---|---|---|---|---|---|
| TODO | TODO | loading/empty/error/data + interactions | TODO | TODO | Chưa thu thập | TODO |

TODO: xác nhận bản thiết kế cuối, font assets và owner; liên kết đúng node,
commit và test run trước khi đánh dấu đạt. Không kế thừa checklist đã tick
của prototype thành kết quả kiểm thử Flutter.
