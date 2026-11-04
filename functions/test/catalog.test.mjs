import assert from 'node:assert/strict';
import test from 'node:test';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { promisify } from 'node:util';
import { execFile } from 'node:child_process';
import { catalogSchema, eventSchema, rewardSchema } from '../lib/catalog.js';

test('imported terms versions fit registration and redemption requests', () => {
  const reward = { id: 'test-reward', title: 'Fixture', description: 'Test only', category: 'test', priceCoins: 200, stockRemaining: 1, status: 'active', usageLocations: [], termsText: 'Test terms', termsVersion: 'v'.repeat(100), redemptionSteps: ['Test step'], fulfillmentType: 'voucher', sourceRef: 'https://example.test/source' };
  assert.equal(rewardSchema.safeParse(reward).success, true);
  assert.equal(rewardSchema.safeParse({ ...reward, termsVersion: 'v'.repeat(101) }).success, false);
  const event = { id: 'test-event', organizerId: 'test-club', title: 'Fixture', description: 'Test only', category: 'test', tags: [], status: 'published', visibility: 'public', startAt: '2026-11-05T03:00:00Z', endAt: '2026-11-05T05:00:00Z', checkInStartAt: '2026-11-05T02:00:00Z', checkInEndAt: '2026-11-05T04:00:00Z', timezone: 'Asia/Ho_Chi_Minh', venue: { name: 'Fixture' }, audience: { scope: 'everyone' }, participationMode: 'registration', capacity: 10, depositCoins: 0, attendanceRewardCoins: 5, registrationTerms: { version: 'v'.repeat(100), text: 'Test terms' }, sourceRef: 'https://example.test/source' };
  assert.equal(eventSchema.safeParse(event).success, true);
  assert.equal(eventSchema.safeParse({ ...event, registrationTerms: { ...event.registrationTerms, version: 'v'.repeat(101) } }).success, false);
});

test('catalog rejects duplicate IDs, invented counters and restricted audience', () => {
  const interest = { id: 'test-interest', label: 'Test only', status: 'active', sourceRef: 'https://example.test/approved' };
  assert.equal(catalogSchema.safeParse({ interests: [interest, interest] }).success, false);
  assert.equal(catalogSchema.safeParse({ interests: [{ ...interest, followerCount: 100 }] }).success, false);
  const event = { id: 'test-event', organizerId: 'test-club', title: 'Fixture', description: 'Fixture only', category: 'test', tags: [], status: 'published', visibility: 'public', startAt: '2026-11-05T03:00:00Z', endAt: '2026-11-05T05:00:00Z', checkInStartAt: '2026-11-05T02:00:00Z', checkInEndAt: '2026-11-05T04:00:00Z', timezone: 'Asia/Ho_Chi_Minh', venue: { name: 'Fixture' }, audience: { scope: 'everyone' }, participationMode: 'walk_in', capacity: null, depositCoins: 0, attendanceRewardCoins: 5, sourceRef: 'https://example.test/approved' };
  assert.equal(eventSchema.safeParse(event).success, true);
  assert.equal(eventSchema.safeParse({ ...event, audience: { scope: 'verified_students' } }).success, false);
  assert.equal(eventSchema.safeParse({ ...event, endAt: event.startAt }).success, false);
  assert.equal(eventSchema.safeParse({ ...event, depositCoins: 20 }).success, false);
  assert.equal(catalogSchema.safeParse({ interests: [interest] }).success, true);
});

test('import dry-run validates input without initializing Firebase or writing documents', async () => {
  const folder = await mkdtemp(join(tmpdir(), 'evia-catalog-test-'));
  try {
    const file = join(folder, 'approved-test.json');
    await writeFile(file, JSON.stringify({ interests: [{ id: 'test', label: 'Test fixture', status: 'active', sourceRef: 'https://example.test/source' }] }));
    const { stdout } = await promisify(execFile)(process.execPath, ['scripts/import-catalog.mjs', '--input', file, '--project', 'demo-evia-backend'], { cwd: new URL('..', import.meta.url) });
    assert.match(stdout, /DRY RUN/);
    assert.match(stdout, /"interests":1/);
  } finally { await rm(folder, { recursive: true }); }
});
