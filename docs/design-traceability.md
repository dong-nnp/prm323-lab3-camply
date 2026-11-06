# Design traceability — Evia

> **Form sự kiện Vite — 06/11/2026:** owner yêu cầu bớt thao tác và thay URL ảnh bằng upload. Đã bỏ technical inputs, dùng danh mục/CLB theo tên, preview ảnh và nhóm Tùy chọn thêm; giữ styles/form components hiện có. Không sửa giao diện sinh viên/Figma. [Evidence](../evidence/event-editor/README.md).

> **Push Android — 06/11/2026:** dùng notification hệ thống Android cho FCM;
> không đổi Widget/layout, màu, assets hoặc thứ tự thành phần trong app.
> Thêm icon notification native và kênh HIGH để hiển thị banner ngoài màn app.
> [Ảnh thật và giới hạn](../evidence/push-notifications/).

> **Flow 3 — 06/11/2026:** nối dữ liệu/actions thật vào Rewards, milestones,
> details/confirm/success, locker/voucher và history gốc. Giữ tokens, ảnh minh
> họa fallback và thứ tự thành phần. Owner cho phép Flexible/xuống dòng ở các
> hàng tràn khi chữ 2×; đã kiểm 360/412dp. Không cần sửa khung dialog: nguyên
> nhân vùng chạm trong test là MediaQuery thiếu kích thước, đã sửa test helper.
> QR thật dùng đúng ô hiện có; không thêm màn admin. [Evidence](../evidence/flow3-api-only/).

> **Flow 2 — 05/11/2026:** nối dữ liệu/actions vào My Events, lịch, dialog hủy,
> vé, check-in và Notifications cũ. Camera thật thay ảnh preview trong đúng khung
> cũ khi live; theme/tokens/assets giữ nguyên. Text trạng thái/giờ/xu lấy từ server.
> Owner cho phép riêng nút nhỏ “Demo: xác nhận đã quét” trên vé và hộp thoại quyền
> Android khi mở Notifications. Không thêm màn staff hoặc ô mã trên vé.
> [Evidence và giới hạn](../evidence/flow2-api-only/).

> **Nút demo trên vé — 05/11/2026:** theo yêu cầu owner, đưa nút nhỏ hiện có
> vào footer cố định để bấm được mà không cuộn xuống dưới QR. Giữ nguyên phần
> nội dung vé, gọi cùng API demo có kiểm quyền trên server và khóa nút khi xử lý.

> **Email mở mọi domain 05/11/2026:** chỉ đổi text label University Email → Email
> và nội dung lỗi để phản ánh policy mới; không đổi bố cục/style/assets hoặc thêm
> màn. Tham chiếu [contract](PREINTEGRATION_DECISIONS.md) và [checks](../evidence/open-email/).

> **API-only theo owner 05/11/2026:** đã gỡ bộ màn `Flow1Screen` tạo ngoài phạm vi;
> nối Firebase vào các màn gốc, giữ layout/style/assets. Giữ 8 thẻ sở thích;
> Gaming/Environment chờ đội UI. Ảnh cũ làm minh họa khi chưa có URL; vé chỉ hiện
> QR trong ô cũ, chưa có mã dự phòng. [Phạm vi](API_INTEGRATION_PHASES.md) · [Evidence sửa lại](../evidence/flow1-api-only/).
> Các mô tả bộ màn live riêng/kết quả cũ bên dưới là lịch sử, không nghiệm thu bản này.


> **Sau review 05/11/2026:** owner đã duyệt sửa các hành vi trái policy trong
> [PREINTEGRATION_DECISIONS.md](PREINTEGRATION_DECISIONS.md): bỏ Waitlist, Skip
> onboarding, feedback/seasonal reward và verified-eligibility; hủy hoàn 30% cọc làm tròn xuống,
> Daily theo lịch server, Café 200, thêm claim controls. Không đổi Figma/layout
> đã duyệt. Manual fallback và notifications mới là mở rộng owner yêu cầu rõ.

