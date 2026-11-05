import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import test, { after } from 'node:test';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { createBackend } from '../lib/backend.js';
import { updateMilestoneDefaults } from '../lib/admin_integrations.js';

const projectId = 'demo-evia-backend';
assert.equal(process.env.GCLOUD_PROJECT, projectId);
assert.match(process.env.FIRESTORE_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
const app = initializeApp({ projectId }, 'admin-operations-test');
const db = getFirestore(app);
const api = createBackend(db, () => new Date('2020-11-07T03:00:00Z'));
const admin = { uid: 'admin-test', token: { admin: true, email: 'admin@example.com' } };
const member = { uid: 'member-test', token: { email: 'member@example.com' } };
const call = (name, data = {}, actor = admin) => api.invoke(name, actor, data);
const prefix = 'admin-' + randomUUID();
const organizerId = prefix + '-organizer';
const sourceRef = 'https://example.com/test-catalog';
const event = {
  id: prefix + '-event', organizerId, title: 'Admin test event', description: 'Fixture',
  category: 'demo', tags: [], status: 'draft', visibility: 'public',
  startAt: '2020-11-10T03:00:00.000Z', endAt: '2020-11-10T05:00:00.000Z',
  checkInStartAt: '2020-11-10T02:00:00.000Z', checkInEndAt: '2020-11-10T04:00:00.000Z',
  timezone: 'Asia/Ho_Chi_Minh', venue: { name: 'Test hall' }, audience: { scope: 'everyone' },
  schedule: [], participationMode: 'walk_in', capacity: null, depositCoins: 0, attendanceRewardCoins: 0, sourceRef,
};
const voucher = {
  id: prefix + '-voucher', title: 'Admin test voucher', description: 'Fixture', category: 'demo',
  priceCoins: 25, stockRemaining: 5, status: 'inactive', usageLocations: [], termsText: 'Original',
  termsVersion: 'v1', redemptionSteps: ['Show code'], fulfillmentType: 'voucher', sourceRef,
};
const appError = code => error => error.details?.code === code;
after(() => deleteApp(app));

test('admin endpoints require an admin claim before exposing data or attempting cloud access', async () => {
  for (const name of [
    'listAdminEvents', 'getAdminEvent', 'createEvent', 'updateEvent', 'publishEvent',
    'listAdminRewards', 'getAdminReward', 'createReward', 'updateReward',
    'getAdminRemoteConfig', 'publishAdminRemoteConfig', 'getAdminAnalyticsReport', 'getAdminCrashlyticsReport',
  ]) {
    await assert.rejects(call(name, {}, null), appError('UNAUTHENTICATED'));
    await assert.rejects(call(name, {}, member), appError('FORBIDDEN_ADMIN'));
  }
});

test('admin can create, edit and publish an event with revision checks and mobile-compatible fields', async () => {
  await db.doc('organizers/' + organizerId).set({ name: 'Test organizer', published: true });
  await call('createEvent', { event });
  const draft = await call('getAdminEvent', { id: event.id });
  assert.equal(draft.status, 'draft');
  assert.equal(draft.startAt, event.startAt);
  assert.equal(draft.registeredCount, 0);
  assert.ok((await call('listAdminEvents', { limit: 50 })).items.some(item => item.id === event.id));
  await assert.rejects(call('getEvent', { eventId: event.id }, member), appError('EVENT_NOT_FOUND'));
  await call('updateEvent', { event: { ...event, title: 'Updated' }, revision: draft.revision });
  await assert.rejects(call('publishEvent', { id: event.id, revision: draft.revision }), appError('CATALOG_CHANGED'));
  const updated = await call('getAdminEvent', { id: event.id });
  await call('publishEvent', { id: event.id, revision: updated.revision });
  await call('publishEvent', { id: event.id, revision: updated.revision });
  const published = await call('getEvent', { eventId: event.id }, member);
  assert.equal(published.title, 'Updated');
  assert.equal(published.status, 'published');
  assert.equal(published.registeredCount, 0);
});

test('admin can activate vouchers without overwriting a concurrent stock decrement or reusing changed terms', async () => {
  await call('createReward', { reward: voucher });
  await assert.rejects(call('getReward', { rewardId: voucher.id }, member), appError('REWARD_NOT_FOUND'));
  const current = await call('getAdminReward', { id: voucher.id });
  await assert.rejects(call('updateReward', { reward: { ...voucher, termsText: 'Changed' }, revision: current.revision }), appError('TERMS_VERSION_REQUIRED'));
  await call('updateReward', { reward: { ...voucher, status: 'active' }, revision: current.revision });
  const active = await call('getAdminReward', { id: voucher.id });
  await db.doc('rewards/' + voucher.id).update({ stockRemaining: 4 });
  await assert.rejects(call('updateReward', { reward: { ...voucher, status: 'active', priceCoins: 30 }, revision: active.revision }), appError('CATALOG_CHANGED'));
  assert.equal((await call('getReward', { rewardId: voucher.id }, member)).stockRemaining, 4);
});

test('admin can page through physical rewards and vouchers and read physical reward details', async () => {
  const cursor = prefix + '-list';
  const physical = { ...voucher, id: cursor + '-a', fulfillmentType: 'physical', status: 'active' };
  const listedVoucher = { ...voucher, id: cursor + '-b' };
  await db.doc('rewards/' + physical.id).set(physical);
  await call('createReward', { reward: listedVoucher });

  const first = await call('listAdminRewards', { cursor, limit: 1 });
  assert.equal(first.items[0].fulfillmentType, 'physical');
  assert.equal(first.nextCursor, physical.id);
  const second = await call('listAdminRewards', { cursor: first.nextCursor, limit: 1 });
  assert.equal(second.items[0].id, listedVoucher.id);
  assert.equal(second.items[0].fulfillmentType, 'voucher');
  assert.equal((await call('getAdminReward', { id: physical.id })).fulfillmentType, 'physical');
});

test('Remote Config edits only the two defaults and refuses a stale template revision', () => {
  const conditions = [{ name: 'QA', expression: "app.id == 'example'" }];
  const unrelated = { defaultValue: { value: 'keep me' } };
  const conditionalValues = { QA: { value: 'false' } };
  const template = {
    etag: 'version-one', conditions, parameters: { another_flag: unrelated },
    parameterGroups: { Features: { parameters: {
      event_milestones_enabled: { defaultValue: { value: 'false' }, conditionalValues },
    } } },
  };
  assert.throws(() => updateMilestoneDefaults(template, { etag: 'older', enabled: true, intro: 'New intro' }), appError('REMOTE_CONFIG_CHANGED'));
  updateMilestoneDefaults(template, { etag: 'version-one', enabled: true, intro: 'New intro' });
  assert.deepEqual(template.conditions, conditions);
  assert.deepEqual(template.parameters.another_flag, unrelated);
  assert.deepEqual(template.parameterGroups.Features.parameters.event_milestones_enabled, {
    defaultValue: { value: 'true' }, conditionalValues, valueType: 'BOOLEAN',
  });
  assert.equal(template.parameters.event_milestones_intro.defaultValue.value, 'New intro');
});
