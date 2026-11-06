import assert from 'node:assert/strict';
import test, { beforeEach, after } from 'node:test';
import { readFile } from 'node:fs/promises';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { createBackend } from '../lib/backend.js';
import { key } from '../lib/shared.js';

const projectId = 'demo-evia-backend';
assert.equal(process.env.GCLOUD_PROJECT, projectId);
assert.match(process.env.FIRESTORE_EMULATOR_HOST ?? '', /^(localhost|127\.0\.0\.1):\d+$/);
assert.match(process.env.FIREBASE_AUTH_EMULATOR_HOST ?? '', /^(localhost|127\.0\.0\.1):\d+$/);
const app = initializeApp({ projectId }, 'milestone-tests'), db = getFirestore(app);
const now = new Date('2026-11-05T03:00:00Z'), api = createBackend(db, () => now);
const alice = { uid: 'milestone-alice', token: { email: 'milestonealice@gmail.com' } }, bob = { uid: 'milestone-bob', token: { email: 'milestonebob@outlook.com' } };
const admin = { uid: 'milestone-admin', token: { admin: true, email: 'milestoneadmin@yahoo.com' } };
const call = (name, actor = alice, input = {}) => api.invoke(name, actor, input);
const rejects = (promise, code) => assert.rejects(promise, e => e.details?.code === code, code);
const policy = JSON.parse(await readFile(new URL('../../firebase/event-milestones.json', import.meta.url), 'utf8')).milestones;
const firstId = policy[0].id;
async function attend(count, actor = alice) {
  for (let i = 0; i < count; i++) await db.doc(`attendance/${key(actor.uid, 'past-event-' + i)}`).set({ uid: actor.uid, eventId: 'past-event-' + i, mode: i % 2 ? 'student_scanned_walkin' : 'organizer_scanned_ticket', verifiedAt: Timestamp.fromDate(new Date('2026-10-01T03:00:00Z')) });
}
beforeEach(async () => {
  const clear = await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: 'DELETE' });
  assert.equal(clear.status, 200);
  for (const id of ['a', 'b', 'c']) await db.doc(`interests/${id}`).set({ status: 'active', label: id });
  for (const actor of [alice, bob, admin]) {
    await call('initializeUser', actor);
    await call('saveInterests', actor, { interests: ['a', 'b', 'c'] });
  }
  for (const milestone of policy) await db.doc(`milestones/${milestone.id}`).set({ ...milestone, version: 1 });
});
after(() => deleteApp(app));

test('approved five milestone policies are preserved as data, not a fixed-size runtime list', () => {
  assert.deepEqual(policy.map(m => [m.requiredEvents, m.rewardCoins]), [[1, 50], [3, 100], [5, 150], [10, 300], [20, 500]]);
});

test('progress includes historical verified attendance, excludes registration/Going/daily and other users', async () => {
  await attend(3); await attend(20, bob);
  await db.doc(`registrations/${key(alice.uid, 'not-attended')}`).set({ uid: alice.uid, state: 'registered' });
  await db.doc(`users/${alice.uid}/event_intents/not-attended`).set({ eventId: 'not-attended' });
  await db.doc('attendance/pending-fixture').set({ uid: alice.uid, mode: 'student_scanned_walkin' });
  await db.doc('attendance/future-fixture').set({ uid: alice.uid, mode: 'student_scanned_walkin', verifiedAt: Timestamp.fromDate(new Date('2027-01-01T00:00:00Z')) });
  await db.doc('attendance/unverified-fixture').set({ uid: alice.uid, mode: 'client_reported', verifiedAt: Timestamp.fromDate(now) });
  await call('claimDailyCheckin');
  const result = await call('getEventMilestones');
  assert.equal(result.verifiedEventCount, 3); assert.equal(result.unlockedCount, 2);
  assert.equal(result.claimedCount, 0); assert.equal(result.totalMilestones, 5);
  assert.equal(result.currentMilestone.requiredEvents, 3);
  assert.equal(result.nextMilestone.requiredEvents, 5); assert.equal(result.nextMilestone.progressPercent, 60);
  assert.equal(result.items[0].canClaim, true);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 205);
  await rejects(call('getEventMilestones', null), 'UNAUTHENTICATED');
});

test('unearned/client-forged claims do not create money or claim records', async () => {
  await rejects(call('claimEventMilestone', alice, { milestoneId: firstId, expectedVersion: 1 }), 'MILESTONE_NOT_UNLOCKED');
  await rejects(call('claimEventMilestone', alice, { milestoneId: firstId, expectedVersion: 1, uid: bob.uid, rewardCoins: 9999 }), 'VALIDATION_FAILED');
  await rejects(call('claimEventMilestone', null, { milestoneId: firstId, expectedVersion: 1 }), 'UNAUTHENTICATED');
  assert.equal((await db.collection(`users/${alice.uid}/milestone_claims`).get()).size, 0);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 200);
});

