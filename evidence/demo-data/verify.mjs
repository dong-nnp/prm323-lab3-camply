import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
const require = createRequire(import.meta.url), cli = join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
const auth = require(join(cli, 'auth.js')), { requireAuth } = require(join(cli, 'requireAuth.js')), { Client } = require(join(cli, 'apiv2.js'));
const project = 'prm393-31822', batch = 'evia-demo-20261105-v1', options = { project, nonInteractive: true };
auth.setActiveAccount(options, auth.getAllAccounts().find(a => a.user.email === 'toilakiet24@gmail.com'));
await requireAuth(options);
const db = new Client({ urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1' });
const identity = new Client({ urlPrefix: 'https://identitytoolkit.googleapis.com', apiVersion: 'v1' });
const root = `projects/${project}/databases/(default)/documents`;
const catalog = JSON.parse(await readFile(new URL('../../firebase/demo-catalog.json', import.meta.url), 'utf8'));
const credentials = JSON.parse(await readFile(new URL('../../.local/demo-operators-20261105/accounts.json', import.meta.url), 'utf8'));
const config = JSON.parse(await readFile(new URL('../../android/app/google-services.json', import.meta.url), 'utf8'));
const apiKey = config.client.find(c => c.client_info.android_client_info.package_name === 'com.example.prm393_lab03').api_key[0].current_key;
const decode = v => 'nullValue' in v ? null : 'timestampValue' in v ? new Date(v.timestampValue).toISOString() : 'integerValue' in v ? Number(v.integerValue) : 'doubleValue' in v ? v.doubleValue : 'stringValue' in v ? v.stringValue : 'booleanValue' in v ? v.booleanValue : 'arrayValue' in v ? (v.arrayValue.values ?? []).map(decode) : Object.fromEntries(Object.entries(v.mapValue.fields ?? {}).map(([k,v]) => [k,decode(v)]));
async function read(path) { return decode({ mapValue: { fields: (await db.get(`${root}/${path}`)).body.fields } }); }
async function invoke(name, data = {}, token) {
  const r = await fetch(`https://asia-southeast1-${project}.cloudfunctions.net/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify({ data }) });
  return { status: r.status, body: await r.json() };
}
const catalogChecks = [];
for (const [collection, rows] of Object.entries(catalog)) {
  for (const row of rows) {
    const actual = await read(`${collection}/${row.id}`);
    for (const [field, value] of Object.entries(row).filter(([k]) => k !== 'id')) assert.deepEqual(actual[field], value, `${collection}/${row.id}.${field}`);
    assert.equal(actual.isDemo, true); assert.equal(actual.seedBatchId, batch);
    if (collection === 'events') assert.equal(actual.registeredCount, 0);
    if (collection === 'organizers') assert.equal(actual.followerCount, 0);
  }
  if (collection === 'milestones') continue;
  const response = await invoke('getPublicCatalog', { kind: collection, limit: 50 });
  assert.equal(response.status, 200);
  const expected = rows.filter(r => collection !== 'events' || r.status === 'published');
  assert.equal(response.body.result.items.length, expected.length);
  catalogChecks.push({ kind: collection, storedCount: rows.length, publicCount: expected.length, httpStatus: response.status });
}
const full = await invoke('getEvent', { eventId: 'demo-full-event' });
const last = await invoke('getEvent', { eventId: 'demo-last-ticket' });
assert.equal(full.body.result.spotsRemaining, 0); assert.equal(last.body.result.spotsRemaining, 1);
const cafe = await invoke('getReward', { rewardId: 'demo-cafe' }); assert.equal(cafe.body.result.priceCoins, 200);
const safeAccounts = [];
for (const operator of credentials.accounts) {
  const r = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: operator.email, password: operator.password, returnSecureToken: true }) });
  const session = await r.json(); assert.equal(r.status, 200); assert.equal(session.localId, operator.uid);
  const token = session.idToken;
  const user = (await identity.post(`projects/${project}/accounts:lookup`, { localId: [operator.uid] }, { skipLog: { body: true, resBody: true } })).body.users[0];
  const claims = JSON.parse(user.customAttributes);
  assert.equal(claims[operator.role], true); assert.equal(claims[operator.role === 'staff' ? 'admin' : 'staff'], undefined);
  assert.equal(user.emailVerified ?? false, false); assert.equal(user.disabled ?? false, false);
  const account = await invoke('getAccount', {}, token); assert.equal(account.status, 200);
  assert.equal(account.body.result.profile.onboardingCompleted, true);
  assert.equal(account.body.result.wallet.availableCoins, 200); assert.equal(account.body.result.wallet.heldCoins, 0);
  assert.equal(account.body.result.interestOptions.length, 10);
  const progress = await invoke('getEventMilestones', {}, token);
  assert.equal(progress.body.result.verifiedEventCount, 0); assert.equal(progress.body.result.totalMilestones, 5);
  const owned = await invoke('listOwned', { kind: 'ledger', limit: 50 }, token);
  assert.equal(owned.body.result.items.length, 1); assert.equal(owned.body.result.items[0].type, 'signup_bonus');
  const existing = await read('milestones/first-event');
  const milestone = { id: 'first-event', ...Object.fromEntries(['title','description','metric','requiredEvents','rewardCoins','sortOrder','active'].map(k => [k,existing[k]])) };
  // Invalid expectedVersion stops before writes; the resulting error proves the role checks ran.
  const adminCheck = await invoke('upsertEventMilestone', { milestone, expectedVersion: 0 }, token);
  assert.equal(adminCheck.body.error.details.code, operator.role === 'admin' ? 'VERSION_CONFLICT' : 'FORBIDDEN_ADMIN');
  const staffCheck = await invoke('issueWalkInQr', { eventId: 'demo-mobile-workshop' }, token);
  assert.equal(staffCheck.body.error.details.code, operator.role === 'staff' ? 'WRONG_PARTICIPATION_MODE' : 'FORBIDDEN_STAFF');
  const voucherCheck = await invoke('verifyVoucher', { code: 'A'.repeat(43), requestId: 'readonly-demo-role-check' }, token);
  assert.equal(voucherCheck.body.error.details.code, operator.role === 'admin' ? 'VOUCHER_UNAVAILABLE' : 'FORBIDDEN_ADMIN');
  const privateRead = await fetch(`https://firestore.googleapis.com/v1/${root}/${operator.role === 'staff' ? 'voucher_admins' : 'milestone_admins'}/${operator.uid}`, { headers: { Authorization: `Bearer ${token}` } });
  assert.equal(privateRead.status, 403);
  safeAccounts.push({ uid: operator.uid, role: operator.role, passwordSignIn: true, profileRead: true, interestOptions: 10, availableCoins: 200, ledgerCount: 1, verifiedAttendance: 0, oppositeRoleDenied: true, appRoleConfirmedWithoutWrites: true, privateRoleDocReadStatus: privateRead.status });
}
const applied = JSON.parse(await readFile(new URL('applied.json', import.meta.url), 'utf8'));
for (const account of applied.operators) for (const path of account.assignedDocuments) {
  const role = await read(path); assert.equal(role.active, true); assert.equal(role.seedBatchId, batch);
  if (path.startsWith('staff_assignments/')) { assert.equal(role.staffUid, account.uid); assert.deepEqual(role.permissions, ['verify_ticket','issue_walk_in']); assert(catalog.events.some(e => e.id === role.eventId && e.status === 'published')); }
}
const counts = {};
for (const collection of ['interests','organizers','events','rewards','milestones','users','wallets','staff_assignments','voucher_admins','milestone_admins','attendance','registrations','notifications','operation_receipts','checkin_tokens','checkin_codes','milestone_audit']) {
  const r = await db.post(`${root}:runAggregationQuery`, { structuredAggregationQuery: { structuredQuery: { from: [{collectionId:collection}] }, aggregations: [{ count: {}, alias: 'n' }] } });
  counts[collection] = Number(r.body[0].result.aggregateFields.n.integerValue);
}
assert.deepEqual(counts, { interests:10,organizers:5,events:12,rewards:5,milestones:5,users:2,wallets:2,staff_assignments:11,voucher_admins:1,milestone_admins:1,attendance:0,registrations:0,notifications:0,operation_receipts:0,checkin_tokens:0,checkin_codes:0,milestone_audit:0 });
const result = { project, batch, verifiedAt: new Date().toISOString(), counts, catalogChecks, accounts: safeAccounts, cafePriceCoins:200, fullEventSpots:0, lastTicketSpots:1, positiveAttendanceOrRedemptionAttempted:false, roleChecksCreatedNoTransactions:true };
await writeFile(new URL('verification.json', import.meta.url), JSON.stringify(result, null, 2));
console.log(JSON.stringify(result, null, 2));
