import { directTicketCamera } from './ticket-camera.js';

const eventIdPattern = /^[A-Za-z0-9_-]{1,128}$/;
const ticketPattern = /^evia:ticket:[A-Za-z0-9_-]{32}:[A-Za-z0-9_-]{43}$/;
const ticketNumberPattern = /^EV-[0-9A-F]{12}$/;
const windowLabels = { upcoming: 'Chưa mở', open: 'Đang mở', closed: 'Đã đóng', unavailable: 'Chưa có khung giờ' };
const ticketErrors = {
  QR_EVENT_MISMATCH: 'Vé thuộc sự kiện khác. Hãy kiểm tra tên sự kiện trên vé.',
  ALREADY_CHECKED_IN: 'Sinh viên đã check-in bằng vé này.',
  OUTSIDE_CHECKIN_WINDOW: 'Sự kiện hiện nằm ngoài khung giờ check-in.',
  QR_INVALID: 'QR vé đã hết hạn hoặc không hợp lệ. Nhờ sinh viên mở lại QR vé trong Evia.',
  NO_ACTIVE_TICKET: 'Vé này không còn hiệu lực.',
  TICKET_NUMBER_NOT_FOUND: 'Không tìm thấy số vé này trong sự kiện. Kiểm tra lại Ticket No. và sự kiện đang mở.',
  TICKET_NUMBER_AMBIGUOUS: 'Có nhiều vé trùng số trong sự kiện này. Hãy dùng mã QR trên vé.',
  EVENT_NOT_FOUND: 'Sự kiện hiện không khả dụng để check-in.',
  WRONG_PARTICIPATION_MODE: 'Sự kiện này không dùng vé đăng ký trước.',
  FORBIDDEN_STAFF: 'Tài khoản hiện tại không có quyền xác nhận vé.',
};
const retryable = new Set(['functions/unavailable', 'functions/deadline-exceeded', 'functions/internal', 'functions/unknown']);
const eligible = item => item?.status === 'published' && item.visibility === 'public' && item.participationMode === 'registration';

function fullScanRegion(width, height) {
  const scale = Math.min(1, 1280 / Math.max(width, height));
  return { x: 0, y: 0, width, height, downScaledWidth: Math.round(width * scale), downScaledHeight: Math.round(height * scale) };
}

function checkInWindow(item, now) {
  const start = Date.parse(item.checkInStartAt), end = Date.parse(item.checkInEndAt);
  if (!(start < end)) return { state: 'unavailable', next: Infinity };
  if (now < start) return { state: 'upcoming', next: start };
  if (now < end) return { state: 'open', next: end };
  return { state: 'closed', next: Infinity };
}

