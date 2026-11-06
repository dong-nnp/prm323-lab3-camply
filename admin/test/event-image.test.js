import assert from 'node:assert/strict';
import test from 'node:test';
import { validateEventImage } from '../src/event-image.js';

test('event image accepts only bounded JPG, PNG and WebP files', () => {
  for (const [type, extension] of [['image/jpeg', 'jpg'], ['image/png', 'png'], ['image/webp', 'webp']]) {
    assert.equal(validateEventImage({ type, size: 5 * 1024 * 1024 }), extension);
  }
  for (const file of [null, { type: 'image/svg+xml', size: 20 }, { type: 'image/png', size: 0 }, { type: 'image/png', size: 5 * 1024 * 1024 + 1 }]) {
    assert.throws(() => validateEventImage(file));
  }
});
