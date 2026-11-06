export function setupNotifications({ firebase, session, status, errorMessage }) {
  const form = document.getElementById('notification-form');
  const reload = document.getElementById('notification-reload');
  const recipient = form.elements.uid;
  const body = form.elements.body;
  const submit = form.querySelector('[type="submit"]');
  let version = 0, loading = false, busy = false, loaded = false, request;
  function sync() {
    recipient.disabled = loading || busy;
    body.disabled = busy;
    reload.disabled = loading || busy;
    submit.disabled = loading || busy || !loaded || !recipient.value || !body.value.trim();
    submit.textContent = busy ? 'Đang gửi…' : 'Gửi thông báo';
  }
  async function load() {
    const current = session();
    if (!current || loading || busy) return;
    const generation = ++version;
    loading = true;
    loaded = false;
    const selected = recipient.value;
    recipient.replaceChildren(new Option('Chọn tài khoản nhận', ''));
    sync();
    status('notification-users-status', 'Đang tải người nhận…');
    try {
      let cursor;
      const cursors = new Set(), users = [];
      do {
        const page = await firebase.notificationUsers(cursor);
        if (session() !== current || version !== generation) return;
        users.push(...page.items.filter(user => user.accountStatus === 'active'));
        cursor = page.nextCursor;
        if (cursor && cursors.has(cursor)) throw new Error('Không tải được đầy đủ người nhận. Hãy thử lại.');
        if (cursor) cursors.add(cursor);
      } while (cursor);
      for (const user of users) {
        const name = user.displayName || user.universityEmail || user.id;
        const detail = user.universityEmail || user.id;
        recipient.add(new Option(name === detail ? name : `${name} · ${detail}`, user.id));
      }
      if (users.some(user => user.id === selected)) recipient.value = selected;
      loaded = true;
      status('notification-users-status', users.length ? `Có ${users.length} tài khoản hoạt động. Chọn đúng tài khoản đang đăng nhập trên điện thoại.` : 'Chưa có tài khoản đang hoạt động.');
    } catch (error) {
      if (session() === current && version === generation) status('notification-users-status', errorMessage(error), true);
    } finally {
      if (session() === current && version === generation) { loading = false; sync(); }
    }
  }
  recipient.addEventListener('change', sync);
  body.addEventListener('input', sync);
  reload.addEventListener('click', () => { void load(); });
  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (busy || loading || !loaded || !session() || !form.reportValidity()) return;
    const input = { uid: recipient.value, body: body.value.trim() };
    if (!input.uid || !input.body) return;
    if (!request || request.uid !== input.uid || request.body !== input.body) request = { ...input, requestId: crypto.randomUUID() };
    const current = session(), generation = version;
    busy = true;
    sync();
    status('notification-status', 'Đang gửi thông báo…');
    try {
      await firebase.sendNotification(request);
      if (session() !== current || version !== generation) return;
      body.value = '';
      request = undefined;
      status('notification-status', 'Đã xếp hàng gửi thông báo qua FCM. Kiểm tra điện thoại và hộp thư trong ứng dụng.');
    } catch (error) {
      if (session() === current && version === generation) status('notification-status', errorMessage(error), true);
    } finally {
      if (session() === current && version === generation) { busy = false; sync(); }
    }
  });
  sync();
  return {
    open() { if (!loaded && !loading && !busy) void load(); },
    reset() {
      version++;
      loading = busy = loaded = false;
      request = undefined;
      form.reset();
      recipient.replaceChildren(new Option('Chọn tài khoản nhận', ''));
      status('notification-status', '');
      status('notification-users-status', '');
      sync();
    },
  };
}
