import assert from 'node:assert/strict';
import test from 'node:test';
import { setupNotifications } from '../src/notifications.js';

const tick = () => new Promise(resolve => setImmediate(resolve));
const deferred = () => { let resolve, reject; const promise = new Promise((a, b) => { resolve = a; reject = b; }); return { promise, resolve, reject }; };
class Control extends EventTarget {
  value = '';
  disabled = false;
  options = [];
  replaceChildren(...options) { this.options = options; this.value = options[0]?.value ?? ''; }
  add(option) { this.options.push(option); }
}
function mount(firebase) {
  const recipient = new Control(), body = new Control(), submit = new Control(), reload = new Control(), form = new Control();
  form.elements = { uid: recipient, body };
  form.querySelector = () => submit;
  form.reportValidity = () => true;
  form.reset = () => { recipient.value = body.value = ''; };
  const nodes = { 'notification-form': form, 'notification-reload': reload };
  globalThis.document = { getElementById: id => nodes[id] };
  globalThis.Option = class { constructor(text, value) { this.text = text; this.value = value; } };
  let session = {};
  const messages = new Map();
  const panel = setupNotifications({ firebase, session: () => session, status: (id, message) => messages.set(id, message), errorMessage: e => e.message });
  return { panel, recipient, body, submit, reload, messages, send: () => form.dispatchEvent(new Event('submit', { cancelable: true })), logout: () => { session = undefined; panel.reset(); } };
}
test('recipient list loads all pages, excludes inactive accounts and recovers after load error', async () => {
  let fail = true;
  const calls = [];
  const ui = mount({ notificationUsers: async cursor => {
    if (fail) throw new Error('Offline');
    calls.push(cursor);
    return cursor ? { items: [{ id: 'second', displayName: 'Second', accountStatus: 'active' }], nextCursor: null }
      : { items: [{ id: 'first', displayName: 'First', accountStatus: 'active' }, { id: 'disabled', accountStatus: 'disabled' }], nextCursor: 'next' };
  } });
  ui.panel.open(); await tick();
  assert.equal(ui.messages.get('notification-users-status'), 'Offline');
  assert.equal(ui.submit.disabled, true);
  fail = false; ui.reload.dispatchEvent(new Event('click')); await tick();
  assert.deepEqual(calls, [undefined, 'next']);
  assert.deepEqual(ui.recipient.options.map(o => o.value), ['', 'first', 'second']);
});
test('send locks duplicate submission, keeps retry id on failure and clears draft only on success', async () => {
  let pending = deferred();
  const calls = [];
  const ui = mount({ notificationUsers: async () => ({ items: [{ id: 'member', accountStatus: 'active' }] }), sendNotification: input => { calls.push(input); return pending.promise; } });
  ui.panel.open(); await tick();
  ui.recipient.value = 'member'; ui.body.value = '  Hello  ';
  ui.body.dispatchEvent(new Event('input'));
  assert.equal(ui.submit.disabled, false);
  ui.send(); ui.send();
  assert.equal(calls.length, 1);
  assert.equal(ui.body.disabled, true);
  pending.reject(new Error('Network error')); await tick();
  assert.equal(ui.body.value, '  Hello  ');
  assert.equal(ui.messages.get('notification-status'), 'Network error');
  pending = deferred(); ui.send();
  assert.equal(calls[0].requestId, calls[1].requestId);
  assert.equal(calls[1].body, 'Hello');
  pending.resolve({ status: 'queued' }); await tick();
  assert.equal(ui.body.value, '');
  assert.equal(ui.submit.disabled, true);
  assert.match(ui.messages.get('notification-status'), /xếp hàng/);
});
test('logout clears recipient and draft and ignores the previous session send result', async () => {
  const pending = deferred();
  const ui = mount({ notificationUsers: async () => ({ items: [{ id: 'member', accountStatus: 'active' }] }), sendNotification: () => pending.promise });
  ui.panel.open(); await tick();
  ui.recipient.value = 'member'; ui.body.value = 'Hello'; ui.send();
  ui.logout(); pending.resolve({ status: 'queued' }); await tick();
  assert.equal(ui.messages.get('notification-status'), '');
  assert.deepEqual(ui.recipient.options.map(o => o.value), ['']);
  assert.equal(ui.body.value, '');
  assert.equal(ui.submit.disabled, true);
});
