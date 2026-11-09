import assert from 'node:assert/strict';
import test from 'node:test';
import { analyticsReportQuery } from '../lib/admin_integrations.js';

test('realtime uses the last 30 minutes and metrics supported by Realtime API', () => {
  const report = analyticsReportQuery({ realtime: true, source: 'android' });
  assert.deepEqual(report.minuteRanges, [{ startMinutesAgo: 29, endMinutesAgo: 0 }]);
  assert.equal(report.dateRanges, undefined);
  assert.deepEqual(report.metrics.map(metric => metric.name), ['eventCount', 'activeUsers']);
  assert.equal(report.dimensionFilter.filter.fieldName, 'platform');
  assert.throws(() => analyticsReportQuery({ realtime: true, days: 7 }));
});

test('Android and web reports filter platform, independently of the old web stream setting', () => {
  const android = analyticsReportQuery({ days: 7, source: 'android' }, '1234');
  assert.equal(android.dimensionFilter.filter.fieldName, 'platform');
  assert.deepEqual(android.dimensionFilter.filter.stringFilter,
    { matchType: 'EXACT', value: 'Android', caseSensitive: false });
  assert.equal(android.dateRanges[0].startDate, '6daysAgo');
  assert.equal(analyticsReportQuery({ days: 30, source: 'web' }).dimensionFilter.filter.stringFilter.value, 'web');
});
test('existing callers retain configured stream/property behavior; invalid sources rejected', () => {
  assert.equal(analyticsReportQuery({ days: 7 }, '1234').dimensionFilter.filter.fieldName, 'streamId');
  assert.equal(analyticsReportQuery({ days: 7 }).dimensionFilter, undefined);
  assert.throws(() => analyticsReportQuery({ days: 7, source: 'arbitrary' }));
  assert.throws(() => analyticsReportQuery({ days: 1, source: 'android' }));
});
