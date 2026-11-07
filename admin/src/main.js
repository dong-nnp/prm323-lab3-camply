import './style.css';
import { createFirebase } from './firebase.js';
import { adminErrorMessage, setupServicePanels } from './service-panels.js';
import { setupEditor } from './editor.js';
import { renderIcons } from './icons.js';
import { setupNotifications } from './notifications.js';
import { setupCheckIn } from './check-in.js';

const env = import.meta.env;
const $ = (id) => document.getElementById(id);
const all = (selector) => [...document.querySelectorAll(selector)];
let firebase;
let firebaseSetupError = 'Chưa có cấu hình Firebase Web. Sao chép admin/.env.example thành admin/.env.local để bắt đầu.';
try {
  firebase = createFirebase(env);
} catch {
  firebaseSetupError = 'Không thể khởi tạo Firebase Web. Kiểm tra thông số Web app trong admin/.env.local.';
}
const routes = new Map(all('[data-route]').map(link => [link.dataset.route, link]));
const gateForm = $('login-form');
const gateButton = gateForm.querySelector('button');
const androidQaButton = $('android-qa-crash');
const diagnosticsEnabled = import.meta.env.DEV && env.VITE_ENABLE_DIAGNOSTICS === 'true';
const androidQaEnabled = diagnosticsEnabled && location.hostname === '127.0.0.1' &&
  /^[a-f0-9]{48}$/.test(env.VITE_QA_ANDROID_TOKEN ?? '') &&
  /^emulator-[1-9]\d{3,4}$/.test(env.VITE_QA_ANDROID_DEVICE ?? '');
const detailEdit = $('detail-edit');
const detailPublish = $('detail-publish');
let detailEntry;
let publishing = false;
let operator;
let authVersion = 0;
let detailVersion = 0;
let catalogs = new Map();

function status(id, message, error = false) {
  const target = $(id);
  target.textContent = message;
  target.classList.toggle('error', error);
}

const canOperate = () => Boolean(operator);
const track = (event) => firebase?.track(event);
const editor = setupEditor({
  canOperate, status, errorMessage: adminErrorMessage,
  save: (kind, entry, revision) => firebase.save(kind, entry, revision),
  listOrganizers: () => firebase.organizers(),
  listCategories: () => firebase.categories(),
  projectId: firebase?.projectId,
  uploadEventImage: (file, progress) => firebase.uploadEventImage(file, progress),
  onSaved: async (kind, message) => {
    const current = operator;
    void track(kind === 'events' ? 'admin_event_saved' : 'admin_voucher_saved');
    location.hash = kind === 'events' ? 'events' : 'vouchers';
    await loadCatalog(kind, true);
    if (operator === current) status('workspace-status', message);
  },
});
const services = setupServicePanels({ firebase, session: () => operator, status, text, track });
const notifications = setupNotifications({ firebase, session: () => operator, status, errorMessage: adminErrorMessage });
const checkIn = setupCheckIn({ firebase, session: () => operator, status, text, formatDate, errorMessage: adminErrorMessage });

function route() {
  if (!canOperate()) return;
  const requested = location.hash.slice(1);
  const page = requested.startsWith('check-in/') ? 'check-in' : routes.has(requested) ? requested : 'overview';
  if (page === 'check-in') checkIn.open(requested === page ? null : requested.slice(page.length + 1));
  else checkIn.close();
  for (const [key, link] of routes) {
    $(key).hidden = key !== page;
    if (key === page) link.setAttribute('aria-current', 'page');
    else link.removeAttribute('aria-current');
  }
  $('current-page').textContent = routes.get(page).textContent.trim();
  if (page === 'events' || page === 'vouchers') {
    const kind = page === 'events' ? 'events' : 'rewards';
    if (!catalogs.has(kind)) void loadCatalog(kind, true);
  }
  services.open(page);
  if (page === 'notifications') notifications.open();
}

function text(tag, value, className) {
  const element = document.createElement(tag);
  element.textContent = value ?? '—';
  if (className) element.className = className;
  return element;
}

