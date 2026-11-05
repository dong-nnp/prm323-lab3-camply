import { Firestore, Timestamp, DocumentSnapshot } from 'firebase-admin/firestore';
import { z } from 'zod';
import { milestoneSchema } from './catalog.js';
import { Actor, activeUser, authenticated, changeWallet, empty, fail, id, ledger, operation, required, walletData } from './shared.js';

function definition(doc: DocumentSnapshot) {
  const data = required(doc.data(), 'MILESTONE_NOT_FOUND');
  const parsed = milestoneSchema.strip().safeParse({ ...data, id: doc.id });
  if (!parsed.success || typeof data.active !== 'boolean' || !Number.isSafeInteger(data.version) || data.version < 1) fail('MILESTONE_CONFIG_INVALID', 'internal');
  return { ...parsed.data, version: data.version as number };
}

export function milestones(db: Firestore, clock: () => Date) {
  const attendanceCount = (uid: string) => db.collection('attendance').where('uid', '==', uid).where('mode', 'in', ['organizer_scanned_ticket', 'student_scanned_walkin']).where('verifiedAt', '>', Timestamp.fromMillis(0)).where('verifiedAt', '<=', Timestamp.fromDate(clock())).count();
  return {
    getEventMilestones: async (actor: Actor | null, raw: unknown) => {
      empty.parse(raw);
      const uid = authenticated(actor);
      return db.runTransaction(async tx => {
        const user = await activeUser(tx, db, uid);
        if (!user.onboardingCompleted) fail('ONBOARDING_REQUIRED');
        const catalog = await tx.get(db.collection('milestones').where('active', '==', true));
        const attendance = await tx.get(attendanceCount(uid));
        const claims = await tx.get(db.collection(`users/${uid}/milestone_claims`));
        const verifiedEventCount = attendance.data().count;
        const claimed = new Map(claims.docs.map(doc => [doc.id, doc.data()]));
        // shortcut: this admin-managed catalog is small; paginate if it grows to hundreds of goals.
        const items = catalog.docs.map(doc => {
          const config = definition(doc), claim = claimed.get(doc.id);
          const milestone = claim ? { ...config, title: claim.title as string, description: (claim.description ?? config.description) as string, requiredEvents: claim.requiredEvents as number, rewardCoins: claim.rewardCoins as number, version: claim.definitionVersion as number } : config;
          const unlocked = !!claim || verifiedEventCount >= milestone.requiredEvents;
          return { ...milestone, progress: Math.min(verifiedEventCount, milestone.requiredEvents), progressPercent: Math.min(100, Math.floor(100 * verifiedEventCount / milestone.requiredEvents)), remainingEvents: Math.max(0, milestone.requiredEvents - verifiedEventCount), unlocked, claimed: !!claim, canClaim: unlocked && !claim, claimedAt: claim?.claimedAt ?? null, claimedRewardCoins: claim?.rewardCoins ?? null };
        }).sort((a, b) => a.sortOrder - b.sortOrder || a.requiredEvents - b.requiredEvents || a.id.localeCompare(b.id, 'en'));
        const byThreshold = [...items].sort((a, b) => a.requiredEvents - b.requiredEvents || a.id.localeCompare(b.id, 'en'));
        return { verifiedEventCount, totalMilestones: items.length, unlockedCount: items.filter(m => m.unlocked).length, claimedCount: items.filter(m => m.claimed).length, currentMilestone: byThreshold.filter(m => m.unlocked).at(-1) ?? null, nextMilestone: byThreshold.find(m => !m.unlocked) ?? null, items };
      }, { readOnly: true });
    },
    claimEventMilestone: async (actor: Actor | null, raw: unknown) => {
      const { milestoneId, expectedVersion } = z.object({ milestoneId: id, expectedVersion: z.number().int().min(1) }).strict().parse(raw);
      const uid = authenticated(actor), now = Timestamp.fromDate(clock());
      return operation(db, uid, 'milestone', milestoneId, { milestoneId }, now, async (tx, op) => {
        const walletRef = db.doc(`wallets/${uid}`), claimRef = db.doc(`users/${uid}/milestone_claims/${milestoneId}`);
        const [milestoneDoc, wallet, claim] = await tx.getAll(db.doc(`milestones/${milestoneId}`), walletRef, claimRef);
        const milestone = definition(milestoneDoc);
        if (!milestone.active) fail('MILESTONE_INACTIVE');
        if (milestone.version !== expectedVersion) fail('MILESTONE_CHANGED', 'failed-precondition', { currentVersion: milestone.version });
        if (claim.exists) fail('ALREADY_CLAIMED', 'already-exists');
        const verifiedEventCount = (await tx.get(attendanceCount(uid))).data().count;
        if (verifiedEventCount < milestone.requiredEvents) fail('MILESTONE_NOT_UNLOCKED');
        const balance = changeWallet(tx, walletRef, walletData(wallet.data()), milestone.rewardCoins, 0, now);
        tx.create(claimRef, { milestoneId, title: milestone.title, description: milestone.description, requiredEvents: milestone.requiredEvents, rewardCoins: milestone.rewardCoins, definitionVersion: milestone.version, verifiedEventCount, claimedAt: now });
        ledger(tx, db, uid, op, 'milestone_reward', milestone.rewardCoins, 0, milestoneId, now);
        return { milestoneId, coinsGranted: milestone.rewardCoins, claimedAt: now, wallet: balance };
      });
    },
    upsertEventMilestone: async (actor: Actor | null, raw: unknown) => {
      const { milestone, expectedVersion } = z.object({ milestone: milestoneSchema, expectedVersion: z.number().int().min(0).max(Number.MAX_SAFE_INTEGER - 1) }).strict().parse(raw);
      const uid = authenticated(actor), now = Timestamp.fromDate(clock());
      const ref = db.doc(`milestones/${milestone.id}`), auditRef = db.collection('milestone_audit').doc();
      return db.runTransaction(async tx => {
        await activeUser(tx, db, uid);
        if (actor?.token.admin !== true || (await tx.get(db.doc(`milestone_admins/${uid}`))).get('active') !== true) fail('FORBIDDEN_ADMIN', 'permission-denied');
        const priorDoc = await tx.get(ref), prior = priorDoc.exists ? definition(priorDoc) : null;
        if ((prior?.version ?? 0) !== expectedVersion) fail('VERSION_CONFLICT', 'aborted');
        // Definition changes affect unclaimed users; immutable claim snapshots preserve earned awards.
        const { id: milestoneId, ...fields } = milestone;
        const version = expectedVersion + 1;
        if (prior) tx.update(ref, { ...fields, version, updatedAt: now });
        else tx.create(ref, { ...fields, version, createdAt: now, updatedAt: now });
        tx.create(auditRef, { actorUid: uid, milestoneId, action: prior ? 'update' : 'create', before: prior, after: { ...milestone, version }, createdAt: now });
        return { milestone: { ...milestone, version }, created: !prior };
      });
    },
  };
}
