import { randomBytes } from 'node:crypto';
import { Firestore, Timestamp, Transaction } from 'firebase-admin/firestore';
import { z } from 'zod';
import { Actor, activeUser, authenticated, changeWallet, coins, fail, id, key, ledger, notification, operation, requestId, required, walletData } from './shared.js';

export async function voucherAdmin(tx: Transaction, db: Firestore, actor: Actor | null) {
  const uid = authenticated(actor);
  if (actor?.token.admin !== true) fail('FORBIDDEN_ADMIN', 'permission-denied');
  await activeUser(tx, db, uid);
  return uid;
}

export function rewards(db: Firestore, clock: () => Date) {
  return {
    redeemReward: async (actor: Actor | null, raw: unknown) => {
      const input = z.object({ rewardId: id, requestId, expectedPriceCoins: coins, expectedTermsVersion: z.string().min(1).max(100) }).strict().parse(raw);
      const uid = authenticated(actor), now = Timestamp.fromDate(clock());
      const redemptionId = key(uid, input.requestId), voucherId = key('voucher', redemptionId), code = randomBytes(32).toString('base64url');
      return operation(db, uid, 'redeem', input.requestId, input, now, async (tx, op) => {
        const rewardRef = db.doc(`rewards/${input.rewardId}`), walletRef = db.doc(`wallets/${uid}`);
        const [rewardDoc, wallet] = await tx.getAll(rewardRef, walletRef);
        const reward = required(rewardDoc.data(), 'REWARD_NOT_FOUND');
        if (reward.status !== 'active') fail('REWARD_INACTIVE');
        if (!Number.isSafeInteger(reward.stockRemaining) || reward.stockRemaining <= 0) fail('OUT_OF_STOCK');
        if (input.expectedPriceCoins !== reward.priceCoins) fail('PRICE_CHANGED', 'failed-precondition', { priceCoins: reward.priceCoins });
        if (input.expectedTermsVersion !== reward.termsVersion) fail('TERMS_CHANGED');
        if (!['voucher', 'physical'].includes(reward.fulfillmentType)) fail('INVALID_FULFILLMENT', 'internal');
        const balance = changeWallet(tx, walletRef, walletData(wallet.data()), -reward.priceCoins, 0, now);
        const expiresAt = Number.isInteger(reward.validDays) && reward.validDays > 0 ? Timestamp.fromMillis(now.toMillis() + reward.validDays * 86_400_000) : null;
        const snapshot = Object.fromEntries(['title', 'imageUrl', 'fulfillmentType', 'usageLocations', 'termsText', 'termsVersion', 'redemptionSteps', 'redemptionInstructions'].filter(k => reward[k] !== undefined).map(k => [k, reward[k]]));
        const issuedVoucher = reward.fulfillmentType === 'voucher' ? voucherId : null;
        tx.create(db.doc(`redemptions/${redemptionId}`), { uid, rewardId: input.rewardId, priceCoinsSnapshot: reward.priceCoins, rewardTitleSnapshot: reward.title, rewardSnapshot: snapshot, status: 'issued', voucherId: issuedVoucher, redeemedAt: now, expiresAt });
        if (issuedVoucher) {
          tx.create(db.doc(`vouchers/${voucherId}`), { uid, rewardId: input.rewardId, redemptionId, status: 'unused', expiresAt, usedAt: null, createdAt: now });
          // Private server-only document allows the owner to retrieve the same code after restart.
          tx.create(db.doc(`voucher_secrets/${voucherId}`), { code, codeHash: key(code), tokenVersion: 1 });
        }
        tx.update(rewardRef, { stockRemaining: reward.stockRemaining - 1, updatedAt: now });
        ledger(tx, db, uid, op, 'redeem_reward', -reward.priceCoins, 0, redemptionId, now);
        notification(tx, db, uid, op, 'reward_redeemed', 'redemption', redemptionId, now);
        return { redemptionId, voucherId: issuedVoucher, costCoins: reward.priceCoins, expiresAt, wallet: balance };
      });
    },
    getVoucherCode: async (actor: Actor | null, raw: unknown) => {
      const { voucherId } = z.object({ voucherId: id }).strict().parse(raw), uid = authenticated(actor);
      const voucher = required((await db.doc(`vouchers/${voucherId}`).get()).data(), 'VOUCHER_NOT_FOUND');
      if (voucher.uid !== uid) fail('NOT_OWNER', 'permission-denied');
      if (voucher.status !== 'unused') fail(voucher.status === 'used' ? 'USED' : 'VOUCHER_UNAVAILABLE');
      if (voucher.expiresAt && voucher.expiresAt.toMillis() <= clock().getTime()) fail('EXPIRED');
      const secret = required((await db.doc(`voucher_secrets/${voucherId}`).get()).data(), 'VOUCHER_UNAVAILABLE');
      return { voucherId, code: secret.code, qrPayload: `evia:voucher:${voucherId}:${secret.code}`, expiresAt: voucher.expiresAt };
    },
    verifyVoucher: async (actor: Actor | null, raw: unknown) => {
      const input = z.object({ code: z.string().regex(/^[A-Za-z0-9_-]{43}$/), requestId }).strict().parse(raw);
      const uid = authenticated(actor), now = Timestamp.fromDate(clock());
      // Recheck revocable admin authority even when returning an idempotent receipt.
      await db.runTransaction(tx => voucherAdmin(tx, db, actor));
      return operation(db, uid, 'verify-voucher', input.requestId, input, now, async (tx) => {
        await voucherAdmin(tx, db, actor);
        const secrets = await tx.get(db.collection('voucher_secrets').where('codeHash', '==', key(input.code)).limit(1));
        const secret = secrets.docs[0];
        if (!secret) fail('VOUCHER_UNAVAILABLE', 'not-found');
        const voucherRef = db.doc(`vouchers/${secret.id}`), voucher = required((await tx.get(voucherRef)).data(), 'VOUCHER_UNAVAILABLE');
        if (voucher.status !== 'unused') fail(voucher.status === 'used' ? 'USED' : 'VOUCHER_UNAVAILABLE');
        if (voucher.expiresAt && voucher.expiresAt.toMillis() <= now.toMillis()) fail('EXPIRED');
        const redemptionRef = db.doc(`redemptions/${voucher.redemptionId}`), redemption = await tx.get(redemptionRef);
        if (redemption.get('voucherId') !== secret.id || redemption.get('status') !== 'issued') fail('VOUCHER_INTEGRITY_ERROR', 'internal');
        tx.update(voucherRef, { status: 'used', usedAt: now, usedBy: uid });
        tx.update(redemptionRef, { status: 'used', usedAt: now, usedBy: uid });
        return { voucherId: secret.id, redemptionId: voucher.redemptionId, status: 'used', usedAt: now };
      });
    },
  };
}
