import { Firestore, Query, QueryDocumentSnapshot, DocumentData, FieldPath, Timestamp, DocumentSnapshot } from 'firebase-admin/firestore';
import { json, key, notification } from './shared.js';

const publicEvent = (event?: DocumentData) => event?.status === 'published' && event.visibility === 'public';
const scheduleKey = (event: DocumentData) => key(json(Object.fromEntries(['startAt', 'endAt', 'timezone', 'checkInStartAt', 'checkInEndAt', 'venue', 'schedule'].map(field => [field, event[field] ?? null]))));
async function each(query: Query, work: (doc: QueryDocumentSnapshot) => Promise<number>) {
  let cursor: DocumentSnapshot | undefined, count = 0;
  for (;;) {
    let page = query.orderBy(FieldPath.documentId()).limit(100);
    if (cursor) page = page.startAfter(cursor);
    const docs = (await page.get()).docs;
    for (const doc of docs) count += await work(doc);
    if (docs.length < 100) return count;
    cursor = docs.at(-1);
  }
}

export function createEventNotifications(db: Firestore, clock = () => new Date()) {
  async function send(eventId: string, type: string, source: DocumentData, cutoff?: Timestamp) {
    const signature = type === 'new_event' ? 'published' : type === 'event_reminder' ? String(source.startAt.toMillis()) : scheduleKey(source);
    const op = key('event-notice', eventId, type, signature), now = Timestamp.fromDate(clock());
    async function recipient(relation: QueryDocumentSnapshot) {
      const uid = relation.ref.parent.id === 'registrations' ? relation.get('uid') : relation.ref.parent.parent?.id;
      if (typeof uid !== 'string') return 0;
      return db.runTransaction(async tx => {
        const ref = db.doc(`notifications/${key(uid, op, type)}`);
        const [user, currentEvent, currentRelation, prior] = await tx.getAll(db.doc(`users/${uid}`), db.doc(`events/${eventId}`), relation.ref, ref);
        const event = currentEvent.data(), data = currentRelation.data();
        if (prior.exists || user.get('accountStatus') !== 'active' || !publicEvent(event) || !(event?.startAt instanceof Timestamp) || event.startAt.toMillis() <= now.toMillis() || !data) return 0;
        if (type === 'schedule_updated' && scheduleKey(event) !== signature || type === 'event_reminder' && String(event.startAt.toMillis()) !== signature) return 0;
        const registered = relation.ref.parent.id === 'registrations';
        if (registered ? data.uid !== uid || data.eventId !== eventId || data.state !== 'registered' : relation.ref.parent.parent?.parent.id !== 'users') return 0;
        if (type === 'new_event' && (data.organizerId !== event.organizerId || relation.ref.id !== event.organizerId)) return 0;
        if (type !== 'new_event' && !registered && (data.eventId !== eventId || relation.ref.id !== eventId)) return 0;
        const joinedAt = registered ? data.registeredAt : data.createdAt;
        if (cutoff && (!(joinedAt instanceof Timestamp) || joinedAt.toMillis() > cutoff.toMillis())) return 0;
        notification(tx, db, uid, op, type, 'event', eventId, now);
        return 1;
      });
    }
    if (type === 'new_event') return each(db.collectionGroup('following').where('organizerId', '==', source.organizerId), recipient);
    return await each(db.collection('registrations').where('eventId', '==', eventId), recipient)
      + await each(db.collectionGroup('event_intents').where('eventId', '==', eventId), recipient);
  }
  return {
    onEventWritten: async (eventId: string, before?: DocumentData, after?: DocumentData, publishedAt = clock()) => {
      if (!publicEvent(after) || !(after?.startAt instanceof Timestamp) || after.startAt.toMillis() <= clock().getTime()) return { createdCount: 0 };
      const type = !publicEvent(before) ? 'new_event' : scheduleKey(before!) !== scheduleKey(after) ? 'schedule_updated' : null;
      return { createdCount: type ? await send(eventId, type, after, type === 'new_event' ? Timestamp.fromDate(publishedAt) : undefined) : 0 };
    },
    sendReminders: async () => {
      const now = Timestamp.fromDate(clock());
      // shortcut: page published lab events; add a due-time projection before a large catalog needs frequent scans.
      const createdCount = await each(db.collection('events').where('status', '==', 'published'), async doc => {
        const event = doc.data();
        if (!publicEvent(event) || !(event.startAt instanceof Timestamp)) return 0;
        const cutoff = Timestamp.fromMillis(event.startAt.toMillis() - 72 * 60 * 60 * 1000);
        if (now.toMillis() < cutoff.toMillis() || now.toMillis() >= event.startAt.toMillis()) return 0;
        const run = db.doc(`notification_runs/${key('reminder', doc.id, event.startAt.toMillis())}`);
        if ((await run.get()).exists) return 0;
        const count = await send(doc.id, 'event_reminder', event, cutoff);
        await run.set({ eventId: doc.id, startAt: event.startAt, completedAt: now });
        return count;
      });
      return { createdCount };
    },
  };
}
