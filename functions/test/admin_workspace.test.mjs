import assert from 'node:assert/strict';
import test, { beforeEach, after } from 'node:test';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { createBackend } from '../lib/backend.js';
assert.equal(process.env.GCLOUD_PROJECT, 'demo-evia-backend');
assert.match(process.env.FIRESTORE_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):/);
const app = initializeApp({ projectId: 'demo-evia-backend' }, 'admin-workspace-tests'), db = getFirestore(app), auth = getAuth(app);
const api = createBackend(db, () => new Date('2026-11-06T04:00:00Z'));
const admin = { uid: 'workspace-admin', token: { email: 'admin@example.com', admin: true } }, staff = { uid: 'workspace-staff', token: { email: 'staff@example.com', staff: true } }, member = { uid: 'workspace-member', token: { email: 'member@example.com' } };
const call = (name, input = {}, actor = admin) => api.invoke(name, actor, input);
const reject = (promise, code) => assert.rejects(promise, e => e.details?.code === code);
beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-evia-backend/databases/(default)/documents`, { method: 'DELETE' });
  for (const actor of [admin, staff, member]) {
    await db.doc(`users/${actor.uid}`).set({ displayName: actor.uid, accountStatus: 'active', onboardingCompleted: true, isDemo: true });
    try { await auth.createUser({ uid: actor.uid, email: actor.token.email }); } catch (e) { if (e.code !== 'auth/uid-already-exists' && e.code !== 'auth/email-already-exists') throw e; }
    await auth.setCustomUserClaims(actor.uid, actor.token);
  }
  await db.doc('events/workspace-event').set({ title: 'Event', status: 'published', visibility: 'public', isDemo: true });
});
after(() => deleteApp(app));
test('operator guard rejects ordinary and disabled users; staff cannot browse users', async () => {
  await reject(call('getOperatorContext', {}, member), 'FORBIDDEN_ADMIN');
  await reject(call('listAdminRecords', { kind: 'users' }, staff), 'FORBIDDEN_ADMIN');
  await db.doc(`users/${admin.uid}`).update({ accountStatus: 'disabled' });
  await reject(call('getOperatorContext'), 'ACCOUNT_DISABLED');
});
test('one admin issues walk-in QR and verifies tickets without a staff role or assignment', async () => {
  assert.equal((await call('getOperatorContext')).voucher, true);
  const event = { title: 'Admin check-in', status: 'published', visibility: 'public', organizerId: 'club', participationMode: 'registration', capacity: 10, registeredCount: 0, depositCoins: 50, attendanceRewardCoins: 10, audience: { scope: 'everyone' }, startAt: Timestamp.fromDate(new Date('2026-11-06T06:00:00Z')), endAt: Timestamp.fromDate(new Date('2026-11-06T08:00:00Z')), checkInStartAt: Timestamp.fromDate(new Date('2026-11-06T03:00:00Z')), checkInEndAt: Timestamp.fromDate(new Date('2026-11-06T08:00:00Z')), registrationTerms: { version: 'v1', text: 'Test only' } };
  await db.doc('events/workspace-event').set(event);
  await db.doc(`wallets/${member.uid}`).set({ availableCoins: 200, heldCoins: 0, version: 1 });
  await call('registerForEvent', { eventId: 'workspace-event', requestId: 'admin-ticket-register', expectedDepositCoins: 50, acceptedTermsVersion: 'v1', attendeeInput: { fullName: 'Test Member', studentId: 'SE123456', universityEmail: 'member@example.com' } }, member);
  const qr = await call('getTicketQr', { eventId: 'workspace-event' }, member);
  const result = await call('verifyRegisteredTicket', { qrPayload: qr.qrPayload, expectedEventId: 'workspace-event', requestId: 'admin-ticket-checkin' });
  assert.equal(result.eventId, 'workspace-event');
  await db.doc('events/walkin-event').set({ ...event, participationMode: 'walk_in', depositCoins: 0 });
  assert.match((await call('issueWalkInQr', { eventId: 'walkin-event' })).qrPayload, /^evia:walkin:/);
  assert.equal((await db.collection('staff_assignments').get()).size, 0);
});
test('organizer edits use revisions and preserve follower counts', async () => {
  const organizer = { id: 'workspace-club', name: 'Club', description: 'Club description', published: true, sourceRef: 'https://example.com/club' };
  await call('upsertOrganizer', { organizer: { ...organizer, logoUrl: 'https://example.com/logo.png' }, expectedRevision: null });
  await db.doc('organizers/workspace-club').update({ followerCount: 4 });
  const rows = await call('listAdminRecords', { kind: 'organizers' });
  await reject(call('upsertOrganizer', { organizer, expectedRevision: null }), 'CATALOG_CHANGED');
  await call('upsertOrganizer', { organizer: { ...organizer, name: 'Renamed' }, expectedRevision: rows.items[0].revision });
  assert.equal((await db.doc('organizers/workspace-club').get()).get('followerCount'), 4);
  assert.equal((await db.doc('organizers/workspace-club').get()).get('logoUrl'), undefined);
});
test('single admin sees event participants without staff assignments; staff is rejected', async () => {
  assert.equal((await call('listOperatorEvents')).items.length, 1);
  await db.doc('registrations/one').set({ uid: 'someone', eventId: 'workspace-event', state: 'registered', token: 'never-return-this' });
  const result = await call('listAdminRecords', { kind: 'participants', eventId: 'workspace-event' });
  assert.equal(result.items[0].token, undefined);
  await reject(call('listAdminRecords', { kind: 'participants', eventId: 'workspace-event' }, staff), 'FORBIDDEN_ADMIN');
  assert.equal((await db.collection('staff_assignments').get()).size, 0);
});
test('demo push is scoped, idempotent and requires registered devices', async () => {
  const input = { uid: member.uid, eventId: 'workspace-event', requestId: 'admin-demo-request-1' };
  await reject(call('sendAdminDemoNotification', input), 'NO_REGISTERED_DEVICE');
  await db.doc(`users/${member.uid}/devices/test`).set({ token: 'test-only-token' });
  const a = await call('sendAdminDemoNotification', input), b = await call('sendAdminDemoNotification', input);
  assert.equal(a.notificationId, b.notificationId); assert.equal((await db.collection('notifications').get()).size, 1);
  await db.doc(`users/${member.uid}`).update({ isDemo: false });
  await reject(call('sendAdminDemoNotification', { ...input, requestId: 'admin-demo-request-2' }), 'DEMO_NOT_ALLOWED');
});
test('user reads exclude private fields and support ledger pagination', async () => {
  await db.doc(`users/${member.uid}`).update({ secret: 'test-only-secret' });
  await db.doc(`wallets/${member.uid}`).set({ availableCoins: 200, heldCoins: 0, version: 1 });
  for (const id of ['a', 'b']) await db.doc(`wallets/${member.uid}/ledger/${id}`).set({ type: 'test', deltaAvailable: 1, deltaHeld: 0, createdAt: Timestamp.now() });
  assert.equal((await call('getAdminUser', { uid: member.uid })).profile.secret, undefined);
  const first = await call('listAdminRecords', { kind: 'ledger', uid: member.uid, limit: 1 });
  assert.equal(first.nextCursor, 'a');
  assert.equal((await call('listAdminRecords', { kind: 'ledger', uid: member.uid, cursor: first.nextCursor })).items[0].id, 'b');
});
test('physical collection is privileged and never debits again', async () => {
  await db.doc(`voucher_admins/${admin.uid}`).set({ active: true });
  await db.doc('redemptions/physical-one').set({ uid: member.uid, status: 'issued', voucherId: null, rewardSnapshot: { fulfillmentType: 'physical' }, expiresAt: Timestamp.fromDate(new Date('2027-01-01T00:00:00Z')) });
  const input = { redemptionId: 'physical-one', requestId: 'collect-physical-one' };
  const result = await call('confirmPhysicalReward', input);
  assert.deepEqual(await call('confirmPhysicalReward', input), result);
  await reject(call('confirmPhysicalReward', { ...input, requestId: 'collect-physical-two' }), 'USED');
  assert.equal((await db.doc(`wallets/${member.uid}`).get()).exists, false);
  await db.doc(`users/${admin.uid}`).update({ accountStatus: 'disabled' });
  await reject(call('confirmPhysicalReward', input), 'ACCOUNT_DISABLED');
});
