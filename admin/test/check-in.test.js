import assert from 'node:assert/strict';
import test from 'node:test';
import { setupCheckIn } from '../src/check-in.js';

test('the scanner gates QR and manual check-in and submits the selected event and ticket number', async t => {
  const controls = new Map();
  t.mock.method(globalThis, 'setTimeout', () => undefined);
  const previousDocument = globalThis.document;
  globalThis.document = {
    getElementById(id) {
      if (!controls.has(id)) controls.set(id, Object.assign(new EventTarget(), {
        classList: { toggle() {} }, replaceChildren() {},
      }));
      return controls.get(id);
    },
  };
  t.after(() => { globalThis.document = previousDocument; });
  const admin = {};
  const statuses = new Map();
  const event = {
    id: 'workshop', title: 'Workshop', status: 'published', visibility: 'public', participationMode: 'registration',
    startAt: '2026-11-07T08:00:00Z', checkInStartAt: '2026-11-07T09:00:00Z', checkInEndAt: '2026-11-07T10:00:00Z',
  };
  let serverTime = event.startAt;
  const calls = [];
  const panel = setupCheckIn({
    firebase: {
      checkInEvent: async () => event, serverInfo: async () => ({ serverTime }),
      verifyTicketNumber: async input => {
        calls.push(input);
        if (calls.length === 1) throw Object.assign(new Error(), { code: 'functions/unavailable' });
        return { coinsGranted: 10, depositRefunded: 50 };
      },
    },
    session: () => admin, status: (id, message) => statuses.set(id, message), formatDate: value => value,
    errorMessage: () => 'Mất kết nối.',
  });
  const cameraButton = controls.get('check-in-start');
  const form = controls.get('check-in-manual');
  const input = controls.get('check-in-number');
  const submit = () => form.dispatchEvent(new Event('submit', { cancelable: true }));
  await panel.open(event.id);
  assert.equal(cameraButton.hidden, true);
  assert.equal(form.hidden, true);
  assert.equal(statuses.get('check-in-camera-status'), 'Chưa mở check-in.');

  serverTime = event.checkInStartAt;
  await panel.open(event.id);
  assert.equal(cameraButton.hidden, false);
  assert.equal(form.hidden, false);
  input.value = ' ev-012345abcdef ';
  submit();
  submit();
  await Promise.resolve();
  assert.equal(calls.length, 1);
  assert.equal(calls[0].eventId, event.id);
  assert.equal(calls[0].ticketNumber, 'EV-012345ABCDEF');
  assert.equal(controls.get('check-in-retry').hidden, false);
  submit();
  await Promise.resolve();
  assert.deepEqual(calls[1], calls[0]);
  assert.match(statuses.get('check-in-result'), /Check-in thành công/);
  assert.equal(input.value, '');

  serverTime = event.checkInEndAt;
  await panel.open(event.id);
  assert.equal(cameraButton.hidden, true);
  assert.equal(form.hidden, true);
  input.value = 'EV-012345ABCDEF';
  submit();
  assert.equal(calls.length, 2);
  assert.equal(statuses.get('check-in-camera-status'), 'Đã đóng check-in.');

  event.participationMode = 'walk_in';
  serverTime = event.checkInStartAt;
  await panel.open(event.id);
  assert.equal(cameraButton.hidden, true);
  assert.equal(form.hidden, true);
  assert.match(controls.get('check-in-event-title').textContent, /không dùng vé đăng ký trước/);
  panel.close();
});
