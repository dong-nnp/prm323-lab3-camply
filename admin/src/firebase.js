import { initializeApp } from 'firebase/app';
import {
  browserSessionPersistence, connectAuthEmulator, initializeAuth, onIdTokenChanged, signInWithEmailAndPassword, signOut,
} from 'firebase/auth';
import { connectFunctionsEmulator, getFunctions, httpsCallable } from 'firebase/functions';
import defaults from '../../firebase/remote-config-defaults.json';

export const milestoneDefaults = {
  enabled: defaults.event_milestones_enabled,
  intro: defaults.event_milestones_intro,
  source: 'Mặc định',
};

export function createFirebase(env) {
  const emulator = env.VITE_FIREBASE_EMULATORS === 'true';
  const options = emulator
    ? { projectId: 'demo-evia-backend', apiKey: 'demo-evia-backend' }
    : {
        apiKey: env.VITE_FIREBASE_API_KEY,
        authDomain: env.VITE_FIREBASE_AUTH_DOMAIN,
        projectId: env.VITE_FIREBASE_PROJECT_ID,
        appId: env.VITE_FIREBASE_APP_ID,
        messagingSenderId: env.VITE_FIREBASE_MESSAGING_SENDER_ID,
        measurementId: env.VITE_FIREBASE_MEASUREMENT_ID,
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
  return {
    emulator,
    projectId: options.projectId,
    analyticsEnabled: !emulator && env.VITE_FIREBASE_ANALYTICS_ENABLED === 'true',
    observeAuth(listener) {
      return onIdTokenChanged(auth, listener);
    },
    login: (email, password) => signInWithEmailAndPassword(auth, email, password),
    logout: () => signOut(auth),
    list: (kind, cursor) => call(kind === 'events' ? 'listAdminEvents' : 'listAdminRewards', { limit: 20, ...(cursor && { cursor }) }),
    organizers: () => call('getPublicCatalog', { kind: 'organizers', limit: 50 }),
    entry: (kind, id) => call(kind === 'events' ? 'getAdminEvent' : 'getAdminReward', { id }),
    save: (kind, entry, revision) => {
      const event = kind === 'events';
      const name = event ? (revision ? 'updateEvent' : 'createEvent') : (revision ? 'updateReward' : 'createReward');
      return call(name, JSON.parse(JSON.stringify({ [event ? 'event' : 'reward']: entry, ...(revision && { revision }) })));
    },
    publishEvent: (id, revision) => call('publishEvent', { id, revision }),
    getRemoteConfig: () => call('getAdminRemoteConfig', {}),
    publishRemoteConfig: (config) => call('publishAdminRemoteConfig', config),
    report: (kind, days) => call(kind === 'analytics' ? 'getAdminAnalyticsReport' : 'getAdminCrashlyticsReport', { days }),
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
