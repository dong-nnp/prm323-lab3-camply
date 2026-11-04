# Design traceability — Evia

## Database review trực tiếp — 04/11/2026

Đã đọc lại 44/44 frame trên page `2083:272` qua Figma, 1.342 visible text nodes,
và xem ảnh 6 frame đại diện. Xem [mapping dữ liệu và conflict registry](database-figma-review.md)
và [schema v1.2](DATABASE_DESIGN.md). Đây là schema proposal, chưa thay đổi UI,
Figma, dữ liệu Firebase hoặc Rules đã deploy.

Các quyết định giữ riêng 200/250 Coin và Waitlist trong UI demo được ghi ở phần
lịch sử bên dưới **không phải backend policy**. Schema production chỉ có một giá
chuẩn **200 xu cho Café voucher**, không có Waitlist; Daily rewards theo PROJECT_CONTEXT.
Owner đã bỏ toàn bộ milestones, ticket email/fixed reminders, feedback bonus,
missions, seasonal targets và assigned seats/VIP/tiers. Walk-in chỉ QR, không
nhập mã; auth mở rộng Google + email/password; tối thiểu 3 sở thích bắt buộc,
không Skip. Student/club verification tạm hoãn; FD-12 cashier flow chưa chốt.
Các quyết định này là target hiện tại; source UI demo/lịch sử bên dưới chưa
được sửa theo task cập nhật database. FD-06 do design team dự kiến sửa.

Trạng thái: đã triển khai source cho 44 màn hình/trạng thái Evia. Đã đọc đủ metadata,
high-fidelity design context và screenshot của từng node trước khi sửa source.
Lần đầu compiler bị Windows Application Control chặn. Sau khi người dùng xử lý
môi trường, nhóm 18 màn hình My Events/Rewards đã có widget render và QA riêng
như ghi nhận bên dưới. Điều này không tự xác nhận nhóm Discover cũ đã đạt.

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

## Mapping màn hình đã triển khai

File Figma: `JQtHz2tigJtvvjVBsx03kx`; page **màn hình cuối** (`2083:272`).

| Tên Figma | Node | Flutter screen / route |
|---|---|---|
| Html → Body → Main - MobileScreenContainer | `2083:4509` | `EviaLoginScreen` / `/` |
| Evia - Discorver interests you | `2088:2` | `EviaInterestsScreen` / `/interests` |
| Evia — Discover (Consistent Event Hierarchy) | `2083:456` | `EviaDiscoverScreen` / `/discover` |
| Evia — Discover (Guest Mode) | `2083:1143` | `EviaDiscoverScreen(guest: true)` / `/discover/guest` |
| T08 — Explore Idle Search State | `2083:993` | `EviaExploreScreen` / `/explore` |
| S04 — Advanced Event Filters | `2083:1438` | `EviaFiltersScreen` / `/filters` |
| S02 V4 — Explore Search Results | `2083:826` | `EviaExploreScreen(referenceResults: true)` / `/explore/results` |
| Following — Their Events | `2083:1582` | `EviaFollowingScreen` / `/following/events` |
| Following — Organizers | `2083:1873` | `EviaFollowingScreen(organizers: true)` / `/following/organizers` |

Tất cả 131 asset exports đã tải về `assets/figma/`, kiểm tra đủ file và không có
file rỗng. `FigmaAssets` giữ mapping theo node + tên asset trong design context.
SVG giữ kích thước gốc; ảnh dùng đúng nguồn export theo slot. Không dùng screenshot
của toàn màn hình làm UI, không thay thumbnail trống bằng ảnh khác.

`EviaTheme` bổ sung màu navy, muted, lavender, gradient featured và kích thước
logo/collage/card từ Figma; tái sử dụng AppColors/AppSpacing/AppRadius/AppButton.
Mock content nằm riêng trong `lib/data/mock/evia_mock_data.dart` theo xác nhận
trực tiếp của người dùng ngày 04/11/2026.

Khác biệt chủ động theo quy tắc repository: Roboto fallback thay Inter chưa có
font asset, body tối thiểu 14sp và hit area tối thiểu 48dp; nội dung có thể cao
hơn frame Figma. Layout scroll/SafeArea dùng các constraints linh hoạt. Chưa có
evidence để xác nhận bố cục thực tế hoặc mọi geometry asset sau render.

