import assert from 'node:assert/strict';
import { writeFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
import { catalogSchema } from '../lib/catalog.js';

export function createDemoCatalog(now = new Date()) {
  assert(Number.isFinite(now.getTime()), 'Valid generation time required');
  const sourceRef = 'https://github.com/dong-nnp/prm323-lab3-camply/blob/KietDM/feat/backend/docs/DEMO_DATA.md';
  const topics = [
    ['technology', 'Công nghệ'], ['music', 'Âm nhạc'], ['arts', 'Nghệ thuật'],
    ['sports', 'Thể thao'], ['volunteer', 'Tình nguyện'], ['career', 'Nghề nghiệp'],
    ['business', 'Kinh doanh'], ['gaming', 'Trò chơi'], ['photography', 'Nhiếp ảnh'],
    ['environment', 'Môi trường'],
  ];
  const clubs = [
    ['demo-tech-club', 'CLB Công nghệ Evia', 'technology', 'Workshop lập trình và chia sẻ công nghệ.'],
    ['demo-music-club', 'CLB Âm nhạc Evia', 'music', 'Giao lưu âm nhạc và biểu diễn sinh viên.'],
    ['demo-creative-club', 'CLB Sáng tạo Evia', 'arts', 'Thiết kế, nghệ thuật và nhiếp ảnh.'],
    ['demo-sports-club', 'CLB Thể thao Evia', 'sports', 'Hoạt động rèn luyện sức khỏe và thể thao.'],
    ['demo-student-union', 'Đội Hoạt động Sinh viên Evia', 'volunteer', 'Kết nối cộng đồng và hoạt động campus.'],
  ];
  const instant = hours => new Date(now.getTime() + hours * 3_600_000).toISOString();
  const eventSpecs = [
    ['demo-live-registration', 'Workshop Flutter đang mở check-in', 0, 'technology', 0.75, 'registration', 30, 50, 100],
    ['demo-live-walkin', 'Ngày hội kết nối CLB', 4, 'volunteer', -0.5, 'walk_in', null, 0, 80],
    ['demo-mobile-workshop', 'Flutter và Firebase từ cơ bản', 0, 'technology', 26, 'registration', 100, 50, 100],
    ['demo-career-talk', 'Định hướng nghề nghiệp lập trình', 0, 'career', 73, 'registration', 80, 0, 80],
    ['demo-music-night', 'Đêm nhạc sinh viên Evia', 1, 'music', 124, 'registration', 100, 100, 150],
    ['demo-photo-walk', 'Dạo campus cùng máy ảnh', 2, 'photography', 145, 'walk_in', null, 0, 70],
    ['demo-badminton', 'Giao lưu cầu lông', 3, 'sports', 169, 'registration', 40, 30, 60],
    ['demo-green-campus', 'Một ngày campus xanh', 4, 'environment', 193, 'walk_in', null, 0, 100],
    ['demo-design-thinking', 'Workshop tư duy thiết kế', 2, 'arts', 220, 'registration', 60, 50, 100],
    ['demo-full-event', 'Workshop đã đóng số lượng vé', 0, 'technology', 244, 'registration', 0, 0, 50],
    ['demo-last-ticket', 'Giao lưu thể thao — một vé cuối', 3, 'sports', 268, 'registration', 1, 0, 50],
    ['demo-past-event', 'Buổi giao lưu campus đã kết thúc', 4, 'volunteer', -48, 'walk_in', null, 0, 80],
  ];
  const catalog = {
    interests: topics.map(([id, label]) => ({ id, label, status: 'active', sourceRef })),
    organizers: clubs.map(([id, name, tag, description]) => ({ id, name: `[DEMO] ${name}`, description: `${description} Đây là CLB giả lập phục vụ Lab 3, không đại diện tổ chức thật.`, tagline: 'Dữ liệu demo do chủ dự án cho phép tạo', kind: 'demo_student_club', tags: [tag], published: true, sourceRef })),
    events: eventSpecs.map(([id, title, club, category, startHour, mode, capacity, deposit, reward], index) => ({
      id, organizerId: clubs[club][0], title: `[DEMO] ${title}`,
      subtitle: 'Sự kiện giả lập cho việc tích hợp và kiểm thử Evia',
      description: `${title}. Nội dung, thời gian và địa điểm do hệ thống tạo theo yêu cầu chủ dự án để thử ba flow. Đây không phải lời mời hoặc lịch tổ chức thật.`,
      category, tags: [...new Set([category, clubs[club][2]])],
      status: startHour < -24 ? 'completed' : 'published', visibility: 'public',
      startAt: instant(startHour), endAt: instant(startHour + 2), timezone: 'Asia/Ho_Chi_Minh',
      doorsOpenAt: instant(startHour - 0.5),
      checkInStartAt: instant(index === 0 ? -0.25 : startHour - 0.5), checkInEndAt: instant(startHour + 1.5),
      ...(mode === 'registration' ? { registrationClosesAt: instant(startHour), registrationTerms: { version: 'demo-refund30-v2', text: `Dữ liệu demo. Đăng ký giữ ${deposit} Evia Coin; check-in hợp lệ hoàn cọc và thưởng ${reward} xu. Chủ động hủy được hoàn 30% cọc, làm tròn xuống số xu nguyên; phần còn lại mất. No-show mất toàn bộ cọc. Không có Waitlist, không quy đổi tiền thật.` } } : {}),
      venue: { name: `[DEMO] ${['Phòng Lab A', 'Sân khấu campus', 'Xưởng sáng tạo', 'Nhà thi đấu', 'Sảnh sinh viên'][club]}`, address: 'Khuôn viên Evia giả lập — địa điểm minh họa', entranceLabel: 'Cổng demo', checkInInstructions: mode === 'registration' ? 'Xuất trình QR hoặc mã vé cho staff demo được phân công.' : 'Quét QR hoặc nhập mã walk-in do staff demo cấp tại sự kiện.', accessibilityNotes: 'Địa điểm giả lập; chưa có thông tin tiếp cận thực tế.', transitNotes: 'Không dùng địa chỉ demo để di chuyển.' },
      audience: { scope: 'everyone' }, benefits: [{ title: 'Thử nghiệm flow tham dự', description: `Check-in hợp lệ nhận ${reward} Evia Coin trong môi trường demo.` }],
      participantRequirements: ['Dùng tài khoản có địa chỉ email hợp lệ trong ứng dụng.', 'Chỉ dùng dữ liệu này để thử nghiệm Lab 3.'],
      schedule: [{ id: 'welcome', title: 'Đón người tham dự', startAt: instant(startHour), endAt: instant(startHour + 0.25), locationLabel: 'Địa điểm demo' }, { id: 'main', title: 'Hoạt động chính', startAt: instant(startHour + 0.25), endAt: instant(startHour + 2) }],
      scheduleNote: 'Lịch demo có thể được chủ dự án sửa sau.', featured: [0, 2, 4].includes(index), admissionNote: mode === 'walk_in' ? 'Walk-in; Going không giữ chỗ hoặc cấp vé.' : 'Vé giới hạn theo capacity; không bán vé bằng tiền thật.',
      participationMode: mode, capacity, depositCoins: deposit, attendanceRewardCoins: reward, sourceRef,
    })),
    rewards: [
      ['demo-cafe', 'Voucher Café Evia', 'food_drinks', 200, 100, 'voucher', 30],
      ['demo-snack', 'Combo nước và bánh', 'food_drinks', 100, 100, 'voucher', 14],
      ['demo-tote', 'Túi vải Evia', 'merchandise', 400, 30, 'physical', 30],
      ['demo-cinema', 'Vé xem phim campus', 'experiences', 500, 30, 'voucher', 30],
      ['demo-hoodie', 'Áo hoodie Evia', 'merchandise', 800, 20, 'physical', 30],
    ].map(([id, title, category, price, stock, fulfillmentType, validDays]) => ({
      id, title: `[DEMO] ${title}`, description: `${title} của nhà tài trợ giả lập Evia Demo Sponsor. Không có quà, dịch vụ hoặc giá trị thanh toán ngoài đời thực.`, category, priceCoins: price, stockRemaining: stock, status: 'active', validDays,
      usageLocations: ['[DEMO] Quầy Evia Demo Sponsor trong khuôn viên giả lập'],
      termsText: 'Chỉ thử nghiệm Lab 3. Không phải cam kết của nhà tài trợ thật, không đổi tiền hoặc nhận quà thật. Mỗi lượt đổi trừ xu theo giá server. Voucher dùng một lần, admin demo xác nhận; quà vật lý chưa có flow xác nhận giao hàng.', termsVersion: 'demo-v1',
      redemptionSteps: ['Xác nhận dùng Evia Coin trong app.', fulfillmentType === 'voucher' ? 'Đưa QR/mã voucher cho admin demo xác nhận.' : 'Lưu mã giao dịch demo để thử màn chi tiết quà.'],
      redemptionInstructions: fulfillmentType === 'voucher' ? 'Admin demo xác nhận đã sử dụng voucher trong môi trường thử nghiệm.' : 'Quà vật lý giả lập; chưa có giao nhận hoặc API xác nhận đã nhận.',
      fulfillmentType, sourceRef,
    })),
  };
  const parsed = catalogSchema.parse(catalog);
  assert.equal(parsed.events.length, 12);
  assert.equal(parsed.rewards.find(r => r.id === 'demo-cafe').priceCoins, 200);
  assert(parsed.events.every(e => parsed.organizers.some(o => o.id === e.organizerId)));
  assert(parsed.events.every(e => e.tags.every(tag => topics.some(([id]) => id === tag))));
  return parsed;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const now = new Date(), catalog = createDemoCatalog(now);
  await writeFile(new URL('../../firebase/demo-catalog.json', import.meta.url), JSON.stringify(catalog, null, 2) + '\n');
  console.log(JSON.stringify({ generatedAt: now.toISOString(), counts: Object.fromEntries(Object.entries(catalog).map(([key, rows]) => [key, rows.length])) }));
}
