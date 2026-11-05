import assert from 'node:assert/strict';
import test from 'node:test';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { fileURLToPath } from 'node:url';

const script = new URL('../scripts/send-demo-notification.mjs', import.meta.url);
const run = args => promisify(execFile)(process.execPath, [fileURLToPath(script), ...args], {
  env: { ...process.env, APPDATA: 'no-firebase-cli-for-test' },
});

test('demo push defaults to a preview with exactly one recipient and no authentication', async () => {
  const { stdout } = await run(['--uid', 'test-user']);
  const plan = JSON.parse(stdout);
  assert.equal(plan.mode, 'DRY RUN');
  assert.equal(plan.uid, 'test-user');
  assert.equal(plan.eventId, 'demo-career-talk');
  assert.equal(plan.project, 'prm393-31822');
  assert.equal(plan.noNetwork, true);
});

test('missing recipient or path injection fails before authentication or writes', async () => {
  for (const args of [[], ['--uid', 'users/someone'], ['--uid', 'test-user', '--event', '../events']]) {
    await assert.rejects(run(args), error => {
      assert.match(error.stderr, /UID|event/i);
      assert.doesNotMatch(error.stderr, /Cannot find module/);
      return true;
    });
  }
});
