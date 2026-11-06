import assert from 'node:assert/strict';
import test from 'node:test';
import { crashQaApp } from '../scripts/android-qa.mjs';

test('Android QA rejects an unmarked or restarted process', () => {
  for (const replies of [['1234', ''], ['1234', '1234', '5678']]) {
    assert.throws(() => crashQaApp(args => {
      assert.notEqual(args[0], 'am');
      return replies.shift();
    }), /outside Android QA|restarted/);
  }
});

test('Android QA sends a crash to the verified process only', () => {
  const calls = [];
  crashQaApp(args => { calls.push(args); return '1234'; });
  assert.deepEqual(calls.at(-1), ['am', 'crash', '--user', 'current', '1234']);
});
