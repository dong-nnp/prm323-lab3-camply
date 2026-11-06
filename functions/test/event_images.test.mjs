import assert from 'node:assert/strict';
import test, { before, after } from 'node:test';
import { randomUUID } from 'node:crypto';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const project = 'demo-evia-backend';
assert.equal(process.env.GCLOUD_PROJECT, project);
for (const key of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST', 'FIREBASE_STORAGE_EMULATOR_HOST']) {
  assert.match(process.env[key] ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
}
const app = initializeApp({ projectId: project }, 'event-image-tests');
const auth = getAuth(app), db = getFirestore(app);
const prefix = 'image-' + randomUUID();
const users = {};
const base = `http://${process.env.FIREBASE_STORAGE_EMULATOR_HOST}/v0/b/${project}.appspot.com/o`;
const bytes = new Uint8Array([137, 80, 78, 71]);
function upload(path, token, type = 'image/png', body = bytes) {
  return fetch(`${base}?uploadType=media&name=${encodeURIComponent(path)}`, {
    method: 'POST', headers: { 'content-type': type, ...(token && { authorization: `Bearer ${token}` }) }, body,
  });
}
async function expectStatus(request, expected) {
  const result = await request;
  assert.equal(result.status, expected, await result.text());
}
before(async () => {
  for (const role of ['admin', 'staff', 'student', 'disabled', 'missing']) {
    const uid = prefix + '-' + role;
    await auth.createUser({ uid, email: uid + '@example.com' });
    await auth.setCustomUserClaims(uid, { admin: ['admin', 'disabled', 'missing'].includes(role), staff: role === 'staff' });
    if (role !== 'missing') await db.doc('users/' + uid).set({ accountStatus: role === 'disabled' ? 'disabled' : 'active' });
    const token = await auth.createCustomToken(uid);
    const response = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=emulator-only`, {
      method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ token, returnSecureToken: true }),
    });
    const result = await response.json();
    assert.ok(result.idToken);
    users[role] = { uid, token: result.idToken };
  }
});
after(() => deleteApp(app));

test('active admin can upload/read own supported event images, cannot overwrite or list, can clean up own assets', async () => {
  const admin = users.admin;
  for (const [extension, type] of [['jpg', 'image/jpeg'], ['png', 'image/png'], ['webp', 'image/webp']]) {
    const path = `event-images/${admin.uid}/${randomUUID()}.${extension}`;
    await expectStatus(upload(path, admin.token, type), 200);
    const url = `${base}/${encodeURIComponent(path)}`;
    const headers = { authorization: `Bearer ${admin.token}` };
    await expectStatus(fetch(url, { headers }), 200);
    await expectStatus(upload(path, admin.token, type), 403);
    await expectStatus(fetch(url, { method: 'DELETE', headers }), 204);
  }
  await expectStatus(fetch(`${base}?prefix=${encodeURIComponent('event-images/' + admin.uid + '/')}`, { headers: { authorization: `Bearer ${admin.token}` } }), 403);
});

test('anonymous, student, staff, disabled admin, missing profile and cross-owner writes are rejected', async () => {
  for (const role of ['staff', 'student', 'disabled', 'missing']) {
    await expectStatus(upload(`event-images/${users[role].uid}/${randomUUID()}.png`, users[role].token), 403);
  }
  await expectStatus(upload(`event-images/${users.admin.uid}/${randomUUID()}.png`), 403);
  await expectStatus(upload(`event-images/${users.student.uid}/${randomUUID()}.png`, users.admin.token), 403);
});

test('event image rules reject unsafe MIME, suffix mismatch, oversized and empty objects', async () => {
  const root = `event-images/${users.admin.uid}/`;
  await expectStatus(upload(root + randomUUID() + '.svg', users.admin.token, 'image/svg+xml'), 403);
  await expectStatus(upload(root + randomUUID() + '.png', users.admin.token, 'image/jpeg'), 403);
  await expectStatus(upload(root + randomUUID() + '.png', users.admin.token, 'image/png', new Uint8Array(5 * 1024 * 1024 + 1)), 403);
  await expectStatus(upload(root + randomUUID() + '.png', users.admin.token, 'image/png', new Uint8Array(0)), 403);
});
