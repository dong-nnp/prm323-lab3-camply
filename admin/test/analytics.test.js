import assert from 'node:assert/strict';
import test from 'node:test';
import { analyticsEventLabel, analyticsScopeLabel } from '../src/analytics-labels.js';

test('event labels retain raw names for verification and unknown events', () => {
  assert.equal(analyticsEventLabel('register_event'), 'Đăng ký sự kiện (register_event)');
  assert.equal(analyticsEventLabel('session_start'), 'session_start');
  assert.match(analyticsScopeLabel('android'), /tất cả stream Android/);
  assert.match(analyticsScopeLabel('stream'), /backend/);
});
