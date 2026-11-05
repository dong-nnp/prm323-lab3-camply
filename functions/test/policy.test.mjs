import assert from 'node:assert/strict';
import test from 'node:test';
import { dailyGrant } from '../lib/policy.js';

test('daily rewards follow local calendar days, cap award, and reset after gaps', () => {
  let state = null;
  const awards = [];
  for (let day = 1; day <= 9; day++) {
    const grant = dailyGrant(new Date(`2026-01-${String(day).padStart(2, '0')}T12:00:00Z`), state);
    awards.push(grant.coins);
    state = { lastLocalDate: grant.dayKey, streakDay: grant.streakDay };
  }
  assert.deepEqual(awards, [5, 10, 15, 30, 50, 70, 100, 100, 100]);
  assert.equal(dailyGrant(new Date('2026-01-11T12:00:00Z'), state).coins, 5);
  assert.equal(dailyGrant(new Date('2026-01-09T16:59:59Z'), state).alreadyClaimed, true);
  assert.equal(dailyGrant(new Date('2026-01-09T17:00:00Z'), state).streakDay, 10);
  assert.equal(dailyGrant(new Date('2026-12-31T17:00:00Z'), { lastLocalDate: '2026-12-31', streakDay: 7 }).dayKey, '2027-01-01');
});