Kiểm thử nguồn: `test/widgets/evia_screens_test.dart` (9 route, 360/412dp, 1x/2x,
navigation/actions và opt-in capture), `test/viewmodels/evia_view_model_test.dart`.
Ở lần triển khai 9 màn hình đầu, compiler bị chặn nên các test đó chưa chạy.
Lượt full run sau khi môi trường được xử lý có 5 tests Discover/Following lỗi
overflow; đây là tồn tại của nhóm trước, chưa được sửa trong scope 18 node mới.

## My Events / Rewards — 18 node bổ sung

Đã đọc đủ 18/18 design context có screenshot trước khi sửa source, session
`08089c8c-2d82-4579-b31e-e60278f768ed`. Không dùng screenshot để thay thế UI.

| Tên Figma | Node | Route |
|---|---|---|
| My Events — Past (No Events on Oct 27) | `2083:2012` | `/my-events/past-empty` |
| My Events — Past (Oct 26 Selected) | `2083:2170` | `/my-events/past-date` |
| S07 V3 — My Ticket | `2083:2345` | `/my-events/ticket` |
| T01 — Cancel Registration Confirmation Dialog | `2083:2795` | `/my-events/cancel` |
| My Events — Past (All Events) | `2083:2931` | `/my-events/past-all` |
| My Events — Selected Date (Nov 2) | `2083:3108` | `/my-events/selected` |
| My Events — Attendance Confirmed | `2083:273` | `/my-events` |
| Evia — Monthly Calendar Bottom Sheet (Select a Date) | `2083:2481` | `/my-events/calendar` |
| Event Check-in — Scan Event QR | `2083:1776` | `/my-events/check-in` |
| Evia — My Rewards Locker | `2083:3267` | `/rewards/locker` |
| Evia — Rewards (Redeem Catalog) | `2083:3327` | `/rewards/catalog` |
| Evia — Rewards (Refined Daily Check-in & Milestones) | `2083:3522` | `/rewards` |
| Evia — Redemption Successful | `2083:3788` | `/rewards/success` |
| Evia — Confirm Redemption Dialog | `2083:3865` | `/rewards/confirm` |
| Evia — Reward Details (Café Voucher) | `2083:3959` | `/rewards/detail` |
| Evia — Reward Voucher & QR | `2083:4059` | `/rewards/voucher` |
| Evia — Event Milestones (Mobile) | `2083:4156` | `/rewards/milestones` |
| Evia — Coin History (Refined) | `2083:4356` | `/rewards/history` |

Source: `my_events_screen.dart`, `monthly_calendar.dart`, `ticket_screen.dart`,
`check_in_screen.dart`, `rewards_screen.dart`, `reward_details_screen.dart`,
`reward_voucher_screen.dart`, `milestones_screen.dart`, `coin_history_screen.dart`.
Tất cả nằm trong `lib/screens/evia/`. Các variant/modal dùng chung composition
và ViewModel, không nhân bản ảnh chụp hay dựng UI thành ảnh toàn màn hình.

230 export assets mới đã tải và kiểm tra không thiếu/rỗng. Mapping ở
`ActivityAssets`; SVG dùng đúng asset từng frame và giữ kích thước root. QA capture
precache tất cả PNG trong frame trước khi chụp để không bỏ sót ảnh do decode async.
Capture còn ghi node asset và bounding boxes SVG để kiểm tra callsite/geometry.
Audit đủ **209 SVG và 21 PNG** xuất hiện trong 18 frame, không có icon size 0.
Đã đối chiếu geometry SVG với root dimensions, gồm sửa prefix search để giữ
icon gốc 15×15 thay vì bị wrapper kéo thành 16×16.
Fonts thử nghiệm lấy Roboto/MaterialIcons từ SDK, monospace từ font hệ thống;
không thêm font tải mạng hoặc đổi file ảnh/SVG gốc.

Quyết định theo nguồn thiết kế:

- Node `2083:273` có tên Attendance Confirmed nhưng nội dung là **All Upcoming
  Events**, gồm Registered và Waitlisted; source theo nội dung frame.
- Café có catalog cost 200, detail/confirmation cost 250. Giữ riêng hai trường;
  giao dịch demo dùng 250. Không âm thầm sửa một frame để khớp frame khác.
- Các ngày/giờ khác nhau ở backdrop hủy và ticket được giữ theo frame tương ứng.
- Scanner hiển thị **CAMERA PREVIEW** thay CAMERA ACTIVE vì chỉ dùng ảnh mô phỏng;
  không giả camera/flashlight hay xác minh attendance qua backend.
- Cỡ body tối thiểu 14sp, hit area 48dp, Roboto fallback và text wrap/scroll theo
  quy tắc repo. Vì thế chiều cao card, dòng metadata và mật độ nội dung khác
  frame dùng Inter 11–13px/nowrap; không cắt chữ để ép vừa.