function formatDate(value, timezone = 'Asia/Ho_Chi_Minh') {
  if (!value) return '—';
  const date = typeof value === 'string' ? new Date(value) :
    new Date((value._seconds ?? value.seconds) * 1000);
  if (!Number.isFinite(date.getTime())) return '—';
  const format = { dateStyle: 'short', timeStyle: 'short' };
  try {
    return new Intl.DateTimeFormat('vi-VN', { ...format, timeZone: timezone }).format(date);
  } catch {
    return new Intl.DateTimeFormat('vi-VN', { ...format, timeZone: 'Asia/Ho_Chi_Minh' }).format(date);
  }
}

function catalogStatus(item) {
  const labels = { draft: 'Bản nháp', published: 'Đã xuất bản', cancelled: 'Đã hủy', completed: 'Đã hoàn tất', active: 'Đang bật', inactive: 'Đang tắt' };
  const label = labels[item.status] ?? item.status;
  return item.visibility === 'private' ? label + ' · Riêng tư' : label;
}

function rewardType(item) {
  const labels = { voucher: 'Voucher', physical: 'Quà vật lý' };
  return labels[item.fulfillmentType] ?? item.fulfillmentType;
}

function renderCatalog(kind, items) {
  const target = $(kind + '-table');
  target.replaceChildren();
  if (!items.length) return;
  const isEvent = kind === 'events';
  const headings = isEvent ? ['Sự kiện', 'Bắt đầu', 'Hình thức', 'Trạng thái', 'Thao tác']
    : ['Phần thưởng', 'Loại', 'Giá xu', 'Tồn kho', 'Trạng thái', 'Thao tác'];
  const table = document.createElement('table');
  table.createTHead().insertRow().append(...headings.map(label => text('th', label)));
  const body = table.createTBody();
  for (const item of items) {
    const row = body.insertRow();
    row.insertCell().append(text('strong', item.title), text('small', item.id));
    if (!isEvent) row.insertCell().textContent = rewardType(item) ?? '—';
    row.insertCell().textContent = isEvent ? formatDate(item.startAt, item.timezone) : item.priceCoins ?? '—';
    row.insertCell().textContent = isEvent
      ? (item.participationMode === 'walk_in' ? 'Walk-in' : 'Đăng ký trước')
      : item.stockRemaining ?? '—';
    row.insertCell().textContent = catalogStatus(item);
    const detail = text('button', 'Chi tiết', 'button secondary row-action');
    detail.type = 'button';
    detail.addEventListener('click', () => { void showDetails(kind, item.id); });
    row.insertCell().append(detail);
  }
  target.append(table);
}

async function loadCatalog(kind, reset) {
  if (!canOperate()) return;
  const previous = catalogs.get(kind);
  if (!reset && (!previous?.cursor || previous.loading)) return;
  const state = { items: reset ? [] : previous.items, cursor: reset ? null : previous.cursor, loading: true };
  catalogs.set(kind, state);
  const more = document.querySelector('[data-more="' + kind + '"]');
  const refresh = document.querySelector('[data-refresh="' + kind + '"]');
  more.disabled = refresh.disabled = true;
  if (reset) {
    more.hidden = true;
    renderCatalog(kind, []);
  }
  status(kind + '-status', 'Đang tải catalog…');
  try {
    const result = await firebase.list(kind, state.cursor);
    if (catalogs.get(kind) !== state) return;
    state.items = [...new Map([...state.items, ...result.items].map(item => [item.id, item])).values()];
    state.cursor = result.nextCursor;
    renderCatalog(kind, state.items);
    status(kind + '-status', state.items.length
      ? 'Đã tải ' + state.items.length + ' mục.'
      : (state.cursor ? 'Trang này chưa có mục phù hợp. Có thể tải thêm.' : 'Chưa có mục phù hợp trong catalog.'));
  } catch (error) {
    if (catalogs.get(kind) === state) status(kind + '-status', adminErrorMessage(error), true);
  } finally {
    if (catalogs.get(kind) === state) {
      state.loading = false;
      refresh.disabled = false;
      more.disabled = false;
      more.hidden = !state.cursor;
    }
  }
}

