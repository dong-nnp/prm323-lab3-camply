import { Firestore, FieldPath, Query, Timestamp, DocumentData } from 'firebase-admin/firestore';
import { z } from 'zod';
import { Actor, authenticated, empty, fail, id, key, publicEvent, required } from './shared.js';
import { staff } from './events.js';
import { voucherAdmin } from './rewards.js';

const page = z.object({ limit: z.number().int().min(1).max(50).default(20), cursor: id.optional() }).strict();
const eventFields = ['organizerId', 'title', 'subtitle', 'description', 'category', 'tags', 'imageUrl', 'status', 'visibility', 'startAt', 'endAt', 'timezone', 'doorsOpenAt', 'checkInStartAt', 'checkInEndAt', 'venue', 'audience', 'benefits', 'participantRequirements', 'schedule', 'scheduleNote', 'featured', 'admissionNote', 'registrationTerms', 'participationMode', 'capacity', 'registeredCount', 'depositCoins', 'attendanceRewardCoins', 'registrationClosesAt'];
function selected(data: DocumentData, fields: string[]) { return Object.fromEntries(fields.filter(f => data[f] !== undefined).map(f => [f, data[f]])); }
export function eventView(eventId: string, data: DocumentData) {
  return { id: eventId, ...selected(data, eventFields), isDemo: data.isDemo === true, spotsRemaining: data.capacity === null ? null : Math.max(0, data.capacity - data.registeredCount) };
}
export function queries(db: Firestore, clock: () => Date) {
  async function list(query: Query, input: z.infer<typeof page>, sort?: { field: string; descending?: boolean; path: string }) {
    let ordered = sort ? query.orderBy(sort.field, sort.descending ? 'desc' : 'asc').orderBy(FieldPath.documentId()) : query.orderBy(FieldPath.documentId());
    if (input.cursor) {
      if (sort) {
        const cursor = await db.doc(`${sort.path}/${input.cursor}`).get();
        if (!cursor.exists || cursor.get(sort.field) === undefined) fail('INVALID_CURSOR', 'invalid-argument');
        ordered = ordered.startAfter(cursor);
      } else ordered = ordered.startAfter(input.cursor);
    }
    const docs = (await ordered.limit(input.limit + 1).get()).docs, hasMore = docs.length > input.limit, visible = docs.slice(0, input.limit);
    return { items: visible.map(d => ({ id: d.id, ...d.data() })), nextCursor: hasMore ? visible.at(-1)!.id : null };
  }
  return {
    getPublicCatalog: async (_actor: Actor | null, raw: unknown) => {
      const input = page.extend({ kind: z.enum(['events', 'organizers', 'rewards', 'interests']), feed: z.enum(['all', 'recommended', 'following']).default('all'), organizerId: id.optional(), category: z.string().trim().max(64).optional(), participationMode: z.enum(['registration', 'walk_in']).optional(), featured: z.boolean().optional(), q: z.string().trim().max(100).optional(), from: z.iso.datetime().optional(), until: z.iso.datetime().optional(), availability: z.enum(['available', 'full', 'unlimited']).optional(), timeOfDay: z.enum(['morning', 'afternoon', 'evening']).optional(), duration: z.enum(['under_hour', 'one_to_three_hours', 'over_three_hours']).optional() }).parse(raw);
      let interests: string[] = [];
      if (input.feed !== 'all') {
        if (input.kind !== 'events') fail('INVALID_FILTER', 'invalid-argument');
        const uid = authenticated(_actor), user = required((await db.doc(`users/${uid}`).get()).data(), 'ACCOUNT_NOT_INITIALIZED');
        if (user.accountStatus !== 'active') fail('ACCOUNT_DISABLED', 'permission-denied');
        if (!user.onboardingCompleted) fail('ONBOARDING_REQUIRED');
        interests = user.interests;
      }
      let query: Query = db.collection(input.kind);
      if (input.kind === 'events') {
        query = query.where('status', '==', 'published').where('visibility', '==', 'public');
      } else if (input.kind === 'organizers') query = query.where('published', '==', true);
      else query = query.where('status', '==', 'active');
      const result = await list(query, input, input.kind === 'events' ? { field: 'startAt', path: 'events' } : undefined);
      // shortcut: filter bounded candidate pages; add a search index when catalog size makes scanning costly.
      const norm = (s: string) => s.normalize('NFD').replace(/\p{M}/gu, '').toLowerCase().replace(/đ/g, 'd');
      const following = new Set<string>();
      if (input.feed === 'following' && result.items.length) {
        const organizerIds: string[] = [...new Set(result.items.map((item: DocumentData) => item.organizerId as string))];
        const relations = await db.getAll(...organizerIds.map(organizerId => db.doc(`users/${_actor!.uid}/following/${organizerId}`)));
        for (const relation of relations) if (relation.exists) following.add(relation.id);
      }
      const filtered = result.items.filter((item: DocumentData) => {
        if (input.category && item.category !== input.category) return false;
        if (input.q && !norm(`${item.title ?? item.name ?? ''} ${item.description ?? ''}`).includes(norm(input.q))) return false;
        if (input.kind !== 'events') return true;
        if (input.feed === 'following' && !following.has(item.organizerId)) return false;
        if (input.feed === 'recommended' && ![item.category, ...(item.tags ?? [])].some(tag => interests.includes(tag))) return false;
        if (input.organizerId && item.organizerId !== input.organizerId || input.participationMode && item.participationMode !== input.participationMode || input.featured !== undefined && item.featured !== input.featured) return false;
        const start = item.startAt.toDate(), end = item.endAt.toDate();
        if (input.from && start < new Date(input.from) || input.until && start >= new Date(input.until)) return false;
        if (input.availability === 'unlimited' && item.capacity !== null) return false;
        if (input.availability === 'full' && (item.capacity === null || item.registeredCount < item.capacity)) return false;
        if (input.availability === 'available' && item.capacity !== null && item.registeredCount >= item.capacity) return false;
        const minutes = (end.getTime() - start.getTime()) / 60_000;
        if (input.duration === 'under_hour' && minutes >= 60 || input.duration === 'one_to_three_hours' && (minutes < 60 || minutes > 180) || input.duration === 'over_three_hours' && minutes <= 180) return false;
        const hour = Number(new Intl.DateTimeFormat('en-GB', { timeZone: item.timezone, hour: '2-digit', hourCycle: 'h23' }).format(start));
        if (input.timeOfDay === 'morning' && (hour < 0 || hour >= 12) || input.timeOfDay === 'afternoon' && (hour < 12 || hour >= 18) || input.timeOfDay === 'evening' && hour < 18) return false;
        return true;
      });
      return { ...result, scannedCount: result.items.length, items: filtered.map(item => input.kind === 'events' ? eventView(item.id, item) : item) };
    },
    getEvent: async (_actor: Actor | null, raw: unknown) => {
      const { eventId } = z.object({ eventId: id }).strict().parse(raw);
      return eventView(eventId, publicEvent((await db.doc(`events/${eventId}`).get()).data()));
    },
    getOrganizer: async (_actor: Actor | null, raw: unknown) => {
      const { organizerId } = z.object({ organizerId: id }).strict().parse(raw);
      const organizer = (await db.doc(`organizers/${organizerId}`).get()).data();
      if (!organizer?.published) fail('ORGANIZER_NOT_FOUND', 'not-found');
      return { id: organizerId, ...organizer };
    },
    getReward: async (_actor: Actor | null, raw: unknown) => {
      const { rewardId } = z.object({ rewardId: id }).strict().parse(raw);
      const reward = (await db.doc(`rewards/${rewardId}`).get()).data();
      if (reward?.status !== 'active') fail('REWARD_NOT_FOUND', 'not-found');
      return { id: rewardId, ...reward };
    },
    listOwned: async (actor: Actor | null, raw: unknown) => {
      const input = page.extend({ kind: z.enum(['following', 'bookmarks', 'event_intents', 'ledger', 'notifications', 'redemptions', 'vouchers', 'registrations', 'attendance']), status: z.string().max(24).optional() }).parse(raw), uid = authenticated(actor);
      let query: Query = ['following', 'bookmarks', 'event_intents'].includes(input.kind) ? db.collection(`users/${uid}/${input.kind}`) : input.kind === 'ledger' ? db.collection(`wallets/${uid}/ledger`) : db.collection(input.kind).where('uid', '==', uid);
      if (input.status) {
        if (!['vouchers', 'redemptions', 'registrations'].includes(input.kind)) fail('INVALID_FILTER', 'invalid-argument');
        query = query.where(input.kind === 'registrations' ? 'state' : 'status', '==', input.status);
      }
      const sortField = input.kind === 'registrations' ? 'registeredAt' : input.kind === 'attendance' ? 'verifiedAt' : input.kind === 'redemptions' ? 'redeemedAt' : 'createdAt';
      const path = ['following', 'bookmarks', 'event_intents'].includes(input.kind) ? `users/${uid}/${input.kind}` : input.kind === 'ledger' ? `wallets/${uid}/ledger` : input.kind;
      return list(query, input, { field: sortField, descending: true, path });
    },
    listMyEvents: async (actor: Actor | null, raw: unknown) => {
      const input = page.extend({ tab: z.enum(['upcoming', 'past']).optional(), localDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional() }).parse(raw), uid = authenticated(actor);
      // shortcut: scan bounded canonical event pages for owner relations; use a maintained projection at larger scale.
      const candidates = await list(db.collection('events'), input, { field: 'startAt', path: 'events' });
      const items = [];
      for (const event of candidates.items as DocumentData[]) {
        const eventId = event.id as string;
        const [reg, intent, attendance] = await db.getAll(db.doc(`registrations/${key(uid, eventId)}`), db.doc(`users/${uid}/event_intents/${eventId}`), db.doc(`attendance/${key(uid, eventId)}`));
        if (!reg.exists && !intent.exists && !attendance.exists) continue;
        const past = event.endAt.toMillis() <= clock().getTime();
        if (input.tab && (input.tab === 'past') !== past) continue;
        if (input.localDate && new Intl.DateTimeFormat('en-CA', { timeZone: event.timezone }).format(event.startAt.toDate()) !== input.localDate) continue;
        items.push({ event: eventView(eventId, event), registration: reg.data() ?? null, going: intent.exists, attendance: attendance.data() ?? null, past });
      }
      return { items, nextCursor: candidates.nextCursor, scannedCount: candidates.items.length };
    },
    getTicket: async (actor: Actor | null, raw: unknown) => {
      const { eventId } = z.object({ eventId: id }).strict().parse(raw), uid = authenticated(actor);
      const registration = required((await db.doc(`registrations/${key(uid, eventId)}`).get()).data(), 'NOT_REGISTERED');
      const [ticket, event] = await db.getAll(db.doc(`tickets/${registration.ticketId}`), db.doc(`events/${eventId}`));
      return { registration, ticket: required(ticket.data(), 'NO_ACTIVE_TICKET'), event: event.exists ? eventView(eventId, event.data()!) : null };
    },
    getOperationStatus: async (actor: Actor | null, raw: unknown) => {
      const { operationKind, operationId } = z.object({ operationKind: z.enum(['register', 'cancel', 'daily', 'redeem', 'verify-ticket', 'verify-walkin', 'verify-voucher', 'milestone']), operationId: z.string().min(1).max(128) }).strict().parse(raw), uid = authenticated(actor);
      const receipt = required((await db.doc(`operation_receipts/${key(uid, operationKind, operationId)}`).get()).data(), 'NOT_FOUND');
      if (operationKind === 'verify-ticket') await db.runTransaction(tx => staff(tx, db, actor, receipt.result.eventId, 'verify_ticket'));
      if (operationKind === 'verify-voucher') await db.runTransaction(tx => voucherAdmin(tx, db, actor));
      return { status: receipt.status, result: receipt.result };
    },
    getServerInfo: async (_actor: Actor | null, raw: unknown) => {
      empty.parse(raw);
      return { apiVersion: 1, serverTime: Timestamp.fromDate(clock()), region: 'asia-southeast1', timezone: 'Asia/Ho_Chi_Minh', monthlyGiftEnabled: true, monthlyGiftMode: 'automatic', cashierVerificationEnabled: true };
    },
  };
}
