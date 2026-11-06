import assert from 'node:assert/strict';
import test from 'node:test';
import { insufficientRewardFixture } from './account_fixture.mjs';

const wallet = { availableCoins: 200 };
const reward = { id: 'test-only', status: 'active', stockRemaining: 2, priceCoins: 350 };

test('selects an unaffordable available reward and derives unchanged balance expectations', () => {
  const result = insufficientRewardFixture(wallet, { items: [{ ...reward, stockRemaining: 0 }, { ...reward, priceCoins: 100 }, reward] }, { items: [{ id: 'b' }, { id: 'a' }] });
  assert.equal(result.reward, reward);
  assert.deepEqual(result.redemptionIds, ['a', 'b']);
  assert.deepEqual(result.expected, { insufficient_funds_visible: true, available_before: 200, available_after: 200, receipt_created: false });
});

test('refuses incomplete receipt history and missing eligible rewards', () => {
  assert.throws(() => insufficientRewardFixture(wallet, { items: [reward] }, { items: [], nextCursor: 'more' }), /complete/);
  assert.throws(() => insufficientRewardFixture(wallet, { items: [{ ...reward, status: 'inactive' }] }, { items: [] }), /No active/);
  assert.throws(() => insufficientRewardFixture({ availableCoins: -1 }, { items: [reward] }, { items: [] }), /Invalid server/);
});
