import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { createServer } from 'vite';
import { crashDebugProcess } from '../src/qa-crash.js';

let server;
let eventImport;
let voucherImport;
let catalogEntry;
let editorValues;
let adminErrorMessage;

before(async () => {
  const root = fileURLToPath(new URL('../', import.meta.url));
  server = await createServer({ root, server: { middlewareMode: true }, appType: 'custom' });
  ({ eventImport, voucherImport, catalogEntry, editorValues } = await server.ssrLoadModule('/src/catalog.js'));
  ({ adminErrorMessage } = await server.ssrLoadModule('/src/service-panels.js'));
});

after(async () => server?.close());

test('Storage errors are actionable and never display raw SDK diagnostics', () => {
  assert.match(adminErrorMessage({ code: 'storage/unauthorized' }), /quyền tải ảnh/);
  assert.doesNotMatch(adminErrorMessage({ code: 'storage/unknown', message: 'secret raw diagnostics' }), /secret/);
});

function form(values) {
  return new Map(Object.entries(values));
}

const base = {
  id: 'fixture-01', title: 'Fixture', description: 'Test fixture', category: 'lab',
  sourceRef: 'https://example.com/approved',
};

test('event export uses the import schema and stores UTC+7 input as UTC draft timestamps', () => {
  const payload = eventImport(form({
    ...base, organizerId: 'fixture-organizer', participationMode: 'walk_in', venue: 'Test venue',
    startAt: '2030-03-01T18:00', endAt: '2030-03-01T19:00',
    checkInStartAt: '2030-03-01T17:30', checkInEndAt: '2030-03-01T18:30',
    depositCoins: '100', attendanceRewardCoins: '30',
  }));
  assert.equal(payload.events[0].status, 'draft');
  assert.equal(payload.events[0].startAt, '2030-03-01T11:00:00.000Z');
  assert.equal(payload.events[0].checkInStartAt, '2030-03-01T10:30:00.000Z');
  assert.equal(payload.events[0].depositCoins, 0);
  assert.equal(payload.events[0].capacity, null);
  assert.equal(payload.events[0].registrationTerms, undefined);
});

test('registration event rejects missing terms and inverted event times', () => {
  const payload = form({
    ...base, organizerId: 'fixture-organizer', participationMode: 'registration', venue: 'Test venue',
    startAt: '2030-03-01T20:00', endAt: '2030-03-01T19:00',
    depositCoins: '0', attendanceRewardCoins: '0',
    checkInStartAt: '2030-03-01T17:30', checkInEndAt: '2030-03-01T18:30',
  });
  assert.throws(() => eventImport(payload), error =>
    error.issues.some(issue => issue.path[0] === 'registrationTerms'));
  payload.set('registrationTerms', 'Fixture terms');
  payload.set('registrationTermsVersion', 'v1');
  assert.throws(() => eventImport(payload), /startAt must precede endAt/);
});

