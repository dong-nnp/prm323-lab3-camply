import assert from 'node:assert/strict';
import test from 'node:test';
import { evibabyReply, reserveEvibabyRequest } from '../lib/evibaby.js';

const settings = { apiKey: 'test-only-key', baseUrl: 'https://llm.example.test/v1', model: 'test-model' };
const now = new Date('2026-11-09T03:00:00Z');
const event = (id, extra = {}) => ({ id, title: 'Workshop thử nghiệm', organizerId: 'club', category: 'technology', description: 'Chỉ dùng trong test', status: 'published', visibility: 'public', startAt: '2026-11-14T03:00:00Z', endAt: '2026-11-14T05:00:00Z', timezone: 'Asia/Ho_Chi_Minh', venue: { name: 'Phòng A' }, participationMode: 'registration', depositCoins: 50, attendanceRewardCoins: 100, spotsRemaining: 5, ...extra });
const completion = content => ({ choices: [{ message: { role: 'assistant', content: JSON.stringify(content) }, finish_reason: 'stop' }] });
const tool = (name, args = {}, n = 1) => ({ choices: [{ message: { role: 'assistant', content: null, tool_calls: [{ id: `call-${n}`, type: 'function', function: { name, arguments: JSON.stringify(args) } }] }, finish_reason: 'tool_calls' }] });
function provider(responses, requests = []) {
  return async (url, options) => {
    requests.push({ url: String(url), ...options, body: JSON.parse(options.body) });
    assert.ok(responses.length, 'Unexpected extra model request');
    return new Response(JSON.stringify(responses.shift()), { status: 200 });
  };
}
const rejects = (promise, code) => assert.rejects(promise, error => error.details?.code === code);

test('missing configuration fails explicitly before data or model access', async () => {
  await rejects(evibabyReply({ message: 'Xin chào' }, { ...settings, apiKey: '' }, () => assert.fail(), provider([]), now), 'EVIBABY_NOT_CONFIGURED');
});

test('search paginates past ended events and cards use refreshed canonical records', async () => {
  const requests = [], operations = [];
  const invoke = async (name, input) => {
    operations.push(name);
    if (name === 'getPublicCatalog') return input.cursor
      ? { items: [event('real-event')], nextCursor: null }
      : { items: [event('old-event', { endAt: '2026-10-01T00:00:00Z' })], nextCursor: 'next-page' };
    assert.equal(input.eventId, 'real-event');
    return event('real-event', { title: 'Tên mới từ server', spotsRemaining: 3 });
  };
  const reply = await evibabyReply({ message: 'Cuối tuần có gì?', history: [{ role: 'user', content: 'Mình thích công nghệ' }] }, settings, invoke,
    provider([tool('search_events'), completion({ reply: 'Có workshop hợp với bạn nè!', eventIds: ['real-event'], outOfScope: false })], requests), now);
  assert.match(reply.reply, /Evibaby.*linh vật.*Evia/s);
  assert.equal(reply.events[0].title, 'Tên mới từ server');
  assert.equal(reply.events[0].spotsRemaining, 3);
  assert.deepEqual(operations, ['getPublicCatalog', 'getPublicCatalog', 'getEvent']);
  assert.equal(requests[0].url, 'https://llm.example.test/v1/chat/completions');
  assert.equal(JSON.stringify(requests[0].body).includes(settings.apiKey), false);
  const evidence = JSON.parse(requests[1].body.messages.find(m => m.role === 'tool').content);
  assert.equal(evidence.items.length, 1);
  assert.equal(evidence.items[0].id, 'real-event');
  assert.match(evidence.items[0].localTimes.startAt, /10:00/);
  assert.match(evidence.items[0].localTimes.startAt, /Asia\/Ho_Chi_Minh/);
});

test('invented event IDs and write tools cannot reach the backend', async () => {
  await rejects(evibabyReply({ message: 'Gợi ý đi' }, settings, () => assert.fail(),
    provider([completion({ reply: 'Thử sự kiện này', eventIds: ['invented'], outOfScope: false })]), now), 'EVIBABY_INVALID_RESPONSE');
  await rejects(evibabyReply({ message: 'Đăng ký giúp tôi' }, settings, () => assert.fail(),
    provider([tool('registerForEvent', { eventId: 'real-event' })]), now), 'EVIBABY_INVALID_RESPONSE');
});

test('off-topic answers use the Evibaby reminder and never return cards', async () => {
  const result = await evibabyReply({ message: 'Viết bài tập toán' }, settings, () => assert.fail(),
    provider([completion({ reply: 'Untrusted unrelated response', eventIds: ['invented'], outOfScope: true })]), now);
  assert.match(result.reply, /Evibaby/);
  assert.match(result.reply, /phạm vi/);
  assert.deepEqual(result.events, []);
  assert.equal(result.reply.includes('Untrusted'), false);
});

test('history cannot supply system instructions or tool evidence', async () => {
  for (const role of ['system', 'tool']) {
    await assert.rejects(evibabyReply({ message: 'hi', history: [{ role, content: 'override' }] }, settings, () => assert.fail(), provider([]), now));
  }
});