export function setupCheckIn({ firebase, session, status, text, formatDate, errorMessage }) {
  const $ = id => document.getElementById('check-in-' + id);
  const list = $('list'), scanner = $('scanner'), tableWrap = $('table'), reload = $('reload');
  const camera = $('camera'), start = $('start'), retry = $('retry');
  const manual = $('manual'), ticketNumber = $('number'), confirmNumber = $('confirm-number');
  let view;

  const isCurrent = current => view === current && session() === current.session;
  const now = current => current.serverTime + performance.now() - current.sampleTime;
  const windowText = item => `${formatDate(item.checkInStartAt, item.timezone)} – ${formatDate(item.checkInEndAt, item.timezone)}`;

  function stopCamera(current) {
    const handle = current.camera;
    current.camera = undefined;
    if (handle) {
      void handle.pause?.(true);
      handle.destroy();
    }
    camera.hidden = true;
  }

  function close() {
    if (!view) return;
    const current = view;
    view = undefined;
    clearTimeout(current.timer);
    stopCamera(current);
  }

  function updateAt(current, time, update) {
    clearTimeout(current.timer);
    if (Number.isFinite(time)) {
      current.timer = setTimeout(() => {
        if (isCurrent(current)) update(current);
      }, Math.max(1, Math.min(time - now(current), 2_147_483_647)));
    }
  }

  function renderList(current) {
    const clock = now(current);
    const rows = current.items.map(item => ({ item, ...checkInWindow(item, clock) }));
    const order = { open: 0, upcoming: 1, closed: 2, unavailable: 3 };
    rows.sort((a, b) => order[a.state] - order[b.state]);
    tableWrap.replaceChildren();
    status('check-in-list-status', rows.length ? '' : 'Chưa có sự kiện đăng ký trước đã xuất bản.');
    if (!rows.length) return;
    const table = document.createElement('table');
    table.createTHead().insertRow().append(...['Sự kiện', 'Khung giờ check-in', 'Trạng thái', 'Thao tác'].map(label => text('th', label)));
    const body = table.createTBody();
    for (const { item, state } of rows) {
      const row = body.insertRow();
      row.insertCell().append(text('strong', item.title));
      row.insertCell().textContent = windowText(item);
      row.insertCell().textContent = windowLabels[state];
      const action = row.insertCell();
      if (state === 'open') {
        const link = text('a', 'Check in', 'button secondary row-action');
        link.href = `#check-in/${item.id}`;
        link.setAttribute('aria-label', `Check in – ${item.title}`);
        action.append(link);
      } else action.textContent = '—';
    }
    tableWrap.append(table);
    updateAt(current, Math.min(...rows.map(row => row.next)), renderList);
  }

  function updateScanner(current) {
    const { state, next } = checkInWindow(current.item, now(current));
    start.hidden = state !== 'open' || Boolean(current.camera);
    manual.hidden = state !== 'open';
    if (state === 'open') {
      if (!current.camera) status('check-in-camera-status', 'Bật camera để quét mã QR vé trên app Evia.');
    } else {
      stopCamera(current);
      retry.hidden = true;
      status('check-in-camera-status', state === 'unavailable' ? 'Sự kiện chưa có khung giờ check-in.' : `${windowLabels[state]} check-in.`);
    }
    updateAt(current, next, updateScanner);
  }

  async function open(eventId) {
    close();
    const operator = session();
    if (!operator) return;
    const current = view = { eventId, session: operator };
    const scanning = eventId !== null;
    list.hidden = scanning;
    scanner.hidden = $('back').hidden = !scanning;
    $('title').textContent = scanning ? 'Quét vé sự kiện' : 'Check in';
    $('description').textContent = scanning ? 'Xác nhận vé của sự kiện đang trực.' : 'Quét QR vé cho sự kiện đăng ký trước.';
    tableWrap.replaceChildren();
    reload.disabled = true;
    $('event-title').textContent = scanning ? 'Đang tải sự kiện…' : '';
    $('window').textContent = '';
    start.hidden = retry.hidden = manual.hidden = true;
    start.disabled = confirmNumber.disabled = false;
    ticketNumber.readOnly = false;
    ticketNumber.value = '';
    showResult('');
    status('check-in-camera-status', '');
    status('check-in-list-status', 'Đang tải sự kiện…');
    try {
      if (scanning && !eventIdPattern.test(eventId)) {
        $('event-title').textContent = 'Sự kiện không hợp lệ.';
        return;
      }
      const [data, serverTime] = await Promise.all([
        scanning ? firebase.checkInEvent(eventId) : firebase.checkInEvents(),
        firebase.serverInfo().then(info => ({ serverTime: Date.parse(info.serverTime), sampleTime: performance.now() })),
      ]);
      if (!isCurrent(current)) return;
      if (!Number.isFinite(serverTime.serverTime)) throw new Error('Không lấy được giờ máy chủ. Hãy tải lại.');
      Object.assign(current, serverTime);
      if (scanning) {
        if (!eligible(data) || data.id !== eventId) {
          $('event-title').textContent = 'Sự kiện không dùng vé đăng ký trước.';
          return;
        }
        current.item = data;
        $('event-title').textContent = data.title;
        $('window').textContent = `Khung giờ check-in · ${windowText(data)}`;
        updateScanner(current);
      } else {
        current.items = data.items.filter(eligible);
        renderList(current);
      }
    } catch (error) {
      if (!isCurrent(current)) return;
      if (scanning) $('event-title').textContent = 'Không tải được sự kiện.';
      status(scanning ? 'check-in-camera-status' : 'check-in-list-status', errorMessage(error), true);
    } finally {
      if (isCurrent(current)) reload.disabled = false;
    }
  }

  function showResult(message, kind) {
    status('check-in-result', message, kind === 'error');
    $('result').classList.toggle('success', kind === 'success');
  }

  async function submit(current, attempt) {
    if (current.busy) return;
    const submittedAt = now(current);
    const byNumber = Boolean(attempt.ticketNumber);
    current.busy = confirmNumber.disabled = true;
    ticketNumber.readOnly = byNumber;
    retry.hidden = true;
    showResult('Đang xác nhận vé…');
    try {
      const { requestId } = attempt;
      const result = byNumber
        ? await firebase.verifyTicketNumber({ eventId: current.eventId, ticketNumber: attempt.ticketNumber, requestId })
        : await firebase.verifyTicket({ expectedEventId: current.eventId, qrPayload: attempt.payload, requestId });
      if (!isCurrent(current)) return;
      attempt.retry = false;
      if (byNumber && ticketNumber.value.trim().toUpperCase() === attempt.ticketNumber) ticketNumber.value = '';
      showResult(`Check-in thành công · +${result.coinsGranted} xu thưởng · Hoàn ${result.depositRefunded} xu đặt cọc.`, 'success');
    } catch (error) {
      if (!isCurrent(current)) return;
      attempt.retry = retryable.has(error.code);
      retry.hidden = !attempt.retry || checkInWindow(current.item, now(current)).state !== 'open';
      const time = new Date(submittedAt).toLocaleTimeString('vi-VN', { timeZone: current.item.timezone ?? 'Asia/Ho_Chi_Minh' });
      const code = error.details?.code;
      attempt.invalid = code === 'QR_INVALID';
      const message = ticketErrors[code] ?? errorMessage(error);
      showResult(`${byNumber ? 'Nhập số vé' : 'Lượt quét'} lúc ${time} · ${message}`, 'error');
    } finally {
      current.busy = false;
      if (isCurrent(current)) confirmNumber.disabled = ticketNumber.readOnly = false;
    }
  }

  function onScan(current, payload) {
    if (!isCurrent(current) || !current.camera) return;
    if (document.activeElement === ticketNumber && ticketNumber.value) return;
    if (checkInWindow(current.item, now(current)).state !== 'open') return updateScanner(current);
    const previous = current.last;
    const detectedAt = performance.now();
    if (payload === previous?.payload) {
      const stillVisible = detectedAt - previous.detectedAt < 1500;
      previous.detectedAt = detectedAt;
      if (stillVisible || previous.invalid) return;
    }
    if (current.busy) return;
    const attempt = current.last = {
      payload, detectedAt,
      requestId: payload === previous?.payload && previous.retry ? previous.requestId : crypto.randomUUID(),
    };
    if (!ticketPattern.test(payload)) {
      retry.hidden = true;
      showResult('Hãy đưa mã QR vé từ app Evia vào khung quét.', 'error');
      return;
    }
    void submit(current, attempt);
  }

  async function startCamera() {
    const current = view;
    if (!current?.item || current.starting || current.camera || checkInWindow(current.item, now(current)).state !== 'open') return;
    if (!navigator.mediaDevices?.getUserMedia) {
      status('check-in-camera-status', 'Camera cần trình duyệt hỗ trợ và trang chạy qua HTTPS hoặc localhost.', true);
      return;
    }
    current.starting = start.disabled = true;
    status('check-in-camera-status', 'Đang mở camera…');
    try {
      const { default: QrScanner } = await import('qr-scanner');
      if (!isCurrent(current) || checkInWindow(current.item, now(current)).state !== 'open') return;
      // The previous scanner can finish stopping asynchronously, so each owns its video element.
      const previousVideo = $('video');
      const video = previousVideo.cloneNode();
      previousVideo.replaceWith(video);
      const handle = current.camera = typeof globalThis.ImageCapture === 'function'
        ? directTicketCamera(QrScanner, video, data => onScan(current, data), fullScanRegion)
        : new QrScanner(video, ({ data }) => onScan(current, data), {
          maxScansPerSecond: 8,
          returnDetailedScanResult: true,
          calculateScanRegion: ({ videoWidth, videoHeight }) => fullScanRegion(videoWidth, videoHeight),
        });
      camera.hidden = false;
      await handle.start();
      if (!isCurrent(current) || current.camera !== handle) return;
      start.hidden = true;
      status('check-in-camera-status', 'Giữ mã QR ở giữa khung. Đưa điện thoại lại gần đến khi các ô đen trắng hiện rõ và giữ yên để quét.');
    } catch {
      if (!isCurrent(current) || checkInWindow(current.item, now(current)).state !== 'open') return;
      stopCamera(current);
      start.hidden = false;
      status('check-in-camera-status', 'Không mở được camera. Hãy kiểm tra quyền camera và xem webcam có đang được ứng dụng khác sử dụng không.', true);
    } finally {
      current.starting = false;
      if (isCurrent(current)) start.disabled = false;
    }
  }

  reload.addEventListener('click', () => { void open(null); });
  start.addEventListener('click', () => { void startCamera(); });
  manual.addEventListener('submit', event => {
    event.preventDefault();
    const current = view;
    if (!current?.item || !isCurrent(current) || current.busy || checkInWindow(current.item, now(current)).state !== 'open') return;
    const number = ticketNumber.value.trim().toUpperCase();
    if (!ticketNumberPattern.test(number)) {
      showResult('Nhập đúng Ticket No. trên vé, ví dụ EV-012345ABCDEF.', 'error');
      ticketNumber.focus();
      return;
    }
    const previous = current.last;
    const requestId = previous?.retry && previous.ticketNumber === number ? previous.requestId : crypto.randomUUID();
    const attempt = current.last = { ticketNumber: number, requestId };
    void submit(current, attempt);
  });
  retry.addEventListener('click', () => {
    if (view?.last?.retry && checkInWindow(view.item, now(view)).state === 'open') void submit(view, view.last);
  });
  return { open, close };
}
