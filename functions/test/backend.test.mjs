import assert from 'node:assert/strict';
import test, { beforeEach, after } from 'node:test';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { createBackend } from '../lib/backend.js';
import { key } from '../lib/shared.js';
import { deliverPush } from '../lib/push_notifications.js';

const projectId = 'demo-evia-backend';
assert.match(process.env.FIRESTORE_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):/);
assert.match(process.env.FIREBASE_AUTH_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):/);
assert.match(process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):/);
assert.equal(process.env.GCLOUD_PROJECT, projectId, 'Tests must never target a live project');
const app = initializeApp({ projectId }, 'backend-tests'), db = getFirestore(app);
let now = new Date('2026-11-04T03:00:00Z');
const api = createBackend(db, () => now);
const alice = { uid: 'test-alice', token: { email: 'alice@gmail.com' } }, bob = { uid: 'test-bob', token: { email: 'bob@outlook.com' } }, operator = { uid: 'test-staff', token: { staff: true, email: 'staff@yahoo.com' } };
const firestoreUrl = `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${projectId}/databases/(default)/documents`;
async function tokenFor(actor) {
  const token = await getAuth(app).createCustomToken(actor.uid);
  const response = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=emulator-only`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ token, returnSecureToken: true }) });
  const data = await response.json(); assert.ok(data.idToken); return data.idToken;
}
const headersFor = token => ({ 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) });
async function status(request, expected) { const response = await request; assert.equal(response.status, expected, await response.text()); }
const call = (name, actor = alice, data = {}) => api.invoke(name, actor, data);
const rejects = async (promise, code) => assert.rejects(promise, e => e.details?.code === code, code);

async function event(eventId = 'registered', overrides = {}) {
  await db.doc(`events/${eventId}`).set({ title: 'Test event fixture', organizerId: 'test-club', category: 'technology', tags: ['technology'], status: 'published', visibility: 'public', participationMode: 'registration', audience: { scope: 'everyone' }, startAt: Timestamp.fromDate(new Date('2026-11-05T03:00:00Z')), endAt: Timestamp.fromDate(new Date('2026-11-05T05:00:00Z')), checkInStartAt: Timestamp.fromDate(new Date('2026-11-04T02:00:00Z')), checkInEndAt: Timestamp.fromDate(new Date('2026-11-04T05:00:00Z')), timezone: 'Asia/Ho_Chi_Minh', capacity: 1, registeredCount: 0, depositCoins: 50, attendanceRewardCoins: 100, registrationTerms: { version: 'v1', text: 'Emulator test only' }, ...overrides });
}
const registration = (requestId = 'register-0001', eventId = 'registered') => ({ eventId, requestId, expectedDepositCoins: 50, acceptedTermsVersion: 'v1', attendeeInput: { fullName: 'Test Student', studentId: 'SE123456', universityEmail: 'student@gmail.com' } });
async function reward(overrides = {}) {
  await db.doc('rewards/cafe').set({ title: 'Test reward fixture', status: 'active', priceCoins: 200, stockRemaining: 1, termsVersion: 'v1', termsText: 'Test terms', validDays: 30, usageLocations: ['Test location'], redemptionSteps: ['Test step'], fulfillmentType: 'voucher', ...overrides });
}
const redemption = requestId => ({ rewardId: 'cafe', requestId, expectedPriceCoins: 200, expectedTermsVersion: 'v1' });
beforeEach(async () => {
  await status(fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: 'DELETE' }), 200);
  now = new Date('2026-11-04T03:00:00Z');
  for (const id of ['technology', 'music', 'arts']) await db.doc(`interests/${id}`).set({ label: id, status: 'active' });
  for (const actor of [alice, bob, operator]) {
    await call('initializeUser', actor);
    await call('saveInterests', actor, { interests: ['technology', 'music', 'arts'] });
  }
  await db.doc('organizers/test-club').set({ name: 'Test club', published: true, followerCount: 0 });
  await event();
});
after(async () => { await deleteApp(app); });

test('push delivery uses the Evia high priority channel and skips users without devices', async () => {
  let message;
  const messaging = { sendEachForMulticast: async value => {
    message = value;
    return { successCount: 1, failureCount: 0, responses: [{ success: true, messageId: 'test-message' }] };
  } };
  const notice = { uid: alice.uid, title: 'New event', body: 'Your club published an event', entityType: 'event', entityId: 'registered' };
  assert.deepEqual(await deliverPush(db, messaging, 'test-notice', notice), { successCount: 0, failureCount: 0 });
  assert.equal(message, undefined);
  await call('registerDevice', alice, { installationId: 'test-installation', token: 'test-only-fcm-device-token', platform: 'android' });
  assert.deepEqual(await deliverPush(db, messaging, 'test-notice', notice), { successCount: 1, failureCount: 0 });
  assert.equal(message.android.priority, 'high');
  assert.equal(message.android.notification.channelId, 'evia_events_v1');
  assert.equal(message.android.notification.tag, 'test-notice');
  assert.deepEqual(message.data, { notificationId: 'test-notice', entityType: 'event', entityId: 'registered' });
});

test('push delivery removes an expired token and retries transient failures', async () => {
  const token = 'test-only-fcm-device-token';
  await call('registerDevice', alice, { installationId: 'test-installation', token, platform: 'android' });
  const notice = { uid: alice.uid, title: 'New event', body: 'A new event' };
  const result = code => ({ sendEachForMulticast: async () => ({ successCount: 0, failureCount: 1, responses: [{ success: false, error: { code } }] }) });
  await assert.rejects(deliverPush(db, result('messaging/internal-error'), 'test-notice', notice), /FCM_TRANSIENT_DELIVERY_FAILURE/);
  assert.equal((await db.doc(`users/${alice.uid}/devices/test-installation`).get()).exists, true);
  await deliverPush(db, result('messaging/registration-token-not-registered'), 'test-notice', notice);
  assert.equal((await db.doc(`users/${alice.uid}/devices/test-installation`).get()).exists, false);
  assert.equal((await db.doc(`device_bindings/${key(token)}`).get()).exists, false);
});

test('account exposes Daily using server Vietnam day, preserving claims and resetting missed days', async () => {
  now = new Date('2026-11-05T17:01:00Z');
  let account = await call('getAccount');
  assert.equal(account.daily.dayKey, '2026-11-06');
  assert.equal(account.daily.streakDay, 1);
  assert.equal(account.daily.coins, 5);
  assert.equal(account.daily.alreadyClaimed, false);
  await call('claimDailyCheckin');
  account = await call('getAccount');
  assert.equal(account.daily.alreadyClaimed, true);
  now = new Date('2026-11-06T17:01:00Z');
  assert.equal((await call('getAccount')).daily.coins, 10);
  now = new Date('2026-11-08T17:01:00Z');
  assert.equal((await call('getAccount')).daily.coins, 5);
});

test('demo attendance requires server flags, settles once, and cannot bypass real staff APIs', async () => {
  const input = { eventId: 'registered', requestId: 'demo-attend-0001' };
  await rejects(call('demoConfirmAttendance', alice, input), 'DEMO_NOT_ALLOWED');
  await db.doc(`users/${alice.uid}`).update({ isDemo: true, demoAttendanceEnabled: true });
  await rejects(call('demoConfirmAttendance', alice, input), 'DEMO_NOT_ALLOWED');
  await db.doc('events/registered').update({ isDemo: true });
  await rejects(call('demoConfirmAttendance', alice, input), 'NOT_REGISTERED');
  await call('registerForEvent', alice, registration());
  const results = await Promise.all([call('demoConfirmAttendance', alice, input), call('demoConfirmAttendance', alice, input)]);
  assert.deepEqual(results[0], results[1]);
  assert.equal(results[0].wallet.availableCoins, 300);
  assert.equal(results[0].wallet.heldCoins, 0);
  assert.equal(results[0].isDemo, true);
  assert.equal((await db.doc(`attendance/${key(alice.uid, 'registered')}`).get()).get('verificationMethod'), 'debug_demo_button');
  assert.equal((await db.doc(`registrations/${key(alice.uid, 'registered')}`).get()).get('state'), 'attended');
  await rejects(call('demoConfirmAttendance', alice, { ...input, requestId: 'demo-attend-0002' }), 'ALREADY_CHECKED_IN');
  await rejects(call('demoConfirmAttendance', bob, input), 'DEMO_NOT_ALLOWED');
  await db.doc(`users/${alice.uid}`).update({ demoAttendanceEnabled: false });
  await rejects(call('demoConfirmAttendance', alice, input), 'DEMO_NOT_ALLOWED');
  await rejects(call('verifyRegisteredCode', alice, { code: 'ABCD-EFGH', requestId: 'not-staff-0001' }), 'FORBIDDEN_STAFF');
  const token = await tokenFor(alice);
  await status(fetch(`${firestoreUrl}/users/${alice.uid}?updateMask.fieldPaths=demoAttendanceEnabled`, {
    method: 'PATCH', headers: headersFor(token), body: JSON.stringify({ fields: { demoAttendanceEnabled: { booleanValue: true } } }),
  }), 403);
});

test('demo walk-in bypasses time only on marked demo data and cannot consume a cancelled ticket', async () => {
  await db.doc(`users/${alice.uid}`).update({ isDemo: true, demoAttendanceEnabled: true });
  await event('demo-walk', { isDemo: true, participationMode: 'walk_in', depositCoins: 0, capacity: null,
    checkInEndAt: Timestamp.fromDate(new Date('2020-01-01T00:00:00Z')) });
  const walk = await call('demoConfirmAttendance', alice, { eventId: 'demo-walk', requestId: 'demo-walk-0001' });
  assert.equal(walk.wallet.availableCoins, 300);
  await db.doc('events/registered').update({ isDemo: true });
  await call('registerForEvent', alice, registration());
  await call('cancelRegistration', alice, { eventId: 'registered', requestId: 'cancel-demo-0001' });
  await rejects(call('demoConfirmAttendance', alice, { eventId: 'registered', requestId: 'cancelled-demo-01' }), 'NO_ACTIVE_TICKET');
});

test('any valid email domain can initialize, edit profile and register while identity syntax stays validated', async () => {
  const newcomer = { uid: 'gmail-user', token: { email: ' Person@Gmail.COM ' } };
  const initialized = await call('initializeUser', newcomer);
  assert.equal(initialized.profile.universityEmail, 'person@gmail.com');
  assert.equal(initialized.wallet.availableCoins, 200);
  await call('saveInterests', newcomer, { interests: ['technology', 'music', 'arts'] });
  await call('updateProfile', newcomer, { studentId: ' se123456 ', universityEmail: ' Person@Outlook.COM ' });
  assert.equal((await db.doc('users/gmail-user').get()).get('universityEmail'), 'person@outlook.com');
  const registered = await call('registerForEvent', newcomer, { ...registration('any-email-register'), attendeeInput: { ...registration().attendeeInput, universityEmail: 'person+event@custom-domain.org' } });
  assert.equal((await db.doc(`registrations/${registered.registrationId}`).get()).get('attendeeSnapshot').universityEmail, 'person+event@custom-domain.org');
  await rejects(call('initializeUser', { uid: 'invalid-email', token: { email: 'invalid' } }), 'EMAIL_REQUIRED');
  assert.equal((await db.doc('wallets/invalid-email').get()).exists, false);
  await rejects(call('updateProfile', alice, { studentId: 'STU-123456' }), 'VALIDATION_FAILED');
  await rejects(call('updateProfile', alice, { universityEmail: 'invalid@' }), 'VALIDATION_FAILED');
  await rejects(call('registerForEvent', bob, { ...registration('invalid-email-register'), attendeeInput: { ...registration().attendeeInput, universityEmail: 'a@@gmail.com' } }), 'VALIDATION_FAILED');
  await rejects(call('initializeUser', null), 'UNAUTHENTICATED');
});

test('manual walk-in code shares QR attendance protection, expiry and retry receipts', async () => {
  await event('walk-code', { participationMode: 'walk_in', depositCoins: 0, capacity: null });
  await db.doc(`staff_assignments/${key(operator.uid, 'walk-code')}`).set({ staffUid: operator.uid, eventId: 'walk-code', active: true, permissions: ['issue_walk_in'] });
  const issued = await call('issueWalkInQr', operator, { eventId: 'walk-code' });
  assert.match(issued.manualCode, /^[A-Z2-9]{4}-[A-Z2-9]{4}$/);
  await rejects(call('verifyWalkInCode', alice, { code: issued.manualCode, expectedEventId: 'another-event', requestId: 'wrong-code-event' }), 'QR_EVENT_MISMATCH');
  await rejects(call('verifyWalkInQr', alice, { qrPayload: issued.qrPayload, expectedEventId: 'another-event', requestId: 'wrong-qr-event' }), 'QR_EVENT_MISMATCH');
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 200);
  const input = { code: issued.manualCode.toLowerCase(), requestId: 'manual-walk-001' };
  await Promise.all([call('verifyWalkInCode', alice, input), call('verifyWalkInCode', alice, input)]);
  for (let i = 0; i < 7; i++) assert.equal((await call('verifyWalkInCode', alice, input)).coinsGranted, 100);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 300);
  await rejects(call('verifyWalkInQr', alice, { qrPayload: issued.qrPayload, requestId: 'manual-then-qr' }), 'ALREADY_CHECKED_IN');
  now = new Date(now.getTime() + 61_000);
  await rejects(call('verifyWalkInCode', bob, { code: issued.manualCode, requestId: 'manual-expired' }), 'CODE_EXPIRED');
  assert.equal((await call('getEventMilestones')).verifiedEventCount, 1);
});

test('manual registered code requires event-scoped staff and cannot become a student self-check-in', async () => {
  await call('registerForEvent', alice, registration('manual-register'));
  const issued = await call('getTicketQr', alice, { eventId: 'registered' });
  const input = { code: issued.manualCode, requestId: 'manual-ticket-001' };
  await rejects(call('verifyRegisteredCode', bob, input), 'FORBIDDEN_STAFF');
  await rejects(call('verifyRegisteredCode', operator, input), 'FORBIDDEN_STAFF');
  await db.doc(`staff_assignments/${key(operator.uid, 'registered')}`).set({ staffUid: operator.uid, eventId: 'registered', active: true, permissions: ['verify_ticket'] });
  const done = await call('verifyRegisteredCode', operator, input);
  assert.equal(done.depositRefunded, 50); assert.equal(done.coinsGranted, 100);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 300);
  await db.doc(`staff_assignments/${key(operator.uid, 'registered')}`).update({ active: false });
  await rejects(call('verifyRegisteredCode', operator, input), 'FORBIDDEN_STAFF');
});

test('manual code guessing is limited per authenticated account across process restarts', async () => {
  const input = { code: '2222-2222', requestId: 'manual-guess-001' };
  for (let i = 0; i < 5; i++) await rejects(call('verifyWalkInCode', bob, input), 'CODE_INVALID');
  await rejects(createBackend(db, () => now).invoke('verifyWalkInCode', bob, input), 'CODE_RATE_LIMITED');
  now = new Date(now.getTime() + 60_000);
  await rejects(call('verifyWalkInCode', bob, input), 'CODE_INVALID');
  assert.equal((await db.doc(`wallets/${bob.uid}`).get()).get('availableCoins'), 200);
});

test('signup bonus is once per UID and interests cannot be forged/duplicated', async () => {
  await Promise.all(Array.from({ length: 5 }, () => call('initializeUser')));
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 200);
  assert.equal((await db.collection(`wallets/${alice.uid}/ledger`).get()).size, 1);
  await rejects(call('saveInterests', alice, { interests: ['music', 'music', 'arts'] }), 'VALIDATION_FAILED');
  await rejects(call('saveInterests', alice, { interests: ['music', 'arts'] }), 'VALIDATION_FAILED');
  await rejects(call('updateProfile', alice, { eligibility: { verificationStatus: 'verified' } }), 'VALIDATION_FAILED');
  await rejects(call('saveInterests', alice, { interests: ['music', 'arts', 'unknown'] }), 'INVALID_INTERESTS');
  await rejects(call('initializeUser', null), 'UNAUTHENTICATED');
});
test('last seat race has one winner, full event has no monetary side effects', async () => {
  const results = await Promise.allSettled([call('registerForEvent', alice, registration('alice-seat-1')), call('registerForEvent', bob, registration('bob-seat-01'))]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal(results.find(r => r.status === 'rejected').reason.details.code, 'EVENT_FULL');
  assert.equal((await db.collection('registrations').get()).size, 1);
  assert.equal((await db.doc('events/registered').get()).get('registeredCount'), 1);
  const wallets = await db.collection('wallets').get();
  assert.equal(wallets.docs.reduce((s, d) => s + d.get('heldCoins'), 0), 50);
});
test('cancel refunds 30 percent once and opens exactly one place to another user', async () => {
  const registered = await call('registerForEvent', alice, registration());
  assert.equal((await call('registerForEvent', alice, registration())).ticketId, registered.ticketId);
  const input = { eventId: 'registered', requestId: 'cancel-00001' };
  const results = await Promise.all([call('cancelRegistration', alice, input), call('cancelRegistration', alice, input)]);
  assert.deepEqual(results[0], results[1]);
  assert.equal(results[0].depositRefunded, 15);
  assert.equal(results[0].depositForfeited, 35);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 165);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('heldCoins'), 0);
  assert.equal((await db.doc('events/registered').get()).get('registeredCount'), 0);
  assert.equal((await db.doc(`tickets/${registered.ticketId}`).get()).get('status'), 'revoked');
  const reg = (await db.doc(`registrations/${registered.registrationId}`).get()).data();
  assert.equal(reg.depositSettlement, 'partially_refunded');
  assert.equal(reg.cancellationRefundCoins, 15);
  assert.equal(reg.cancellationForfeitedCoins, 35);
  const ledger = await db.collection(`wallets/${alice.uid}/ledger`).where('type', '==', 'deposit_partial_refund').get();
  assert.equal(ledger.size, 1);
  assert.equal(ledger.docs[0].get('deltaAvailable'), 15);
  assert.equal(ledger.docs[0].get('deltaHeld'), -50);
  await call('registerForEvent', bob, registration('bob-reopen-1'));
  await rejects(call('cancelRegistration', alice, { ...input, requestId: 'cancel-00002' }), 'ALREADY_CANCELLED');
  assert.equal((await db.doc('events/registered').get()).get('registeredCount'), 1);
});
test('cancellation rounds down, uses the original held deposit and never grants attendance', async () => {
  for (const deposit of [0, 1, 3, 4, 55, 199]) {
    const eventId = `cancel-deposit-${deposit}`;
    await event(eventId, { depositCoins: deposit });
    await db.doc(`wallets/${alice.uid}`).update({ availableCoins: 1000, heldCoins: 0 });
    const reg = await call('registerForEvent', alice, { ...registration(`hold-${deposit}-0001`, eventId), expectedDepositCoins: deposit });
    await db.doc(`events/${eventId}`).update({ depositCoins: 999 });
    const cancelled = await call('cancelRegistration', alice, { eventId, requestId: `cancel-${deposit}-001` });
    assert.equal(cancelled.depositRefunded, Math.floor(deposit * 3 / 10));
    assert.equal(cancelled.depositForfeited, deposit - Math.floor(deposit * 3 / 10));
    assert.equal(cancelled.wallet.availableCoins, 1000 - deposit + Math.floor(deposit * 3 / 10));
    assert.equal(cancelled.wallet.heldCoins, 0);
    assert.equal((await db.doc(`registrations/${reg.registrationId}`).get()).get('depositSettlement'), deposit ? 'partially_refunded' : 'none');
    assert.equal((await db.doc(`attendance/${key(alice.uid, eventId)}`).get()).exists, false);
  }
});

test('cancellation racing check-in settles the deposit by exactly one path', async () => {
  const registered = await call('registerForEvent', alice, registration('race-cancel-hold'));
  const qr = await call('getTicketQr', alice, { eventId: 'registered' });
  await db.doc(`staff_assignments/${key(operator.uid, 'registered')}`).set({ staffUid: operator.uid, eventId: 'registered', active: true, permissions: ['verify_ticket'] });
  const results = await Promise.allSettled([
    call('cancelRegistration', alice, { eventId: 'registered', requestId: 'race-cancel-0001' }),
    call('verifyRegisteredTicket', operator, { qrPayload: qr.qrPayload, requestId: 'race-checkin-001' }),
  ]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  const reg = (await db.doc(`registrations/${registered.registrationId}`).get()).data();
  const wallet = (await db.doc(`wallets/${alice.uid}`).get()).data();
  assert.equal(wallet.heldCoins, 0);
  assert.equal(wallet.availableCoins, reg.state === 'cancelled' ? 165 : 300);
  assert.equal((await db.doc(`attendance/${key(alice.uid, 'registered')}`).get()).exists, reg.state === 'attended');
});

test('stale terms/deposit and requestId conflicts do not change wallet', async () => {
  await rejects(call('registerForEvent', alice, { ...registration(), acceptedTermsVersion: 'old' }), 'TERMS_CHANGED');
  await rejects(call('registerForEvent', alice, { ...registration(), expectedDepositCoins: 0 }), 'QUOTE_CHANGED');
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 200);
  await call('registerForEvent', alice, registration());
  await rejects(call('registerForEvent', alice, { ...registration(), attendeeInput: { ...registration().attendeeInput, fullName: 'Changed' } }), 'DUPLICATE_CONFLICT');
});
test('scoped staff verifies a ticket, refunds and rewards once, rejects student/replay', async () => {
  await call('registerForEvent', alice, registration());
  const qr = await call('getTicketQr', alice, { eventId: 'registered' });
  const input = { qrPayload: qr.qrPayload, requestId: 'scan-ticket-1' };
  await rejects(call('verifyRegisteredTicket', bob, input), 'FORBIDDEN_STAFF');
  await rejects(call('verifyRegisteredTicket', operator, input), 'FORBIDDEN_STAFF');
  await db.doc(`staff_assignments/${key(operator.uid, 'registered')}`).set({ staffUid: operator.uid, eventId: 'registered', active: true, permissions: ['verify_ticket'] });
  const done = await call('verifyRegisteredTicket', operator, input);
  assert.equal(done.depositRefunded, 50); assert.equal(done.coinsGranted, 100);
  assert.equal((await call('verifyRegisteredTicket', operator, input)).wallet, undefined);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 300);
  await rejects(call('verifyRegisteredTicket', operator, { ...input, requestId: 'scan-ticket-2' }), 'ALREADY_CHECKED_IN');
  await db.doc(`staff_assignments/${key(operator.uid, 'registered')}`).update({ active: false });
  await rejects(call('verifyRegisteredTicket', operator, input), 'FORBIDDEN_STAFF');
  await rejects(call('getOperationStatus', operator, { operationKind: 'verify-ticket', operationId: input.requestId }), 'FORBIDDEN_STAFF');
  const rows = await db.collection(`wallets/${alice.uid}/ledger`).get();
  assert.equal(rows.docs.reduce((s, d) => s + d.get('deltaAvailable'), 0), 300);
  assert.equal(rows.docs.reduce((s, d) => s + d.get('deltaHeld'), 0), 0);
});
test('walk-in Going is only an intent and QR verification is unique/window-bound', async () => {
  await event('walk-in', { participationMode: 'walk_in', depositCoins: 0, capacity: null });
  const going = { eventId: 'walk-in', going: true };
  await Promise.all([call('setWalkInGoing', alice, going), call('setWalkInGoing', alice, going)]);
  assert.equal((await db.collection(`users/${alice.uid}/event_intents`).get()).size, 1);
  assert.equal((await db.collection('registrations').get()).size, 0);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 200);
  await db.doc(`staff_assignments/${key(operator.uid, 'walk-in')}`).set({ staffUid: operator.uid, eventId: 'walk-in', active: true, permissions: ['issue_walk_in'] });
  const qr = await call('issueWalkInQr', operator, { eventId: 'walk-in' });
  const input = { qrPayload: qr.qrPayload, requestId: 'walkin-scan-1' };
  const done = await call('verifyWalkInQr', alice, input); assert.equal(done.coinsGranted, 100);
  assert.equal((await call('getEventMilestones')).verifiedEventCount, 1);
  await rejects(call('verifyWalkInQr', alice, { ...input, requestId: 'walkin-scan-2' }), 'ALREADY_CHECKED_IN');
  now = new Date(now.getTime() + 61_000);
  await rejects(call('verifyWalkInQr', bob, { ...input, requestId: 'walkin-expire' }), 'QR_INVALID');
});
test('daily race grants once; Vietnam midnight advances; gap resets streak', async () => {
  const results = await Promise.all(Array.from({ length: 4 }, () => call('claimDailyCheckin')));
  assert.ok(results.every(r => r.coinsGranted === 5));
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 205);
  now = new Date('2026-11-04T17:00:00Z');
  assert.equal((await call('claimDailyCheckin')).coinsGranted, 10);
  now = new Date('2026-11-07T03:00:00Z');
  assert.equal((await call('claimDailyCheckin')).coinsGranted, 5);
  await rejects(call('grantMonthlyGift'), 'AUTOMATIC_ONLY');
});
test('stock=1 concurrent redemption yields one voucher, no double debit on retry', async () => {
  await reward();
  const a = redemption('reward-alice'), b = redemption('reward-bobby');
  const results = await Promise.allSettled([call('redeemReward', alice, a), call('redeemReward', bob, b)]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal((await db.doc('rewards/cafe').get()).get('stockRemaining'), 0);
  const winner = results[0].status === 'fulfilled' ? alice : bob;
  const input = winner === alice ? a : b;
  const first = results.find(r => r.status === 'fulfilled').value;
  assert.equal((await call('redeemReward', winner, input)).voucherId, first.voucherId);
  assert.equal((await db.doc(`wallets/${winner.uid}`).get()).get('availableCoins'), 0);
  assert.equal((await db.collection('redemptions').get()).size, 1);
  const secret = await call('getVoucherCode', winner, { voucherId: first.voucherId });
  assert.equal(secret.code, (await call('getVoucherCode', winner, { voucherId: first.voucherId })).code);
  await rejects(call('getVoucherCode', winner === alice ? bob : alice, { voucherId: first.voucherId }), 'NOT_OWNER');
  await rejects(call('verifyVoucher', operator, { code: secret.code, requestId: 'cashier-test' }), 'FORBIDDEN_ADMIN');
});
test('stale reward price/terms and insufficient balance leave stock unchanged', async () => {
  await reward({ priceCoins: 250 });
  await rejects(call('redeemReward', alice, redemption('price-change')), 'PRICE_CHANGED');
  await rejects(call('redeemReward', alice, { ...redemption('terms-change'), expectedPriceCoins: 250, expectedTermsVersion: 'old' }), 'TERMS_CHANGED');
  await rejects(call('redeemReward', alice, { ...redemption('low-balance'), expectedPriceCoins: 250 }), 'INSUFFICIENT_COINS');
  assert.equal((await db.doc('rewards/cafe').get()).get('stockRemaining'), 1);
});
test('follow/unfollow races keep counters correct and do not imply membership', async () => {
  const input = { organizerId: 'test-club' };
  await Promise.all([call('followOrganizer', alice, input), call('followOrganizer', alice, input)]);
  assert.equal((await db.doc('organizers/test-club').get()).get('followerCount'), 1);
  await Promise.all([call('unfollowOrganizer', alice, input), call('unfollowOrganizer', alice, input)]);
  assert.equal((await db.doc('organizers/test-club').get()).get('followerCount'), 0);
});
test('notification read scope and mark-all cutoff are enforced', async () => {
  const time = Timestamp.fromDate(now);
  await db.doc('notifications/old-alice').set({ uid: alice.uid, readAt: null, createdAt: time });
  await db.doc('notifications/new-alice').set({ uid: alice.uid, readAt: null, createdAt: Timestamp.fromMillis(time.toMillis() + 1000) });
  await db.doc('notifications/bob-private').set({ uid: bob.uid, readAt: null, createdAt: time });
  await rejects(call('markNotificationsRead', alice, { notificationIds: ['bob-private'] }), 'FORBIDDEN');
  const result = await call('markNotificationsRead'); assert.equal(result.updatedCount, 1);
  assert.equal((await db.doc('notifications/new-alice').get()).get('readAt'), null);
  assert.equal((await db.doc('notifications/bob-private').get()).get('readAt'), null);
});
test('Rules allow own reads and published public queries, deny cross-UID and all direct mutations', async () => {
  const a = headersFor(await tokenFor(alice)), b = headersFor(await tokenFor(bob));
  await status(fetch(`${firestoreUrl}/wallets/${alice.uid}`, { headers: a }), 200);
  await status(fetch(`${firestoreUrl}/wallets/${alice.uid}`, { headers: b }), 403);
  for (const path of [`wallets/${alice.uid}`, `users/${alice.uid}`, 'attendance/fake', 'events/registered']) await status(fetch(`${firestoreUrl}/${path}`, { method: 'PATCH', headers: a, body: JSON.stringify({ fields: { availableCoins: { integerValue: '99999' } } }) }), 403);
  await status(fetch(`${firestoreUrl}/voucher_secrets/private`, { headers: a }), 403);
  await status(fetch(`${firestoreUrl}/users/${alice.uid}/devices/test`, { headers: a }), 403);
  await db.doc(`voucher_admins/${alice.uid}`).set({ active: true });
  await status(fetch(`${firestoreUrl}/voucher_admins/${alice.uid}`, { headers: a }), 403);
  await status(fetch(`${firestoreUrl}/voucher_admins/${alice.uid}`, { method: 'PATCH', headers: a, body: JSON.stringify({ fields: { active: { booleanValue: true } } }) }), 403);
  const publicQuery = { structuredQuery: { from: [{ collectionId: 'events' }], where: { compositeFilter: { op: 'AND', filters: [ ['status', 'published'], ['visibility', 'public'] ].map(([field, value]) => ({ fieldFilter: { field: { fieldPath: field }, op: 'EQUAL', value: { stringValue: value } } })) } } } };
  await status(fetch(`${firestoreUrl}:runQuery`, { method: 'POST', headers: headersFor(null), body: JSON.stringify(publicQuery) }), 200);
  await event('draft-private', { status: 'draft', visibility: 'private' });
  await status(fetch(`${firestoreUrl}/events/draft-private`), 403);
  await status(fetch(`${firestoreUrl}:runQuery`, { method: 'POST', headers: headersFor(null), body: JSON.stringify({ structuredQuery: { from: [{ collectionId: 'events' }] } }) }), 403);
});
test('Storage permits owner PDF creation/read only; rejects cross-user/type/size/overwrite', async () => {
  const a = await tokenFor(alice), b = await tokenFor(bob);
  const path = `reports/${alice.uid}/test-${Date.now()}.pdf`, pdf = new TextEncoder().encode('%PDF-1.7\nTEST FIXTURE');
  const base = `http://${process.env.FIREBASE_STORAGE_EMULATOR_HOST}/v0/b/${projectId}.appspot.com/o`;
  const upload = (name, bytes, contentType) => fetch(`${base}?uploadType=media&name=${encodeURIComponent(name)}`, { method: 'POST', headers: { authorization: `Bearer ${a}`, 'content-type': contentType }, body: bytes });
  await status(upload(path, pdf, 'application/pdf'), 200);
  await status(fetch(`${base}/${encodeURIComponent(path)}?alt=media`, { headers: { authorization: `Bearer ${a}` } }), 200);
  await status(fetch(`${base}/${encodeURIComponent(path)}?alt=media`, { headers: { authorization: `Bearer ${b}` } }), 403);
  await status(upload(path, pdf, 'application/pdf'), 403);
  await status(upload(`reports/${alice.uid}/bad.txt`, pdf, 'text/plain'), 403);
  await status(upload(`reports/${alice.uid}/big.pdf`, new Uint8Array(5 * 1024 * 1024 + 1), 'application/pdf'), 403);
});
test('catalog feeds and cursors preserve public scope and owner event union', async () => {
  await event('later', { category: 'sports', tags: ['sports'], startAt: Timestamp.fromDate(new Date('2026-11-06T03:00:00Z')), endAt: Timestamp.fromDate(new Date('2026-11-06T05:00:00Z')) });
  await event('draft', { status: 'draft' });
  const first = await call('getPublicCatalog', null, { kind: 'events', limit: 1, category: 'sports' });
  assert.equal(first.items.length, 0); assert.ok(first.nextCursor);
  const second = await call('getPublicCatalog', null, { kind: 'events', limit: 1, category: 'sports', cursor: first.nextCursor });
  assert.deepEqual(second.items.map(e => e.id), ['later']); assert.equal(second.nextCursor, null);
  await rejects(call('getPublicCatalog', null, { kind: 'events', feed: 'following' }), 'UNAUTHENTICATED');
  assert.equal((await call('getPublicCatalog', alice, { kind: 'events', feed: 'following' })).items.length, 0);
  await call('followOrganizer', alice, { organizerId: 'test-club' });
  assert.equal((await call('getPublicCatalog', alice, { kind: 'events', feed: 'following' })).items.length, 2);
  assert.deepEqual((await call('getPublicCatalog', alice, { kind: 'events', feed: 'recommended' })).items.map(e => e.id), ['registered']);
  assert.equal((await call('getPublicCatalog', null, { kind: 'events', q: 'test', timeOfDay: 'morning', duration: 'one_to_three_hours', availability: 'available' })).items.length, 2);
  await call('registerForEvent', alice, registration());
  assert.equal((await call('listMyEvents', alice, { tab: 'upcoming', localDate: '2026-11-05' })).items.length, 1);
  assert.equal((await call('listMyEvents', bob)).items.length, 0);
  const ledger = await call('listOwned', alice, { kind: 'ledger', limit: 1 });
  assert.equal(ledger.items.length, 1); assert.ok(ledger.nextCursor);
  assert.equal((await call('listOwned', alice, { kind: 'ledger', limit: 1, cursor: ledger.nextCursor })).items.length, 1);
});

