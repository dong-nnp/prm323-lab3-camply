import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { setGlobalOptions } from 'firebase-functions/v2';
import { defineSecret } from 'firebase-functions/params';
import { z } from 'zod';
import { evibabyConfigured, evibabyReply, evibabyRequest, reserveEvibabyRequest } from './evibaby.js';
import { createBackend } from './backend.js';
import { REGION, PRODUCT_TIMEZONE } from './policy.js';
import { createMaintenance } from './maintenance.js';
import { createEventNotifications } from './event_notifications.js';
import { deliverPush } from './push_notifications.js';

initializeApp();
// Lab traffic fits fractional CPU and avoids exhausting the project's regional CPU quota.
setGlobalOptions({ region: REGION, minInstances: 0, maxInstances: 3, memory: '256MiB', cpu: 'gcf_gen1', concurrency: 1 });
const db = getFirestore(), backend = createBackend(db);
const evibabyApiKey = defineSecret('EVIBABY_API_KEY');
export const chatWithEvibaby = onCall({
  secrets: [evibabyApiKey], timeoutSeconds: 60,
  enforceAppCheck: process.env.ENFORCE_APP_CHECK === 'true',
}, async request => {
  try {
    const input = evibabyRequest.parse(request.data);
    const settings = { apiKey: evibabyApiKey.value(), baseUrl: process.env.EVIBABY_BASE_URL ?? '', model: process.env.EVIBABY_MODEL ?? '' };
    if (!evibabyConfigured(settings)) throw new HttpsError('unavailable', 'EVIBABY_NOT_CONFIGURED', { code: 'EVIBABY_NOT_CONFIGURED' });
    await reserveEvibabyRequest(db, request.auth ? { uid: request.auth.uid, token: request.auth.token } : null, new Date());
    return await evibabyReply(input, settings, (name, data) => backend.invoke(name, null, data));
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    if (error instanceof z.ZodError) throw new HttpsError('invalid-argument', 'VALIDATION_FAILED', { code: 'VALIDATION_FAILED' });
    console.error('Backend failure', { operation: 'chatWithEvibaby' });
    throw new HttpsError('internal', 'EVIBABY_UNAVAILABLE', { code: 'EVIBABY_UNAVAILABLE' });
  }
});
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
export const getAdminWalkInQr = callable('getAdminWalkInQr');
export const verifyRegisteredTicket = callable('verifyRegisteredTicket');
export const verifyAdminTicketNumber = callable('verifyAdminTicketNumber');
export const verifyWalkInQr = callable('verifyWalkInQr');
export const verifyRegisteredCode = callable('verifyRegisteredCode');
export const verifyWalkInCode = callable('verifyWalkInCode');
export const demoConfirmAttendance = callable('demoConfirmAttendance');
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
export const getEventMilestones = callable('getEventMilestones');
export const claimEventMilestone = callable('claimEventMilestone');
export const upsertEventMilestone = callable('upsertEventMilestone');
export const listAdminEvents = callable('listAdminEvents');
export const getAdminEvent = callable('getAdminEvent');
export const createEvent = callable('createEvent');
export const updateEvent = callable('updateEvent');
export const publishEvent = callable('publishEvent');
export const listAdminRewards = callable('listAdminRewards');
export const getAdminReward = callable('getAdminReward');
export const createReward = callable('createReward');
export const updateReward = callable('updateReward');
export const getAdminRemoteConfig = callable('getAdminRemoteConfig');
export const publishAdminRemoteConfig = callable('publishAdminRemoteConfig');
export const getAdminAnalyticsReport = callable('getAdminAnalyticsReport');
export const getAdminCrashlyticsReport = callable('getAdminCrashlyticsReport');
export const getOperatorContext = callable('getOperatorContext');
export const listAdminRecords = callable('listAdminRecords');
export const getAdminUser = callable('getAdminUser');
export const upsertOrganizer = callable('upsertOrganizer');
export const listOperatorEvents = callable('listOperatorEvents');
export const sendAdminDemoNotification = callable('sendAdminDemoNotification');
export const sendAdminNotification = callable('sendAdminNotification');
export const confirmPhysicalReward = callable('confirmPhysicalReward');

const maintenance = createMaintenance(db);
const eventNotices = createEventNotifications(db);
export const eventNotifications = onDocumentWritten({ document: 'events/{eventId}', retry: true, timeoutSeconds: 540 }, async event => {
  const result = await eventNotices.onEventWritten(event.params.eventId, event.data?.before.data(), event.data?.after.data(), new Date(event.time));
  console.info('Event notifications prepared', result);
});
export const eventReminderSchedule = onSchedule({ schedule: 'every 15 minutes', timeZone: PRODUCT_TIMEZONE, timeoutSeconds: 540, retryCount: 3 }, async () => {
  console.info('Event reminders finished', await eventNotices.sendReminders());
});
export const monthlyGiftSchedule = onSchedule({ schedule: '0 0 1 * *', timeZone: PRODUCT_TIMEZONE, timeoutSeconds: 540, retryCount: 3 }, async event => {
  const result = await maintenance.grantMonthly(new Date(event.scheduleTime));
  console.info('Monthly gifts finished', result);
});
export const noShowSchedule = onSchedule({ schedule: 'every 60 minutes', timeZone: PRODUCT_TIMEZONE, timeoutSeconds: 540, retryCount: 3 }, async () => {
  console.info('No-show settlement finished', await maintenance.settleNoShows());
});

export const deliverNotification = onDocumentCreated({ document: 'notifications/{notificationId}', retry: true }, async event => {
  const notification = event.data?.data();
  if (!notification || process.env.FUNCTIONS_EMULATOR === 'true') return;
  const result = await deliverPush(db, getMessaging(), event.params.notificationId, notification);
  await event.data!.ref.update({ pushDispatch: { ...result, completedAt: new Date(), status: result.successCount ? 'accepted_by_fcm' : 'no_delivery' } });
  // FCM acceptance is not a device display receipt.
  console.info('FCM dispatch finished', { notificationId: event.params.notificationId, ...result });
});
