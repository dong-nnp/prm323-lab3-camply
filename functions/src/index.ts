import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { createBackend } from './backend.js';
import { REGION } from './policy.js';
import { key } from './shared.js';

initializeApp();
// Lab traffic fits fractional CPU and avoids exhausting the project's regional CPU quota.
setGlobalOptions({ region: REGION, minInstances: 0, maxInstances: 3, memory: '256MiB', cpu: 'gcf_gen1', concurrency: 1 });
const db = getFirestore(), backend = createBackend(db);
const callable = (name: string) => onCall({ enforceAppCheck: process.env.ENFORCE_APP_CHECK === 'true' }, async request => {
  try { return await backend.invoke(name, request.auth ? { uid: request.auth.uid, token: request.auth.token } : null, request.data ?? {}); }
  catch (error) {
    if (error instanceof HttpsError) throw error;
    // No payload, token, PII, voucher code or raw SDK diagnostics are returned/logged.
    console.error('Backend failure', { operation: name });
    throw new HttpsError('internal', 'INTERNAL_ERROR', { code: 'INTERNAL_ERROR' });
  }
});
export const initializeUser = callable('initializeUser');
export const updateProfile = callable('updateProfile');
export const saveInterests = callable('saveInterests');
export const getAccount = callable('getAccount');
export const followOrganizer = callable('followOrganizer');
export const unfollowOrganizer = callable('unfollowOrganizer');
export const setBookmark = callable('setBookmark');
export const setWalkInGoing = callable('setWalkInGoing');
export const registerForEvent = callable('registerForEvent');
export const cancelRegistration = callable('cancelRegistration');
export const getTicketQr = callable('getTicketQr');
export const issueWalkInQr = callable('issueWalkInQr');
export const verifyRegisteredTicket = callable('verifyRegisteredTicket');
export const verifyWalkInQr = callable('verifyWalkInQr');
export const claimDailyCheckin = callable('claimDailyCheckin');
export const grantMonthlyGift = callable('grantMonthlyGift');
export const redeemReward = callable('redeemReward');
export const getVoucherCode = callable('getVoucherCode');
export const verifyVoucher = callable('verifyVoucher');
export const markNotificationsRead = callable('markNotificationsRead');
export const registerDevice = callable('registerDevice');
export const unregisterDevice = callable('unregisterDevice');
export const getPublicCatalog = callable('getPublicCatalog');
export const getEvent = callable('getEvent');
export const getOrganizer = callable('getOrganizer');
export const getReward = callable('getReward');
export const listOwned = callable('listOwned');
export const listMyEvents = callable('listMyEvents');
export const getTicket = callable('getTicket');
export const getOperationStatus = callable('getOperationStatus');
export const getServerInfo = callable('getServerInfo');

export const deliverNotification = onDocumentCreated({ document: 'notifications/{notificationId}', retry: true }, async event => {
  const notification = event.data?.data();
  if (!notification || process.env.FUNCTIONS_EMULATOR === 'true') return;
  const devices = await db.collection(`users/${notification.uid}/devices`).limit(10).get();
  if (devices.empty) return;
  const response = await getMessaging().sendEachForMulticast({ tokens: devices.docs.map(d => d.get('token')), notification: { title: notification.title, body: notification.body }, android: { notification: { tag: event.params.notificationId } }, data: { notificationId: event.params.notificationId, entityType: notification.entityType ?? '', entityId: notification.entityId ?? '' } });
  await Promise.all(response.responses.map(async (r, i) => {
    if (!['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(r.error?.code ?? '')) return;
    const sent = devices.docs[i];
    await db.runTransaction(async tx => {
      const current = await tx.get(sent.ref);
      if (current.get('token') === sent.get('token')) {
        tx.delete(sent.ref);
        tx.delete(db.doc(`device_bindings/${key(sent.get('token'))}`));
      }
    });
  }));
  if (response.responses.some(r => r.error && !['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(r.error.code))) throw new Error('FCM_TRANSIENT_DELIVERY_FAILURE');
});