test('FCM token reassignment and rotation remove the previous account binding', async () => {
  const device = { installationId: 'test-installation', token: 'test-only-fcm-token-00000001', platform: 'android' };
  await call('registerDevice', alice, device);
  await call('registerDevice', bob, device);
  assert.equal((await db.doc(`users/${alice.uid}/devices/${device.installationId}`).get()).exists, false);
  assert.equal((await db.doc(`device_bindings/${key(device.token)}`).get()).get('uid'), bob.uid);
  await call('registerDevice', bob, { ...device, token: device.token + '-rotated' });
  assert.equal((await db.doc(`device_bindings/${key(device.token)}`).get()).exists, false);
  await call('unregisterDevice', bob, { installationId: device.installationId });
  assert.equal((await db.collection('device_bindings').get()).size, 0);
});

test('FCM device cap rejects an extra installation without deleting registered tokens', async () => {
  for (let i = 0; i < 10; i++) await call('registerDevice', alice, { installationId: `installation-${i}`, token: `test-token-for-device-number-${i}`, platform: 'android' });
  await rejects(call('registerDevice', alice, { installationId: 'installation-extra', token: 'test-token-for-extra-device-11', platform: 'android' }), 'TOO_MANY_DEVICES');
  assert.equal((await db.collection(`users/${alice.uid}/devices`).get()).size, 10);
  assert.equal((await db.collection('device_bindings').get()).size, 10);
});

