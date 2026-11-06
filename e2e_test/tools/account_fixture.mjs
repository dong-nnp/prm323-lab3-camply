// Maintainer-only test setup. Creates one dedicated Firebase email/password account;
// never edits another user's wallet, registrations, attendance or catalog records.
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { randomBytes } from 'node:crypto';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

export function insufficientRewardFixture(wallet, rewards, redemptions) {
  if (!Number.isSafeInteger(wallet.availableCoins) || wallet.availableCoins < 0) throw Error('Invalid server balance');
  if (redemptions.nextCursor || !Array.isArray(redemptions.items)) throw Error('Redemption baseline must be complete');
  const reward = rewards.items.find(row => row.status === 'active' && row.stockRemaining > 0 && Number.isSafeInteger(row.priceCoins) && row.priceCoins > wallet.availableCoins);
  if (!reward) throw Error('No active in-stock reward above the test balance');
  return {
    reward,
    redemptionIds: redemptions.items.map(row => row.id).sort(),
    expected: { insufficient_funds_visible: true, available_before: wallet.availableCoins, available_after: wallet.availableCoins, receipt_created: false },
  };
}

async function main() {
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const local = resolve(root, '.local/e2e');
await mkdir(local, { recursive: true });
const config = JSON.parse(await readFile(resolve(root, 'android/app/google-services.json'), 'utf8'));
if (config.project_info.project_id !== 'prm393-31822') throw Error('Unexpected Firebase project');
const client = config.client.find(c => c.client_info.android_client_info.package_name === 'com.example.prm393_lab03');
const apiKey = client.api_key[0].current_key;
const accountFile = resolve(local, 'test-account.json');
const [mode = 'create', caseId] = process.argv.slice(2);
async function http(url, body, headers = {}) {
  const r = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json', ...headers }, body: JSON.stringify(body), signal: AbortSignal.timeout(60000) });
  const data = await r.json();
  if (!r.ok || data.error) throw Error('Test setup request failed: ' + (data.error?.status || data.error?.message || r.status));
  return data;
}
async function login(account) {
  return http(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`, { email: account.email, password: account.password, returnSecureToken: true });
}
async function callable(name, token, data = {}) {
  const result = await http(`https://asia-southeast1-prm393-31822.cloudfunctions.net/${name}`, { data }, { Authorization: `Bearer ${token}` });
  return result.result ?? result.data;
}
async function savedAccount() {
  const account = JSON.parse(await readFile(accountFile, 'utf8'));
  if (account.project !== config.project_info.project_id || account.purpose !== 'evia-artemis-dedicated-test' || !/^evia\.e2e\.[a-f0-9]+@example\.com$/.test(account.email)) throw Error('Refusing non-test account');
  const auth = await login(account);
  if (auth.localId !== account.uid) throw Error('Test UID mismatch');
  return { account, auth };
}
const supported = ['TC02', 'TC05', 'TC06', 'TC07', 'TC14', 'TC18', 'TC19'];
async function configure(account) {
  const settingsFile = resolve(local, 'settings.json');
  const settings = JSON.parse(await readFile(settingsFile, 'utf8'));
  settings.test_account_uid = account.uid;
  settings.test_account_email = account.email;
  const driver = resolve(root, 'e2e_test/tools/account_fixture.mjs');
  for (const id of supported) settings.cases[id] = { prepare_command: ['node', driver, 'prepare'], verify_command: ['node', driver, 'verify'], cleanup_command: ['node', driver, 'cleanup'] };
  await writeFile(settingsFile, JSON.stringify(settings, null, 2));
}
function testAdb() {
  const adb = resolve(process.env.LOCALAPPDATA, 'Android/Sdk/platform-tools/adb.exe');
  const call = args => execFileSync(adb, ['-s', 'emulator-5556', ...args], { encoding: 'utf8', timeout: 60000 });
  if (call(['emu', 'avd', 'name']).split(/\r?\n/)[0].trim() !== 'EVIA_E2E') throw Error('Refusing non-test AVD');
  if (call(['shell', 'am', 'get-current-user']).trim() !== '0') throw Error('Unexpected Android user');
  return call;
}
if (mode === 'configure') {
  const { account } = await savedAccount();
  await configure(account);
  console.log(JSON.stringify({ configured: supported, existing_dedicated_account: true }));
  return;
}
if (mode === 'create') {
  let exists = false;
  try { await readFile(accountFile); exists = true; } catch (error) { if (error.code !== 'ENOENT') throw error; }
  if (exists) {
    const { account } = await savedAccount();
    await configure(account);
    console.log(JSON.stringify({ ready: true, existing_dedicated_account: true }));
    return;
  }
  const email = `evia.e2e.${randomBytes(8).toString('hex')}@example.com`;
  const password = randomBytes(24).toString('base64url') + '!aA9';
  const auth = await http(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${apiKey}`, { email, password, returnSecureToken: true });
  // Save immediately so a setup retry never creates additional accounts.
  const account = { purpose: 'evia-artemis-dedicated-test', project: config.project_info.project_id, uid: auth.localId, email, password, createdAt: new Date().toISOString() };
  await writeFile(accountFile, JSON.stringify(account, null, 2));
  await callable('initializeUser', auth.idToken);
  await callable('updateProfile', auth.idToken, { displayName: 'EVIA E2E', studentId: 'SE990001', universityEmail: email });
  const data = await callable('getAccount', auth.idToken);
  const interests = data.interestOptions.slice(0, 3).map(i => i.id);
  if (interests.length !== 3) throw Error('Not enough real catalog interests for test setup');
  await callable('saveInterests', auth.idToken, { interests });
  await configure(account);
  console.log(JSON.stringify({ ready: true, dedicated_account_created: true, onboarding_complete: true, no_existing_account_modified: true }));
} else if (['prepare', 'verify', 'cleanup'].includes(mode)) {
  if (!supported.includes(caseId)) throw Error('Case not supported by this isolated account driver');
  const { account, auth } = await savedAccount();
  if (mode === 'cleanup') {
    if (caseId === 'TC19') {
      const adb = testAdb();
      adb(['shell', 'svc', 'wifi', 'enable']);
      adb(['shell', 'svc', 'data', 'enable']);
    }
    if (caseId === 'TC07') {
      await callable('setBookmark', auth.idToken, { eventId: 'demo-career-talk', saved: false });
      await callable('unfollowOrganizer', auth.idToken, { organizerId: 'demo-tech-club' });
    }
    console.log(JSON.stringify({ cleaned: true, case_id: caseId, uid: account.uid }));
    return;
  }
  const data = await callable('getAccount', auth.idToken);
  const baseline = resolve(local, caseId + '-before.json');
  if (mode === 'prepare') {
    const settings = JSON.parse(await readFile(resolve(local, 'settings.json'), 'utf8'));
    if (settings.avd_name !== 'EVIA_E2E' || settings.device !== 'emulator-5556') throw Error('Refusing personal emulator');
    const adb = resolve(process.env.LOCALAPPDATA, 'Android/Sdk/platform-tools/adb.exe');
    const callAdb = args => execFileSync(adb, ['-s', settings.device, ...args], { encoding: 'utf8', timeout: 60000 });
    if (callAdb(['emu', 'avd', 'name']).split(/\r?\n/)[0].trim() !== 'EVIA_E2E') throw Error('AVD identity mismatch');
    if (callAdb(['shell', 'am', 'get-current-user']).trim() !== '0') throw Error('Unexpected test Android user');
    callAdb(['shell', 'am', 'force-stop', 'com.example.prm393_lab03']);
    const clear = callAdb(['shell', 'pm', 'clear', '--user', '0', 'com.example.prm393_lab03']);
    if (!clear.includes('Success')) throw Error('Could not reset isolated test app state');
    callAdb(['shell', 'pm', 'grant', 'com.example.prm393_lab03', 'android.permission.POST_NOTIFICATIONS']);
    callAdb(['shell', 'am', 'start', '-n', 'com.example.prm393_lab03/.MainActivity']);
    const context = { login: { method: 'email_password', email: account.email, password: account.password }, instruction: 'Start from Welcome, choose Log In and use the supplied dedicated test credentials. Do not use Google. Profile should show EVIA E2E.' };
    let expected;
    if (caseId === 'TC02') {
      delete context.login;
      context.instruction = 'Stay signed out. Open Log In, tap Continue with Google, then cancel/back out of the native Google flow. Never enter credentials or add an account. Finish on the login screen.';
      expected = { screen: 'Login', google_picker_seen: true, signed_in: false };
    }
    if (caseId === 'TC05') expected = { visited_tabs: ['Discover', 'Events', 'Rewards', 'Profile'], selected_tab: 'Profile' };
    if (caseId === 'TC06') {
      const event = await callable('getEvent', auth.idToken, { eventId: 'demo-career-talk' });
      const organizer = await callable('getOrganizer', auth.idToken, { organizerId: event.organizerId });
      const rewards = await callable('getPublicCatalog', auth.idToken, { kind: 'rewards', limit: 50 });
      const reward = rewards.items[0];
      if (!reward) throw Error('No real reward available for detail fixture');
      const localTime = new Date(new Date(event.startAt).getTime() + 7 * 3600000);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const date = `${months[localTime.getUTCMonth()]} ${localTime.getUTCDate()}, ${localTime.getUTCFullYear()} · ${String(localTime.getUTCHours()).padStart(2, '0')}:${String(localTime.getUTCMinutes()).padStart(2, '0')}`;
      context.entities = { event_title: event.title, organizer_name: organizer.name, reward_title: reward.title };
      context.navigation = 'Open the event from Discover/Search, check its About/Schedule/Location tabs, then Back to Discover. Reopen event About, open its organizer and Back to Event Details. Open the named reward from Rewards and Back to Rewards. Report back_destinations as canonical names Discover, Event Details, Rewards in this order. Do not register or redeem.';
      expected = { event_title: event.title, organizer_name: organizer.name, reward_title: reward.title, price_coins: reward.priceCoins, event_date: date, back_destinations: ['Discover', 'Event Details', 'Rewards'] };
    }
    if (caseId === 'TC07') {
      await callable('setBookmark', auth.idToken, { eventId: 'demo-career-talk', saved: false });
      await callable('unfollowOrganizer', auth.idToken, { organizerId: 'demo-tech-club' });
      const event = await callable('getEvent', auth.idToken, { eventId: 'demo-career-talk' });
      const organizer = await callable('getOrganizer', auth.idToken, { organizerId: 'demo-tech-club' });
      context.entities = { event_title: event.title, organizer_name: organizer.name };
      expected = { saved_after: true, followed_after: true, saved_after_undo: false, followed_after_undo: false };
    }
    let redemptionIds;
    if (caseId === 'TC14') {
      const rewards = await callable('getPublicCatalog', auth.idToken, { kind: 'rewards', limit: 50 });
      const receipts = await callable('listOwned', auth.idToken, { kind: 'redemptions', limit: 50 });
      const fixture = insufficientRewardFixture(data.wallet, rewards, receipts);
      expected = fixture.expected;
      redemptionIds = fixture.redemptionIds;
      context.entities = { reward_title: fixture.reward.title };
      context.navigation = 'Read your available balance in Rewards. Open the named reward detail and inspect the insufficient-coins message or disabled redemption button. Never earn more coins, claim daily, or redeem another reward. Return available_before/available_after as JSON integers read from the UI. Open My Rewards to check no new receipt appeared.';
    }
    if (caseId === 'TC18') expected = { signed_in: false, old_account_data_visible: false, guard_blocks: true };
    if (caseId === 'TC19') expected = { error_visible: true, retry_visible: true, recovered: true };
    await writeFile(baseline, JSON.stringify({ ...data.wallet, ...(redemptionIds ? { redemptionIds } : {}) }));
    console.log(JSON.stringify({ ready: true, uid: account.uid, case_id: caseId, context, expected }));
  } else {
    const before = JSON.parse(await readFile(baseline, 'utf8'));
    let verified = before.availableCoins === data.wallet.availableCoins && before.heldCoins === data.wallet.heldCoins && data.profile.displayName === 'EVIA E2E';
    if (caseId === 'TC07') {
      const bookmarks = await callable('listOwned', auth.idToken, { kind: 'bookmarks', limit: 50 });
      const following = await callable('listOwned', auth.idToken, { kind: 'following', limit: 50 });
      verified &&= !bookmarks.items.some(row => row.eventId === 'demo-career-talk') && !following.items.some(row => row.organizerId === 'demo-tech-club');
    }
    if (caseId === 'TC14') {
      const receipts = await callable('listOwned', auth.idToken, { kind: 'redemptions', limit: 50 });
      verified &&= !receipts.nextCursor && before.version === data.wallet.version && Array.isArray(before.redemptionIds) && JSON.stringify(before.redemptionIds) === JSON.stringify(receipts.items.map(row => row.id).sort());
    }
    console.log(JSON.stringify({ verified, uid: account.uid, case_id: caseId, wallet_unchanged: verified, wallet: data.wallet }));
  }
} else throw Error('Unknown mode');

}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
