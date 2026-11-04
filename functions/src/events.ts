import { randomBytes } from 'node:crypto';
import { Firestore, Timestamp, DocumentData, Transaction } from 'firebase-admin/firestore';
import { z } from 'zod';
import { Actor, authenticated, activeUser, changeWallet, coins, fail, id, key, ledger, notification, operation, publicEvent, requestId, required, walletData } from './shared.js';

const attendee = z.object({ fullName: z.string().trim().min(1).max(100), studentId: z.string().trim().min(1).max(64), universityEmail: z.email().max(254), phoneNumber: z.string().regex(/^\+?[0-9 ()-]{7,24}$/).optional() }).strict();
const eventRequest = z.object({ eventId: id, requestId }).strict();
function scope(event: DocumentData) {
  if (event.audience?.scope && event.audience.scope !== 'everyone') fail('VERIFIED_AUDIENCE_DEFERRED');
}
function checkWindow(event: DocumentData, now: Timestamp) {
  if (!(event.checkInStartAt instanceof Timestamp) || !(event.checkInEndAt instanceof Timestamp) || now.toMillis() < event.checkInStartAt.toMillis() || now.toMillis() >= event.checkInEndAt.toMillis()) fail('OUTSIDE_CHECKIN_WINDOW');
}
export async function staff(tx: Transaction, db: Firestore, actor: Actor | null, eventId: string, permission: string) {
  const uid = authenticated(actor);
  if (actor?.token.staff !== true) fail('FORBIDDEN_STAFF', 'permission-denied');
  const assignment = (await tx.get(db.doc(`staff_assignments/${key(uid, eventId)}`))).data();
  if (!assignment?.active || assignment.staffUid !== uid || assignment.eventId !== eventId || !Array.isArray(assignment.permissions) || !assignment.permissions.includes(permission)) fail('FORBIDDEN_STAFF', 'permission-denied');
  return uid;
}
export function events(db: Firestore, clock: () => Date) {
  return {
    followOrganizer: async (actor: Actor | null, raw: unknown) => follow(actor, raw, true),
    unfollowOrganizer: async (actor: Actor | null, raw: unknown) => follow(actor, raw, false),
    setBookmark: async (actor: Actor | null, raw: unknown) => {
      const { eventId, saved } = z.object({ eventId: id, saved: z.boolean() }).strict().parse(raw), uid = authenticated(actor);
      await db.runTransaction(async tx => {
        await activeUser(tx, db, uid);
        publicEvent((await tx.get(db.doc(`events/${eventId}`))).data());
        const ref = db.doc(`users/${uid}/bookmarks/${eventId}`), prior = await tx.get(ref);
        if (saved && !prior.exists) tx.create(ref, { eventId, createdAt: Timestamp.fromDate(clock()) });
        if (!saved && prior.exists) tx.delete(ref);
      });
      return { eventId, saved };
    },
    setWalkInGoing: async (actor: Actor | null, raw: unknown) => {
      const { eventId, going } = z.object({ eventId: id, going: z.boolean() }).strict().parse(raw), uid = authenticated(actor);
      await db.runTransaction(async tx => {
        const user = await activeUser(tx, db, uid);
        if (!user.onboardingCompleted) fail('ONBOARDING_REQUIRED');
        const event = publicEvent((await tx.get(db.doc(`events/${eventId}`))).data());
        if (event.participationMode !== 'walk_in') fail('WRONG_PARTICIPATION_MODE');
        const ref = db.doc(`users/${uid}/event_intents/${eventId}`), prior = await tx.get(ref);
        if (going && !prior.exists) tx.create(ref, { eventId, createdAt: Timestamp.fromDate(clock()) });
        if (!going && prior.exists) tx.delete(ref);
      });
      return { eventId, going };
    },
    registerForEvent: async (actor: Actor | null, raw: unknown) => {
      const input = eventRequest.extend({ attendeeInput: attendee, acceptedTermsVersion: z.string().min(1).max(100), expectedDepositCoins: coins }).parse(raw);
      const uid = authenticated(actor), now = Timestamp.fromDate(clock()), registrationId = key(uid, input.eventId);
      return operation(db, uid, 'register', input.requestId, input, now, async (tx, op) => {
        const eventRef = db.doc(`events/${input.eventId}`), regRef = db.doc(`registrations/${registrationId}`), walletRef = db.doc(`wallets/${uid}`);
        const [eventDoc, reg, wallet] = await tx.getAll(eventRef, regRef, walletRef);
        const event = publicEvent(eventDoc.data()); scope(event);
        if (event.participationMode !== 'registration') fail('WRONG_PARTICIPATION_MODE');
        if (reg.exists && reg.get('state') !== 'cancelled') fail('ALREADY_REGISTERED', 'already-exists');
        const closesAt = event.registrationClosesAt ?? event.startAt;
        if (!(closesAt instanceof Timestamp) || now.toMillis() >= closesAt.toMillis()) fail('EVENT_NOT_OPEN');
        if (event.capacity !== null && event.registeredCount >= event.capacity) fail('EVENT_FULL');
        if (input.acceptedTermsVersion !== event.registrationTerms?.version) fail('TERMS_CHANGED');
        if (input.expectedDepositCoins !== event.depositCoins) fail('QUOTE_CHANGED', 'failed-precondition', { depositCoins: event.depositCoins });
        const balance = changeWallet(tx, walletRef, walletData(wallet.data()), -event.depositCoins, event.depositCoins, now);
        const ticketId = key('ticket', registrationId, input.requestId);
        if (reg.exists) tx.create(regRef.collection('history').doc(reg.get('ticketId')), reg.data()!);
        tx.set(regRef, { uid, eventId: input.eventId, state: 'registered', attendeeSnapshot: input.attendeeInput, termsAcceptance: { version: input.acceptedTermsVersion, acceptedAt: now }, depositCoins: event.depositCoins, attendanceRewardCoinsSnapshot: event.attendanceRewardCoins, ticketId, registeredAt: now, cancelledAt: null, attendedAt: null, depositSettlement: event.depositCoins ? 'held' : 'none' });
        tx.create(db.doc(`tickets/${ticketId}`), { uid, eventId: input.eventId, registrationId, ticketNumber: `EV-${ticketId.slice(0, 12).toUpperCase()}`, status: 'active', issuedAt: now, revokedAt: null, checkedInAt: null, tokenVersion: 1 });
        tx.update(eventRef, { registeredCount: event.registeredCount + 1, updatedAt: now });
        if (event.depositCoins) ledger(tx, db, uid, op, 'deposit_hold', -event.depositCoins, event.depositCoins, registrationId, now);
        notification(tx, db, uid, op, 'registration_confirmed', 'ticket', ticketId, now);
        return { registrationId, ticketId, wallet: balance };
      });
    },
    cancelRegistration: async (actor: Actor | null, raw: unknown) => {
      const input = eventRequest.parse(raw), uid = authenticated(actor), now = Timestamp.fromDate(clock()), registrationId = key(uid, input.eventId);
      return operation(db, uid, 'cancel', input.requestId, input, now, async (tx, op) => {
        const regRef = db.doc(`registrations/${registrationId}`), eventRef = db.doc(`events/${input.eventId}`), walletRef = db.doc(`wallets/${uid}`);
        const [regDoc, eventDoc, wallet] = await tx.getAll(regRef, eventRef, walletRef);
        const reg = required(regDoc.data(), 'NOT_REGISTERED'), event = required(eventDoc.data(), 'EVENT_NOT_FOUND');
        if (reg.state === 'cancelled') fail('ALREADY_CANCELLED', 'already-exists');
        if (reg.state === 'attended') fail('ALREADY_ATTENDED');
        if (reg.state !== 'registered') fail('CANNOT_CANCEL');
        const ticketRef = db.doc(`tickets/${reg.ticketId}`), ticket = await tx.get(ticketRef);
        if (ticket.get('status') !== 'active' || event.registeredCount < 1) fail('REGISTRATION_INTEGRITY_ERROR', 'internal');
        const balance = changeWallet(tx, walletRef, walletData(wallet.data()), 0, -reg.depositCoins, now);
        tx.update(regRef, { state: 'cancelled', cancelledAt: now, depositSettlement: reg.depositCoins ? 'forfeited' : 'none' });
        tx.update(ticketRef, { status: 'revoked', revokedAt: now });
        tx.update(eventRef, { registeredCount: event.registeredCount - 1, updatedAt: now });
        if (reg.depositCoins) ledger(tx, db, uid, op, 'deposit_forfeit', 0, -reg.depositCoins, registrationId, now);
        return { registrationId, state: 'cancelled', wallet: balance };
      });
    },
    getTicketQr: async (actor: Actor | null, raw: unknown) => {
      const { eventId } = z.object({ eventId: id }).strict().parse(raw), uid = authenticated(actor), now = Timestamp.fromDate(clock());
      const tokenId = randomBytes(24).toString('base64url'), secret = randomBytes(32).toString('base64url');
      return db.runTransaction(async tx => {
        await activeUser(tx, db, uid);
        const reg = required((await tx.get(db.doc(`registrations/${key(uid, eventId)}`))).data(), 'NO_ACTIVE_TICKET');
        const ticket = required((await tx.get(db.doc(`tickets/${reg.ticketId}`))).data(), 'NO_ACTIVE_TICKET');
        if (reg.state !== 'registered' || ticket.status !== 'active') fail('NO_ACTIVE_TICKET');
        const expiresAt = Timestamp.fromMillis(now.toMillis() + 120_000);
        tx.create(db.doc(`checkin_tokens/${tokenId}`), { eventId, uid, ticketId: reg.ticketId, mode: 'registered', tokenHash: key(secret), validFrom: now, validUntil: expiresAt, revoked: false, issuedBy: uid });
        return { ticketId: reg.ticketId, ticketNumber: ticket.ticketNumber, qrPayload: `evia:ticket:${tokenId}:${secret}`, expiresAt };
      });
    },
    issueWalkInQr: async (actor: Actor | null, raw: unknown) => {
      const { eventId } = z.object({ eventId: id }).strict().parse(raw), now = Timestamp.fromDate(clock());
      const tokenId = randomBytes(24).toString('base64url'), secret = randomBytes(32).toString('base64url');
      return db.runTransaction(async tx => {
        await activeUser(tx, db, authenticated(actor)); await staff(tx, db, actor, eventId, 'issue_walk_in');
        const event = publicEvent((await tx.get(db.doc(`events/${eventId}`))).data());
        if (event.participationMode !== 'walk_in') fail('WRONG_PARTICIPATION_MODE');
        checkWindow(event, now);
        const expiresAt = Timestamp.fromMillis(Math.min(now.toMillis() + 60_000, event.checkInEndAt.toMillis()));
        tx.create(db.doc(`checkin_tokens/${tokenId}`), { eventId, mode: 'walkin', tokenHash: key(secret), validFrom: now, validUntil: expiresAt, revoked: false, issuedBy: actor!.uid });
        return { eventId, qrPayload: `evia:walkin:${tokenId}:${secret}`, expiresAt };
      });
    },
    verifyRegisteredTicket: async (actor: Actor | null, raw: unknown) => verify(actor, raw, true),
    verifyWalkInQr: async (actor: Actor | null, raw: unknown) => verify(actor, raw, false),
  };

  async function follow(actor: Actor | null, raw: unknown, following: boolean) {
    const { organizerId } = z.object({ organizerId: id }).strict().parse(raw), uid = authenticated(actor);
    await db.runTransaction(async tx => {
      const user = await activeUser(tx, db, uid); if (!user.onboardingCompleted) fail('ONBOARDING_REQUIRED');
      const ref = db.doc(`users/${uid}/following/${organizerId}`), organizerRef = db.doc(`organizers/${organizerId}`);
      const [prior, organizer] = await tx.getAll(ref, organizerRef);
      if (organizer.get('published') !== true) fail('ORGANIZER_NOT_FOUND', 'not-found');
      if (prior.exists === following) return;
      const count = organizer.get('followerCount');
      if (!Number.isSafeInteger(count) || count < (following ? 0 : 1)) fail('COUNTER_INTEGRITY_ERROR', 'internal');
      if (following) tx.create(ref, { organizerId, createdAt: Timestamp.fromDate(clock()) }); else tx.delete(ref);
      tx.update(organizerRef, { followerCount: count + (following ? 1 : -1) });
    });
    return { organizerId, following };
  }

  async function verify(actor: Actor | null, raw: unknown, registered: boolean) {
    const input = z.object({ qrPayload: z.string().max(512).regex(/^evia:(ticket|walkin):[A-Za-z0-9_-]{32}:[A-Za-z0-9_-]{43}$/), requestId }).strict().parse(raw);
    const scannerUid = authenticated(actor), now = Timestamp.fromDate(clock());
    const [, mode, tokenId, secret] = input.qrPayload.split(':');
    if (mode !== (registered ? 'ticket' : 'walkin')) fail('QR_INVALID');
    if (registered) {
      const meta = required((await db.doc(`checkin_tokens/${tokenId}`).get()).data(), 'QR_INVALID');
      // Recheck scope even when the operation returns a previously completed receipt.
      await db.runTransaction(tx => staff(tx, db, actor, meta.eventId, 'verify_ticket'));
    }
    return operation(db, scannerUid, registered ? 'verify-ticket' : 'verify-walkin', input.requestId, input, now, async (tx, op) => {
      const token = required((await tx.get(db.doc(`checkin_tokens/${tokenId}`))).data(), 'QR_INVALID');
      if (registered) await staff(tx, db, actor, token.eventId, 'verify_ticket');
      const uid = registered ? token.uid : scannerUid;
      await activeUser(tx, db, uid);
      const event = publicEvent((await tx.get(db.doc(`events/${token.eventId}`))).data()); scope(event);
      checkWindow(event, now);
      if (token.mode !== (registered ? 'registered' : 'walkin') || token.tokenHash !== key(secret) || token.revoked || now.toMillis() < token.validFrom.toMillis() || now.toMillis() >= token.validUntil.toMillis()) fail('QR_INVALID');
      const attendanceId = key(uid, token.eventId), attendanceRef = db.doc(`attendance/${attendanceId}`), walletRef = db.doc(`wallets/${uid}`);
      const [prior, wallet] = await tx.getAll(attendanceRef, walletRef);
      if (prior.exists) fail('ALREADY_CHECKED_IN', 'already-exists');
      let deposit = 0, reward = event.attendanceRewardCoins, registrationId: string | null = null;
      if (registered) {
        if (event.participationMode !== 'registration') fail('WRONG_PARTICIPATION_MODE');
        registrationId = key(uid, token.eventId);
        const regRef = db.doc(`registrations/${registrationId}`), ticketRef = db.doc(`tickets/${token.ticketId}`);
        const [regDoc, ticketDoc] = await tx.getAll(regRef, ticketRef);
        const reg = required(regDoc.data(), 'NO_ACTIVE_TICKET');
        if (reg.state !== 'registered' || reg.ticketId !== token.ticketId || ticketDoc.get('status') !== 'active' || ticketDoc.get('uid') !== uid) fail('NO_ACTIVE_TICKET');
        deposit = reg.depositCoins; reward = reg.attendanceRewardCoinsSnapshot;
        tx.update(regRef, { state: 'attended', attendedAt: now, depositSettlement: deposit ? 'refunded' : 'none' });
        tx.update(ticketRef, { status: 'checked_in', checkedInAt: now });
      } else if (event.participationMode !== 'walk_in') fail('WRONG_PARTICIPATION_MODE');
      const balance = changeWallet(tx, walletRef, walletData(wallet.data()), deposit + reward, -deposit, now);
      tx.create(attendanceRef, { uid, eventId: token.eventId, mode: registered ? 'organizer_scanned_ticket' : 'student_scanned_walkin', registrationId, verifiedAt: now, verifiedBy: scannerUid, rewardCoinsGranted: reward });
      if (deposit) ledger(tx, db, uid, op, 'deposit_refund', deposit, -deposit, registrationId!, now);
      ledger(tx, db, uid, op, 'event_reward', reward, 0, token.eventId, now);
      return { attendanceId, eventId: token.eventId, coinsGranted: reward, depositRefunded: deposit, ...(registered ? {} : { wallet: balance }) };
    });
  }
}
