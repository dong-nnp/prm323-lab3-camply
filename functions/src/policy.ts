export const REGION = 'asia-southeast1';
export const PRODUCT_TIMEZONE = 'Asia/Ho_Chi_Minh';
export const SIGNUP_BONUS_COINS = 200;

export function dailyGrant(now: Date, previous: { lastLocalDate: string; streakDay: number } | null) {
  const dayKey = new Intl.DateTimeFormat('en-CA', { timeZone: PRODUCT_TIMEZONE, year: 'numeric', month: '2-digit', day: '2-digit' }).format(now);
  const yesterday = new Date(`${dayKey}T00:00:00Z`);
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  const alreadyClaimed = previous?.lastLocalDate === dayKey;
  const streakDay = alreadyClaimed ? previous.streakDay : previous?.lastLocalDate === yesterday.toISOString().slice(0, 10) ? previous.streakDay + 1 : 1;
  return { dayKey, streakDay, coins: [5, 10, 15, 30, 50, 70, 100][Math.min(streakDay, 7) - 1], alreadyClaimed };
}
