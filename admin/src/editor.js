import { catalogEntry, editorValues } from './catalog.js';
import { validateEventImage } from './event-image.js';

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
  field('title', 'Tên sự kiện', 'text', wideRequired),
  field('category', 'Danh mục', 'select', { ...required, choices: [['', 'Đang tải danh mục…']] }),
  field('organizerId', 'Ban tổ chức', 'select', { ...required, choices: [['', 'Đang tải ban tổ chức…']] }),
  area('description', 'Mô tả', true),
  field('image', 'Ảnh sự kiện (tùy chọn)', 'file', { wide: true, hint: 'JPG, PNG hoặc WebP, tối đa 5 MB. Chọn ảnh để xem trước; ảnh được tải lên khi lưu.' }),
  date('startAt', 'Bắt đầu · UTC+7'),
  date('endAt', 'Kết thúc · UTC+7'),
  field('venue', 'Địa điểm', 'text', required),
  number('capacity', 'Số chỗ (bỏ trống nếu không giới hạn)'),
  field('participationMode', 'Hình thức tham dự', 'select', {
    choices: [['registration', 'Đăng ký trước'], ['walk_in', 'Đến trực tiếp (walk-in)']],
  }),
  number('depositCoins', 'Xu đặt cọc', { ...required, registration: true, value: '0' }),
  number('attendanceRewardCoins', 'Xu thưởng check-in', { ...required, value: '0' }),
  field('visibility', 'Phạm vi hiển thị', 'select', {
    choices: [['public', 'Công khai'], ['private', 'Riêng tư']], advanced: true,
  }),
  field('address', 'Địa chỉ chi tiết (tùy chọn)', 'text', { advanced: true }),
  date('checkInStartAt', 'Mở check-in · UTC+7', { advanced: true, hint: 'Bỏ trống để dùng giờ bắt đầu sự kiện.' }),
  date('checkInEndAt', 'Đóng check-in · UTC+7', { advanced: true, hint: 'Bỏ trống để dùng giờ kết thúc sự kiện.' }),
  date('registrationClosesAt', 'Đóng đăng ký · UTC+7 (tùy chọn)', { registration: true, advanced: true }),
  { ...area('tags', 'Tags (tùy chọn, mỗi dòng một mã)'), advanced: true },
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
  if (type === 'file') input.accept = 'image/jpeg,image/png,image/webp';
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

