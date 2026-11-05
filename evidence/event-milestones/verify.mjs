import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { readFile, writeFile } from 'node:fs/promises';
const require = createRequire(import.meta.url), cli = 'C:/Users/toila/AppData/Roaming/npm/node_modules/firebase-tools/lib/';
const auth = require(cli + 'auth.js'), { requireAuth } = require(cli + 'requireAuth.js'), { Client } = require(cli + 'apiv2.js');
const project = 'prm393-31822', region = 'asia-southeast1', options = { project, nonInteractive: true };
auth.setActiveAccount(options, auth.getAllAccounts().find(a => a.user.email === 'toilakiet24@gmail.com'));
await requireAuth(options);
const client = (domain, version = 'v1') => new Client({ urlPrefix: `https://${domain}.googleapis.com`, apiVersion: version });
const root = `projects/${project}/databases/(default)/documents`;
const functions = (await client('cloudfunctions', 'v2').get(`projects/${project}/locations/${region}/functions`)).body.functions;
assert.equal(functions.length, 37);
assert(functions.every(f => f.state === 'ACTIVE'));
const targets = ['getEventMilestones', 'claimEventMilestone', 'upsertEventMilestone', 'getOperationStatus'];
const deployments = [];
for (const name of targets) {
  const f = functions.find(f => f.name.endsWith('/' + name));
  assert(f);
  const run = (await client('run', 'v2').get(f.serviceConfig.service)).body;
  assert.equal(run.terminalCondition.state, 'CONDITION_SUCCEEDED');
  assert.equal(run.latestReadyRevision, run.latestCreatedRevision);
  deployments.push({ name, state: f.state, updateTime: f.updateTime, uri: f.serviceConfig.uri, latestReadyRevision: run.latestReadyRevision, terminalState: run.terminalCondition.state, sourceHash: f.labels?.['firebase-functions-hash'] });
}
const indexes = (await client('firestore').get(`projects/${project}/databases/(default)/collectionGroups/attendance/indexes`)).body.indexes;
const index = indexes.find(i => ['uid','mode','verifiedAt'].every((field,n) => i.fields[n]?.fieldPath === field));
assert.equal(index?.state, 'READY');
const filter = (fieldPath, op, value) => ({ fieldFilter: { field: { fieldPath }, op, value } });
const aggregate = (await client('firestore').post(`${root}:runAggregationQuery`, { structuredAggregationQuery: { structuredQuery: { from: [{ collectionId: 'attendance' }], where: { compositeFilter: { op: 'AND', filters: [filter('uid','EQUAL',{stringValue:'backend-readonly-probe'}), filter('mode','IN',{arrayValue:{values:[{stringValue:'organizer_scanned_ticket'},{stringValue:'student_scanned_walkin'}]}}),filter('verifiedAt','GREATER_THAN',{timestampValue:'1970-01-01T00:00:00Z'}),filter('verifiedAt','LESS_THAN_OR_EQUAL',{timestampValue:new Date().toISOString()})] } } }, aggregations: [{ count: {}, alias: 'count' }] } })).body;
assert.equal(aggregate[0].result.aggregateFields.count.integerValue, '0');
const rows = JSON.parse(await readFile(new URL('../../firebase/event-milestones.json', import.meta.url), 'utf8')).milestones;
const activeQuery = { structuredQuery: { from: [{collectionId:'milestones'}], where: filter('active','EQUAL',{booleanValue:true}) } };
const publicResponse = await fetch(`https://firestore.googleapis.com/v1/${root}:runQuery`, { method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(activeQuery) });
assert.equal(publicResponse.status,200);
const publicDocs = (await publicResponse.json()).flatMap(r => r.document ? [r.document] : []);
assert.equal(publicDocs.length,5);
for (const expected of rows) {
  const doc = publicDocs.find(d => d.name.endsWith('/'+expected.id));
  assert(doc);
  for (const [field, value] of Object.entries(expected).filter(([k])=>k!=='id')) {
    const actual = doc.fields[field];
    assert.equal(actual.booleanValue ?? actual.stringValue ?? Number(actual.integerValue), value);
  }
  assert.equal(doc.fields.version.integerValue,'1');
}
// Use the existing approved value so even an unexpected Rules failure cannot change economics.
const write = await fetch(`https://firestore.googleapis.com/v1/${root}/milestones/first-event?updateMask.fieldPaths=rewardCoins`, { method:'PATCH',headers:{'Content-Type':'application/json'},body:JSON.stringify({fields:{rewardCoins:{integerValue:'50'}}}) });
assert.equal(write.status,403);
const callableChecks = [];
for (const [name,data] of [['getEventMilestones',{}],['claimEventMilestone',{milestoneId:'first-event',expectedVersion:1}],['upsertEventMilestone',{milestone:rows[0],expectedVersion:0}]]) {
  const response = await fetch(`https://${region}-${project}.cloudfunctions.net/${name}`, { method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({data}) });
  const body = await response.json();
  assert.equal(response.status,401);
  assert.equal(body.error.status,'UNAUTHENTICATED');
  callableChecks.push({name,httpStatus:response.status,error:body.error.status});
}
const rc = (await client('firebaseremoteconfig').get(`projects/${project}/remoteConfig`)).body;
const defaults = JSON.parse(await readFile(new URL('../../firebase/remote-config-defaults.json', import.meta.url),'utf8'));
for (const [key,value] of Object.entries(defaults)) assert.equal(rc.parameters[key].defaultValue.value,String(value));
const result = { project, verifiedAt:new Date().toISOString(), totalFunctions:functions.length, allFunctionsActive:true, deployments, attendanceIndex:{name:index.name,state:index.state,fields:index.fields}, aggregationProbeCount:0, publicMilestones:rows.map(({id,requiredEvents,rewardCoins})=>({id,requiredEvents,rewardCoins})), anonymousWriteStatus:write.status, callableChecks, remoteConfigVersion:rc.version.versionNumber, parameters:defaults, boundaries:['No live user, attendance, wallet, ledger or claim was created or changed','Positive authenticated claim verified in Emulator, not on a real mobile account','UI and admin screens not integrated in this backend-only release'] };
await writeFile(new URL('cloud-verification.json',import.meta.url),JSON.stringify(result,null,2));
console.log(JSON.stringify(result,null,2));