test('Vietnamese search matches d-stroke and diacritics without losing accents', async () => {
  await event('vietnamese', { title: 'Ngày hội Đoàn viên', description: 'Sinh hoạt cộng đồng' });
  for (const q of ['ngay hoi doan vien', 'NGÀY HỘI ĐOÀN VIÊN']) {
    const result = await call('getPublicCatalog', null, { kind: 'events', q });
    assert.deepEqual(result.items.map(item => item.id), ['vietnamese']);
    assert.equal(result.items[0].title, 'Ngày hội Đoàn viên');
  }
});

test('cancelled owner can compete for the reopened seat with a new ticket', async () => {
  const first = await call('registerForEvent', alice, registration('first-attempt'));
  const oldQr = await call('getTicketQr', alice, { eventId: 'registered' });
  await call('cancelRegistration', alice, { eventId: 'registered', requestId: 'cancel-first' });
  const results = await Promise.allSettled([
    call('registerForEvent', alice, registration('second-attempt')),
    call('registerForEvent', bob, registration('bob-competes')),
  ]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal(results.find(r => r.status === 'rejected').reason.details.code, 'EVENT_FULL');
  if (results[0].status === 'rejected') return;
  assert.notEqual(results[0].value.ticketId, first.ticketId);
  assert.equal((await db.doc(`tickets/${first.ticketId}`).get()).get('status'), 'revoked');
  assert.equal((await db.collection(`registrations/${first.registrationId}/history`).get()).size, 1);
  await db.doc(`staff_assignments/${key(operator.uid, 'registered')}`).set({ staffUid: operator.uid, eventId: 'registered', active: true, permissions: ['verify_ticket'] });
  await rejects(call('verifyRegisteredTicket', operator, { qrPayload: oldQr.qrPayload, requestId: 'old-qr-replay' }), 'NO_ACTIVE_TICKET');
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 115);
});

