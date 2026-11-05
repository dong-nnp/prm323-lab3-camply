// Read-only release checks: no Auth accounts, attendance, wallet or catalog mutations.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { readFile, writeFile } from 'node:fs/promises';
const require = createRequire(import.meta.url), cli = 'C:/Users/toila/AppData/Roaming/npm/node_modules/firebase-tools/lib/';
const auth = require(cli + 'auth.js'), { requireAuth } = require(cli + 'requireAuth.js'), { Client } = require(cli + 'apiv2.js');
const project = 'prm393-31822', region = 'asia-southeast1', options = { project, nonInteractive: true };
const account = auth.getAllAccounts().find(a => a.user.email === 'toilakiet24@gmail.com');
assert(account, 'Authorized CLI account required');
auth.setActiveAccount(options, account);
await requireAuth(options);
const client = (host, version = 'v1') => new Client({ urlPrefix: `https://${host}.googleapis.com`, apiVersion: version });
const firestore = client('firestore'), root = `projects/${project}/databases/(default)/documents`;
const functions = (await client('cloudfunctions', 'v2').get(`projects/${project}/locations/${region}/functions`)).body.functions;
const exports = [...(await readFile(new URL('../../functions/src/index.ts', import.meta.url), 'utf8')).matchAll(/^export const (\w+)\s*=/gm)].map(m => m[1]).sort();
assert.equal(exports.length, 41);
assert.deepEqual(functions.map(f => f.name.split('/').at(-1)).sort(), exports);
assert(functions.every(f => f.state === 'ACTIVE'));
const hashes = [...new Set(functions.map(f => f.labels?.['firebase-functions-hash']))];
assert.equal(hashes.length, 1);
assert(hashes[0]);
const run = await Promise.all(functions.map(async f => {
  const service = (await client('run', 'v2').get(f.serviceConfig.service)).body;
  assert.equal(service.terminalCondition.state, 'CONDITION_SUCCEEDED');
  assert.equal(service.latestReadyRevision, service.latestCreatedRevision);
  return { name: f.name.split('/').at(-1), state: f.state, latestReadyRevision: service.latestReadyRevision, updateTime: f.updateTime };
}));
const fieldChecks = [];
for (const [collection, field] of [['following','organizerId'],['event_intents','eventId']]) {
  const metadata = (await firestore.get(`projects/${project}/databases/(default)/collectionGroups/${collection}/fields/${field}`)).body;
  const groupIndex = metadata.indexConfig.indexes.find(i => i.queryScope === 'COLLECTION_GROUP' && i.fields.some(f => f.fieldPath === field && f.order === 'ASCENDING'));
  assert.equal(groupIndex?.state, 'READY');
  const query = (await firestore.post(`${root}:runQuery`, { structuredQuery: { from: [{ collectionId: collection, allDescendants: true }], where: { fieldFilter: { field: { fieldPath: field }, op: 'EQUAL', value: { stringValue: 'backend-readonly-probe' } } }, orderBy: [{ field: { fieldPath: '__name__' }, direction: 'ASCENDING' }], limit: 100 } })).body;
  assert.equal(query.filter(row => row.document).length, 0);
  fieldChecks.push({ collection, field, state: groupIndex.state, queryPassed: true });
}
const scheduler = (await client('cloudscheduler').get(`projects/${project}/locations/${region}/jobs`)).body.jobs;
assert.equal(scheduler.length, 3);
const reminder = scheduler.find(j => j.name.includes('eventReminderSchedule'));
assert(reminder);
assert.equal(reminder.state, 'ENABLED');
assert.equal(reminder.schedule, 'every 15 minutes');
assert.equal(reminder.timeZone, 'Asia/Ho_Chi_Minh');
assert.equal(reminder.httpTarget.uri, `https://${region}-${project}.cloudfunctions.net/eventReminderSchedule`);
const jobFunction = functions.find(f => f.name.endsWith('/eventReminderSchedule'));
const policy = (await client('run', 'v2').get(`${jobFunction.serviceConfig.service}:getIamPolicy`)).body;
assert(!policy.bindings?.some(b => b.role === 'roles/run.invoker' && b.members?.some(m => m === 'allUsers' || m === 'allAuthenticatedUsers')));
assert(policy.bindings?.some(b => b.role === 'roles/run.invoker' && b.members?.includes(`serviceAccount:${reminder.httpTarget.oidcToken.serviceAccountEmail}`)));
const checks = [];
for (const name of ['verifyWalkInCode', 'verifyRegisteredCode']) {
  const response = await fetch(`https://${region}-${project}.cloudfunctions.net/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ data: { code: '2222-2222', requestId: 'readonly-probe-001' } }) });
  const body = await response.json();
  assert.equal(response.status, 401);
  assert.equal(body.error.details.code, 'UNAUTHENTICATED');
  checks.push({ name, httpStatus: response.status, code: body.error.details.code });
}
for (const kind of ['events', 'interests', 'organizers', 'rewards']) {
  const response = await fetch(`https://${region}-${project}.cloudfunctions.net/getPublicCatalog`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ data: { kind } }) });
  const body = await response.json();
  assert.equal(response.status, 200);
  assert.equal(body.result.items.length, 0);
  checks.push({ name: 'getPublicCatalog', kind, httpStatus: response.status, count: body.result.items.length });
}
const counts = {};
for (const collection of ['users','wallets','events','organizers','interests','rewards','milestones','attendance','notifications','checkin_tokens','checkin_codes','code_attempts','notification_runs','staff_assignments','voucher_admins']) {
  const response = await firestore.post(`${root}:runAggregationQuery`, { structuredAggregationQuery: { structuredQuery: { from: [{ collectionId: collection }] }, aggregations: [{ count: {}, alias: 'n' }] } });
  counts[collection] = Number(response.body[0].result.aggregateFields.n.integerValue);
  assert.equal(counts[collection], collection === 'milestones' ? 5 : 0);
}
const remote = (await client('firebaseremoteconfig').get(`projects/${project}/remoteConfig`)).body;
assert.equal(remote.parameters.event_milestones_enabled.defaultValue.value, 'true');
const result = { checkedAt: new Date().toISOString(), project, region, totalFunctions: functions.length, allActiveAndReady: true, sourceHash: hashes[0], run, groupIndexes: fieldChecks, scheduler: scheduler.map(j => ({ name: j.name.split('/').at(-1), state: j.state, schedule: j.schedule, timeZone: j.timeZone, lastAttemptTime: j.lastAttemptTime, status: j.status })), reminderInvokerPrivateAndAuthorized: true, checks, counts, remoteConfigVersion: remote.version.versionNumber, boundaries: ['No live business or Auth data was written by these checks', 'FPT guard and positive code/notification behavior verified in Emulator, not via live user transactions', 'Scheduler configuration and IAM are verified; delivery on a real mobile account is not verified'] };
await writeFile(new URL('cloud-verification.json', import.meta.url), JSON.stringify(result, null, 2));
console.log(JSON.stringify(result, null, 2));
