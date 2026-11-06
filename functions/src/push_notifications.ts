import { Firestore, DocumentData } from 'firebase-admin/firestore';
import { Messaging } from 'firebase-admin/messaging';
import { key } from './shared.js';

export async function deliverPush(db: Firestore, messaging: Pick<Messaging, 'sendEachForMulticast'>, notificationId: string, notification: DocumentData) {
  const devices = await db.collection(`users/${notification.uid}/devices`).limit(10).get();
  if (devices.empty) return { successCount: 0, failureCount: 0 };
  const response = await messaging.sendEachForMulticast({
    tokens: devices.docs.map(d => d.get('token')),
    notification: { title: notification.title, body: notification.body },
    android: { priority: 'high', notification: { channelId: 'evia_events_v1', icon: 'ic_notification', tag: notificationId } },
    data: { notificationId, entityType: notification.entityType ?? '', entityId: notification.entityId ?? '' },
  });
  const invalid = ['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'];
  await Promise.all(response.responses.map(async (result, i) => {
    if (!invalid.includes(result.error?.code ?? '')) return;
    const sent = devices.docs[i];
    await db.runTransaction(async tx => {
      const current = await tx.get(sent.ref);
      if (current.get('token') === sent.get('token')) {
        tx.delete(sent.ref);
        tx.delete(db.doc(`device_bindings/${key(sent.get('token'))}`));
      }
    });
  }));
  if (response.failureCount) console.warn('FCM dispatch failures', { notificationId, codes: response.responses.flatMap(r => r.error ? [r.error.code] : []) });
  if (response.responses.some(r => r.error && !invalid.includes(r.error.code))) throw new Error('FCM_TRANSIENT_DELIVERY_FAILURE');
  return { successCount: response.successCount, failureCount: response.failureCount };
}