test('reregistering while the seat is available always creates a new ticket and preserves the cancelled attempt', async () => {
  const first = await call('registerForEvent', alice, registration('first-ticket'));
  const oldQr = await call('getTicketQr', alice, { eventId: 'registered' });
  await call('cancelRegistration', alice, { eventId: 'registered', requestId: 'cancel-ticket' });
  const second = await call('registerForEvent', alice, registration('second-ticket'));
  assert.notEqual(first.ticketId, second.ticketId);
  assert.equal((await db.collection(`registrations/${first.registrationId}/history`).get()).size, 1);
  await db.doc(`staff_assignments/${key(operator.uid, 'registered')}`).set({ staffUid: operator.uid, eventId: 'registered', active: true, permissions: ['verify_ticket'] });
  await rejects(call('verifyRegisteredTicket', operator, { qrPayload: oldQr.qrPayload, requestId: 'revoked-ticket-qr' }), 'NO_ACTIVE_TICKET');
});

test('only authorized admins consume a sponsor voucher once without another debit', async () => {
  await reward();
  const issued = await call('redeemReward', alice, redemption('admin-voucher'));
  const secret = await call('getVoucherCode', alice, { voucherId: issued.voucherId });
  const admin = { uid: operator.uid, token: { admin: true, email: 'staff@yahoo.com' } };
  const input = { code: secret.code, requestId: 'use-voucher-1' };
  await rejects(call('verifyVoucher', alice, input), 'FORBIDDEN_ADMIN');
  const results = await Promise.allSettled([
    call('verifyVoucher', admin, input),
    call('verifyVoucher', admin, { ...input, requestId: 'use-voucher-2' }),
  ]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal(results.find(r => r.status === 'rejected').reason.details.code, 'USED');
  const winnerId = results[0].status === 'fulfilled' ? input.requestId : 'use-voucher-2';
  assert.equal((await call('verifyVoucher', admin, { ...input, requestId: winnerId })).status, 'used');
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 0);
  const voucher = (await db.doc(`vouchers/${issued.voucherId}`).get()).data();
  assert.equal(voucher.usedBy, admin.uid); assert.ok(voucher.usedAt);
  assert.equal((await db.doc(`redemptions/${issued.redemptionId}`).get()).get('status'), 'used');
  await db.doc(`users/${admin.uid}`).update({ accountStatus: 'disabled' });
  await rejects(call('verifyVoucher', admin, { ...input, requestId: winnerId }), 'ACCOUNT_DISABLED');
  await rejects(call('getOperationStatus', admin, { operationKind: 'verify-voucher', operationId: winnerId }), 'ACCOUNT_DISABLED');
});

