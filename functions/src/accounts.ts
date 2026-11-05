import { Firestore, Timestamp, FieldPath } from 'firebase-admin/firestore';
import { z } from 'zod';
import { Actor, authenticated, activeUser, empty, fail, id, key, ledger, required, walletData } from './shared.js';
import { SIGNUP_BONUS_COINS, dailyGrant, PRODUCT_TIMEZONE } from './policy.js';
import { changeWallet, operation } from './shared.js';
import { emailAddress, fptStudentId } from './identity.js';

export function accounts(db: Firestore, clock: () => Date) {
  return {
    initializeUser: async (actor: Actor | null, raw: unknown) => {
      empty.parse(raw);
      const uid = authenticated(actor), now = Timestamp.fromDate(clock());
      return db.runTransaction(async tx => {
        const userRef = db.doc(`users/${uid}`), walletRef = db.doc(`wallets/${uid}`);
        const [user, wallet] = await tx.getAll(userRef, walletRef);
        if (user.exists) {
          if (user.get('accountStatus') !== 'active') fail('ACCOUNT_DISABLED', 'permission-denied');
          return { profile: user.data(), wallet: walletData(wallet.data()), created: false };
        }
        if (wallet.exists) fail('ACCOUNT_INTEGRITY_ERROR', 'internal');
        const profile = { displayName: typeof actor?.token.name === 'string' ? actor.token.name : null, universityEmail: emailAddress.parse(actor?.token.email), studentId: null, phoneNumber: null, photoUrl: null, interests: [], onboardingCompleted: false, accountStatus: 'active', createdAt: now, updatedAt: now };
        const balance = { availableCoins: SIGNUP_BONUS_COINS, heldCoins: 0, version: 1, updatedAt: now };
        tx.create(userRef, profile); tx.create(walletRef, balance);
        ledger(tx, db, uid, key('signup', uid), 'signup_bonus', SIGNUP_BONUS_COINS, 0, uid, now);
        return { profile, wallet: balance, created: true };
      });
    },
    updateProfile: async (actor: Actor | null, raw: unknown) => {
      const input = z.object({ displayName: z.string().trim().min(1).max(100).optional(), studentId: fptStudentId.optional(), universityEmail: emailAddress.optional(), phoneNumber: z.string().trim().regex(/^\+?[0-9 ()-]{7,24}$/).nullable().optional() }).strict().refine(v => Object.keys(v).length > 0).parse(raw);
      const uid = authenticated(actor);
      await db.runTransaction(async tx => { await activeUser(tx, db, uid); tx.update(db.doc(`users/${uid}`), { ...input, updatedAt: Timestamp.fromDate(clock()) }); });
      return { updated: true };
    },
    saveInterests: async (actor: Actor | null, raw: unknown) => {
      const { interests } = z.object({ interests: z.array(id).min(3).max(50).refine(v => new Set(v).size === v.length) }).strict().parse(raw);
      const uid = authenticated(actor);
      await db.runTransaction(async tx => {
        await activeUser(tx, db, uid);
        const options = await tx.getAll(...interests.map(interest => db.doc(`interests/${interest}`)));
        if (options.some(option => option.get('status') !== 'active')) fail('INVALID_INTERESTS', 'invalid-argument');
        tx.update(db.doc(`users/${uid}`), { interests, onboardingCompleted: true, updatedAt: Timestamp.fromDate(clock()) });
      });
      return { interests, onboardingCompleted: true };
    },
    claimDailyCheckin: async (actor: Actor | null, raw: unknown) => {
      empty.parse(raw);
      const uid = authenticated(actor), now = Timestamp.fromDate(clock()), today = dailyGrant(now.toDate(), null).dayKey;
      return operation(db, uid, 'daily', today, {}, now, async (tx, op) => {
        const stateRef = db.doc(`users/${uid}/reward_state/daily`), walletRef = db.doc(`wallets/${uid}`);
        const [state, wallet] = await tx.getAll(stateRef, walletRef);
        const grant = dailyGrant(now.toDate(), state.exists ? state.data() as { lastLocalDate: string; streakDay: number } : null);
        if (grant.alreadyClaimed) fail('DAILY_INTEGRITY_ERROR', 'internal');
        const balance = changeWallet(tx, walletRef, walletData(wallet.data()), grant.coins, 0, now);
        tx.set(stateRef, { lastLocalDate: today, streakDay: grant.streakDay });
        tx.create(db.doc(`users/${uid}/daily_checkins/${today}`), { localDate: today, streakDay: grant.streakDay, coinsGranted: grant.coins, timezone: PRODUCT_TIMEZONE, policyVersion: 'daily-v1', createdAt: now });
        ledger(tx, db, uid, op, 'daily_checkin', grant.coins, 0, today, now);
        return { dayKey: today, streakDay: grant.streakDay, coinsGranted: grant.coins, wallet: balance };
      });
    },
    grantMonthlyGift: async (actor: Actor | null, raw: unknown) => { authenticated(actor); empty.parse(raw); return fail('AUTOMATIC_ONLY'); },
    markNotificationsRead: async (actor: Actor | null, raw: unknown) => {
      const { notificationIds, before } = z.object({ notificationIds: z.array(id).min(1).max(30).optional(), before: z.iso.datetime().optional() }).strict().parse(raw);
      const uid = authenticated(actor), now = Timestamp.fromDate(clock());
      const cutoff = before ? Timestamp.fromDate(new Date(before)) : now;
      if (cutoff.toMillis() > now.toMillis()) fail('INVALID_CUTOFF', 'invalid-argument');
      return db.runTransaction(async tx => {
        await activeUser(tx, db, uid);
        const snapshot = notificationIds
          ? await tx.get(db.collection('notifications').where(FieldPath.documentId(), 'in', [...new Set(notificationIds)]))
          : await tx.get(db.collection('notifications').where('uid', '==', uid).where('readAt', '==', null).where('createdAt', '<=', cutoff).orderBy('createdAt').limit(100));
        if (notificationIds && snapshot.size !== new Set(notificationIds).size) fail('INVALID_NOTIFICATION_IDS', 'invalid-argument');
        for (const doc of snapshot.docs) if (doc.get('uid') !== uid) fail('FORBIDDEN', 'permission-denied');
        const unread = snapshot.docs.filter(d => !d.get('readAt'));
        for (const doc of unread) tx.update(doc.ref, { readAt: now });
        return { updatedCount: unread.length, before: cutoff, hasMore: !notificationIds && snapshot.size === 100 };
      });
    },
    registerDevice: async (actor: Actor | null, raw: unknown) => {
      const input = z.object({ installationId: id, token: z.string().min(20).max(4096), platform: z.enum(['android', 'ios', 'web']) }).strict().parse(raw);
      const uid = authenticated(actor);
      await db.runTransaction(async tx => {
        await activeUser(tx, db, uid);
        const deviceRef = db.doc(`users/${uid}/devices/${input.installationId}`), bindingRef = db.doc(`device_bindings/${key(input.token)}`);
        const [device, binding] = await tx.getAll(deviceRef, bindingRef);
        const devices = await tx.get(db.collection(`users/${uid}/devices`).limit(11));
        if (!device.exists && devices.size >= 10) fail('TOO_MANY_DEVICES', 'resource-exhausted');
        if (device.exists && device.get('token') !== input.token) tx.delete(db.doc(`device_bindings/${key(device.get('token'))}`));
        if (binding.exists && (binding.get('uid') !== uid || binding.get('installationId') !== input.installationId)) tx.delete(db.doc(`users/${binding.get('uid')}/devices/${binding.get('installationId')}`));
        tx.set(deviceRef, { token: input.token, platform: input.platform, updatedAt: Timestamp.fromDate(clock()) });
        tx.set(bindingRef, { uid, installationId: input.installationId });
      });
      return { registered: true };
    },
    unregisterDevice: async (actor: Actor | null, raw: unknown) => {
      const { installationId } = z.object({ installationId: id }).strict().parse(raw), uid = authenticated(actor);
      await db.runTransaction(async tx => {
        await activeUser(tx, db, uid);
        const ref = db.doc(`users/${uid}/devices/${installationId}`), prior = await tx.get(ref);
        tx.delete(ref);
        if (prior.exists) tx.delete(db.doc(`device_bindings/${key(prior.get('token'))}`));
      });
      return { unregistered: true };
    },
    getAccount: async (actor: Actor | null, raw: unknown) => {
      empty.parse(raw); const uid = authenticated(actor);
      const [user, wallet, daily] = await db.getAll(db.doc(`users/${uid}`), db.doc(`wallets/${uid}`), db.doc(`users/${uid}/reward_state/daily`));
      const profile = required(user.data(), 'ACCOUNT_NOT_INITIALIZED');
      if (profile.accountStatus !== 'active') fail('ACCOUNT_DISABLED', 'permission-denied');
      const interests = await db.collection('interests').where('status', '==', 'active').orderBy(FieldPath.documentId()).limit(100).get();
      const now = clock();
      const grant = dailyGrant(now, daily.exists ? daily.data() as { lastLocalDate: string; streakDay: number } : null);
      return { profile, wallet: walletData(wallet.data()), daily: { ...grant, serverTime: now.toISOString(), timezone: PRODUCT_TIMEZONE }, interestOptions: interests.docs.map(d => ({ id: d.id, label: d.get('label') })) };
    },
  };
}