async function showDetails(kind, id) {
  if (!canOperate()) return;
  const version = ++detailVersion;
  const dialog = $('details');
  const content = $('detail-content');
  const isEvent = kind === 'events';
  content.replaceChildren();
  $('detail-title').textContent = id;
  status('detail-status', 'Đang tải chi tiết…');
  detailEntry = undefined;
  detailEdit.hidden = detailPublish.hidden = true;
  dialog.showModal();
  try {
    const item = await firebase.entry(kind, id);
    if (version !== detailVersion || !dialog.open || !canOperate()) return;
    detailEntry = { kind, item };
    detailEdit.hidden = isEvent
      ? !['draft', 'published'].includes(item.status)
      : item.fulfillmentType !== 'voucher';
    detailPublish.hidden = !isEvent || item.status !== 'draft';
    $('detail-title').textContent = item.title;
    content.append(text('p', item.description, 'detail-description'));
    const rows = isEvent
      ? [['ID', item.id], ['Ban tổ chức', item.organizerId], ['Địa điểm', item.venue?.name], ['Bắt đầu', formatDate(item.startAt, item.timezone)], ['Kết thúc', formatDate(item.endAt, item.timezone)]]
      : [['ID', item.id], ['Loại', rewardType(item)], ['Giá xu', item.priceCoins], ['Tồn kho', item.stockRemaining], ['Điều khoản', item.termsText], ['Phiên bản', item.termsVersion]];
    const list = document.createElement('dl');
    list.className = 'definition-list';
    for (const [label, value] of [['Trạng thái', catalogStatus(item)], ...rows]) {
      const row = document.createElement('div');
      row.append(text('dt', label), text('dd', value));
      list.append(row);
    }
    content.append(list);
    if (isEvent && item.participationMode === 'walk_in' && item.status === 'published' && item.visibility === 'public') {
      status('detail-status', 'Đang tải QR check-in…');
      const [{ qrPayload }, { default: qr }] = await Promise.all([firebase.getWalkInQr(id), import('qrcode')]);
      const png = await qr.toDataURL(qrPayload, { scale: 16 });
      if (version !== detailVersion || !dialog.open || !canOperate()) return;
      const section = document.createElement('section');
      section.className = 'detail-qr';
      const image = document.createElement('img');
      image.src = png;
      image.alt = `Mã QR check-in cho ${item.title}`;
      const download = text('a', 'Tải QR (.png)', 'button secondary');
      download.href = png;
      download.download = `evia-check-in-${id}.png`;
      const checkInStart = formatDate(item.checkInStartAt, item.timezone);
      const checkInEnd = formatDate(item.checkInEndAt, item.timezone);
      section.append(text('h3', 'QR check-in'), text('p', `Quét bằng Evia từ ${checkInStart} đến ${checkInEnd}.`), image, download);
      content.append(section);
    }
    status('detail-status', '');
  } catch (error) {
    if (version === detailVersion && dialog.open) status('detail-status', adminErrorMessage(error), true);
  }
}

function showGate(message, blocked = false, error = false) {
  operator = undefined;
  catalogs = new Map();
  services.reset();
  notifications.reset();
  checkIn.close();
  editor.invalidate();
  detailVersion++;
  detailEntry = undefined;
  for (const dialog of all('dialog[open]')) dialog.close();
  for (const kind of ['events', 'rewards']) renderCatalog(kind, []);
  $('detail-content').replaceChildren();
  $('editor-fields').replaceChildren();
  $('account-email').textContent = '';
  $('workspace').hidden = true;
  $('gate').hidden = false;
  $('denied-logout').hidden = !blocked;
  gateButton.disabled = blocked || !firebase;
  status('gate-status', message, error);
  androidQaButton.hidden = true;
  status('android-qa-status', '');
}

async function updateAuth(user) {
  const version = ++authVersion;
  if (!user) {
    showGate('Đăng nhập bằng tài khoản quản trị đã được cấp quyền.');
    return;
  }
  if (!operator || user.uid !== operator.uid) showGate('Đang xác minh quyền quản trị…', true);
  try {
    const token = await user.getIdTokenResult();
    if (version !== authVersion) return;
    if (token.claims.admin !== true) {
      showGate('Tài khoản chưa được cấp quyền admin.', true, true);
      return;
    }
    if (operator?.uid === user.uid) return;
    operator = user;
    $('account-email').textContent = user.email ?? '';
    $('environment').textContent = firebase.emulator ? 'Emulator' : firebase.projectId;
    status('workspace-status', '');
    $('gate').hidden = true;
    $('workspace').hidden = false;
    androidQaButton.hidden = !androidQaEnabled || firebase.emulator;
    $('android-qa-hint').hidden = !androidQaButton.hidden;
    const dashboard = $('crashlytics-dashboard');
    dashboard.hidden = firebase.emulator;
    if (!firebase.emulator) {
      dashboard.href = 'https://console.firebase.google.com/project/' +
        encodeURIComponent(firebase.projectId) + '/crashlytics';
    }
    route();
  } catch {
    if (version === authVersion) showGate('Không xác minh được quyền. Hãy đăng xuất và thử lại.', true, true);
  }
}

