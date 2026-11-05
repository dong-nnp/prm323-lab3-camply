import { Adb, AdbDaemonTransport } from '@yume-chan/adb';
import AdbWebCredentialStore from '@yume-chan/adb-credential-web';
import { AdbDaemonWebUsbDeviceManager } from '@yume-chan/adb-daemon-webusb';

export const androidPackage = 'com.example.prm393_lab03';
const delay = (milliseconds) => new Promise(resolve => setTimeout(resolve, milliseconds));

export async function crashDebugProcess(shell, onRequested, wait = delay) {
  const debuggable = await shell(['run-as', androidPackage, 'id']);
  if (debuggable.exitCode !== 0) throw new Error('Thiết bị chưa cài bản debug Evia.');
  const pidCommand = ['pidof', '-s', androidPackage];
  const process = await shell(pidCommand);
  const pid = process.stdout.trim();
  if (process.exitCode !== 0 || !/^[1-9]\d*$/.test(pid)) throw new Error('Hãy mở app Evia QA trên điện thoại trước.');
  const command = await shell(['am', 'crash', '--user', 'current', androidPackage]);
  if (command.exitCode !== 0 || command.stderr.trim()) throw new Error('Android từ chối lệnh crash.');
  onRequested();
  for (let attempt = 0; attempt < 8; attempt++) {
    await wait(400);
    const current = await shell(pidCommand);
    if (current.stdout.trim() === pid) continue;
    const log = await shell(['logcat', '-b', 'crash', '--pid=' + pid, '-d']);
    if (log.exitCode === 0 && /FATAL EXCEPTION/.test(log.stdout) &&
        log.stdout.includes('Process: ' + androidPackage + ', PID: ' + pid)) return;
  }
  throw new Error('Đã gửi lệnh nhưng chưa xác minh được crash trong log Android.');
}

export function createQaDevice(approvedSerial, onDisconnect) {
  const manager = AdbDaemonWebUsbDeviceManager.BROWSER;
  let device;
  let generation = 0;
  return {
    available: Boolean(manager && approvedSerial),
    get connected() { return Boolean(device); },
    async connect() {
      if (!manager || !approvedSerial) throw new Error('WebUSB hoặc thiết bị QA chưa được cấu hình.');
      const request = ++generation;
      const selected = await manager.requestDevice();
      if (!selected || request !== generation) return false;
      if (selected.serial !== approvedSerial) throw new Error('Thiết bị này nằm ngoài phạm vi QA được cấp phép.');
      const connection = await selected.connect();
      let transport;
      const timeout = setTimeout(() => {
        void selected.raw.close().catch(() => {});
      }, 25000);
      try {
        transport = await AdbDaemonTransport.authenticate({
          serial: selected.serial,
          connection,
          credentialStore: new AdbWebCredentialStore('Evia Admin QA'),
        });
        const adb = new Adb(transport);
        const shell = adb.subprocess.shellProtocol;
        if (request !== generation || !shell) {
          await adb.close();
          if (!shell) throw new Error('Thiết bị không hỗ trợ ADB shell v2.');
          return false;
        }
        device = { adb, shell };
        const disconnected = () => {
          if (device?.adb !== adb) return;
          device = undefined;
          onDisconnect();
        };
        void transport.disconnected.then(disconnected, disconnected);
        return true;
      } catch (error) {
        if (!transport) await selected.raw.close().catch(() => {});
        throw error;
      } finally {
        clearTimeout(timeout);
      }
    },
    async disconnect() {
      generation++;
      const previous = device;
      device = undefined;
      if (previous) await previous.adb.close();
    },
    async crash(onRequested) {
      if (!device) throw new Error('Kết nối lại Android QA trước khi chạy test.');
      const connection = device;
      return crashDebugProcess(command => {
        if (device !== connection) throw new Error('Kết nối Android QA đã bị ngắt.');
        return connection.shell.spawnWaitText(command);
      }, onRequested);
    },
  };
}