> **Mô phỏng UI 05/11/2026:** debug + `DEMO_AUTH=true` hiện cho phép mô phỏng
> giữ/hoàn cọc, check-in, daily reward và đổi thưởng. `ActivityViewModel` quản lý
> presentation state tạm trong RAM từ fixtures đã được cho phép, không gọi backend.
> `/profile/demo` chỉ đăng ký khi cờ bật, cho mở 44 màn/trạng thái và reset ví 2.000 xu.
> Các mô tả “không mutation” phía dưới vẫn áp dụng khi cờ tắt; không dùng demo này
> làm evidence tích hợp thật. Xem hướng dẫn mới trong README.


> 05/11/2026: theo yêu cầu xem UI, thêm DemoAuthenticationService qua DI khi debug + DEMO_AUTH=true; mặc định vẫn pending. Login đi View → EviaViewModel → AuthenticationRepository → AuthenticationService, session stream cập nhật guard; logout xóa session. Không tích hợp Firebase Auth thật. Xem tài khoản/lệnh chạy trong README.


## Database review trực tiếp — 04/11/2026

Đã đọc lại 44/44 frame trên page `2083:272` qua Figma, 1.342 visible text nodes,
và xem ảnh 6 frame đại diện. Xem [mapping dữ liệu và conflict registry](database-figma-review.md)
và [schema v1.2](DATABASE_DESIGN.md). Đây là schema proposal, chưa thay đổi UI,
Figma, dữ liệu Firebase hoặc Rules đã deploy.

Các quyết định giữ riêng 200/250 Coin và Waitlist trong UI demo được ghi ở phần
lịch sử bên dưới **không phải backend policy**. Schema production chỉ có một giá
chuẩn **200 xu cho Café voucher**, không có Waitlist; Daily rewards theo PROJECT_CONTEXT.
Milestones được owner khôi phục ngày 05/11/2026 theo [hợp đồng mới](EVENT_MILESTONES.md);
backend chỉ thêm policy/API, chưa thay UI. Owner đã bỏ ticket email/fixed reminders, feedback bonus,
missions, seasonal targets và assigned seats/VIP/tiers. Walk-in chỉ QR, không
nhập mã; auth mở rộng Google + email/password; tối thiểu 3 sở thích bắt buộc,
không Skip. Student/club verification tạm hoãn; FD-12 cashier flow chưa chốt.
Các quyết định này là target hiện tại; source UI demo/lịch sử bên dưới chưa
được sửa theo task cập nhật database. FD-06 do design team dự kiến sửa.
## S01 Welcome — yêu cầu trực tiếp 05/11/2026

Nguồn layout: `assets/EVIA_S01_Welcome_Reference.png` do người dùng cung cấp.
Source: `welcome_screen.dart`, route `/`; Login cũ chuyển `/login`.
Runtime chỉ dùng logo chính thức `evia-logo-lime-transparent(4).png` và
`EVIA_Welcome_Hero.png` (giữ tỷ lệ, không thêm artwork/decorations khác).
Reference screenshot không bundle/render. Text/buttons là Flutter components.
Tokens bổ sung cục bộ `WelcomeTokens`: blue #1769F5, navy #17243B,
secondary #64748B, nền trắng #FFFFFF theo tinh chỉnh tiếp theo của người dùng;
headline 28sp, body 15sp,
buttons minHeight 52dp và radius 12dp. Không thay theme các màn khác.
SafeArea thật; không giả status bar/nav bar, không bottom navigation/carousel.
Hero co theo chiều cao có giới hạn; nội dung scroll khi màn thấp/text scale lớn.
Get Started mở `/signup` với form Create Account; adapter đăng ký vẫn pending.
Không đánh đồng form hợp lệ hoặc chọn sở thích với tạo tài khoản thành công.

## Sign Up / Create Account — 05/11/2026