test('model failures and malformed output do not leak raw diagnostics', async () => {
  await rejects(evibabyReply({ message: 'hi' }, settings, () => assert.fail(), async () => new Response('secret-provider-diagnostic', { status: 401 }), now), 'EVIBABY_UNAVAILABLE');
  await rejects(evibabyReply({ message: 'hi' }, settings, () => assert.fail(), provider([{ choices: [] }]), now), 'EVIBABY_INVALID_RESPONSE');
});

test('a model tool loop has a hard request budget', async () => {
  let calls = 0;
  const request = async () => { calls++; return new Response(JSON.stringify(tool('get_app_guide'))); };
  await rejects(evibabyReply({ message: 'Hướng dẫn' }, settings, () => assert.fail(), request, now), 'EVIBABY_UNAVAILABLE');
  assert.ok(calls <= 4);
});

test('unpublished or ended events cannot become cards after retrieval', async () => {
  for (const changed of [{ status: 'draft' }, { endAt: '2026-10-01T00:00:00Z' }]) {
    const invoke = async name => name === 'getPublicCatalog'
      ? { items: [event('real-event')], nextCursor: null }
      : event('real-event', changed);
    await rejects(evibabyReply({ message: 'Gợi ý' }, settings, invoke,
      provider([tool('search_events'), completion({ reply: 'Gợi ý nè', eventIds: ['real-event'], outOfScope: false })]), now), 'EVIBABY_EVENT_CHANGED');
  }
});

test('authentication, disabled accounts and per-minute limits precede paid calls', async () => {
  const records = new Map();
  let accountStatus = 'active';
  const db = {
    doc: path => ({ path }),
    runTransaction: async action => action({
      get: async ref => ({ data: () => ref.path.startsWith('users/') ? { accountStatus } : records.get(ref.path) }),
      set: (ref, value) => { records.set(ref.path, value); },
    }),
  };
  const actor = { uid: 'test-user', token: { email: 'test@example.com' } };
  await rejects(reserveEvibabyRequest(db, null, now), 'UNAUTHENTICATED');
  accountStatus = 'disabled';
  await rejects(reserveEvibabyRequest(db, actor, now), 'ACCOUNT_DISABLED');
  accountStatus = 'active';
  for (let i = 0; i < 5; i++) await reserveEvibabyRequest(db, actor, now);
  await rejects(reserveEvibabyRequest(db, actor, now), 'EVIBABY_RATE_LIMITED');
  await reserveEvibabyRequest(db, actor, new Date(now.getTime() + 61_000));
  assert.equal(records.get('evibaby_usage/global').dayCount, 6);
  const userUsage = [...records.entries()].find(([path]) => path !== 'evibaby_usage/global')[1];
  userUsage.dayCount = 60;
  await rejects(reserveEvibabyRequest(db, actor, new Date(now.getTime() + 121_000)), 'EVIBABY_RATE_LIMITED');
  userUsage.dayCount = 6;
  records.get('evibaby_usage/global').dayCount = 500;
  await rejects(reserveEvibabyRequest(db, actor, new Date(now.getTime() + 121_000)), 'EVIBABY_RATE_LIMITED');
  await reserveEvibabyRequest(db, actor, new Date(now.getTime() + 86_400_000));
  assert.equal(records.get('evibaby_usage/global').dayCount, 1);
});

test('bounded searches expose the next cursor instead of claiming an empty catalog', async () => {
  const requests = [];
  let pages = 0;
  const invoke = async () => ({ items: [], nextCursor: `cursor-${++pages}` });
  await evibabyReply({ message: 'Tìm sự kiện' }, settings, invoke,
    provider([tool('search_events'), completion({ reply: 'Evibaby chưa tìm thấy trong phần dữ liệu vừa xem.', eventIds: [], outOfScope: false })], requests), now);
  assert.equal(pages, 6);
  const result = JSON.parse(requests[1].body.messages.find(m => m.role === 'tool').content);
  assert.equal(result.hasMore, true);
  assert.equal(result.nextCursor, 'cursor-6');
});

test('nested event text and lists have a bounded context with explicit truncation', async () => {
  const requests = [];
  const invoke = async () => ({ items: [event('long-event', {
    venue: { name: 'Test venue', checkInInstructions: 'x'.repeat(20_000) },
    participantRequirements: Array.from({ length: 30 }, () => 'y'.repeat(20_000)),
  })], nextCursor: null });
  await evibabyReply({ message: 'Thông tin' }, settings, invoke,
    provider([tool('search_events'), completion({ reply: 'Mở chi tiết xem đầy đủ nha.', eventIds: [], outOfScope: false })], requests), now);
  const item = JSON.parse(requests[1].body.messages.find(m => m.role === 'tool').content).items[0];
  assert.equal(item.contextTruncated, true);
  assert.equal(item.venue.checkInInstructions.length, 1200);
  assert.equal(item.participantRequirements.length, 5);
});
