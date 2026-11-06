import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { createServer } from 'vite';

let server;
let eventImport;
let voucherImport;
let catalogEntry;
let editorValues;

before(async () => {
  const root = fileURLToPath(new URL('../', import.meta.url));
  server = await createServer({ root, server: { middlewareMode: true }, appType: 'custom' });
  ({ eventImport, voucherImport, catalogEntry, editorValues } = await server.ssrLoadModule('/src/catalog.js'));
});

after(async () => server?.close());

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
