const labels = {
  login: 'Đăng nhập', logout: 'Đăng xuất', sign_up: 'Tạo tài khoản',
  view_event: 'Xem chi tiết sự kiện', register_event: 'Đăng ký sự kiện',
  cancel_registration: 'Hủy đăng ký', check_in_event: 'Xác nhận tham dự',
  view_reward: 'Xem chi tiết quà', redeem_reward: 'Đổi quà',
  generate_report: 'Xuất báo cáo', action_error: 'Thao tác gặp lỗi',
  admin_event_saved: 'Admin lưu sự kiện', admin_event_published: 'Admin xuất bản sự kiện',
  admin_voucher_saved: 'Admin lưu voucher', admin_remote_config_published: 'Admin xuất bản cấu hình',
  first_open: 'Mở ứng dụng lần đầu', first_visit: 'Truy cập trang web lần đầu',
  session_start: 'Bắt đầu phiên truy cập', user_engagement: 'Tương tác của người dùng',
  page_view: 'Xem trang web', screen_view: 'Xem màn hình', app_update: 'Cập nhật ứng dụng',
  scroll: 'Cuộn trang', click: 'Nhấn liên kết ngoài',
};
export function analyticsEventLabel(name) {
  if (Object.hasOwn(labels, name)) return labels[name];
  const words = name.replace(/_+/g, ' ').trim();
  return words ? words[0].toLocaleUpperCase('vi-VN') + words.slice(1) : 'Sự kiện không có tên';
}
export const analyticsScopeLabel = scope => ({
  android: 'Android · tất cả stream Android trong property',
  web: 'Web · tất cả stream web trong property',
  stream: 'Stream đã cấu hình trên backend',
  property: 'Toàn bộ GA4 property',
}[scope] ?? 'Nguồn chưa xác định; kiểm tra phiên bản backend');
