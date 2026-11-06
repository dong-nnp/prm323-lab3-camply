import { Firestore } from 'firebase-admin/firestore';
import { coins } from './shared.js';
import { z } from 'zod';

export const REGION = 'asia-southeast1';
export const PRODUCT_TIMEZONE = 'Asia/Ho_Chi_Minh';
export const SIGNUP_BONUS_COINS = 200;

export const dailyRewardsSchema = z.array(coins).length(7);
export const defaultDailyRewards = [5, 10, 15, 30, 50, 70, 100] as const;
export const dailyRewardPolicy = (db: Firestore) => db.doc('server_config/daily_checkin');
export type DailyState = { lastLocalDate: string; streakDay: number };

export function dailyGrant(now: Date, previous: DailyState | null, rewards: readonly number[] = defaultDailyRewards) {
  const dayKey = new Intl.DateTimeFormat('en-CA', { timeZone: PRODUCT_TIMEZONE, year: 'numeric', month: '2-digit', day: '2-digit' }).format(now);
  const yesterday = new Date(`${dayKey}T00:00:00Z`);
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  const alreadyClaimed = previous?.lastLocalDate === dayKey;
  const streakDay = alreadyClaimed ? previous.streakDay : previous?.lastLocalDate === yesterday.toISOString().slice(0, 10) ? previous.streakDay + 1 : 1;
  return { dayKey, streakDay, coins: rewards[Math.min(streakDay, 7) - 1], alreadyClaimed };
}
