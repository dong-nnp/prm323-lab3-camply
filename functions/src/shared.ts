import { createHash } from 'node:crypto';
import { Firestore, Timestamp, Transaction, DocumentReference, DocumentData } from 'firebase-admin/firestore';
import { HttpsError, FunctionsErrorCode } from 'firebase-functions/v2/https';
import { z } from 'zod';

export type Actor = { uid: string; token: Record<string, unknown> };
export type Result = Record<string, unknown>;
export const id = z.string().regex(/^[A-Za-z0-9_-]{1,128}$/);
export const requestId = z.string().regex(/^[A-Za-z0-9_-]{8,128}$/);
export const coins = z.number().int().min(0).max(1_000_000_000);
export const empty = z.object({}).strict();
export function fail(code: string, status: FunctionsErrorCode = 'failed-precondition', extra: Result = {}): never {
  throw new HttpsError(status, code, { code, ...extra });
}
export function authenticated(actor: Actor | null): string {
  if (!actor) fail('UNAUTHENTICATED', 'unauthenticated');
  return actor.uid;
}
export function key(...parts: unknown[]): string {
  return createHash('sha256').update(JSON.stringify(parts)).digest('hex');
}
export function required<T extends DocumentData>(data: T | undefined, code: string): T {
  if (!data) fail(code, 'not-found');
  return data;
}
export async function activeUser(tx: Transaction, db: Firestore, uid: string) {
  const user = required((await tx.get(db.doc(`users/${uid}`))).data(), 'ACCOUNT_NOT_INITIALIZED');
  if (user.accountStatus !== 'active') fail('ACCOUNT_DISABLED', 'permission-denied');
  return user;
}
export function publicEvent(event: DocumentData | undefined) {
  if (!event || event.status !== 'published' || event.visibility !== 'public') fail('EVENT_NOT_FOUND', 'not-found');
  if (![event.registeredCount, event.depositCoins, event.attendanceRewardCoins].every(n => Number.isSafeInteger(n) && n >= 0) || event.capacity !== null && (!Number.isSafeInteger(event.capacity) || event.capacity < event.registeredCount)) fail('EVENT_INTEGRITY_ERROR', 'internal');
  return event;
}
export function walletData(data: DocumentData | undefined) {
  const wallet = required(data, 'WALLET_NOT_INITIALIZED');
  if (![wallet.availableCoins, wallet.heldCoins, wallet.version].every(Number.isSafeInteger) || wallet.availableCoins < 0 || wallet.heldCoins < 0 || wallet.version < 1) fail('WALLET_INTEGRITY_ERROR', 'internal');
  return wallet as { availableCoins: number; heldCoins: number; version: number };
}
export function changeWallet(tx: Transaction, ref: DocumentReference, wallet: ReturnType<typeof walletData>, available: number, held: number, now: Timestamp) {
  const next = { availableCoins: wallet.availableCoins + available, heldCoins: wallet.heldCoins + held, version: wallet.version + 1, updatedAt: now };
  if (next.availableCoins < 0) fail('INSUFFICIENT_COINS');
  if (next.heldCoins < 0 || !Number.isSafeInteger(next.availableCoins) || !Number.isSafeInteger(next.heldCoins)) fail('WALLET_INTEGRITY_ERROR', 'internal');
  tx.update(ref, next);
  return next;
}
export function ledger(tx: Transaction, db: Firestore, uid: string, operationKey: string, type: string, available: number, held: number, sourceId: string, now: Timestamp) {
  tx.create(db.doc(`wallets/${uid}/ledger/${key(operationKey, type)}`), { type, deltaAvailable: available, deltaHeld: held, sourceType: type, sourceId, operationKey, createdAt: now });
}
export async function operation(db: Firestore, uid: string, kind: string, operationId: string, input: unknown, now: Timestamp, work: (tx: Transaction, operationKey: string) => Promise<Result>): Promise<Result> {
  const operationKey = key(uid, kind, operationId);
  const inputHash = key(input);
  return db.runTransaction(async tx => {
    const user = await activeUser(tx, db, uid);
    if (!user.onboardingCompleted) fail('ONBOARDING_REQUIRED');
    const ref = db.doc(`operation_receipts/${operationKey}`);
    const prior = (await tx.get(ref)).data();
    if (prior) {
      if (prior.inputHash !== inputHash) fail('DUPLICATE_CONFLICT', 'already-exists');
      return prior.result as Result;
    }
    const result = await work(tx, operationKey);
    tx.create(ref, { uid, kind, inputHash, status: 'complete', result, createdAt: now });
    return result;
  });
}
export function notification(tx: Transaction, db: Firestore, uid: string, op: string, type: string, entityType: string, entityId: string, now: Timestamp) {
  const title = type === 'registration_confirmed' ? 'Đăng ký thành công' : type === 'reward_redeemed' ? 'Đổi quà thành công' : 'Cập nhật sự kiện';
  tx.create(db.doc(`notifications/${key(uid, op, type)}`), { uid, type, title, body: title, entityType, entityId, readAt: null, createdAt: now });
}
export function json(value: unknown): any {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map(json);
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, json(v)]));
  return value;
}