Nguồn: ảnh tham chiếu và yêu cầu trực tiếp, dùng Login hiện tại làm chuẩn.
`sign_up_screen.dart` dùng EviaPage/LoginBackdrop/EviaLogo/AppButton,
cùng text fields/theme. Theo tinh chỉnh mới nhất, Sign Up không collage nhưng
logo 180dp và tagline “Find Events. Make Memories.” giống Login. Khi có bàn phím,
logo thu 112dp, tagline ẩn như Login. Subtitle: “Join Evia and discover events you'll love.”
Theo sửa thứ tự tiếp theo: bốn fields → Terms checkbox → Create Account →
Google → Log In. Không thu nhỏ chữ/vùng bấm. Bản thử ba ảnh ngang
trước đó không còn dùng ở Sign Up. Login và assets giữ nguyên.
Không fake status bar, Student ID, university email hoặc phone. Bốn fields có
show/hide password riêng, error text inline, checkbox không preselected. Terms và
Privacy là văn bản vì chưa có URL. Fields giữ state khi mở bàn phím.
Route `/signup` thay placeholder cũ; Log In về `/login`, Skip đến guest Discover.

Tinh chỉnh chuyển màn theo yêu cầu: giữ giao diện Login cũ, Welcome → Login
slide 6% chiều rộng từ phải vào + fade trong 280ms; Back đảo chiều trong 220ms.
Reduced motion bỏ animation. Không thay S00, asset hoặc thêm dependency.

Tinh chỉnh Login khi nhập liệu: giữ nền/collage gốc lúc bàn phím đóng. Khi bàn
phím ảo hiện, logo từ 180dp thu về 112dp, các phần minh họa/tagline và header
phụ collapse + fade trong 180ms. Form giữ nguyên element/controller/focus,
vẫn scroll khi thiếu chỗ. Đóng bàn phím khôi phục hình; reduced motion bỏ tween.

## S00 Splash — yêu cầu trực tiếp 05/11/2026

Nguồn: PNG chính thức do người dùng cung cấp tại
`assets/evia-logo-lime-transparent(4).png` (1952×806, RGBA), giữ nguyên bytes.
Logo chỉ có e trắng trong vé + via navy, hai tia lime. Không vẽ lại typography.
Theo yêu cầu sửa animation tiếp theo, thay fade toàn ảnh bằng ba lớp độc lập:
vé (scale 0.85→1, 0–300ms), vé trượt ngang từ giữa đến vị trí cuối (300–800ms),
via wipe trái→phải (350–800ms), hai tia lime pulse một lần (700–950ms).
Giữ logo hoàn chỉnh đến 1200ms, không đổi ảnh/crossfade ở frame cuối.
`tool/derive_splash_layers.py` tách connected components không đổi pixel hay
resample, kiểm tra ghép lại trùng RGBA ảnh gốc. Canvas alpha 1690×622 dùng chung;
vé [0,92,638,530], via [618,40,1072,539], rays [522,0,185,181] theo x/y/w/h.
Displacement từ tâm vé đến tâm canvas được scale theo viewport, không offset
pixel tùy ý. Bản reduced motion dùng nguyên PNG đầy đủ tĩnh.
Nền Splash/Welcome trắng #FFFFFF theo tinh chỉnh tiếp theo; Login giữ nền và
trang trí gốc. `AppColors.splashBackground` dùng chung màu trắng từ entryBackground.
Logo tối đa 280dp, giữ tỷ lệ.
Không caption, nút, spinner hoặc bottom navigation.
Android static splash dùng cùng PNG/nền cho light/dark và Android 12+.
Không có iOS host để xác minh native. Mapping Figma của các màn cũ bên dưới
không phải nguồn thiết kế S00 này.

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
| Html → Body → Main - MobileScreenContainer | `2083:4509` | `EviaLoginScreen` / `/login` |
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

Theo yêu cầu thống nhất UI, hai tab Earn Coins và Redeem Rewards dùng chung
`RewardsWallet` với thiết kế Earn Coins (`2083:3522`): nền mây, chồng xu bên trái
số dư, mascot lớn và dòng `Temporarily locked`. Khung số dư trên catalog chủ động
khác frame `2083:3327`; số xu vẫn lấy từ cùng `ActivityViewModel`.

Đợt sửa UI/UX tiếp theo thống nhất giá café 250 xu ở mọi bước (override catalog
Figma 200 xu), header/tab/bottom bar dùng cùng một kiểu, vùng bấm tab tối thiểu
48dp. Locker/voucher/success render receipt thật của phiên demo; khi chưa có receipt
hiển thị empty state thay cho voucher/success mẫu. Nội dung merchandise chưa có
handoff được ghi chưa cấu hình. QR chỉ là minh họa; phần thưởng merchandise dùng
ảnh và mã demo riêng. Các overrides này theo yêu cầu sửa lỗi UI/UX, không phải
bằng chứng backend/fulfillment thật đã được tích hợp.

