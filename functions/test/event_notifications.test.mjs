import assert from 'node:assert/strict';
import test, { beforeEach, after } from 'node:test';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { createBackend } from '../lib/backend.js';
import { createEventNotifications } from '../lib/event_notifications.js';
import { key } from '../lib/shared.js';

assert.equal(process.env.GCLOUD_PROJECT, 'demo-evia-backend');
assert.match(process.env.FIRESTORE_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
const app = initializeApp({ projectId: 'demo-evia-backend' }, 'event-notifications'), db = getFirestore(app);
// Historical dates keep real emulator triggers separate from the injected job clock.
let now = new Date('2020-11-07T03:00:00Z');
const api = createBackend(db, () => now), jobs = createEventNotifications(db, () => now);
const t = iso => Timestamp.fromDate(new Date(iso));
const source = () => ({ title: 'Test event only', organizerId: 'club-fixture', status: 'published', visibility: 'public', startAt: t('2020-11-10T03:00:00Z'), endAt: t('2020-11-10T05:00:00Z'), timezone: 'Asia/Ho_Chi_Minh', venue: { name: 'Test hall' }, schedule: [], registeredCount: 1 });
const notices = async type => (await db.collection('notifications').where('type', '==', type).get()).docs.map(d => d.data());
beforeEach(async () => {
  const clear = await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-evia-backend/databases/(default)/documents`, { method: 'DELETE' });
  assert.equal(clear.status, 200);
  now = new Date('2020-11-07T03:00:00Z');
  for (const uid of ['notice-alice', 'notice-bob', 'notice-carl']) await api.invoke('initializeUser', { uid, token: { email: `${uid}@fpt.edu.vn` } }, {});
  await db.doc('users/notice-alice/following/club-fixture').set({ organizerId: 'club-fixture', createdAt: t('2020-11-06T03:00:00Z') });
  await db.doc(`registrations/${key('notice-bob', 'event-fixture')}`).set({ uid: 'notice-bob', eventId: 'event-fixture', state: 'registered', registeredAt: t('2020-11-06T03:00:00Z') });
  await db.doc('users/notice-carl/event_intents/event-fixture').set({ eventId: 'event-fixture', createdAt: t('2020-11-06T03:00:00Z') });
  await db.doc('events/event-fixture').set(source());
});
after(() => deleteApp(app));

test('publication notifies active followers once and does not broadcast to every user', async () => {
  await Promise.all([jobs.onEventWritten('event-fixture', undefined, source()), jobs.onEventWritten('event-fixture', undefined, source())]);
  const rows = await notices('new_event');
  assert.equal(rows.length, 1); assert.equal(rows[0].uid, 'notice-alice');
  assert.equal(rows[0].entityType, 'event'); assert.equal(rows[0].entityId, 'event-fixture');
  await db.doc('users/notice-alice/following/club-fixture').delete();
  await db.doc('users/notice-bob/following/club-fixture').set({ organizerId: 'club-fixture', createdAt: t('2020-11-08T03:00:00Z') });
  await jobs.onEventWritten('event-fixture', undefined, source());
  assert.equal((await notices('new_event')).length, 1);
});

test('schedule updates target current registrants and Going users with idempotent receipts', async () => {
  const before = source(), after = { ...before, venue: { name: 'Changed test hall' } };
  await db.doc('events/event-fixture').set(after);
  await jobs.onEventWritten('event-fixture', before, after);
  await jobs.onEventWritten('event-fixture', before, after);
  assert.deepEqual((await notices('schedule_updated')).map(r => r.uid).sort(), ['notice-bob', 'notice-carl']);
  await db.doc('events/event-fixture').update({ registeredCount: 2 });
  await jobs.onEventWritten('event-fixture', after, { ...after, registeredCount: 2 });
  assert.equal((await notices('schedule_updated')).length, 2);
});

test('out-of-order event updates cannot notify users with stale schedules', async () => {
  const before = source(), stale = { ...before, venue: { name: 'Stale hall' } }, latest = { ...before, venue: { name: 'Latest hall' } };
  await db.doc('events/event-fixture').set(latest);
  await jobs.onEventWritten('event-fixture', before, stale);
  assert.equal((await notices('schedule_updated')).length, 0);
  await jobs.onEventWritten('event-fixture', stale, latest);
  assert.equal((await notices('schedule_updated')).length, 2);
});

test('three-day reminder uses a 72-hour cutoff and cannot duplicate on overlapping job runs', async () => {
  now = new Date('2020-11-07T02:59:59Z');
  await jobs.sendReminders();
  assert.equal((await notices('event_reminder')).length, 0);
  now = new Date('2020-11-07T03:00:00Z');
  await Promise.all([jobs.sendReminders(), jobs.sendReminders()]);
  assert.deepEqual((await notices('event_reminder')).map(r => r.uid).sort(), ['notice-bob', 'notice-carl']);
  await jobs.sendReminders();
  assert.equal((await notices('event_reminder')).length, 2);
  assert.equal((await db.doc('wallets/notice-bob').get()).get('availableCoins'), 200);
});

test('reminders exclude cancelled and late-joining participation', async () => {
  await db.doc(`registrations/${key('notice-bob', 'event-fixture')}`).update({ state: 'cancelled' });
  await db.doc('users/notice-carl/event_intents/event-fixture').update({ createdAt: t('2020-11-07T03:01:00Z') });
  await jobs.sendReminders();
  assert.equal((await notices('event_reminder')).length, 0);
  await db.doc('events/event-fixture').update({ status: 'cancelled' });
  await jobs.onEventWritten('event-fixture', undefined, source());
  assert.equal((await notices('new_event')).length, 0);
});

test('disabled users and ended events receive no new notifications or reminders', async () => {
  await db.doc('users/notice-alice').update({ accountStatus: 'disabled' });
  await db.doc('users/notice-bob').update({ accountStatus: 'disabled' });
  await db.doc('users/notice-carl').update({ accountStatus: 'disabled' });
  await jobs.onEventWritten('event-fixture', undefined, source());
  await jobs.sendReminders();
  assert.equal((await db.collection('notifications').get()).size, 0);
  now = new Date('2020-11-11T03:00:00Z');
  await db.doc('users/notice-alice').update({ accountStatus: 'active' });
  await jobs.onEventWritten('event-fixture', undefined, source());
  assert.equal((await db.collection('notifications').get()).size, 0);
});
