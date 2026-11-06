import assert from 'node:assert/strict';
import test from 'node:test';
import { analyticsReportQuery } from '../lib/admin_integrations.js';

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
