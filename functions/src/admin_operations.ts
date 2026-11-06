import { DocumentData, FieldPath, FieldValue, Firestore, Query, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';
import { organizerSchema } from './catalog.js';
import { requireAdmin } from './admin_catalog.js';
import { voucherAdmin } from './rewards.js';
import { Actor, activeUser, empty, fail, id, key, operation, requestId, required } from './shared.js';

const page = { cursor: id.optional(), limit: z.number().int().min(1).max(50).default(20) };
const fields = (data: DocumentData, names: string[]) => Object.fromEntries(names.filter(n => data[n] !== undefined).map(n => [n, data[n]]));
const eventFields = ['title', 'organizerId', 'participationMode', 'startAt', 'endAt', 'status', 'checkInStartAt', 'checkInEndAt'];
const profileFields = ['displayName', 'universityEmail', 'studentId', 'phoneNumber', 'accountStatus', 'onboardingCompleted'];
const revision = (doc: { updateTime?: Timestamp }) => doc.updateTime ? `${doc.updateTime.seconds}:${doc.updateTime.nanoseconds}` : null;

export function adminOperations(db: Firestore, clock: () => Date) {
  async function admin(actor: Actor | null) {
    const uid = requireAdmin(actor);
    await db.runTransaction(tx => activeUser(tx, db, uid));
    return uid;
  }
  async function list(query: Query, input: { cursor?: string; limit: number }, names?: string[]) {
    let ordered = query.orderBy(FieldPath.documentId());
    if (input.cursor) ordered = ordered.startAfter(input.cursor);
    const docs = (await ordered.limit(input.limit + 1).get()).docs, visible = docs.slice(0, input.limit);
    return { items: visible.map((doc): DocumentData => ({ id: doc.id, ...(names ? fields(doc.data(), names) : doc.data()), revision: revision(doc) })), nextCursor: docs.length > input.limit ? visible.at(-1)!.id : null };
  }
  return {
    getOperatorContext: async (actor: Actor | null, raw: unknown) => {
      empty.parse(raw); const uid = await admin(actor);
      const user = required((await db.doc(`users/${uid}`).get()).data(), 'USER_NOT_FOUND');
      const isAdmin = true;
      return { uid, displayName: user.displayName ?? '', admin: isAdmin, staff: false, voucher: true, milestones: true };
    },
    listAdminRecords: async (actor: Actor | null, raw: unknown) => {
      const input = z.object({ ...page, kind: z.enum(['organizers', 'milestones', 'users', 'participants', 'attendance', 'redemptions', 'notifications', 'ledger']), eventId: id.optional(), uid: id.optional() }).strict().parse(raw);
      if (input.kind === 'participants' || input.kind === 'attendance') {
        if (!input.eventId) fail('EVENT_REQUIRED', 'invalid-argument');
        await admin(actor);
        return list(db.collection(input.kind === 'participants' ? 'registrations' : 'attendance').where('eventId', '==', input.eventId), input,
          input.kind === 'participants' ? ['uid', 'eventId', 'state', 'attendeeSnapshot', 'registeredAt', 'cancelledAt', 'depositCoins', 'ticketId'] : ['uid', 'eventId', 'verifiedAt', 'mode', 'rewardCoinsGranted']);
      }
      await admin(actor);
      if (input.kind === 'ledger') {
        if (!input.uid) fail('USER_REQUIRED', 'invalid-argument');
        return list(db.collection(`wallets/${input.uid}/ledger`), input, ['type', 'deltaAvailable', 'deltaHeld', 'sourceId', 'createdAt']);
      }
      const names: Record<string, string[] | undefined> = {
        organizers: [...Object.keys(organizerSchema.shape).filter(n => n !== 'id'), 'followerCount'],
        milestones: ['title', 'description', 'metric', 'requiredEvents', 'rewardCoins', 'sortOrder', 'active', 'version'],
        users: profileFields, redemptions: ['uid', 'rewardId', 'rewardTitleSnapshot', 'priceCoinsSnapshot', 'rewardSnapshot', 'status', 'voucherId', 'redeemedAt', 'expiresAt', 'usedAt'],
        notifications: ['uid', 'type', 'title', 'body', 'entityType', 'entityId', 'createdAt', 'readAt', 'pushDispatch'],
      };
      let query: Query = db.collection(input.kind);
      if (input.uid && ['redemptions', 'notifications'].includes(input.kind)) query = query.where('uid', '==', input.uid);
      return list(query, input, names[input.kind]);
    },
    getAdminUser: async (actor: Actor | null, raw: unknown) => {
      await admin(actor); const { uid } = z.object({ uid: id }).strict().parse(raw);
      const [user, wallet] = await db.getAll(db.doc(`users/${uid}`), db.doc(`wallets/${uid}`));
      return { uid, profile: fields(required(user.data(), 'USER_NOT_FOUND'), profileFields), wallet: fields(wallet.data() ?? {}, ['availableCoins', 'heldCoins', 'version']) };
    },
    upsertOrganizer: async (actor: Actor | null, raw: unknown) => {
      const actorUid = await admin(actor);
      const { organizer, expectedRevision } = z.object({ organizer: organizerSchema, expectedRevision: z.string().regex(/^\d+:\d+$/).nullable() }).strict().parse(raw);
      return db.runTransaction(async tx => {
        const ref = db.doc(`organizers/${organizer.id}`), prior = await tx.get(ref);
        if (revision(prior) !== expectedRevision) fail('CATALOG_CHANGED', 'aborted');
        const { id: ignored, ...data } = organizer, now = Timestamp.fromDate(clock());
        tx.set(ref, { ...data, ...(prior.exists && !data.logoUrl ? { logoUrl: FieldValue.delete() } : {}), updatedAt: now, ...(prior.exists ? {} : { followerCount: 0, createdAt: now }) }, { merge: true });
        tx.create(db.collection('admin_audit').doc(), { actorUid, action: 'upsert_organizer', entityId: organizer.id, createdAt: now });
        return { id: organizer.id };
      });
    },
    listOperatorEvents: async (actor: Actor | null, raw: unknown) => {
      await admin(actor); return list(db.collection('events'), z.object(page).strict().parse(raw), eventFields);
    },
    sendAdminDemoNotification: async (actor: Actor | null, raw: unknown) => {
      await admin(actor); const { uid, eventId, requestId: rid } = z.object({ uid: id, eventId: id, requestId }).strict().parse(raw);
      const ref = db.doc(`notifications/${key('admin-demo', rid, uid)}`);
      await db.runTransaction(async tx => {
        const [user, event, prior, devices] = await Promise.all([tx.get(db.doc(`users/${uid}`)), tx.get(db.doc(`events/${eventId}`)), tx.get(ref), tx.get(db.collection(`users/${uid}/devices`).limit(1))]);
        if (user.get('isDemo') !== true || user.get('accountStatus') !== 'active' || event.get('isDemo') !== true || event.get('status') !== 'published' || event.get('visibility') !== 'public') fail('DEMO_NOT_ALLOWED', 'permission-denied');
        if (devices.empty) fail('NO_REGISTERED_DEVICE');
        if (prior.exists) { if (prior.get('entityId') !== eventId) fail('DUPLICATE_CONFLICT'); return; }
        tx.create(ref, { uid, type: 'demo_fcm_smoke', title: '[DEMO] Thông báo từ Firebase', body: 'Thông báo thử từ Firebase. Nhấn để xem sự kiện.', entityType: 'event', entityId: eventId, readAt: null, createdAt: Timestamp.fromDate(clock()) });
      });
      return { notificationId: ref.id, status: 'queued' };
    },
    sendAdminNotification: async (actor: Actor | null, raw: unknown) => {
      const actorUid = await admin(actor);
      const { uid, body, requestId: rid } = z.object({ uid: id, body: z.string().trim().min(1).max(500), requestId }).strict().parse(raw);
      const ref = db.doc(`notifications/${key('admin-message', actorUid, rid)}`);
      await db.runTransaction(async tx => {
        await activeUser(tx, db, actorUid);
        await activeUser(tx, db, uid);
        const prior = await tx.get(ref);
        if (prior.exists) {
          if (prior.get('uid') !== uid || prior.get('body') !== body) fail('DUPLICATE_CONFLICT', 'already-exists');
          return;
        }
        const devices = await tx.get(db.collection(`users/${uid}/devices`).limit(1));
        if (devices.empty) fail('NO_REGISTERED_DEVICE');
        tx.create(ref, { uid, type: 'admin_message', title: 'Thông báo từ Evia', body, entityType: 'inbox', entityId: '', createdBy: actorUid, readAt: null, createdAt: Timestamp.fromDate(clock()) });
      });
      return { notificationId: ref.id, status: 'queued' };
    },
    confirmPhysicalReward: async (actor: Actor | null, raw: unknown) => {
      const uid = await admin(actor), input = z.object({ redemptionId: id, requestId }).strict().parse(raw), now = Timestamp.fromDate(clock());
      await db.runTransaction(tx => voucherAdmin(tx, db, actor));
      return operation(db, uid, 'fulfill-physical', input.requestId, input, now, async tx => {
        await voucherAdmin(tx, db, actor);
        const ref = db.doc(`redemptions/${input.redemptionId}`), redemption = required((await tx.get(ref)).data(), 'REDEMPTION_NOT_FOUND');
        if (redemption.rewardSnapshot?.fulfillmentType !== 'physical' || redemption.voucherId) fail('WRONG_FULFILLMENT');
        if (redemption.status !== 'issued') fail('USED');
        if (redemption.expiresAt && redemption.expiresAt.toMillis() <= now.toMillis()) fail('EXPIRED');
        tx.update(ref, { status: 'used', usedBy: uid, usedAt: now });
        return { redemptionId: input.redemptionId, status: 'used' };
      });
    },
  };
}
