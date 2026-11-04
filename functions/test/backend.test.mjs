import assert from 'node:assert/strict';
import test, { beforeEach, after } from 'node:test';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { createBackend } from '../lib/backend.js';
import { key } from '../lib/shared.js';

const projectId = 'demo-evia-backend';
assert.match(process.env.FIRESTORE_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):/);
assert.match(process.env.FIREBASE_AUTH_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):/);
assert.match(process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):/);
assert.equal(process.env.GCLOUD_PROJECT, projectId, 'Tests must never target a live project');
const app = initializeApp({ projectId }, 'backend-tests'), db = getFirestore(app);
let now = new Date('2026-11-04T03:00:00Z');
const api = createBackend(db, () => now);
const alice = { uid: 'test-alice', token: {} }, bob = { uid: 'test-bob', token: {} }, operator = { uid: 'test-staff', token: { staff: true } };
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
const registration = (requestId = 'register-0001', eventId = 'registered') => ({ eventId, requestId, expectedDepositCoins: 50, acceptedTermsVersion: 'v1', attendeeInput: { fullName: 'Test Student', studentId: 'TEST-01', universityEmail: 'student@example.test' } });
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
test('cancel forfeits once and opens exactly one place to another user', async () => {
  const registered = await call('registerForEvent', alice, registration());
  assert.equal((await call('registerForEvent', alice, registration())).ticketId, registered.ticketId);
  const input = { eventId: 'registered', requestId: 'cancel-00001' };
  await Promise.all([call('cancelRegistration', alice, input), call('cancelRegistration', alice, input)]);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 150);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('heldCoins'), 0);
  assert.equal((await db.doc('events/registered').get()).get('registeredCount'), 0);
  assert.equal((await db.doc(`tickets/${registered.ticketId}`).get()).get('status'), 'revoked');
  await call('registerForEvent', bob, registration('bob-reopen-1'));
  await rejects(call('cancelRegistration', alice, { ...input, requestId: 'cancel-00002' }), 'ALREADY_CANCELLED');
  assert.equal((await db.doc('events/registered').get()).get('registeredCount'), 1);
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
  await rejects(call('grantMonthlyGift'), 'POLICY_NOT_APPROVED');
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
  await rejects(call('verifyVoucher', operator, { code: secret.code, requestId: 'cashier-test' }), 'CASHIER_POLICY_NOT_APPROVED');
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

test('Vietnamese search matches d-stroke and diacritics without losing accents', async () => {
  await event('vietnamese', { title: 'Ngày hội Đoàn viên', description: 'Sinh hoạt cộng đồng' });
  for (const q of ['ngay hoi doan vien', 'NGÀY HỘI ĐOÀN VIÊN']) {
    const result = await call('getPublicCatalog', null, { kind: 'events', q });
    assert.deepEqual(result.items.map(item => item.id), ['vietnamese']);
    assert.equal(result.items[0].title, 'Ngày hội Đoàn viên');
  }
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
  const signup = await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=emulator-only', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email: `transport-${Date.now()}@example.test`, password: 'emulator-fixture-only-123', returnSecureToken: true }) });
  const session = await signup.json(); assert.ok(session.idToken);
  const response = await fetch(`${base}/initializeUser`, { method: 'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${session.idToken}` }, body: JSON.stringify({ data: {} }) });
  assert.equal(response.status, 200);
  assert.equal((await response.json()).result.wallet.availableCoins, 200);
});
