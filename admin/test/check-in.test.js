import assert from 'node:assert/strict';
import test from 'node:test';
import { setupCheckIn } from '../src/check-in.js';

test('a direct scanner link gates the camera on the check-in window and ticket type', async t => {
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
  const panel = setupCheckIn({
    firebase: { checkInEvent: async () => event, serverInfo: async () => ({ serverTime }) },
    session: () => admin, status: (id, message) => statuses.set(id, message), formatDate: value => value,
  });
  const cameraButton = controls.get('check-in-start');
  await panel.open(event.id);
  assert.equal(cameraButton.hidden, true);
  assert.equal(statuses.get('check-in-camera-status'), 'Chưa mở check-in.');

  serverTime = event.checkInStartAt;
  await panel.open(event.id);
  assert.equal(cameraButton.hidden, false);

  serverTime = event.checkInEndAt;
  await panel.open(event.id);
  assert.equal(cameraButton.hidden, true);
  assert.equal(statuses.get('check-in-camera-status'), 'Đã đóng check-in.');

  event.participationMode = 'walk_in';
  serverTime = event.checkInStartAt;
  await panel.open(event.id);
  assert.equal(cameraButton.hidden, true);
  assert.match(controls.get('check-in-event-title').textContent, /không dùng vé đăng ký trước/);
  panel.close();
});