export function setupEditor({ canOperate, save, onSaved, listOrganizers, listCategories, projectId, uploadEventImage, status, errorMessage }) {
  const dialog = document.getElementById('editor');
  const form = document.getElementById('catalog-form');
  const target = document.getElementById('editor-fields');
  const submit = document.getElementById('editor-save');
  let kind;
  let original;
  let busy = false;
  let version = 0;
  let eventId;
  let imagePreviewUrl;
  let uploadedImage;
  let optionsReady = true;
  function releasePreview() {
    if (imagePreviewUrl) URL.revokeObjectURL(imagePreviewUrl);
    imagePreviewUrl = undefined;
  }
  dialog.addEventListener('close', releasePreview);

  dialog.addEventListener('cancel', event => { if (busy) event.preventDefault(); });

  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (!canOperate() || busy || !optionsReady) return;
    const selected = kind;
    const request = version;
    const fields = new FormData(form);
    const image = form.elements.image?.files?.[0];
    const closeButtons = [...dialog.querySelectorAll('[data-close]')];
    busy = submit.disabled = true;
    for (const button of closeButtons) button.disabled = true;
    status('editor-status', 'Đang lưu…');
    try {
      let entry = catalogEntry(selected, fields, original, { id: eventId, projectId });
      const oldDisabled = [...form.elements].map(input => [input, input.disabled]);
      for (const [input] of oldDisabled) input.disabled = true;
      try {
        if (selected === 'events' && image) {
          validateEventImage(image);
          if (uploadedImage?.file !== image) {
            const url = await uploadEventImage(image, percent => {
              if (request === version) status('editor-status', `Đang tải ảnh… ${percent}%`);
            });
            uploadedImage = { file: image, url };
          }
          if (!canOperate() || request !== version) return;
          entry = { ...entry, imageUrl: uploadedImage.url };
        }
        status('editor-status', selected === 'events' ? 'Đang lưu sự kiện…' : 'Đang lưu voucher…');
        await save(selected, entry, original?.revision);
      } finally {
        for (const [input, disabled] of oldDisabled) input.disabled = disabled;
      }
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
      busy = false;
      submit.disabled = !optionsReady;
      for (const button of closeButtons) button.disabled = false;
    }
  });

  return {
    invalidate() { version++; releasePreview(); uploadedImage = undefined; },
    open(selected, entry) {
      if (!canOperate() || busy) return;
      version++;
      kind = selected;
      original = entry;
      const isEvent = selected === 'events';
      eventId = isEvent ? entry?.id ?? `event-${crypto.randomUUID()}` : undefined;
      uploadedImage = undefined;
      releasePreview();
      optionsReady = !isEvent;
      submit.disabled = isEvent;
      document.getElementById('editor-title').textContent = entry
        ? (isEvent ? 'Sửa sự kiện' : 'Sửa mẫu voucher')
        : (isEvent ? 'Tạo bản nháp sự kiện' : 'Tạo mẫu voucher');
      const summary = document.createElement('p');
      summary.className = 'muted';
      summary.textContent = isEvent
        ? 'Điền thông tin và lưu bản nháp. Mã sự kiện, nguồn và điều khoản được hệ thống xử lý. Sau đó mở chi tiết để xuất bản.'
        : 'Mẫu mới được tạo ở trạng thái tắt. Mở lại mẫu để bật khi đã duyệt.';
      const grid = document.createElement('div');
      grid.className = 'form-grid';
      const advanced = document.createElement('details');
      advanced.className = 'editor-advanced';
      const advancedTitle = document.createElement('summary');
      advancedTitle.textContent = 'Tùy chọn thêm: thời gian check-in, phạm vi và địa chỉ';
      const advancedGrid = document.createElement('div');
      advancedGrid.className = 'form-grid';
      advanced.append(advancedTitle, advancedGrid);
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
        (definition.advanced ? advancedGrid : grid).append(field);
      }
      target.replaceChildren(summary, grid, ...(isEvent ? [advanced] : []));
      if (isEvent) {
        const mode = form.elements.participationMode;
        const updateMode = () => {
          for (const wrapper of target.querySelectorAll('[data-registration]')) {
            wrapper.hidden = mode.value !== 'registration';
            wrapper.querySelector('input, textarea').disabled = wrapper.hidden;
          }
        };
        mode.addEventListener('change', updateMode);
        updateMode();
        const image = form.elements.image;
        const preview = document.createElement('img');
        preview.className = 'event-image-preview';
        preview.alt = 'Ảnh xem trước của sự kiện';
        preview.hidden = !entry?.imageUrl;
        if (entry?.imageUrl) preview.src = entry.imageUrl;
        image.parentElement.append(preview);
        preview.addEventListener('error', () => {
          if (image.files?.[0]) {
            image.setCustomValidity('Không đọc được ảnh. Vui lòng chọn ảnh khác.');
            status('editor-status', 'Không đọc được ảnh. Vui lòng chọn ảnh khác.', true);
          }
        });
        image.addEventListener('change', () => {
          releasePreview();
          image.setCustomValidity('');
          const file = image.files?.[0];
          try {
            if (file) {
              validateEventImage(file);
              imagePreviewUrl = URL.createObjectURL(file);
            }
            const source = imagePreviewUrl ?? entry?.imageUrl;
            preview.hidden = !source;
            if (source) preview.src = source;
            else preview.removeAttribute('src');
            status('editor-status', '');
          } catch (error) {
            preview.hidden = !entry?.imageUrl;
            if (entry?.imageUrl) preview.src = entry.imageUrl;
            else preview.removeAttribute('src');
            image.setCustomValidity(error.message);
            image.reportValidity();
            status('editor-status', error.message, true);
          }
        });
      }
      status('editor-status', '');
      dialog.showModal();
      if (isEvent) {
        const request = version;
        const retry = document.createElement('button');
        retry.type = 'button';
        retry.className = 'button secondary';
        retry.textContent = 'Tải lại danh mục và ban tổ chức';
        retry.hidden = true;
        summary.after(retry);
        const loadOptions = async () => {
          retry.disabled = true;
          try {
            const [organizers, categories] = await Promise.all([listOrganizers(), listCategories()]);
            if (request !== version || !dialog.open) return;
            for (const [name, items, label, placeholder] of [
              ['organizerId', organizers.items, 'name', 'Chọn ban tổ chức'],
              ['category', categories.items, 'label', 'Chọn danh mục'],
            ]) {
              const input = form.elements[name];
              input.replaceChildren(new Option(placeholder, ''));
              for (const item of items) input.add(new Option(item[label], item.id));
              const saved = entry?.[name];
              if (saved && !items.some(item => item.id === saved)) input.add(new Option(`Giá trị hiện tại (${saved})`, saved));
              input.value = saved ?? (items.length === 1 ? items[0].id : '');
            }
            optionsReady = true;
            submit.disabled = false;
            retry.hidden = true;
            status('editor-status', '');
          } catch (error) {
            if (request !== version || !dialog.open) return;
            retry.hidden = false;
            status('editor-status', 'Không tải được danh mục/ban tổ chức. ' + errorMessage(error), true);
          } finally {
            retry.disabled = false;
          }
        };
        retry.addEventListener('click', () => { void loadOptions(); });
        void loadOptions();
      }
    },
  };
}