test('voucher verification rejects expired codes and forged admin permissions', async () => {
  await reward({ validDays: 1 });
  const issued = await call('redeemReward', alice, redemption('expiring-admin'));
  const secret = await call('getVoucherCode', alice, { voucherId: issued.voucherId });
  const admin = { uid: operator.uid, token: { admin: true, email: 'staff@yahoo.com' } };
  await db.doc(`voucher_admins/${admin.uid}`).set({ active: true });
  await rejects(call('verifyVoucher', operator, { code: secret.code, requestId: 'false-admin-1' }), 'FORBIDDEN_ADMIN');
  now = new Date(now.getTime() + 86_400_000);
  await rejects(call('verifyVoucher', admin, { code: secret.code, requestId: 'expired-admin' }), 'EXPIRED');
  assert.equal((await db.doc(`vouchers/${issued.voucherId}`).get()).get('status'), 'unused');
});

test('physical reward creates no voucher; expired voucher code is denied', async () => {
  await reward({ fulfillmentType: 'physical', redemptionInstructions: 'Test pickup' });
  const physical = await call('redeemReward', alice, redemption('physical-test'));
  assert.equal(physical.voucherId, null); assert.equal((await db.collection('vouchers').get()).size, 0);
  await reward({ fulfillmentType: 'voucher', validDays: 1 });
  const voucher = await call('redeemReward', bob, redemption('expires-test'));
  now = new Date(now.getTime() + 86_400_000);
  await rejects(call('getVoucherCode', bob, { voucherId: voucher.voucherId }), 'EXPIRED');
});

