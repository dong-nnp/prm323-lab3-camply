import { DocumentData, DocumentSnapshot, FieldPath, FieldValue, Firestore, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';
import { eventSchema, rewardSchema } from './catalog.js';
import { Actor, authenticated, fail, id, json, required } from './shared.js';

const page = z.object({ cursor: id.optional(), limit: z.number().int().min(1).max(50).default(20) }).strict();
const revision = z.string().regex(/^\d+:\d+$/);
const detail = z.object({ id }).strict();
const publish = detail.extend({ revision }).strict();
const createEvent = z.object({ event: eventSchema }).strict();
const updateEvent = createEvent.extend({ revision }).strict();
const createReward = z.object({ reward: rewardSchema }).strict();
const updateReward = createReward.extend({ revision }).strict();

export function requireAdmin(actor: Actor | null): string {
  const uid = authenticated(actor);
  if (actor?.token.admin !== true) fail('FORBIDDEN_ADMIN', 'permission-denied');
  return uid;
}

function documentRevision(doc: DocumentSnapshot) {
  const stamp = doc.updateTime;
  return stamp ? String(stamp.seconds) + ':' + stamp.nanoseconds : null;
}

function checkRevision(doc: DocumentSnapshot, expected: string) {
  if (documentRevision(doc) !== expected) fail('CATALOG_CHANGED', 'aborted');
}

const eventFields = Object.keys(eventSchema.shape).filter(field => field !== 'id');
const rewardFields = Object.keys(rewardSchema.shape).filter(field => field !== 'id');

function view(doc: DocumentSnapshot, fields: string[], missing: string) {
  const data = required(doc.data(), missing);
  return {
    id: doc.id,
    ...Object.fromEntries(fields.filter(field => data[field] !== undefined).map(field => [field, data[field]])),
    revision: documentRevision(doc),
  };
}

function stored(value: unknown): any {
  if (Array.isArray(value)) return value.map(stored);
  if (!value || typeof value !== 'object') return value;
  return Object.fromEntries(Object.entries(value).filter(([, item]) => item !== undefined).map(([field, item]) => [
    field,
    field.endsWith('At') && typeof item === 'string' ? Timestamp.fromDate(new Date(item)) : stored(item),
  ]));
}

function updateFields(fields: string[], value: DocumentData) {
  const record = stored(value);
  return Object.fromEntries(fields.map(field => [field, record[field] === undefined ? FieldValue.delete() : record[field]]));
}

export function adminCatalog(db: Firestore, clock: () => Date) {
  async function list(kind: 'events' | 'rewards', raw: unknown) {
    const input = page.parse(raw);
    const query = db.collection(kind).orderBy(FieldPath.documentId());
    const docs = (await (input.cursor ? query.startAfter(input.cursor) : query).limit(input.limit + 1).get()).docs;
    const visible = docs.slice(0, input.limit);
    const fields = kind === 'events' ? ['title', 'startAt', 'timezone', 'participationMode', 'status', 'visibility']
      : ['title', 'priceCoins', 'stockRemaining', 'status', 'fulfillmentType'];
    return { items: visible.map(doc => view(doc, fields, 'CATALOG_NOT_FOUND')), nextCursor: docs.length > input.limit ? visible.at(-1)!.id : null };
  }

  return {
    listAdminEvents: async (actor: Actor | null, raw: unknown) => {
      requireAdmin(actor);
      return list('events', raw);
    },
    getAdminEvent: async (actor: Actor | null, raw: unknown) => {
      requireAdmin(actor);
      const input = detail.parse(raw);
      return view(await db.doc('events/' + input.id).get(), [...eventFields, 'registeredCount'], 'EVENT_NOT_FOUND');
    },
    createEvent: async (actor: Actor | null, raw: unknown) => {
      requireAdmin(actor);
      const { event: { id: eventId, ...event } } = createEvent.parse(raw);
      if (event.status !== 'draft') fail('EVENT_MUST_START_AS_DRAFT', 'invalid-argument');
      const ref = db.doc('events/' + eventId);
      await db.runTransaction(async tx => {
        const [existing, organizer] = await tx.getAll(ref, db.doc('organizers/' + event.organizerId));
        if (existing.exists) fail('EVENT_ALREADY_EXISTS', 'already-exists');
        if (!organizer.exists) fail('ORGANIZER_NOT_FOUND', 'not-found');
        const now = Timestamp.fromDate(clock());
        tx.create(ref, { ...stored(event), registeredCount: 0, createdAt: now, updatedAt: now });
      });
      return { id: eventId };
    },
    updateEvent: async (actor: Actor | null, raw: unknown) => {
      requireAdmin(actor);
      const { event: { id: eventId, ...event }, revision: expected } = updateEvent.parse(raw);
      const ref = db.doc('events/' + eventId);
      await db.runTransaction(async tx => {
        const [current, organizer] = await tx.getAll(ref, db.doc('organizers/' + event.organizerId));
        const old = required(current.data(), 'EVENT_NOT_FOUND');
        checkRevision(current, expected);
        if (!organizer.exists) fail('ORGANIZER_NOT_FOUND', 'not-found');
        if (event.status !== old.status || !['draft', 'published'].includes(old.status)) fail('EVENT_STATE_CHANGED');
        if (old.status === 'published' && (event.visibility !== old.visibility || event.organizerId !== old.organizerId || event.participationMode !== old.participationMode)) fail('PUBLISHED_EVENT_FIELDS_LOCKED');
        if (!Number.isSafeInteger(old.registeredCount) || old.registeredCount < 0) fail('EVENT_INTEGRITY_ERROR', 'internal');
        if (event.capacity !== null && event.capacity < old.registeredCount) fail('EVENT_CAPACITY_BELOW_REGISTRATIONS');
        if (old.registrationTerms?.version === event.registrationTerms?.version &&
            old.registrationTerms?.text !== event.registrationTerms?.text) fail('TERMS_VERSION_REQUIRED');
        tx.update(ref, { ...updateFields(eventFields, event), updatedAt: Timestamp.fromDate(clock()) });
      });
      return { id: eventId };
    },
    publishEvent: async (actor: Actor | null, raw: unknown) => {
      requireAdmin(actor);
      const input = publish.parse(raw);
      const ref = db.doc('events/' + input.id);
      await db.runTransaction(async tx => {
        const current = await tx.get(ref);
        const event = required(current.data(), 'EVENT_NOT_FOUND');
        if (event.status === 'published') return;
        checkRevision(current, input.revision);
        if (event.status !== 'draft') fail('EVENT_STATE_CHANGED');
        const { revision: ignored, ...payload } = view(current, eventFields, 'EVENT_NOT_FOUND');
        eventSchema.parse(json(payload));
        const organizer = await tx.get(db.doc('organizers/' + event.organizerId));
        const now = Timestamp.fromDate(clock());
        if (!organizer.exists || (event.visibility === 'public' && organizer.get('published') !== true)) fail('ORGANIZER_UNAVAILABLE');
        if (!(event.startAt instanceof Timestamp) || event.startAt.toMillis() <= now.toMillis()) fail('EVENT_MUST_BE_UPCOMING');
        tx.update(ref, { status: 'published', updatedAt: now });
      });
      return { id: input.id };
    },
    listAdminRewards: async (actor: Actor | null, raw: unknown) => {
      requireAdmin(actor);
      return list('rewards', raw);
    },
    getAdminReward: async (actor: Actor | null, raw: unknown) => {
      requireAdmin(actor);
      const input = detail.parse(raw);
      return view(await db.doc('rewards/' + input.id).get(), rewardFields, 'REWARD_NOT_FOUND');
    },
    createReward: async (actor: Actor | null, raw: unknown) => {
      requireAdmin(actor);
      const { reward: { id: rewardId, ...reward } } = createReward.parse(raw);
      if (reward.status !== 'inactive') fail('REWARD_MUST_START_INACTIVE', 'invalid-argument');
      const ref = db.doc('rewards/' + rewardId);
      await db.runTransaction(async tx => {
        if ((await tx.get(ref)).exists) fail('REWARD_ALREADY_EXISTS', 'already-exists');
        const now = Timestamp.fromDate(clock());
        tx.create(ref, { ...stored(reward), createdAt: now, updatedAt: now });
      });
      return { id: rewardId };
    },
    updateReward: async (actor: Actor | null, raw: unknown) => {
      requireAdmin(actor);
      const { reward: { id: rewardId, ...reward }, revision: expected } = updateReward.parse(raw);
      const ref = db.doc('rewards/' + rewardId);
      await db.runTransaction(async tx => {
        const doc = await tx.get(ref);
        const old = required(doc.data(), 'REWARD_NOT_FOUND');
        if (old.fulfillmentType !== reward.fulfillmentType) fail('REWARD_TYPE_LOCKED');
        checkRevision(doc, expected);
        if (old.termsText !== reward.termsText && old.termsVersion === reward.termsVersion) fail('TERMS_VERSION_REQUIRED');
        tx.update(ref, { ...updateFields(rewardFields, reward), updatedAt: Timestamp.fromDate(clock()) });
      });
      return { id: rewardId };
    },
  };
}