test('simple event form supplies technical fields, standard policy and check-in defaults', () => {
  const event = catalogEntry('events', form({
    title: 'Fixture event', description: 'Fixture description', category: 'technology',
    organizerId: 'fixture-organizer', participationMode: 'registration', venue: 'Fixture venue',
    startAt: '2030-03-01T18:00', endAt: '2030-03-01T19:00',
    depositCoins: '50', attendanceRewardCoins: '30',
  }), undefined, { id: 'generated-fixture', projectId: 'demo-evia-backend' });
  assert.equal(event.id, 'generated-fixture');
  assert.match(event.sourceRef, /^https:\/\/console.firebase.google.com\/project\/demo-evia-backend\//);
  assert.equal(event.checkInStartAt, event.startAt);
  assert.equal(event.checkInEndAt, event.endAt);
  assert.equal(event.registrationTerms.version, 'evia-standard-v1');
  assert.match(event.registrationTerms.text, /30%/);
  assert.match(event.registrationTerms.text, /mất toàn bộ/);
  assert.deepEqual(event.schedule, []);
  assert.equal(event.status, 'draft');
});

test('simplified editing preserves hidden terms, provenance, agenda and existing image', () => {
  const original = {
    ...base, organizerId: 'fixture-organizer', participationMode: 'registration',
    status: 'published', visibility: 'public', timezone: 'Asia/Ho_Chi_Minh',
    startAt: '2030-03-01T11:00:00.000Z', endAt: '2030-03-01T12:00:00.000Z',
    checkInStartAt: '2030-03-01T10:30:00.000Z', checkInEndAt: '2030-03-01T12:00:00.000Z',
    venue: { name: 'Fixture venue', checkInInstructions: 'Keep existing instructions' },
    audience: { scope: 'everyone' }, capacity: 50, depositCoins: 50, attendanceRewardCoins: 30,
    tags: [], registrationTerms: { version: 'custom-v3', text: 'Existing approved terms' },
    schedule: [{ id: 'opening', title: 'Opening', startAt: '2030-03-01T11:00:00.000Z' }],
    imageUrl: 'https://example.com/previous.png', revision: '1:500', registeredCount: 4,
  };
  const values = editorValues(original);
  for (const key of ['id', 'sourceRef', 'registrationTerms', 'registrationTermsVersion', 'schedule', 'imageUrl']) delete values[key];
  const updated = catalogEntry('events', form(values), original);
  assert.deepEqual(updated.registrationTerms, original.registrationTerms);
  assert.deepEqual(updated.schedule, original.schedule);
  assert.equal(updated.sourceRef, original.sourceRef);
  assert.equal(updated.imageUrl, original.imageUrl);
  assert.equal(updated.checkInStartAt, original.checkInStartAt);
  assert.equal(updated.venue.checkInInstructions, original.venue.checkInInstructions);
  const replaced = catalogEntry('events', form(values), original, { imageUrl: 'https://example.com/new.png' });
  assert.equal(replaced.imageUrl, 'https://example.com/new.png');
});

test('voucher export is inactive and uses the existing reward contract', () => {
  const payload = form({
    ...base, priceCoins: '200', stockRemaining: '5', validDays: '7',
    termsText: 'Fixture terms', termsVersion: 'v1',
    usageLocations: 'Campus\nPartner', redemptionSteps: 'Show QR\nConfirm',
  });
  const reward = voucherImport(payload).rewards[0];
  assert.equal(reward.fulfillmentType, 'voucher');
  assert.equal(reward.status, 'inactive');
  assert.equal(reward.priceCoins, 200);
  assert.deepEqual(reward.redemptionSteps, ['Show QR', 'Confirm']);
  payload.set('stockRemaining', '-1');
  assert.throws(() => voucherImport(payload), /stockRemaining/);
});

test('editing a published event keeps server data outside the form and restores disabled fields', () => {
  const entry = {
    ...base, status: 'published', revision: '10:500', registeredCount: 5,
    organizerId: 'fixture-organizer', visibility: 'public', participationMode: 'walk_in',
    startAt: '2030-03-01T11:00:01.500Z', endAt: '2030-03-01T12:00:00.000Z',
    checkInStartAt: '2030-03-01T10:30:00.000Z', checkInEndAt: '2030-03-01T11:30:00.000Z',
    timezone: 'Asia/Ho_Chi_Minh', venue: { name: 'Test venue', entranceLabel: 'North' },
    audience: { scope: 'everyone' }, schedule: [], tags: [],
    capacity: null, depositCoins: 0, attendanceRewardCoins: 30, featured: true,
    benefits: [{ title: 'Benefit', description: 'Fixture' }],
  };
  const fields = form(editorValues(entry));
  for (const key of ['organizerId', 'visibility', 'participationMode']) fields.delete(key);
  fields.set('title', 'Updated event');
  const saved = catalogEntry('events', fields, entry);
  assert.equal(saved.title, 'Updated event');
  assert.equal(saved.status, 'published');
  assert.equal(saved.organizerId, entry.organizerId);
  assert.equal(saved.startAt, entry.startAt);
  assert.equal(saved.venue.entranceLabel, 'North');
  assert.equal(saved.featured, true);
  assert.deepEqual(saved.benefits, entry.benefits);
  assert.equal('registeredCount' in saved, false);
  assert.equal('revision' in saved, false);
});

function fakeShell(responses) {
  const calls = [];
  return {
    calls,
    run: async (command) => {
      calls.push(command);
      return { exitCode: 0, stdout: '', stderr: '', ...responses.shift() };
    },
  };
}
const noWait = async () => {};

test('one crash request targets Evia debug and requires a matching fatal Android log', async () => {
  const shell = fakeShell([
    {}, { stdout: '3456' }, {}, { stdout: '3456' }, { exitCode: 1 },
    { stdout: 'FATAL EXCEPTION: main\nProcess: com.example.prm393_lab03, PID: 3456' },
  ]);
  let requests = 0;
  await crashDebugProcess(shell.run, () => { requests++; }, noWait);
  assert.equal(requests, 1);
  assert.deepEqual(shell.calls.filter(([command]) => command === 'am'), [
    ['am', 'crash', '--user', 'current', 'com.example.prm393_lab03'],
  ]);
  assert.deepEqual(shell.calls[0], ['run-as', 'com.example.prm393_lab03', 'id']);
});

test('a release build or missing process never receives a crash command', async () => {
  const release = fakeShell([{ exitCode: 1 }]);
  const notRunning = fakeShell([{}, { exitCode: 1 }]);
  for (const shell of [release, notRunning]) {
    await assert.rejects(crashDebugProcess(shell.run, () => assert.fail('Unexpected crash'), noWait));
    assert.equal(shell.calls.some(([command]) => command === 'am'), false);
  }
});

test('a sent command alone does not count as a verified crash', async () => {
  const shell = fakeShell([{}, { stdout: '3456' }, {}]);
  await assert.rejects(crashDebugProcess(shell.run, () => {}, noWait), /chưa xác minh được/);
});
