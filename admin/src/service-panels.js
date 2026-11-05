import { milestoneDefaults } from './firebase.js';

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
    REMOTE_CONFIG_CHANGED: 'Cấu hình đã thay đổi. Tải lại trước khi xuất bản.',
    REMOTE_CONFIG_ACCESS_DENIED: 'Backend chưa có quyền quản lý Firebase Remote Config.',
    ANALYTICS_NOT_CONFIGURED: 'Backend chưa có GA4 Property ID hợp lệ.',
    ANALYTICS_ACCESS_DENIED: 'Tài khoản chạy backend cần quyền xem GA4 property.',
    CRASHLYTICS_NOT_CONFIGURED: 'Backend chưa có bảng BigQuery xuất từ Crashlytics.',
    CRASHLYTICS_ACCESS_DENIED: 'Tài khoản chạy backend cần quyền truy vấn và đọc bảng Crashlytics.',
    CRASHLYTICS_QUERY_PENDING: 'BigQuery đang xử lý báo cáo. Hãy thử lại sau.',
    CLOUD_INTEGRATION_UNAVAILABLE_IN_EMULATOR: 'Chức năng này cần kết nối dự án Firebase thật.',
  };
  const code = error.details?.code;
  if (messages[code]) return messages[code];
  if (error.code === 'functions/not-found') return 'Không tìm thấy bản ghi hoặc API. Kiểm tra backend đã được cập nhật.';
  if (error.code === 'functions/permission-denied') return 'Tài khoản hiện tại không có quyền thực hiện thao tác này.';
  return error.code?.startsWith('functions/') ? 'Không thể hoàn tất thao tác. Hãy thử lại.' : (error.message || 'Không thể hoàn tất thao tác.');
}

export function setupServicePanels({ firebase, session, status, text, formatDate, track }) {
  const form = $('config-form');
  const enabled = form.elements.enabled;
  const intro = form.elements.intro;
  const reload = $('fetch-config');
  const publish = $('publish-config');
  let config;
  let configRequested = false;
  let configBusy = false;
  const requestedReports = new Set();

  function preview() {
    const visible = enabled.value === 'true';
    $('config-preview').hidden = !visible;
    $('config-preview-intro').textContent = intro.value;
    $('config-hidden').hidden = visible;
  }

  function setConfig(value) {
    config = value;
    enabled.value = value?.enabled === 'true' || (value?.enabled == null && milestoneDefaults.enabled) ? 'true' : 'false';
    intro.value = value?.intro ?? milestoneDefaults.intro;
    preview();
  }

  function syncConfigControls() {
    reload.disabled = configBusy;
    publish.disabled = enabled.disabled = intro.disabled = configBusy || !config;
  }

  async function runConfig(saving) {
    const current = session();
    if (!current || configBusy || (saving && !config)) return;
    configRequested = true;
    const input = saving ? { etag: config.etag, enabled: enabled.value === 'true', intro: intro.value } : null;
    configBusy = true;
    syncConfigControls();
    status('config-status', saving ? 'Đang xuất bản…' : 'Đang tải cấu hình…');
    try {
      const value = await (saving ? firebase.publishRemoteConfig(input) : firebase.getRemoteConfig());
      if (session() !== current) return;
      setConfig(value);
      if (saving) void track('admin_remote_config_published');
      const message = saving ? 'Đã xuất bản' : 'Đã tải giá trị mặc định';
      status('config-status', message + (value.version ? ' · Phiên bản ' + value.version : '') +
        (value.hasConditions ? ' · Các giá trị theo điều kiện vẫn được áp dụng.' : ''));
    } catch (error) {
      if (session() !== current) return;
      if (!saving || error.details?.code === 'REMOTE_CONFIG_CHANGED') config = undefined;
      status('config-status', adminErrorMessage(error), true);
    } finally {
      if (session() === current) {
        configBusy = false;
        syncConfigControls();
      }
    }
  }

  function renderReport(kind, items) {
    const target = $(kind + '-report-table');
    target.replaceChildren();
    if (!items.length) return;
    const analytics = kind === 'analytics';
    const columns = analytics ? ['Sự kiện', 'Lượt ghi nhận', 'Người dùng'] : ['Mã lỗi', 'Loại', 'Số lần', 'Lần gần nhất', 'Phiên bản app'];
    const table = document.createElement('table');
    table.createTHead().insertRow().append(...columns.map(value => text('th', value)));
    const body = table.createTBody();
    for (const item of items) {
      const row = body.insertRow();
      const values = analytics ? [item.name, item.count, item.users] : [item.issueId, item.type, item.count, formatDate(item.lastSeen), item.version];
      row.append(...values.map(value => text('td', value)));
    }
    target.append(table);
  }

  async function loadReport(kind) {
    const current = session();
    const reportForm = $(kind + '-report-form');
    const button = reportForm.querySelector('button');
    if (!current || button.disabled) return;
    requestedReports.add(kind);
    const days = Number(reportForm.elements.days.value);
    button.disabled = reportForm.elements.days.disabled = true;
    renderReport(kind, []);
    status(kind + '-report-status', 'Đang tải báo cáo…');
    try {
      const report = await firebase.report(kind, days);
      if (session() !== current) return;
      renderReport(kind, report.items);
      status(kind + '-report-status', report.items.length
        ? 'Đã tải ' + report.items.length + ' mục' + (report.scope === 'property' ? ' · Toàn bộ GA4 property.' : '.')
        : 'Chưa có dữ liệu trong khoảng thời gian đã chọn.');
    } catch (error) {
      if (session() === current) status(kind + '-report-status', adminErrorMessage(error), true);
    } finally {
      if (session() === current) button.disabled = reportForm.elements.days.disabled = false;
    }
  }

  form.addEventListener('input', preview);
  form.addEventListener('submit', event => {
    event.preventDefault();
    if (config && window.confirm('Xuất bản giá trị mặc định mới cho Event Milestones?')) void runConfig(true);
  });
  reload.addEventListener('click', () => void runConfig(false));
  for (const kind of ['analytics', 'crashlytics']) {
    $(kind + '-report-form').addEventListener('submit', event => {
      event.preventDefault();
      void loadReport(kind);
    });
  }

  return {
    open(page) {
      if (page === 'config' && !configRequested) void runConfig(false);
      if ((page === 'analytics' || page === 'crashlytics') && !requestedReports.has(page)) void loadReport(page);
    },
    reset() {
      configBusy = configRequested = false;
      requestedReports.clear();
      setConfig(undefined);
      syncConfigControls();
      status('config-status', '');
      for (const kind of ['analytics', 'crashlytics']) {
        const reportForm = $(kind + '-report-form');
        reportForm.querySelector('button').disabled = reportForm.elements.days.disabled = false;
        renderReport(kind, []);
        status(kind + '-report-status', '');
      }
    },
  };
}