- Used/Expired tab chỉ có số lượng trong frame gốc; nội dung tab đó là mock minh
  họa riêng. Các QR/code/receipt không được dùng để đổi thưởng ngoài đời.

Đã thực hiện capture cả 18 route ở 390dp theo chiều cao reference và xem ảnh.
Responsive tests phủ 360/412dp, text scale 1x/2x. Đây là kiểm tra layout và đối
chiếu thủ công, không phải kết quả pixel-diff hay native Android visual sign-off.

## Đợt 3 — event registration / Profile (17/17)

Đã truy cập đầy đủ context fidelity cao và screenshot trước khi implementation.

| Tên Figma | Node | Route |
|---|---|---|
| T02 — Registration Form Validation Error | `2083:4627` | `/registration/legacy-error` |
| S03-B V2 — Event Detail (Schedule) | `2083:4752` | `/event/schedule` |
| S05 V4 — Registration Success | `2083:4961` | `/registration/success` |
| S04 V3 — Event Registration | `2083:5029` | `/registration/legacy` |
| S03-C V2 — Event Detail (Location) | `2083:5137` | `/event/location` |
| Evia — Event Registration (Validation Error) | `2083:5329` | `/registration/error` |
| S03-A V2 — Event Detail (About) | `2083:5523` | `/event/about` |
| Evia — Event Registration (Default) | `2083:5709` | `/registration` |
| Walk-in Event — Going Confirmed | `2083:5861` | `/registration/going` |
| Registration Unavailable — Event Full | `2083:5931` | `/registration/full` |
| T03 — Registration Loading State | `2083:5987` | `/registration/loading` |
| T09 — Registration Failed Error State | `2083:6200` | `/registration/failed` |
| Evia — Organizer Profile (Student Union) | `2083:6080` | `/organizer` |
| User Profile 1 — Profile | `2089:154` | `/profile` |
| User Profile 2 — My Interests | `2089:296` | `/profile/interests` |
| User Profile 3 — Saved Events | `2091:440` | `/profile/saved` |
| User Profile 4 — Notifications | `2092:607` | `/profile/notifications` |

Source mới: event_details_screen, registration_form_screen,
registration_result_screen, organizer_profile_screen, profile_screens.
Cùng dùng registration_models, registration_mock_data, hai ViewModel mới,
FlowTheme và widgets/event_flow_widgets.dart. Fixtures tách riêng theo chấp thuận
của user, không nối production event API.

180/180 asset mới tồn tại, không rỗng và có callsite trong capture của 17 frame
(157 SVG, 23 PNG); tổng bundle 541 file (484 SVG, 57 PNG). SVG giữ native root
width/height; audit bounding box ở 390dp không có mismatch. Hai error-thumbnail
là source snapshot lớn: đặt canvas 334×715.5, offset -28/-73, clip 78×78 theo
context, không dùng snapshot làm màn hình app. Map preview dùng SVG 314×174,
không dùng Image.asset decoder cho SVG.

Giữ nội dung khác nhau giữa các frame: legacy Oct 26, modern Nov 7; profile
STU-842901, registration STU-849201; Saved Music venue Main Auditorium trong khi
chi tiết là Main Stadium. About frame lặp Sat Nov 7 tại cả date/time/location;
reference music giữ nguyên lỗi nguồn, các tab Schedule/Location có metadata đúng.
Organizer follow dùng state shared: ban đầu Following theo organizer/following
frames, thay cho + Follow trong detail snapshot để tương tác nhất quán.

Cỡ body 14sp, touch target 48dp, font Roboto fallback và text wrap/scroll có thể
làm card cao hơn và nút nằm dưới vùng cuộn so với bản Inter 11–13px/nowrap.
Đã capture/xem cả 17 frame ở 390dp và thử 360/412dp, scale 1x/2x; chưa phải
pixel-diff hoặc native Android visual sign-off. Các badge verified/QR là mẫu,
không biểu thị server đã xác minh. Map và Help/Settings là hướng dẫn nội bộ.

## Backend handoff — 04/11/2026

Backend API hiện có trong [backend-integration.md](backend-integration.md);
không sửa màn hình/Figma ở task backend. UI demo cũ có thể còn Waitlist, milestone,
coin minh họa và auth giả: đội frontend cần chuyển theo owner decisions và bind
services thay demo data. Không coi 20 backend Emulator tests là visual/native
acceptance của 44 frames. Các nghiệp vụ chưa chốt vẫn bị backend khóa.
