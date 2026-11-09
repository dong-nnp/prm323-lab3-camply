import assert from 'node:assert/strict';
import test, { after } from 'node:test';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { createBackend } from '../lib/backend.js';
import { evibabyReply, reserveEvibabyRequest } from '../lib/evibaby.js';

assert.match(process.env.FIRESTORE_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):/);
assert.equal(process.env.GCLOUD_PROJECT, 'demo-evia-backend');
const app = initializeApp({ projectId: 'demo-evia-backend' }, 'evibaby-tests'), db = getFirestore(app);
after(() => deleteApp(app));
const now = new Date('2026-11-09T03:00:00Z');

test('Evibaby reads the public catalog through real backend queries and rechecks cards', async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-evia-backend/databases/(default)/documents`, { method: 'DELETE' });
  const base = {
    title: 'Workshop fixture', description: 'Emulator only', organizerId: 'club', category: 'technology', tags: [],
    status: 'published', visibility: 'public', participationMode: 'registration', venue: { name: 'Test venue' },
    capacity: 10, registeredCount: 0, depositCoins: 50, attendanceRewardCoins: 100, timezone: 'Asia/Ho_Chi_Minh',
    startAt: Timestamp.fromDate(new Date('2026-11-14T03:00:00Z')), endAt: Timestamp.fromDate(new Date('2026-11-14T05:00:00Z')),
  };
  await Promise.all([
    db.doc('events/evibaby-public').set(base),
    db.doc('events/evibaby-private').set({ ...base, visibility: 'private' }),
    db.doc('events/evibaby-draft').set({ ...base, status: 'draft' }),
    db.doc('events/evibaby-past').set({ ...base, endAt: Timestamp.fromDate(new Date('2026-11-01T00:00:00Z')) }),
  ]);
  const api = createBackend(db, () => now);
  let round = 0;
  const request = async (_url, options) => {
    const input = JSON.parse(options.body);
    if (round++ === 0) return new Response(JSON.stringify({ choices: [{ finish_reason: 'tool_calls', message: { role: 'assistant', content: null, tool_calls: [{ id: 'search-1', type: 'function', function: { name: 'search_events', arguments: '{}' } }] } }] }));
    const evidence = JSON.parse(input.messages.find(m => m.role === 'tool').content);
    assert.deepEqual(evidence.items.map(e => e.id), ['evibaby-public']);
    await db.doc('events/evibaby-public').update({ title: 'Updated canonical title' });
    return new Response(JSON.stringify({ choices: [{ finish_reason: 'stop', message: { role: 'assistant', content: JSON.stringify({ reply: 'Có workshop hợp nè', eventIds: ['evibaby-public'], outOfScope: false }) } }] }));
  };
  const response = await evibabyReply({ message: 'Tìm workshop' }, { apiKey: 'test-only', baseUrl: 'https://model.example.test', model: 'test' }, (name, input) => api.invoke(name, null, input), request, now);
  assert.equal(response.events[0].title, 'Updated canonical title');
  assert.equal(response.events[0].spotsRemaining, 10);
});

test('concurrent paid requests atomically enforce quota without changing business data', async () => {
  const actor = { uid: 'evibaby-user', token: { email: 'test@example.com' } };
  await db.doc(`users/${actor.uid}`).set({ accountStatus: 'active' });
  await db.doc(`wallets/${actor.uid}`).set({ availableCoins: 200, heldCoins: 0 });
  const outcomes = await Promise.allSettled(Array.from({ length: 6 }, () => reserveEvibabyRequest(db, actor, now)));
  assert.equal(outcomes.filter(r => r.status === 'fulfilled').length, 5);
  assert.equal(outcomes.find(r => r.status === 'rejected').reason.details.code, 'EVIBABY_RATE_LIMITED');
  assert.deepEqual((await db.doc(`wallets/${actor.uid}`).get()).data(), { availableCoins: 200, heldCoins: 0 });
  assert.equal((await db.collection('registrations').get()).size, 0);
});
