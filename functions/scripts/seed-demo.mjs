// Explicit owner-authorized demo import. Dry-run by default; no existing content is overwritten.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { createHash, randomBytes } from 'node:crypto';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { catalogSchema } from '../lib/catalog.js';
import { key } from '../lib/shared.js';

const rootDir = fileURLToPath(new URL('../..', import.meta.url)), project = 'prm393-31822';
const batch = 'evia-demo-20261105-v1';
const input = await readFile(join(rootDir, 'firebase/demo-catalog.json'), 'utf8');
const catalog = catalogSchema.parse(JSON.parse(input));
const digest = createHash('sha256').update(input).digest('hex');
const counts = Object.fromEntries(Object.entries(catalog).map(([c, rows]) => [c, rows.length]));
assert.deepEqual(counts, { organizers: 5, events: 12, rewards: 5, interests: 10, milestones: 0 });
assert.equal(catalog.rewards.find(r => r.id === 'demo-cafe').priceCoins, 200);
const recordPaths = Object.entries(catalog).flatMap(([collection, rows]) => rows.map(row => `${collection}/${row.id}`));
assert.equal(new Set(recordPaths).size, 32);
const operatorSpecs = [{ uid: 'evia-demo-staff-v1', role: 'staff', displayName: '[DEMO] Evia Staff', claims: { staff: true, demoSeedBatchId: batch } }, { uid: 'evia-demo-admin-v1', role: 'admin', displayName: '[DEMO] Evia Admin', claims: { admin: true, demoSeedBatchId: batch } }];
const activeEvents = catalog.events.filter(e => e.status === 'published');
if (!process.argv.includes('--apply')) {
  console.log(JSON.stringify({ project, mode: 'DRY RUN', batch, digest, counts, operatorCount: operatorSpecs.length, staffAssignmentCount: activeEvents.length, roles: ['staff:verify_ticket,issue_walk_in (seeded events only)', 'admin:app voucher and milestone management; no Google Cloud IAM'], noNetwork: true }));
  process.exit(0);
}
assert.equal(process.versions.node.split('.')[0], '22');
assert(!process.env.FIRESTORE_EMULATOR_HOST && !process.env.FIREBASE_AUTH_EMULATOR_HOST, 'Do not mix emulator and live seed');
const privateDir = resolve(rootDir, '.local/demo-operators-20261105');
const evidenceDir = resolve(rootDir, 'evidence/demo-data');
await mkdir(evidenceDir, { recursive: true });
const statePath = join(privateDir, 'accounts.json');
let state;
try { state = JSON.parse(await readFile(statePath, 'utf8')); }
catch (error) {
  if (error.code !== 'ENOENT') throw error;
  state = { project, batch, digest, createdAt: new Date().toISOString(), accounts: operatorSpecs.map(spec => ({ ...spec, email: `evia.lab3.${spec.role}.${randomBytes(5).toString('hex')}@fpt.edu.vn`, password: `Evia!${randomBytes(20).toString('base64url')}9aA` })) };
  await writeFile(statePath, JSON.stringify(state, null, 2), { flag: 'wx', mode: 0o600 });
}
assert.equal(state.project, project); assert.equal(state.batch, batch); assert.equal(state.digest, digest);
assert.deepEqual(state.accounts.map(a => a.uid), operatorSpecs.map(a => a.uid));
try {
  const completed = JSON.parse(await readFile(join(evidenceDir, 'applied.json'), 'utf8'));
  assert.equal(completed.batch, batch); assert.equal(completed.catalogDigest, digest);
  console.log(JSON.stringify({ project, batch, status: 'ALREADY APPLIED — no network calls or writes', counts: completed.counts }));
  process.exit(0);
} catch (error) { if (error.code !== 'ENOENT') throw error; }
const require = createRequire(import.meta.url), cli = join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
const auth = require(join(cli, 'auth.js')), { requireAuth } = require(join(cli, 'requireAuth.js')), { Client } = require(join(cli, 'apiv2.js'));
const options = { project, nonInteractive: true };
const account = auth.getAllAccounts().find(a => a.user.email === 'toilakiet24@gmail.com');
assert(account, 'Authorized CLI owner account required'); auth.setActiveAccount(options, account); await requireAuth(options);
const firestore = new Client({ urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1' });
const identity = new Client({ urlPrefix: 'https://identitytoolkit.googleapis.com', apiVersion: 'v1' });
const docRoot = `projects/${project}/databases/(default)/documents`;
const authLog = { skipLog: { body: true, resBody: true, queryParams: true } };
const config = JSON.parse(await readFile(join(rootDir, 'android/app/google-services.json'), 'utf8'));
assert.equal(config.project_info.project_id, project);
const apiKey = config.client.find(c => c.client_info.android_client_info.package_name === 'com.example.prm393_lab03').api_key[0].current_key;
const encode = value => value === null ? { nullValue: null } : Array.isArray(value) ? { arrayValue: { values: value.map(encode) } } : typeof value === 'object' ? { mapValue: { fields: Object.fromEntries(Object.entries(value).map(([k,v]) => [k, k.endsWith('At') && typeof v === 'string' ? { timestampValue: v } : encode(v)])) } } : typeof value === 'boolean' ? { booleanValue: value } : typeof value === 'number' ? { integerValue: String(value) } : { stringValue: value };
function create(path, data) {
  return { update: { name: `${docRoot}/${path}`, fields: encode(data).mapValue.fields }, currentDocument: { exists: false }, updateTransforms: [{ fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' }, { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }] };
}
async function readDocuments(paths) {
  const response = await firestore.post(`${docRoot}:batchGet`, { documents: paths.map(path => `${docRoot}/${path}`) });
  return new Map(response.body.map(row => [row.found?.name ?? row.missing, row.found ?? null]));
}
async function callable(name, token, data = {}) {
  const r = await fetch(`https://asia-southeast1-${project}.cloudfunctions.net/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ data }) });
  const body = await r.json();
  if (!r.ok || body.error) throw new Error(`${name}: ${body.error?.details?.code ?? r.status}`);
  return body.result;
}
async function login(operator) {
  const r = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: operator.email, password: operator.password, returnSecureToken: true }) });
  const session = await r.json(); assert(r.ok && session.idToken && session.localId === operator.uid, 'Demo account password sign-in must succeed');
  return session.idToken;
}
let stage = 'preflight';
try {
  const existing = await readDocuments(recordPaths);
  for (const doc of existing.values()) if (doc) assert.equal(doc.fields.seedBatchId?.stringValue, batch, 'Refuse to overwrite existing data outside this seed');
  const priorAuth = (await identity.post(`projects/${project}/accounts:lookup`, { localId: state.accounts.map(a => a.uid), email: state.accounts.map(a => a.email) }, authLog)).body.users ?? [];
  for (const user of priorAuth) assert(state.accounts.some(a => a.uid === user.localId && a.email === user.email), 'UID/email collision; no account may be taken over');
  const backupPath = join(evidenceDir, 'before.json');
  try { await writeFile(backupPath, JSON.stringify({ project, batch, checkedAt: new Date().toISOString(), documents: [...existing.values()].filter(Boolean), operatorUidsAlreadyPresent: priorAuth.map(u => u.localId) }, null, 2), { flag: 'wx' }); }
  catch (error) { if (error.code !== 'EEXIST') throw error; }
  stage = 'catalog commit';
  const writes = Object.entries(catalog).flatMap(([collection, rows]) => rows.flatMap(({ id, ...data }) => {
    const path = `${collection}/${id}`;
    if (existing.get(`${docRoot}/${path}`)) return [];
    return [create(path, { ...data, ...(collection === 'events' ? { registeredCount: 0 } : {}), ...(collection === 'organizers' ? { followerCount: 0 } : {}), isDemo: true, seedBatchId: batch, demoNotice: 'Dữ liệu giả lập được chủ dự án yêu cầu tạo cho Lab 3; có thể sửa hoặc xóa sau.' })];
  }));
  if (writes.length) await firestore.post(`${docRoot}:commit`, { writes });
  const safeOperators = [];
  for (const operator of state.accounts) {
    stage = `create/init ${operator.role}`;
    if (!priorAuth.some(u => u.localId === operator.uid)) {
      // Use the project-scoped admin endpoint used by Firebase Admin SDK; CLI OAuth belongs to its own client project.
      const created = await identity.post(`projects/${project}/accounts`, { localId: operator.uid, email: operator.email, password: operator.password, displayName: operator.displayName, emailVerified: false, disabled: false }, authLog);
      assert.equal(created.body.localId, operator.uid);
    }
    const token = await login(operator);
    await callable('initializeUser', token);
    await callable('updateProfile', token, { displayName: operator.displayName });
    await callable('saveInterests', token, { interests: ['technology', 'music', 'arts'] });
    await firestore.post(`${docRoot}:commit`, { writes: [{ update: { name: `${docRoot}/users/${operator.uid}`, fields: encode({ isDemo: true, seedBatchId: batch, demoRole: operator.role }).mapValue.fields }, updateMask: { fieldPaths: ['isDemo','seedBatchId','demoRole'] }, currentDocument: { exists: true } }] });
    stage = `assign ${operator.role} scope`;
    const roleRows = operator.role === 'staff'
      ? activeEvents.map(event => [`staff_assignments/${key(operator.uid, event.id)}`, { staffUid: operator.uid, eventId: event.id, active: true, permissions: ['verify_ticket', 'issue_walk_in'] }])
      : [[`voucher_admins/${operator.uid}`, { active: true }], [`milestone_admins/${operator.uid}`, { active: true }]];
    const priorRoles = await readDocuments(roleRows.map(([path]) => path));
    for (const row of priorRoles.values()) if (row) assert.equal(row.fields.seedBatchId?.stringValue, batch, 'Unexpected existing role assignment');
    const roleWrites = roleRows.flatMap(([path, data]) => priorRoles.get(`${docRoot}/${path}`) ? [] : [create(path, { ...data, isDemo: true, seedBatchId: batch })]);
    if (roleWrites.length) await firestore.post(`${docRoot}:commit`, { writes: roleWrites });
    await identity.post(`projects/${project}/accounts:update`, { localId: operator.uid, customAttributes: JSON.stringify(operatorSpecs.find(s => s.uid === operator.uid).claims) }, authLog);
    stage = `verify ${operator.role}`;
    const freshToken = await login(operator);
    const profile = await callable('getAccount', freshToken);
    assert.equal(profile.profile.onboardingCompleted, true);
    assert.equal(profile.wallet.availableCoins, 200);
    assert.equal(profile.wallet.heldCoins, 0);
    const milestones = await callable('getEventMilestones', freshToken);
    assert.equal(milestones.totalMilestones, 5); assert.equal(milestones.verifiedEventCount, 0);
    const authUser = (await identity.post(`projects/${project}/accounts:lookup`, { localId: [operator.uid] }, authLog)).body.users[0];
    const claims = JSON.parse(authUser.customAttributes);
    assert.equal(claims[operator.role], true); assert.equal(authUser.emailVerified ?? false, false);
    safeOperators.push({ uid: operator.uid, role: operator.role, claims, assignedDocuments: roleRows.map(([path]) => path), passwordSignInPassed: true, onboardingCompleted: true, availableCoins: profile.wallet.availableCoins, heldCoins: profile.wallet.heldCoins, verifiedEventCount: milestones.verifiedEventCount, emailVerified: false });
  }
  stage = 'final catalog verification';
  const after = await readDocuments(recordPaths);
  assert.equal([...after.values()].filter(Boolean).length, 32);
  for (const [path, doc] of after) assert.equal(doc.fields.seedBatchId.stringValue, batch, path);
  const result = { project, batch, completedAt: new Date().toISOString(), catalogDigest: digest, counts, createdThisRun: writes.length, catalogDocumentPaths: recordPaths, operators: safeOperators, credentialsPath: '.local/demo-operators-20261105/accounts.json', boundaries: ['Generated data is intentionally demo, not real FPT events or sponsor commitments', 'No email, SMS, verification or reset email was sent', 'Only normal one-time 200 signup coins per operator, no manual balance grants or fabricated attendance', 'No Google Cloud IAM roles or billing permissions were granted', 'Images are optional and omitted; mobile should show its standard placeholders'] };
  await writeFile(join(evidenceDir, 'applied.json'), JSON.stringify(result, null, 2));
  const handoff = ['EVIA — TAI KHOAN VAN HANH DEMO (KHONG COMMIT FILE NAY)', `Project: ${project}`, 'Email nay la dinh danh demo, khong phai hop thu that da duoc xac minh. Khong dung reset/verification email.', ...state.accounts.flatMap(a => ['', `Vai tro: ${a.role}`, `UID: ${a.uid}`, `Email: ${a.email}`, `Mat khau: ${a.password}`]), '', 'Dang nhap qua Firebase Auth/SDK sau khi mobile da duoc noi. Ban DEMO_AUTH=true cu van dung tai khoan local rieng.', 'Sau demo: doi mat khau/chuyen sang tai khoan that, revoke assignments/custom claims neu khong dung nua.'].join('\r\n');
  await writeFile(join(privateDir, 'TAI_KHOAN_DEMO.txt'), handoff, { mode: 0o600 });
  console.log(JSON.stringify(result, null, 2));
} catch (error) {
  // Never print API request/response objects, passwords or bearer tokens.
  console.error(`Demo setup stopped at: ${stage}. ${error instanceof assert.AssertionError ? error.message : 'Inspect the local checkpoint and retry without regenerating the catalog.'}`);
  if (!(error instanceof assert.AssertionError)) console.error(JSON.stringify({ status: error.status ?? error.context?.response?.statusCode ?? null, serverCodes: (String(error.message).match(/\b[A-Z][A-Z_]{4,}\b/g) ?? []).filter(code => !['HTTPS','POST','ERROR'].includes(code)), errorPropertyNames: Object.keys(error) }));
  let safeMessage = String(error.message).replaceAll(apiKey, '[api-key]');
  for (const operator of state.accounts) safeMessage = safeMessage.replaceAll(operator.password, '[password]').replaceAll(operator.email, '[demo-email]');
  console.error(safeMessage.slice(0, 350));
  process.exitCode = 1;
}
