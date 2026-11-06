// Trusted operator command: creates one demo inbox record; the deployed trigger sends FCM.
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';

try {
  const { values } = parseArgs({ options: {
    uid: { type: 'string' }, event: { type: 'string', default: 'demo-career-talk' },
    send: { type: 'boolean', default: false },
  } });
  assert(/^[A-Za-z0-9_-]{1,128}$/.test(values.uid ?? ''), 'UID required: --uid <Firebase User UID>');
  assert(/^demo-[A-Za-z0-9_-]{1,123}$/.test(values.event), 'Event must be a demo event ID.');
  const project = 'prm393-31822', uid = values.uid, eventId = values.event;
  if (!values.send) {
    console.log(JSON.stringify({ mode: 'DRY RUN', project, uid, eventId, noNetwork: true }));
  } else {
    assert(!process.env.FIRESTORE_EMULATOR_HOST, 'Do not mix live demo push and Emulator.');
    const root = fileURLToPath(new URL('../..', import.meta.url));
    const config = JSON.parse(await readFile(join(root, 'firebase.json'), 'utf8'));
    assert.equal(config.flutter.platforms.android.default.projectId, project, 'Firebase project mismatch.');
    const require = createRequire(import.meta.url);
    // shortcut: reuse the Windows global Firebase CLI login; revisit if the team changes CLI installation.
    const cli = join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
    const auth = require(join(cli, 'auth.js'));
    const { requireAuth } = require(join(cli, 'requireAuth.js'));
    const { Client } = require(join(cli, 'apiv2.js'));
    const options = { project, nonInteractive: true };
    const account = auth.getProjectDefaultAccount(root);
    assert(account, 'Run firebase login on this computer first.');
    auth.setActiveAccount(options, account);
    await requireAuth(options);
    const db = new Client({ urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1' });
    const base = `projects/${project}/databases/(default)/documents`;
    const quiet = () => ({ skipLog: { body: true, resBody: true, queryParams: true } });
    const [{ body: user }, { body: event }, { body: devices }] = await Promise.all([
      db.get(`${base}/users/${uid}`, quiet()),
      db.get(`${base}/events/${eventId}`, quiet()),
      db.get(`${base}/users/${uid}/devices`, quiet()),
    ]);
    assert(user.fields.accountStatus?.stringValue === 'active' && user.fields.isDemo?.booleanValue === true, 'Recipient must be an active demo account.');
    assert(event.fields.isDemo?.booleanValue === true && event.fields.status?.stringValue === 'published' && event.fields.visibility?.stringValue === 'public', 'Event must be published, public and marked demo.');
    assert(devices.documents?.some(d => d.fields.token?.stringValue), 'Open Notifications in the app and allow notifications first.');
    const notificationId = `demo-push-${randomUUID()}`;
    await db.post(`${base}:commit`, { writes: [{
      update: { name: `${base}/notifications/${notificationId}`, fields: {
        uid: { stringValue: uid }, type: { stringValue: 'demo_fcm_smoke' },
        title: { stringValue: '[DEMO] Thông báo từ Firebase' },
        body: { stringValue: 'Evia đã gửi push notification. Nhấn để xem sự kiện.' },
        entityType: { stringValue: 'event' }, entityId: { stringValue: eventId },
        readAt: { nullValue: null }, isDemo: { booleanValue: true },
      } },
      currentDocument: { exists: false },
      updateTransforms: [{ fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' }],
    }] }, quiet());
    console.log(`Đã tạo ${notificationId} cho ${uid}. Firebase sẽ xử lý gửi FCM; chưa xác nhận điện thoại đã nhận.`);
  }
} catch (error) {
  console.error(`Không gửi thông báo demo: ${error.message}`);
  process.exitCode = 1;
}
