import assert from 'node:assert/strict';
import test from 'node:test';
import { analyticsEventLabel, analyticsScopeLabel } from '../src/analytics-labels.js';

test('event labels show readable names in the report', () => {
  assert.equal(analyticsEventLabel('action_error'), 'Thao tác gặp lỗi');
  assert.equal(analyticsEventLabel('register_event'), 'Đăng ký sự kiện');
  assert.equal(analyticsEventLabel('session_start'), 'Bắt đầu phiên truy cập');
  assert.equal(analyticsEventLabel('custom_event_name'), 'Custom event name');
  assert.match(analyticsScopeLabel('android'), /tất cả stream Android/);
  assert.match(analyticsScopeLabel('stream'), /backend/);
});