test('real callable transport validates Firebase Auth and returns stable error contract', async () => {
  const base = `http://127.0.0.1:5001/${projectId}/asia-southeast1`;
  const unauthorized = await fetch(`${base}/getAccount`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ data: {} }) });
  assert.equal(unauthorized.status, 401);
  assert.equal((await unauthorized.json()).error.details.code, 'UNAUTHENTICATED');
  const signup = await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=emulator-only', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email: `transport-${Date.now()}@gmail.com`, password: 'emulator-fixture-only-123', returnSecureToken: true }) });
  const session = await signup.json(); assert.ok(session.idToken);
  const response = await fetch(`${base}/initializeUser`, { method: 'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${session.idToken}` }, body: JSON.stringify({ data: {} }) });
  assert.equal(response.status, 200);
  assert.equal((await response.json()).result.wallet.availableCoins, 200);
});


test('verified registration QR unlocks a milestone and manual claim adds only its bonus', async () => {
  await db.doc('milestones/qr-first').set({ title: 'Test first event', description: 'Test fixture', metric: 'verified_events', requiredEvents: 1, rewardCoins: 50, sortOrder: 1, active: true, version: 1 });
  await call('registerForEvent', alice, registration('milestone-register'));
  assert.equal((await call('getEventMilestones')).verifiedEventCount, 0);
  const qr = await call('getTicketQr', alice, { eventId: 'registered' });
  await db.doc(`staff_assignments/${key(operator.uid, 'registered')}`).set({ staffUid: operator.uid, eventId: 'registered', active: true, permissions: ['verify_ticket'] });
  await call('verifyRegisteredTicket', operator, { qrPayload: qr.qrPayload, requestId: 'milestone-staff-scan' });
  assert.equal((await call('getEventMilestones')).verifiedEventCount, 1);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 300);
  await call('claimEventMilestone', alice, { milestoneId: 'qr-first', expectedVersion: 1 });
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 350);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('heldCoins'), 0);
});
