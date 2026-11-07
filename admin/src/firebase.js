import { initializeApp } from 'firebase/app';
import {
  browserSessionPersistence, connectAuthEmulator, initializeAuth, onIdTokenChanged, signInWithEmailAndPassword, signOut,
} from 'firebase/auth';
import { connectFunctionsEmulator, getFunctions, httpsCallable } from 'firebase/functions';
import { connectStorageEmulator, getStorage, ref, uploadBytesResumable, getDownloadURL } from 'firebase/storage';
import { validateEventImage } from './event-image.js';
export function createFirebase(env) {
  const emulator = env.VITE_FIREBASE_EMULATORS === 'true';
  const options = emulator
    ? { projectId: 'demo-evia-backend', apiKey: 'demo-evia-backend', storageBucket: 'demo-evia-backend.appspot.com' }
    : {
        apiKey: env.VITE_FIREBASE_API_KEY,
        authDomain: env.VITE_FIREBASE_AUTH_DOMAIN,
        projectId: env.VITE_FIREBASE_PROJECT_ID,
        appId: env.VITE_FIREBASE_APP_ID,
        messagingSenderId: env.VITE_FIREBASE_MESSAGING_SENDER_ID,
        measurementId: env.VITE_FIREBASE_MEASUREMENT_ID,
        storageBucket: env.VITE_FIREBASE_STORAGE_BUCKET,
      };
  if (!options.apiKey || !options.projectId || (!emulator && !options.appId)) return null;

  const app = initializeApp(options);
  const auth = initializeAuth(app, { persistence: browserSessionPersistence });
  const functions = getFunctions(app, 'asia-southeast1');
  if (emulator) {
    connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
    connectFunctionsEmulator(functions, '127.0.0.1', 5001);
  }

  const call = async (name, data) => (await httpsCallable(functions, name)(data)).data;
  let analytics;
  let storage;
  async function catalog(kind, filters = {}) {
    const items = [];
    const cursors = new Set();
    let cursor;
    do {
      const page = await call('getPublicCatalog', { kind, ...filters, limit: 50, ...(cursor && { cursor }) });
      items.push(...page.items);
      if (page.nextCursor && cursors.has(page.nextCursor)) throw new Error('Không tải được danh sách. Vui lòng thử lại.');
      cursor = page.nextCursor;
      if (cursor) cursors.add(cursor);
    } while (cursor);
    return { items };
  }
  return {
    emulator,
    projectId: options.projectId,
    analyticsEnabled: !emulator && env.VITE_FIREBASE_ANALYTICS_ENABLED === 'true',
    observeAuth(listener, onError) {
      return onIdTokenChanged(auth, listener, onError);
    },
    login: (email, password) => signInWithEmailAndPassword(auth, email, password),
    logout: () => signOut(auth),
    notificationUsers: cursor => call('listAdminRecords', { kind: 'users', limit: 50, ...(cursor && { cursor }) }),
    sendNotification: input => call('sendAdminNotification', input),
    list: (kind, cursor) => call(kind === 'events' ? 'listAdminEvents' : 'listAdminRewards', { limit: 20, ...(cursor && { cursor }) }),
    organizers: () => catalog('organizers'),
    categories: () => catalog('interests'),
    checkInEvents: () => catalog('events', { participationMode: 'registration' }),
    checkInEvent: eventId => call('getEvent', { eventId }),
    serverInfo: () => call('getServerInfo', {}),
    verifyTicket: input => call('verifyRegisteredTicket', input),
    verifyTicketNumber: input => call('verifyAdminTicketNumber', input),
    async uploadEventImage(file, onProgress) {
      const extension = validateEventImage(file);
      const user = auth.currentUser;
      if (!user) throw new Error('Vui lòng đăng nhập lại trước khi tải ảnh.');
      if (!options.storageBucket) throw new Error('Chưa cấu hình Firebase Storage bucket.');
      if (!storage) {
        storage = getStorage(app);
        if (emulator) connectStorageEmulator(storage, '127.0.0.1', 9199);
      }
      // shortcut: retain replaced/orphan uploads; add reference-aware cleanup if unused images accumulate.
      const target = ref(storage, `event-images/${user.uid}/${crypto.randomUUID()}.${extension}`);
      const task = uploadBytesResumable(target, file, { contentType: file.type, cacheControl: 'public,max-age=31536000,immutable' });
      await new Promise((resolve, reject) => {
        task.on('state_changed', snapshot => onProgress?.(Math.round(snapshot.bytesTransferred * 100 / snapshot.totalBytes)), reject, resolve);
      });
      if (auth.currentUser !== user) throw new Error('Phiên đăng nhập đã thay đổi. Vui lòng mở lại biểu mẫu.');
      return getDownloadURL(task.snapshot.ref);
    },
    entry: (kind, id) => call(kind === 'events' ? 'getAdminEvent' : 'getAdminReward', { id }),
    getWalkInQr: eventId => call('getAdminWalkInQr', { eventId }),
    save: (kind, entry, revision) => {
      const event = kind === 'events';
      const name = event ? (revision ? 'updateEvent' : 'createEvent') : (revision ? 'updateReward' : 'createReward');
      return call(name, JSON.parse(JSON.stringify({ [event ? 'event' : 'reward']: entry, ...(revision && { revision }) })));
    },
    publishEvent: (id, revision) => call('publishEvent', { id, revision }),
    getRemoteConfig: () => call('getAdminRemoteConfig', {}),
    publishRemoteConfig: (config) => call('publishAdminRemoteConfig', config),
    report: (kind, days, source) => call(kind === 'analytics' ? 'getAdminAnalyticsReport' : 'getAdminCrashlyticsReport', { days, ...(kind === 'analytics' && source && { source }) }),
    async track(name) {
      if (!this.analyticsEnabled || !auth.currentUser) return;
      try {
        analytics ??= import('firebase/analytics').then(async (sdk) => {
          if (!await sdk.isSupported()) {
            if (import.meta.env.DEV) {
              console.warn('[Evia Analytics] Trình duyệt không hỗ trợ Analytics trong phiên này. Kiểm tra cookies và IndexedDB.');
            }
            return null;
          }
          return { sdk, instance: sdk.getAnalytics(app) };
        }).catch(error => {
          analytics = undefined;
          throw error;
        });
        const service = await analytics;
        if (!service) return;
        service.sdk.logEvent(service.instance, name);
        if (import.meta.env.DEV) console.info('[Evia Analytics] Đã gọi logEvent:', name);
      } catch (error) {
        if (import.meta.env.DEV) {
          console.warn('[Evia Analytics] Không thể ghi sự kiện:', name, error?.code ?? error?.name);
        }
      }
    },
  };
}
