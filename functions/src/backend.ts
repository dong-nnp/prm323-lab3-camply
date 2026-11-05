import { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';
import { Actor, Result, fail, json } from './shared.js';
import { accounts } from './accounts.js';
import { events } from './events.js';
import { rewards } from './rewards.js';
import { queries } from './queries.js';
import { milestones } from './milestones.js';
import { demoAttendance } from './demo_attendance.js';

export function createBackend(db: Firestore, clock = () => new Date()) {
  const handlers: Record<string, (actor: Actor | null, input: unknown) => Promise<Result>> = { ...accounts(db, clock), ...events(db, clock), ...rewards(db, clock), ...queries(db, clock), ...milestones(db, clock), ...demoAttendance(db, clock) };
  return {
    async invoke(name: string, actor: Actor | null, input: unknown = {}) {
      if (!handlers[name]) fail('UNKNOWN_OPERATION', 'not-found');
      try { return json(await handlers[name](actor, input)); }
      catch (error) {
        if (error instanceof z.ZodError) fail('VALIDATION_FAILED', 'invalid-argument', { fields: error.issues.map(i => ({ path: i.path.join('.'), code: i.code })) });
        throw error;
      }
    },
  };
}
