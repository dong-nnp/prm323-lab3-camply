import assert from 'node:assert/strict';
import test from 'node:test';
import { setImmediate } from 'node:timers/promises';
import QrScanner from 'qr-scanner';
import { setupCheckIn } from '../src/check-in.js';

function mountScanner(t, api) {
  const controls = new Map();
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
  const panel = setupCheckIn({
    firebase: {
      checkInEvent: async () => event, serverInfo: async () => ({ serverTime }),
      ...api,
    },
    session: () => admin, status: (id, message) => statuses.set(id, message), formatDate: value => value,
    errorMessage: () => 'Mất kết nối.',
  });
  t.after(panel.close);
  return { controls, statuses, event, panel, setServerTime: time => { serverTime = time; } };
}

test('the scanner gates QR and manual check-in and submits the selected event and ticket number', async t => {
  t.mock.method(globalThis, 'setTimeout', () => undefined);
  const calls = [];
  const { controls, statuses, event, panel, setServerTime } = mountScanner(t, {
    verifyTicketNumber: async input => {
      calls.push(input);
      if (calls.length === 1) throw Object.assign(new Error(), { code: 'functions/unavailable' });
      return { coinsGranted: 10, depositRefunded: 50 };
    },
  });
  const cameraButton = controls.get('check-in-start');
  const form = controls.get('check-in-manual');
  const input = controls.get('check-in-number');
  const submit = () => form.dispatchEvent(new Event('submit', { cancelable: true }));
  await panel.open(event.id);
  assert.equal(cameraButton.hidden, true);
  assert.equal(form.hidden, true);
  assert.equal(statuses.get('check-in-camera-status'), 'Chưa mở check-in.');

  setServerTime(event.checkInStartAt);
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

  setServerTime(event.checkInEndAt);
  await panel.open(event.id);
  assert.equal(cameraButton.hidden, true);
  assert.equal(form.hidden, true);
  input.value = 'EV-012345ABCDEF';
  submit();
  assert.equal(calls.length, 2);
  assert.equal(statuses.get('check-in-camera-status'), 'Đã đóng check-in.');

  event.participationMode = 'walk_in';
  setServerTime(event.checkInStartAt);
  await panel.open(event.id);
  assert.equal(cameraButton.hidden, true);
  assert.equal(form.hidden, true);
  assert.match(controls.get('check-in-event-title').textContent, /không dùng vé đăng ký trước/);
});

test('a QR read again after a gap keeps its success message and the next ticket can check in', async t => {
  const firstQr = `evia:ticket:${'A'.repeat(32)}:${'B'.repeat(43)}`;
  const nextQr = `evia:ticket:${'C'.repeat(32)}:${'D'.repeat(43)}`;
  let payload = firstQr;
  let detectedAt = 0;
  let nextFrame;
  t.mock.method(performance, 'now', () => detectedAt);
  t.mock.method(globalThis, 'setTimeout', (callback, delay) => {
    if (delay === 125) nextFrame = callback;
  });
  t.mock.getter(globalThis, 'navigator', () => ({
    mediaDevices: { getUserMedia: async () => ({ getVideoTracks: () => [], getTracks: () => [] }) },
  }));
  globalThis.ImageCapture = class { async grabFrame() {} };
  globalThis.Worker = class {};
  t.mock.method(QrScanner, 'createQrEngine', async () => null);
  t.mock.method(QrScanner, 'scanImage', async () => ({ data: payload }));

  const first = Promise.withResolvers();
  const next = Promise.withResolvers();
  const scans = [];
  const { controls, statuses, event, panel, setServerTime } = mountScanner(t, {
    verifyTicket: input => {
      scans.push(input);
      return scans.length === 1 ? first.promise : next.promise;
    },
  });
  t.after(() => {
    delete globalThis.ImageCapture;
    delete globalThis.Worker;
  });
  const video = { play: async () => {}, videoWidth: 640, videoHeight: 480 };
  controls.set('check-in-video', { cloneNode: () => video, replaceWith() {} });
  globalThis.document.createElement = () => ({ getContext() {} });
  setServerTime(event.checkInStartAt);
  await panel.open(event.id);
  controls.get('check-in-start').dispatchEvent(new Event('click'));
  await setImmediate();
  assert.equal(statuses.get('check-in-result'), 'Đang xác nhận vé…');

  detectedAt = 1600;
  first.resolve({ coinsGranted: 100, depositRefunded: 50 });
  await setImmediate();
  const confirmation = 'Check-in thành công · +100 xu thưởng · Hoàn 50 xu đặt cọc.';
  assert.equal(statuses.get('check-in-result'), confirmation);
  nextFrame();
  await setImmediate();
  assert.equal(statuses.get('check-in-result'), confirmation);
  assert.equal(scans.length, 1);

  payload = nextQr;
  nextFrame();
  await setImmediate();
  assert.equal(scans[1].qrPayload, nextQr);
  next.resolve({ coinsGranted: 10, depositRefunded: 0 });
  await setImmediate();
  assert.equal(statuses.get('check-in-result'), 'Check-in thành công · +10 xu thưởng · Hoàn 0 xu đặt cọc.');
});
