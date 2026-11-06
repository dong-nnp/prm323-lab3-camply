import { catalogEntry, editorValues } from './catalog.js';

const field = (name, label, type = 'text', options = {}) => ({ name, label, type, ...options });
const area = (name, label, required = false, hint) => field(name, label, 'textarea', { wide: true, required, hint });
const number = (name, label, options) => field(name, label, 'number', { min: 0, ...options });
const required = { required: true };
const wideRequired = { required: true, wide: true };
const date = (name, label, options = required) => field(name, label, 'datetime-local', options);

const commonFields = [
  field('id', 'ID ổn định', 'text', { ...required, hint: 'Chữ, số, gạch ngang hoặc gạch dưới.' }),
  field('category', 'Mã danh mục', 'text', required),
  field('title', 'Tiêu đề', 'text', wideRequired),
  area('description', 'Mô tả', true),
  field('imageUrl', 'URL ảnh (tùy chọn)', 'url'),
  field('sourceRef', 'URL nguồn HTTPS', 'url', required),
];

const eventFields = [
  ...commonFields,
  field('organizerId', 'ID ban tổ chức', 'text', required),
  field('visibility', 'Phạm vi hiển thị', 'select', {
    choices: [['public', 'Công khai'], ['private', 'Riêng tư']],
  }),
  field('participationMode', 'Hình thức tham dự', 'select', {
    choices: [['registration', 'Đăng ký trước'], ['walk_in', 'Walk-in']],
  }),
  date('startAt', 'Bắt đầu · UTC+7'),
  date('endAt', 'Kết thúc · UTC+7'),
  date('checkInStartAt', 'Mở check-in · UTC+7'),
  date('checkInEndAt', 'Đóng check-in · UTC+7'),
  field('venue', 'Tên địa điểm', 'text', required),
  field('address', 'Địa chỉ (tùy chọn)'),
  number('capacity', 'Sức chứa (bỏ trống nếu không giới hạn)'),
  number('attendanceRewardCoins', 'Xu thưởng check-in', { ...required, value: '0' }),
  date('registrationClosesAt', 'Đóng đăng ký · UTC+7 (tùy chọn)', { registration: true }),
  number('depositCoins', 'Xu đặt cọc', { ...required, registration: true, value: '0' }),
  field('registrationTermsVersion', 'Phiên bản điều khoản', 'text', { ...required, registration: true }),
  { ...area('registrationTerms', 'Điều khoản đăng ký', true), registration: true },
  area('tags', 'Tags (tùy chọn, mỗi dòng một mã)'),
  area('schedule', 'Lịch chi tiết (JSON, tùy chọn)', false, 'Danh sách mục có id, title, startAt ISO 8601 UTC và endAt nếu có.'),
];

const rewardFields = [
  ...commonFields,
  field('status', 'Trạng thái', 'select', {
    choices: [['inactive', 'Đang tắt'], ['active', 'Đang bật']],
  }),
  number('priceCoins', 'Giá xu', required),
  number('stockRemaining', 'Số lượng còn lại', required),
  number('validDays', 'Số ngày hiệu lực (tùy chọn)', { min: 1, max: 365 }),
  field('termsVersion', 'Phiên bản điều khoản', 'text', required),
  area('termsText', 'Điều khoản sử dụng', true),
  area('usageLocations', 'Địa điểm sử dụng (mỗi dòng một địa điểm)'),
  area('redemptionSteps', 'Các bước sử dụng (mỗi dòng một bước)', true),
  area('redemptionInstructions', 'Hướng dẫn bổ sung (tùy chọn)'),
];

function addField(definition) {
  const { name, label, type, wide, required, value, min, max, choices, hint, registration } = definition;
  const wrapper = document.createElement('label');
  wrapper.textContent = label;
  if (wide) wrapper.className = 'wide';
  const input = document.createElement(type === 'select' || type === 'textarea' ? type : 'input');
  if (input.tagName === 'INPUT') input.type = type;
  if (type === 'datetime-local') input.step = '0.001';
  if (input.tagName === 'TEXTAREA') input.rows = 3;
  if (choices) for (const [key, display] of choices) input.add(new Option(display, key));
  if (value !== undefined) input.value = value;
  if (min !== undefined) input.min = min;
  if (max !== undefined) input.max = max;
  input.name = name;
  input.required = Boolean(required);
  wrapper.append(input);
  if (hint) {
    const note = document.createElement('small');
    note.className = 'muted';
    note.textContent = hint;
    wrapper.append(note);
  }
  if (registration) wrapper.dataset.registration = '';
  return wrapper;
}

