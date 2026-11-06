import { execFileSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { appendFileSync, existsSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const scheme = 'evia-android-qa';
const registry = 'HKCU\\Software\\Classes\\' + scheme;
const androidPackage = 'com.example.prm393_lab03';
const emulatorSerial = /^emulator-[1-9]\d{3,4}$/;
const script = fileURLToPath(import.meta.url);

function run(program, args) {
  return execFileSync(program, args, { encoding: 'utf8', timeout: 8000, windowsHide: true }).trim();
}

export function crashQaApp(shell) {
  const pid = shell(['pidof', '-s', androidPackage]);
  if (!/^[1-9]\d*$/.test(pid)) throw new Error('Open Evia QA on the selected emulator.');
  const qaPid = shell(['run-as', androidPackage, 'cat', 'files/evia-qa-crash-pid']);
  if (qaPid !== pid) throw new Error('The running app is outside Android QA mode.');
  const current = shell(['pidof', '-s', androidPackage]);
  if (current !== pid) throw new Error('The app restarted. Open Evia QA and retry.');
  shell(['am', 'crash', '--user', 'current', pid]);
}

function handleRequest(configPath, url) {
  const config = JSON.parse(readFileSync(configPath, 'utf8'));
  if (url !== scheme + '://crash/' + config.token || !emulatorSerial.test(config.serial)) return;
  try {
    process.kill(config.ownerPid, 0);
    if (run(config.adb, ['-s', config.serial, 'get-state']) !== 'device') {
      throw new Error('The selected emulator is offline.');
    }
    crashQaApp(args => run(config.adb, ['-s', config.serial, 'shell', ...args]));
    appendFileSync(config.log, 'Crash requested for ' + config.serial + '.\n');
  } catch (error) {
    appendFileSync(config.log, 'Crash request failed: ' + error.message + '\n');
  }
}

async function start(serial) {
  if (process.platform !== 'win32' || !emulatorSerial.test(serial ?? '')) {
    throw new Error('Run on Windows with the serial of a local Android emulator, for example emulator-5554.');
  }
  const sdk = process.env.ANDROID_HOME || process.env.ANDROID_SDK_ROOT ||
    join(process.env.LOCALAPPDATA, 'Android', 'Sdk');
  const adb = join(sdk, 'platform-tools', 'adb.exe');
  if (!existsSync(adb) || run(adb, ['-s', serial, 'get-state']) !== 'device') {
    throw new Error('Start the selected Android emulator first.');
  }
  const dir = mkdtempSync(join(tmpdir(), 'evia-android-qa-'));
  const configPath = join(dir, 'session.json');
  const log = join(dir, 'activity.log');
  const token = randomBytes(24).toString('hex');
  writeFileSync(configPath, JSON.stringify({ serial, adb, token, log, ownerPid: process.pid }));
  process.env.VITE_QA_ANDROID_TOKEN = token;
  process.env.VITE_QA_ANDROID_DEVICE = serial;
  process.env.VITE_ENABLE_DIAGNOSTICS = 'true';

  const { createServer } = await import('vite');
  const server = await createServer({ server: { host: '127.0.0.1', port: 5174, strictPort: true } });
  try {
    await server.listen();
    const command = [process.execPath, script, 'request', configPath, '%1'].map(value => '"' + value + '"').join(' ');
    run('reg.exe', ['add', registry, '/v', 'URL Protocol', '/t', 'REG_SZ', '/d', '', '/f']);
    run('reg.exe', ['add', registry + '\\shell\\open\\command', '/ve', '/t', 'REG_SZ', '/d', command, '/f']);
    server.printUrls();
    console.log('Android QA: ' + serial + ' | Local log: ' + log);
    process.once('exit', () => {
      // The handler expires with this session. Keep the activity log for debugging.
      try { writeFileSync(configPath, '{}'); } catch {}
    });
  } catch (error) {
    await server.close();
    throw error;
  }
}

if (process.argv[1] && process.argv[1] === script) {
  const [mode, ...args] = process.argv.slice(2);
  if (mode === 'request') handleRequest(...args);
  else await start(mode);
}
