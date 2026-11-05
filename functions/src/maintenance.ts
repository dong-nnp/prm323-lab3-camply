import { Firestore, FieldPath, Query, Timestamp } from 'firebase-admin/firestore';
import { changeWallet, fail, key, ledger, required, walletData } from './shared.js';
import { PRODUCT_TIMEZONE } from './policy.js';

export function createMaintenance(db: Firestore, clock = () => new Date()) {
  // shortcut: bounded pages with per-record transactions suit lab traffic; use resumable task queues before large fanout.
  async function each(query: Query, work: (id: string) => Promise<boolean>) {
    let cursor: string | undefined, count = 0;
    for (;;) {
      let page = query.orderBy(FieldPath.documentId()).limit(100);
      if (cursor) page = page.startAfter(cursor);
      const docs = (await page.get()).docs;
      for (const doc of docs) if (await work(doc.id)) count++;
      if (docs.length < 100) return count;
      cursor = docs.at(-1)!.id;
    }
  }
  return {
    grantMonthly: async (scheduledAt: Date) => {
      const localDate = new Intl.DateTimeFormat('en-CA', { timeZone: PRODUCT_TIMEZONE }).format(scheduledAt);
      if (!localDate.endsWith('-01')) fail('INVALID_MONTHLY_SCHEDULE', 'invalid-argument');
      const monthKey = localDate.slice(0, 7), cutoff = Timestamp.fromDate(new Date(`${localDate}T00:00:00+07:00`));
      const now = Timestamp.fromDate(clock());
      const grantedCount = await each(db.collection('users'), uid => db.runTransaction(async tx => {
        const userRef = db.doc(`users/${uid}`), walletRef = db.doc(`wallets/${uid}`), grantRef = db.doc(`users/${uid}/monthly_grants/${monthKey}`);
        const [user, wallet, prior] = await tx.getAll(userRef, walletRef, grantRef);
        if (!user.exists || prior.exists) return false;
        const createdAt = user.get('createdAt');
        if (!(createdAt instanceof Timestamp)) fail('ACCOUNT_INTEGRITY_ERROR', 'internal');
        if (createdAt.toMillis() > cutoff.toMillis()) return false;
        changeWallet(tx, walletRef, walletData(wallet.data()), 200, 0, now);
        tx.create(grantRef, { monthKey, coinsGranted: 200, scheduledAt: cutoff, grantedAt: now, policyVersion: 'monthly-v1' });
        ledger(tx, db, uid, key('monthly', uid, monthKey), 'monthly_gift', 200, 0, monthKey, now);
        return true;
      }));
      return { monthKey, grantedCount };
    },
    settleNoShows: async () => {
      const now = Timestamp.fromDate(clock());
      const settledCount = await each(db.collection('registrations').where('state', '==', 'registered'), registrationId => db.runTransaction(async tx => {
        const regRef = db.doc(`registrations/${registrationId}`), regDoc = await tx.get(regRef);
        const reg = required(regDoc.data(), 'NOT_REGISTERED');
        if (reg.state !== 'registered') return false;
        const event = required((await tx.get(db.doc(`events/${reg.eventId}`))).data(), 'EVENT_NOT_FOUND');
        if (!['published', 'completed'].includes(event.status)) return false;
        if (!(event.endAt instanceof Timestamp) || !(event.checkInEndAt instanceof Timestamp)) fail('EVENT_INTEGRITY_ERROR', 'internal');
        if (now.toMillis() < Math.max(event.endAt.toMillis(), event.checkInEndAt.toMillis())) return false;
        const walletRef = db.doc(`wallets/${reg.uid}`), ticketRef = db.doc(`tickets/${reg.ticketId}`);
        const [wallet, ticket] = await tx.getAll(walletRef, ticketRef);
        if (ticket.get('status') !== 'active' || ticket.get('uid') !== reg.uid || !Number.isSafeInteger(reg.depositCoins) || reg.depositCoins < 0) fail('REGISTRATION_INTEGRITY_ERROR', 'internal');
        changeWallet(tx, walletRef, walletData(wallet.data()), 0, -reg.depositCoins, now);
        tx.update(regRef, { state: 'no_show', noShowAt: now, depositSettlement: reg.depositCoins ? 'forfeited' : 'none' });
        tx.update(ticketRef, { status: 'revoked', revokedAt: now });
        if (reg.depositCoins) ledger(tx, db, reg.uid, key('no-show', reg.ticketId), 'no_show_forfeit', 0, -reg.depositCoins, registrationId, now);
        return true;
      }));
      return { settledCount };
    },
  };
}