test('concurrent retries and restarts award a milestone only once with ledger and receipt', async () => {
  await attend(1);
  await db.doc(`wallets/${alice.uid}`).update({ heldCoins: 25 });
  const input = { milestoneId: firstId, expectedVersion: 1 };
  const results = await Promise.all([call('claimEventMilestone', alice, input), call('claimEventMilestone', alice, input)]);
  assert.ok(results.every(r => r.coinsGranted === 50));
  await createBackend(db, () => now).invoke('claimEventMilestone', alice, input);
  const wallet = (await db.doc(`wallets/${alice.uid}`).get()).data();
  assert.equal(wallet.availableCoins, 250); assert.equal(wallet.heldCoins, 25);
  assert.equal((await db.collection(`users/${alice.uid}/milestone_claims`).get()).size, 1);
  const ledger = await db.collection(`wallets/${alice.uid}/ledger`).where('type', '==', 'milestone_reward').get();
  assert.equal(ledger.size, 1); assert.equal(ledger.docs[0].get('deltaAvailable'), 50);
  const receipt = await call('getOperationStatus', alice, { operationKind: 'milestone', operationId: firstId });
  assert.equal(receipt.result.coinsGranted, 50);
  const progress = await call('getEventMilestones');
  assert.equal(progress.items[0].claimed, true); assert.equal(progress.items[0].canClaim, false);
  assert.equal(progress.claimedCount, 1);
  assert.equal((await call('getEventMilestones', bob)).claimedCount, 0);
});

test('all five manual claims total 1100 coins and never auto-grant from progress reads', async () => {
  await attend(20);
  assert.equal((await call('getEventMilestones')).unlockedCount, 5);
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 200);
  for (const milestone of [...policy].reverse()) await call('claimEventMilestone', alice, { milestoneId: milestone.id, expectedVersion: 1 });
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 1300);
  assert.equal((await call('getEventMilestones')).nextMilestone, null);
});

test('admin adds/edits goals with version guards; claimed history never pays a second time', async () => {
  await attend(3);
  const milestone = { id: 'extra-fixture', title: 'Test fixture', description: 'Test only', requiredEvents: 2, rewardCoins: 25, sortOrder: 6, active: true, metric: 'verified_events' };
  await rejects(call('upsertEventMilestone', alice, { milestone, expectedVersion: 0 }), 'FORBIDDEN_ADMIN');
  await rejects(call('upsertEventMilestone', { ...admin, token: { email: admin.token.email } }, { milestone, expectedVersion: 0 }), 'FORBIDDEN_ADMIN');
  await call('upsertEventMilestone', admin, { milestone, expectedVersion: 0 });
  assert.equal((await call('getEventMilestones')).totalMilestones, 6);
  assert.equal((await call('claimEventMilestone', alice, { milestoneId: milestone.id, expectedVersion: 1 })).coinsGranted, 25);
  const edited = { ...milestone, title: 'Updated title', requiredEvents: 4, rewardCoins: 1000 };
  await rejects(call('upsertEventMilestone', admin, { milestone: edited, expectedVersion: 0 }), 'VERSION_CONFLICT');
  await call('upsertEventMilestone', admin, { milestone: edited, expectedVersion: 1 });
  assert.equal((await call('claimEventMilestone', alice, { milestoneId: milestone.id, expectedVersion: 2 })).coinsGranted, 25);
  const earned = (await call('getEventMilestones')).items.find(m => m.id === milestone.id);
  assert.equal(earned.rewardCoins, 25); assert.equal(earned.requiredEvents, 2); assert.equal(earned.title, 'Test fixture');
  await attend(4, bob);
  await rejects(call('claimEventMilestone', bob, { milestoneId: milestone.id, expectedVersion: 1 }), 'MILESTONE_CHANGED');
  assert.equal((await call('claimEventMilestone', bob, { milestoneId: milestone.id, expectedVersion: 2 })).coinsGranted, 1000);
  assert.equal((await db.collection('milestone_audit').get()).size, 2);
  await db.doc(`users/${admin.uid}`).update({ accountStatus: 'disabled' });
  await rejects(call('upsertEventMilestone', admin, { milestone, expectedVersion: 2 }), 'ACCOUNT_DISABLED');
});

test('disabled and malformed server policies cannot award coins', async () => {
  await attend(20);
  await db.doc(`milestones/${firstId}`).update({ active: false });
  await rejects(call('claimEventMilestone', alice, { milestoneId: firstId, expectedVersion: 1 }), 'MILESTONE_INACTIVE');
  await db.doc(`milestones/${policy[1].id}`).update({ rewardCoins: -100 });
  await rejects(call('claimEventMilestone', alice, { milestoneId: policy[1].id, expectedVersion: 1 }), 'MILESTONE_CONFIG_INVALID');
  assert.equal((await db.doc(`wallets/${alice.uid}`).get()).get('availableCoins'), 200);
});

test('Rules protect definitions/admin/audit/claims and allow only the owner to read a claim', async () => {
  await attend(1); await call('claimEventMilestone', alice, { milestoneId: firstId, expectedVersion: 1 });
  async function headers(actor) {
    const token = await getAuth(app).createCustomToken(actor.uid);
    const response = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=emulator-only`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ token, returnSecureToken: true }) });
    return { authorization: `Bearer ${(await response.json()).idToken}`, 'content-type': 'application/json' };
  }
  const a = await headers(alice), b = await headers(bob);
  const base = `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${projectId}/databases/(default)/documents`;
  assert.equal((await fetch(`${base}/milestones/${firstId}`)).status, 200);
  const claim = `users/${alice.uid}/milestone_claims/${firstId}`;
  assert.equal((await fetch(`${base}/${claim}`, { headers: a })).status, 200);
  assert.equal((await fetch(`${base}/${claim}`, { headers: b })).status, 403);
  for (const path of [`milestones/${firstId}`, claim, `milestone_admins/${alice.uid}`]) {
    assert.equal((await fetch(`${base}/${path}`, { method: 'PATCH', headers: a, body: JSON.stringify({ fields: { rewardCoins: { integerValue: '999999' } } }) })).status, 403);
  }
  assert.equal((await fetch(`${base}/milestone_audit/private`, { headers: a })).status, 403);
});