export function setupEditor({ canOperate, save, onSaved, listOrganizers, status, errorMessage }) {
  const dialog = document.getElementById('editor');
  const form = document.getElementById('catalog-form');
  const target = document.getElementById('editor-fields');
  const submit = document.getElementById('editor-save');
  let kind;
  let original;
  let busy = false;
  let version = 0;

  dialog.addEventListener('cancel', event => { if (busy) event.preventDefault(); });

  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (!canOperate() || busy) return;
    const selected = kind;
    const request = version;
    const closeButtons = [...dialog.querySelectorAll('[data-close]')];
    busy = submit.disabled = true;
    for (const button of closeButtons) button.disabled = true;
    status('editor-status', 'Đang lưu…');
    try {
      const entry = catalogEntry(selected, new FormData(form), original);
      await save(selected, entry, original?.revision);
      if (!canOperate() || request !== version) return;
      dialog.close();
      const message = original
        ? 'Đã lưu thay đổi.'
        : selected === 'events'
          ? 'Đã tạo bản nháp. Mở chi tiết để xuất bản sự kiện.'
          : 'Đã tạo bản ghi.';
      await onSaved(selected, message);
    } catch (error) {
      if (request !== version || !dialog.open) return;
      const fields = error.issues ?? error.details?.fields;
      status('editor-status', fields?.map(issue => (Array.isArray(issue.path) ? issue.path.join('.') : issue.path) + ' · ' + (issue.message ?? issue.code)).join('\n') || errorMessage(error), true);
    } finally {
      busy = submit.disabled = false;
      for (const button of closeButtons) button.disabled = false;
    }
  });

  return {
    invalidate() { version++; },
    open(selected, entry) {
      if (!canOperate() || busy) return;
      version++;
      kind = selected;
      original = entry;
      const isEvent = selected === 'events';
      document.getElementById('editor-title').textContent = entry
        ? (isEvent ? 'Sửa sự kiện' : 'Sửa mẫu voucher')
        : (isEvent ? 'Tạo bản nháp sự kiện' : 'Tạo mẫu voucher');
      const summary = document.createElement('p');
      summary.className = 'muted';
      summary.textContent = isEvent
        ? 'Lưu bản nháp trước. Dùng nút Xuất bản ở trang chi tiết khi đã duyệt.'
        : 'Mẫu mới được tạo ở trạng thái tắt. Mở lại mẫu để bật khi đã duyệt.';
      const grid = document.createElement('div');
      grid.className = 'form-grid';
      const values = entry ? editorValues(entry) : {};
      for (const definition of isEvent ? eventFields : rewardFields) {
        if (!entry && definition.name === 'status') continue;
        const field = addField(definition);
        const input = field.querySelector('input, textarea, select');
        if (values[definition.name] !== undefined) input.value = values[definition.name];
        if (entry && definition.name === 'id') input.readOnly = true;
        if (isEvent && entry?.status === 'published' && ['organizerId', 'visibility', 'participationMode'].includes(definition.name)) {
          input.disabled = true;
        }
        grid.append(field);
      }
      target.replaceChildren(summary, grid);
      if (isEvent) {
        const mode = form.elements.participationMode;
        const updateMode = () => {
          for (const wrapper of grid.querySelectorAll('[data-registration]')) {
            wrapper.hidden = mode.value !== 'registration';
            wrapper.querySelector('input, textarea').disabled = wrapper.hidden;
          }
        };
        mode.addEventListener('change', updateMode);
        updateMode();
      }
      status('editor-status', '');
      dialog.showModal();
      if (isEvent && !form.elements.organizerId.disabled) {
        const request = version;
        void listOrganizers().then(({ items }) => {
          if (request !== version || !dialog.open) return;
          const options = document.createElement('datalist');
          options.id = 'editor-organizers';
          for (const organizer of items) options.append(new Option(organizer.name, organizer.id));
          form.elements.organizerId.setAttribute('list', options.id);
          grid.append(options);
        }).catch(() => {}); // The organizer ID can still be entered directly.
      }
    },
  };
}
