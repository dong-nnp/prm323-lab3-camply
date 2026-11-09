import { analyticsEventLabel, analyticsScopeLabel } from './analytics-labels.js';

const $ = id => document.getElementById(id);

export function adminErrorMessage(error) {
  const messages = {
    CATALOG_CHANGED: 'Bản ghi đã thay đổi. Mở lại chi tiết để tải dữ liệu mới.',
    EVENT_ALREADY_EXISTS: 'ID sự kiện đã được sử dụng.',
    REWARD_ALREADY_EXISTS: 'ID mẫu voucher đã được sử dụng.',
    ORGANIZER_NOT_FOUND: 'Không tìm thấy ban tổ chức theo ID đã nhập.',
    ORGANIZER_UNAVAILABLE: 'Ban tổ chức phải được công khai trước khi xuất bản sự kiện công khai.',
    EVENT_MUST_BE_UPCOMING: 'Ngày bắt đầu phải ở tương lai để xuất bản.',
    EVENT_STATE_CHANGED: 'Trạng thái sự kiện đã thay đổi. Hãy mở lại chi tiết.',
    PUBLISHED_EVENT_FIELDS_LOCKED: 'Ban tổ chức, phạm vi và hình thức tham dự đã được khóa khi xuất bản.',
    EVENT_CAPACITY_BELOW_REGISTRATIONS: 'Sức chứa thấp hơn số người đã đăng ký.',
    TERMS_VERSION_REQUIRED: 'Hãy tăng phiên bản điều khoản khi sửa nội dung điều khoản.',
    REMOTE_CONFIG_REWARD_INVALID: 'Lịch xu đã xuất bản không hợp lệ. Kiểm tra daily_checkin_rewards trong Firebase.',
    REMOTE_CONFIG_CHANGED: 'Cấu hình đã thay đổi. Tải lại trước khi xuất bản.',
    REMOTE_CONFIG_ACCESS_DENIED: 'Backend chưa có quyền quản lý Firebase Remote Config.',
    ANALYTICS_NOT_CONFIGURED: 'Backend chưa có GA4 Property ID hợp lệ.',
    ANALYTICS_ACCESS_DENIED: 'Tài khoản chạy backend cần quyền xem GA4 property.',
    CRASHLYTICS_NOT_CONFIGURED: 'Backend chưa có bảng BigQuery xuất từ Crashlytics.',
    CRASHLYTICS_ACCESS_DENIED: 'Tài khoản chạy backend cần quyền truy vấn và đọc bảng Crashlytics.',
    CRASHLYTICS_QUERY_PENDING: 'BigQuery đang xử lý báo cáo. Hãy thử lại sau.',
    CLOUD_INTEGRATION_UNAVAILABLE_IN_EMULATOR: 'Chức năng này cần kết nối dự án Firebase thật.',
    NO_REGISTERED_DEVICE: 'Tài khoản này chưa đăng ký thiết bị nhận push. Hãy đăng nhập trên điện thoại, mở Thông báo và cho phép nhận thông báo rồi gửi lại.',
    ACCOUNT_DISABLED: 'Tài khoản gửi hoặc nhận không còn hoạt động. Hãy tải lại danh sách và kiểm tra tài khoản.',
    ACCOUNT_NOT_INITIALIZED: 'Không tìm thấy hồ sơ tài khoản. Hãy tải lại danh sách người nhận.',
    DUPLICATE_CONFLICT: 'Lượt gửi này đã được dùng cho nội dung khác. Hãy tải lại trang trước khi gửi tiếp.',
  };
  const code = error.details?.code;
  if (error.code?.startsWith('storage/')) {
    const storageMessages = {
      'storage/unauthorized': 'Không có quyền tải ảnh. Kiểm tra phiên admin và Storage Rules.',
      'storage/retry-limit-exceeded': 'Tải ảnh bị gián đoạn. Kiểm tra kết nối và lưu lại để thử tiếp.',
      'storage/canceled': 'Đã hủy tải ảnh.',
      'storage/bucket-not-found': 'Không tìm thấy bucket Firebase Storage đã cấu hình.',
      'storage/quota-exceeded': 'Firebase Storage đã vượt hạn mức hiện tại.',
    };
    return storageMessages[error.code] ?? 'Không tải được ảnh lên Firebase Storage. Vui lòng thử lại.';
  }
  if (messages[code]) return messages[code];
  if (error.code === 'functions/not-found') return 'Không tìm thấy bản ghi hoặc API. Kiểm tra backend đã được cập nhật.';
  if (error.code === 'functions/permission-denied') return 'Tài khoản hiện tại không có quyền thực hiện thao tác này.';
  return error.code?.startsWith('functions/') ? 'Không thể hoàn tất thao tác. Hãy thử lại.' : (error.message || 'Không thể hoàn tất thao tác.');
}

