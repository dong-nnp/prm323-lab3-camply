import { Firestore, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';
import { Actor, authenticated, changeWallet, coins, fail, id, key, ledger, operation, publicEvent, requestId, required, walletData } from './shared.js';

// Owner-authorized teaching demo: access flag and event marker are server-only.
export function demoAttendance(db: Firestore, clock: () => Date) {
  return { demoConfirmAttendance: async (actor: Actor | null, raw: unknown) => {
    const input = z.object({ eventId: id, requestId }).strict().parse(raw);
    const uid = authenticated(actor), now = Timestamp.fromDate(clock());
    const authorize = (user: FirebaseFirestore.DocumentData, event: FirebaseFirestore.DocumentData) => {
      if (user.demoAttendanceEnabled !== true || user.isDemo !== true || event.isDemo !== true) fail('DEMO_NOT_ALLOWED', 'permission-denied');
    };
    // Recheck flags even for a receipt retry after an administrator disables demo access.
    const [user, event] = await db.getAll(db.doc(`users/${uid}`), db.doc(`events/${input.eventId}`));
    authorize(required(user.data(), 'ACCOUNT_NOT_INITIALIZED'), required(event.data(), 'EVENT_NOT_FOUND'));
    return operation(db, uid, 'demo-checkin', input.requestId, input, now, async (tx, op) => {
      const regId = key(uid, input.eventId), regRef = db.doc(`registrations/${regId}`);
      const walletRef = db.doc(`wallets/${uid}`), attendanceRef = db.doc(`attendance/${regId}`);
      const [userDoc, eventDoc, regDoc, wallet, prior] = await tx.getAll(user.ref, event.ref, regRef, walletRef, attendanceRef);
      const e = publicEvent(eventDoc.data()); authorize(userDoc.data()!, e);
      if (prior.exists) fail('ALREADY_CHECKED_IN', 'already-exists');
      let deposit = 0, reward = e.attendanceRewardCoins;
      const registered = e.participationMode === 'registration';
      if (registered) {
        const reg = required(regDoc.data(), 'NOT_REGISTERED');
        const ticketRef = db.doc(`tickets/${reg.ticketId}`), ticket = await tx.get(ticketRef);
        if (reg.uid !== uid || reg.state !== 'registered' || ticket.get('status') !== 'active' || ticket.get('uid') !== uid) fail('NO_ACTIVE_TICKET');
        deposit = reg.depositCoins; reward = reg.attendanceRewardCoinsSnapshot;
        if (!coins.safeParse(deposit).success || !coins.safeParse(reward).success) fail('REGISTRATION_INTEGRITY_ERROR', 'internal');
        tx.update(regRef, { state: 'attended', attendedAt: now, depositSettlement: deposit ? 'refunded' : 'none' });
        tx.update(ticketRef, { status: 'checked_in', checkedInAt: now });
      } else if (e.participationMode !== 'walk_in') fail('WRONG_PARTICIPATION_MODE');
      const balance = changeWallet(tx, walletRef, walletData(wallet.data()), deposit + reward, -deposit, now);
      tx.create(attendanceRef, { uid, eventId: input.eventId, mode: registered ? 'organizer_scanned_ticket' : 'student_scanned_walkin', registrationId: registered ? regId : null, verifiedAt: now, verifiedBy: uid, rewardCoinsGranted: reward, isDemo: true, verificationMethod: 'debug_demo_button' });
      if (deposit) ledger(tx, db, uid, op, 'deposit_refund', deposit, -deposit, regId, now);
      ledger(tx, db, uid, op, 'event_reward', reward, 0, input.eventId, now);
      return { attendanceId: regId, eventId: input.eventId, coinsGranted: reward, depositRefunded: deposit, wallet: balance, isDemo: true };
    });
  } };
}
