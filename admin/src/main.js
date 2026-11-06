import './style.css';
import { createFirebase } from './firebase.js';
import { adminErrorMessage, setupServicePanels } from './service-panels.js';
import { setupEditor } from './editor.js';
import { renderIcons } from './icons.js';
import { createQaDevice } from './qa-crash.js';

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
const qaConnect = $('qa-connect');
const qaDisconnect = $('qa-disconnect');
const qaCrash = $('qa-crash');
const detailEdit = $('detail-edit');
const detailPublish = $('detail-publish');
let detailEntry;
let publishing = false;
let operator;
let authVersion = 0;
let detailVersion = 0;
let qaBusy = false;
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
const services = setupServicePanels({ firebase, session: () => operator, status, text, formatDate, track });
const qa = createQaDevice(env.VITE_QA_ANDROID_SERIAL?.trim(), () => {
  updateQaControls();
  status('qa-status', 'Đã mất kết nối Android QA.');
});

function route() {
  if (!canOperate()) return;
  const requested = location.hash.slice(1);
  const page = routes.has(requested) ? requested : 'overview';
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
    status('detail-status', '');
  } catch (error) {
    if (version === detailVersion && dialog.open) status('detail-status', adminErrorMessage(error), true);
  }
}

function updateQaControls() {
  qaConnect.disabled = !qa.available || qaBusy;
  qaConnect.hidden = qa.connected;
  qaDisconnect.hidden = !qa.connected;
  qaDisconnect.disabled = qaBusy;
  qaCrash.disabled = !canOperate() || qaBusy || !qa.connected;
}

async function qaAction(message, action) {
  if (!canOperate() || qaBusy) return;
  const session = operator;
  qaBusy = true;
  updateQaControls();
  status('qa-status', message);
  try {
    const result = await action();
    if (operator === session) status('qa-status', result);
  } catch (error) {
    if (operator === session) status('qa-status', error.message || 'Không thể thao tác với thiết bị QA.', true);
  } finally {
    qaBusy = false;
    updateQaControls();
  }
}

function showGate(message, blocked = false, error = false) {
  operator = undefined;
  catalogs = new Map();
  services.reset();
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
  void qa.disconnect().catch(() => {});
  updateQaControls();
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
    status('qa-status', qa.available
      ? 'Sẵn sàng kết nối thiết bị đã được duyệt.'
      : 'Cần trình duyệt hỗ trợ WebUSB và serial thiết bị Android QA trong cấu hình.');
    status('workspace-status', '');
    $('gate').hidden = true;
    $('workspace').hidden = false;
    updateQaControls();
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
qaConnect.addEventListener('click', () => void qaAction('Đang kết nối. Cấp quyền USB debugging trên Android nếu được hỏi.', async () =>
  await qa.connect() ? 'Đã kết nối. Mở app Evia QA rồi nhấn Crash app.' : 'Chưa chọn thiết bị Android QA.'));
qaDisconnect.addEventListener('click', () => void qaAction('Đang ngắt kết nối…', async () => {
  await qa.disconnect();
  return 'Đã ngắt kết nối Android QA.';
}));
qaCrash.addEventListener('click', () => void qaAction('Đang chạy và kiểm tra log crash Android…', async () => {
  await qa.crash(() => { void track('admin_qa_crash_requested'); });
  return 'Đã xác minh crash trong log Android. Mở lại app rồi tải lại báo cáo trên trang này.';
}));

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
