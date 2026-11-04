import assert from 'node:assert/strict';
import test, { beforeEach, after } from 'node:test';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { createBackend } from '../lib/backend.js';
import { createMaintenance } from '../lib/maintenance.js';
import { key } from '../lib/shared.js';

assert.equal(process.env.GCLOUD_PROJECT, 'demo-evia-backend');
assert.match(process.env.FIRESTORE_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
const app = initializeApp({ projectId: 'demo-evia-backend' }, 'maintenance-tests');
const db = getFirestore(app);
let now = new Date('2026-11-04T03:00:00Z');
const api = createBackend(db, () => now), jobs = createMaintenance(db, () => now);
const alice = { uid: 'test-monthly-alice', token: {} };
beforeEach(async () => {
  const response = await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-evia-backend/databases/(default)/documents`, { method: 'DELETE' });
  assert.equal(response.status, 200);
  now = new Date('2026-11-04T03:00:00Z');
  await api.invoke('initializeUser', alice, {});
});
after(() => deleteApp(app));

test('monthly job grants all initialized accounts once per Vietnam month, even before onboarding', async () => {
  const scheduled = new Date('2026-11-30T17:00:00Z');
  now = new Date('2026-12-02T03:00:00Z');
  await api.invoke('initializeUser', { uid: 'test-after-cutoff', token: {} }, {});
  const results = await Promise.all([jobs.grantMonthly(scheduled), jobs.grantMonthly(scheduled)]);
  assert.equal(results.reduce((n, r) => n + r.grantedCount, 0), 1);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 400);
  assert.equal((await db.doc('wallets/test-after-cutoff').get()).get('availableCoins'), 200);
  assert.equal((await db.collection(`users/${alice.uid}/monthly_grants`).get()).size, 1);
  assert.equal((await db.collection(`wallets/${alice.uid}/ledger`).get()).size, 2);
  await assert.rejects(jobs.grantMonthly(new Date('2026-12-02T03:00:00Z')), /INVALID_MONTHLY_SCHEDULE/);
  await assert.rejects(api.invoke('grantMonthlyGift', alice, {}), e => e.details?.code === 'AUTOMATIC_ONLY');
  now = new Date('2026-12-31T17:00:00Z');
  assert.equal((await jobs.grantMonthly(now)).grantedCount, 2);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 600);
});

test('no-show settlement forfeits only held deposit once after both event and check-in end', async () => {
  const t = Timestamp.fromDate(now);
  await db.doc(`wallets/${alice.uid}`).update({ availableCoins: 150, heldCoins: 50 });
  await db.doc('events/test-noshow').set({ status: 'published', endAt: t, checkInEndAt: Timestamp.fromMillis(t.toMillis() + 60_000) });
  await db.doc('tickets/test-noshow-ticket').set({ uid: alice.uid, status: 'active' });
  const regId = key(alice.uid, 'test-noshow');
  await db.doc(`registrations/${regId}`).set({ uid: alice.uid, eventId: 'test-noshow', ticketId: 'test-noshow-ticket', state: 'registered', depositCoins: 50, depositSettlement: 'held' });
  assert.equal((await jobs.settleNoShows()).settledCount, 0);
  now = new Date(now.getTime() + 60_000);
  const runs = await Promise.all([jobs.settleNoShows(), jobs.settleNoShows()]);
  assert.equal(runs.reduce((n, r) => n + r.settledCount, 0), 1);
  const wallet = (await db.doc(`wallets/${alice.uid}`).get()).data();
  assert.equal(wallet.availableCoins, 150); assert.equal(wallet.heldCoins, 0);
  assert.equal((await db.doc(`registrations/${regId}`).get()).get('state'), 'no_show');
  assert.equal((await db.doc('tickets/test-noshow-ticket').get()).get('status'), 'revoked');
  assert.equal((await db.collection(`wallets/${alice.uid}/ledger`).get()).size, 2);
  assert.equal((await jobs.settleNoShows()).settledCount, 0);
});

test('no-show job leaves cancelled events and already attended registrations untouched', async () => {
  const t = Timestamp.fromDate(now);
  await db.doc('events/cancelled').set({ status: 'cancelled', endAt: t, checkInEndAt: t });
  await db.doc('registrations/cancelled-event').set({ uid: alice.uid, eventId: 'cancelled', state: 'registered' });
  await db.doc('registrations/attended').set({ uid: alice.uid, eventId: 'completed', state: 'attended' });
  assert.equal((await jobs.settleNoShows()).settledCount, 0);
  assert.equal((await db.doc('registrations/cancelled-event').get()).get('state'), 'registered');
});