export function setupServicePanels({ firebase, session, status, text, track }) {
  const form = $('config-form');
  const day = form.elements.rewardDay;
  const coins = form.elements.rewardCoins;
  const reload = $('fetch-config');
  const publish = $('publish-config');
  let config;
  let configRequested = false;
  let configBusy = false;
  const reportForm = $('analytics-report-form');
  const reportButton = reportForm.querySelector('button');
  let analyticsRequested = false;

  function showSelectedReward() {
    coins.value = config?.rewards[Number(day.value) - 1] ?? '';
  }
  let realtimeTimer;

  function setConfig(value) {
    config = value;
    showSelectedReward();
  }

  function syncConfigControls() {
    reload.disabled = configBusy;
    publish.disabled = day.disabled = coins.disabled = configBusy || !config;
  }

  async function runConfig(saving) {
    const current = session();
    if (!current || configBusy || (saving && !config)) return;
    configRequested = true;
    const input = saving ? { etag: config.etag, day: Number(day.value), coins: coins.valueAsNumber } : null;
    configBusy = true;
    syncConfigControls();
    status('config-status', saving ? 'Đang xuất bản…' : 'Đang tải cấu hình…');
    try {
      const value = await (saving ? firebase.publishRemoteConfig(input) : firebase.getRemoteConfig());
      if (session() !== current) return;
      if (!Array.isArray(value.rewards) || !Array.isArray(value.appliedRewards)) {
        throw new Error('Backend chưa hỗ trợ lịch Daily Check-in. Cập nhật Cloud Functions rồi tải lại.');
      }
      setConfig(value);
      if (saving) void track('admin_remote_config_published');
      const message = saving ? 'Đã áp dụng mức thưởng Daily Check-in.' : 'Đã tải cấu hình.';
      const pending = value.rewards.some((coins, index) => coins !== value.appliedRewards[index])
        ? ' Lịch đã xuất bản chưa đồng bộ. Bấm Xuất bản và áp dụng để đồng bộ.' : '';
      status('config-status', message + pending);
    } catch (error) {
      if (session() !== current) return;
      setConfig(undefined);
      status('config-status', adminErrorMessage(error), true);
    } finally {
      if (session() === current) {
        configBusy = false;
        syncConfigControls();
      }
    }
  }

  function renderReport(items, realtime = false) {
    const target = $('analytics-report-table');
    target.replaceChildren();
    if (!items.length) return;
    const columns = ['Hành vi', 'Lượt ghi nhận', realtime ? 'Người dùng hoạt động' : 'Người dùng'];
    const table = document.createElement('table');
    table.createTHead().insertRow().append(...columns.map(value => text('th', value)));
    const body = table.createTBody();
    for (const item of items) {
      const row = body.insertRow();
      const values = [analyticsEventLabel(item.name), item.count, item.users];
      row.append(...values.map(value => text('td', value)));
    }
    target.append(table);
  }

  async function loadReport({ background = false } = {}) {
    const current = session();
    if (!current || reportButton.disabled) return;
    analyticsRequested = true;
    const period = reportForm.elements.days.value;
    const realtime = period === 'realtime';
    const source = reportForm.elements.source.value;
    reportButton.disabled = reportForm.elements.days.disabled = true;
    if (reportForm.elements.source) reportForm.elements.source.disabled = true;
    if (!background) {
      renderReport([]);
      status('analytics-report-status', 'Đang tải báo cáo…');
    }
    try {
      const report = await firebase.analyticsReport(realtime
        ? { realtime: true, source }
        : { days: Number(period), source });
      if (session() !== current) return;
      renderReport(report.items, realtime);
      const updated = realtime ? ' Cập nhật lúc ' + new Date().toLocaleTimeString('vi-VN') + '.' : '';
      status('analytics-report-status', (report.items.length
        ? 'Đã tải ' + report.items.length + ' mục' + (report.scope === 'property' ? ' · Toàn bộ GA4 property.' : '.')
        : 'Chưa có dữ liệu trong khoảng thời gian đã chọn.') + ' Nguồn: ' + analyticsScopeLabel(report.scope) + '.' + updated);
    } catch (error) {
      if (session() === current) status('analytics-report-status', adminErrorMessage(error), true);
    } finally {
      if (session() === current) {
        reportButton.disabled = reportForm.elements.days.disabled = false;
        if (reportForm.elements.source) reportForm.elements.source.disabled = false;
      }
    }
  }

  day.addEventListener('change', showSelectedReward);
  form.addEventListener('submit', event => {
    event.preventDefault();
    if (config && window.confirm('Xuất bản và áp dụng mức thưởng cho ngày đã chọn?')) void runConfig(true);
  });
  reload.addEventListener('click', () => void runConfig(false));
  reportForm.addEventListener('submit', event => {
    event.preventDefault();
    void loadReport();
  });

  return {
    open(page) {
      clearInterval(realtimeTimer);
      if (page === 'config' && !configRequested) void runConfig(false);
      if (page === 'analytics') {
        if (!analyticsRequested || reportForm.elements.days.value === 'realtime') void loadReport();
        realtimeTimer = setInterval(() => {
          if (!document.hidden && reportForm.elements.days.value === 'realtime') {
            void loadReport({ background: true });
          }
        }, 30000);
      }
    },
    reset() {
      configBusy = configRequested = false;
      analyticsRequested = false;
      setConfig(undefined);
      syncConfigControls();
      status('config-status', '');
      reportButton.disabled = reportForm.elements.days.disabled = false;
      if (reportForm.elements.source) reportForm.elements.source.disabled = false;
      renderReport([]);
      status('analytics-report-status', '');
    },
  };
}
  reportForm.addEventListener('change', () => { void loadReport(); });
      clearInterval(realtimeTimer);