renderIcons();
services.reset();
window.addEventListener('hashchange', () => {
  route();
  if (canOperate()) $('main').focus();
});
window.addEventListener('pagehide', checkIn.close);
window.addEventListener('pageshow', event => { if (event.persisted) route(); });
for (const button of all('[data-create]')) button.addEventListener('click', () => editor.open(button.dataset.create));
for (const button of all('[data-refresh]')) button.addEventListener('click', () => { void loadCatalog(button.dataset.refresh, true); });
for (const button of all('[data-more]')) button.addEventListener('click', () => { void loadCatalog(button.dataset.more, false); });
for (const button of all('[data-close]')) button.addEventListener('click', () => $(button.dataset.close).close());
detailEdit.addEventListener('click', () => {
  if (!detailEntry || publishing || !canOperate()) return;
  $('details').close();
  editor.open(detailEntry.kind, detailEntry.item);
});
$('details').addEventListener('cancel', event => { if (publishing) event.preventDefault(); });
detailPublish.addEventListener('click', async () => {
  if (!detailEntry || publishing || !canOperate()) return;
  const { item } = detailEntry;
  const notice = item.visibility === 'public' ? ' Sự kiện công khai có thể gửi thông báo cho người theo dõi.' : '';
  if (!window.confirm('Xuất bản sự kiện này?' + notice)) return;
  const session = operator;
  const version = detailVersion;
  const dialog = $('details');
  const buttons = [...dialog.querySelectorAll('button')];
  publishing = true;
  for (const button of buttons) button.disabled = true;
  status('detail-status', 'Đang xuất bản…');
  try {
    await firebase.publishEvent(item.id, item.revision);
    if (operator !== session || detailVersion !== version) return;
    void track('admin_event_published');
    dialog.close();
    await loadCatalog('events', true);
    if (operator === session) status('workspace-status', 'Đã xuất bản sự kiện.');
  } catch (error) {
    if (operator === session && detailVersion === version) status('detail-status', adminErrorMessage(error), true);
  } finally {
    publishing = false;
    for (const button of buttons) button.disabled = false;
  }
});
androidQaButton.addEventListener('click', (event) => {
  if (!operator || !androidQaEnabled || firebase.emulator) return;
  if (!window.confirm('Gây crash app Evia QA đang mở trên ' + env.VITE_QA_ANDROID_DEVICE + '?')) return;
  const button = event.currentTarget;
  button.disabled = true;
  status('android-qa-status', 'Đã yêu cầu Windows mở trình kiểm thử. Sau khi app đóng, mở lại để gửi báo cáo.');
  window.location.href = 'evia-android-qa://crash/' + env.VITE_QA_ANDROID_TOKEN;
  window.setTimeout(() => { button.disabled = false; }, 3000);
});

gateForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  if (!firebase || gateButton.disabled) return;
  const fields = new FormData(gateForm);
  gateButton.disabled = true;
  status('gate-status', 'Đang đăng nhập…');
  try {
    await firebase.login(fields.get('email').trim(), fields.get('password'));
    gateForm.reset();
  } catch {
    gateButton.disabled = false;
    status('gate-status', 'Đăng nhập thất bại. Kiểm tra tài khoản, mật khẩu hoặc kết nối.', true);
  }
});
for (const [id, target] of [['logout', 'workspace-status'], ['denied-logout', 'gate-status']]) {
  $(id).addEventListener('click', async () => {
    try {
      await firebase.logout();
    } catch {
      status(target, 'Không thể đăng xuất. Hãy thử lại.', true);
    }
  });
}
if (firebase) firebase.observeAuth(user => { void updateAuth(user); });
else showGate(firebaseSetupError);
