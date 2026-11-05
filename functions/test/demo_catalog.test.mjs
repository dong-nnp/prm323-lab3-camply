import assert from 'node:assert/strict';
import test from 'node:test';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { createDemoCatalog } from '../scripts/generate-demo-catalog.mjs';

const now = new Date('2026-11-05T05:00:00Z');

test('generated catalog uses valid references/taxonomy and includes only disclosed demo content', () => {
  const catalog = createDemoCatalog(now);
  assert.deepEqual(Object.fromEntries(Object.entries(catalog).map(([k,v]) => [k,v.length])), { organizers:5, events:12, rewards:5, interests:10, milestones:0 });
  const interests = new Set(catalog.interests.map(i => i.id)), clubs = new Set(catalog.organizers.map(o => o.id));
  for (const event of catalog.events) {
    assert(clubs.has(event.organizerId)); assert(interests.has(event.category));
    assert(event.tags.every(tag => interests.has(tag)));
    assert(event.title.startsWith('[DEMO]'));
    assert(Date.parse(event.startAt) < Date.parse(event.endAt));
    assert(Date.parse(event.checkInStartAt) < Date.parse(event.checkInEndAt));
  }
  assert(catalog.organizers.every(c => c.name.startsWith('[DEMO]')));
  assert(catalog.rewards.every(r => r.title.startsWith('[DEMO]') && r.termsText.includes('Không phải cam kết')));
  assert.equal(catalog.rewards.find(r => r.id === 'demo-cafe').priceCoins, 200);
});

test('live windows permit registration and walk-in while full/last-ticket fixtures need no invented users', () => {
  const { events } = createDemoCatalog(now);
  const registered = events.find(e => e.id === 'demo-live-registration');
  assert(Date.parse(registered.registrationClosesAt) > now.getTime());
  for (const id of ['demo-live-registration','demo-live-walkin']) {
    const event = events.find(e => e.id === id);
    assert(Date.parse(event.checkInStartAt) < now.getTime());
    assert(Date.parse(event.checkInEndAt) > now.getTime());
  }
  assert.equal(events.find(e => e.id === 'demo-full-event').capacity, 0);
  assert.equal(events.find(e => e.id === 'demo-last-ticket').capacity, 1);
  assert(events.filter(e => e.participationMode === 'walk_in').every(e => e.depositCoins === 0));
  assert.equal(events.filter(e => e.status === 'published').length, 11);
  assert.equal(events.filter(e => e.status === 'completed').length, 1);
});

test('seed command defaults to a dry run without SDK credentials, role grants or network', async () => {
  const { stdout } = await promisify(execFile)(process.execPath, ['scripts/seed-demo.mjs'], { cwd: new URL('..', import.meta.url), env: { ...process.env, APPDATA: 'not-a-real-cli-directory', GOOGLE_APPLICATION_CREDENTIALS: 'no-credentials.json' } });
  const summary = JSON.parse(stdout);
  assert.equal(summary.mode, 'DRY RUN'); assert.equal(summary.noNetwork, true);
  assert.equal(summary.staffAssignmentCount, 11); assert.equal(summary.operatorCount, 2);
  assert.equal(summary.counts.milestones, 0);
});