Theo yêu cầu điều chỉnh More Ways to Earn: Attend Events mở `/my-events` thay vì
scanner trực tiếp. Complete Missions đổi thành Event Milestones và mở
`/rewards/milestones`; mô tả hai action được cập nhật theo đúng màn hình đích.

Tinh chỉnh tiếp theo: bỏ avatar Profile trên header của cả hai tab Rewards vì
đã có tab Profile ở bottom bar. Nút Check In Today/Checked In Today bỏ icon cuối,
giữ text thể hiện trạng thái và số xu.

Daily Check-in dùng vòng tròn 32dp cho cả 7 ngày, căn icon ở giữa để các icon
check/xu/chấm/sao và dòng số xu không lệch hàng theo kích thước asset.

My Rewards / Used & Expired dùng thumbnail và category từ reward fixture đã có;
badge trạng thái căn cuối hàng, trạng thái Expired dùng warning tokens. Icon tab
được tint theo selected state để icon trắng không bị chìm trên nền tab chưa chọn.

Dòng In Deposits căn số xu về mép phải, ngay trước chevron, tách khỏi phần mô tả
bên trái; số xu vẫn có thể xuống dòng khi tăng cỡ chữ.

In Deposits mở Coin History với filter Deposits được chọn sẵn, thay bottom sheet
giải thích. Nếu đang ở Coin History thì chỉ đổi filter, không push thêm route.
View coin history mở filter All để không giữ nhầm filter từ lần xem deposits.

Theo yêu cầu thống nhất icon xu: `CoinIcon` dùng duy nhất asset đồng xu tròn có
dấu `$` (`2083:456/imgContainer18`, 12.5dp mặc định) ở số dư, giá Rewards, milestone,
Discover/Following, xu sự kiện/đăng ký và saved events. Wallet dùng cùng hình ở
32dp; màu trạng thái vẫn dùng tokens tương ứng. Các icon xu hình sao, stack ghép
và ký tự ghép được thay bằng widget này; hình xu nằm trong minh họa mascot giữ
nguyên asset gốc. Số dư/đơn vị dữ liệu không đổi trong yêu cầu thống nhất icon.

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
- Café có giá 200 ở catalog Figma, 250 ở detail/confirmation. Bản đầu giữ riêng
  hai giá; sau yêu cầu sửa UX, runtime thống nhất 250 xu ở mọi bước như override
  đã ghi ở trên.
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
chi tiết là Main Stadium. About frame lặp Sat Nov 7 tại cả date/time/location.
Luồng chi tiết dùng ngày, giờ và địa điểm riêng của sự kiện được chọn ở cả ba tab.
Nút Follow trong chi tiết phản ánh danh sách Follow của phiên đăng nhập.

Cỡ body 14sp, touch target 48dp, font Roboto fallback và text wrap/scroll có thể
làm card cao hơn và nút nằm dưới vùng cuộn so với bản Inter 11–13px/nowrap.
Đã capture/xem cả 17 frame ở 390dp và thử 360/412dp, scale 1x/2x; chưa phải
pixel-diff hoặc native Android visual sign-off. Các badge verified/QR là mẫu,
không biểu thị server đã xác minh. Map và Help/Settings là hướng dẫn nội bộ.

## Backend handoff — 04/11/2026

Backend API hiện có trong [backend-integration.md](backend-integration.md);
không sửa màn hình/Figma ở task backend. UI demo cũ có thể còn Waitlist hoặc milestone chưa nối API,
coin minh họa và auth giả: đội frontend cần chuyển theo owner decisions và bind
services thay demo data. Không coi 20 backend Emulator tests là visual/native
acceptance của 44 frames. Các nghiệp vụ chưa chốt vẫn bị backend khóa.

## Rewards preview override - 05/11/2026

User requested visible mock data with local currency mutation/persistence removed.
Daily Check-in previews day 8 (+20 from day 7). Financial actions wait for API.
CoinIcon defaults to FlowTheme.gold. My Rewards Back returns to Rewards catalog.
