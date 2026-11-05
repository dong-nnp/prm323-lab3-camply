import { z } from 'zod';

const id = z.string().regex(/^[A-Za-z0-9_-]{1,128}$/);
const text = z.string().trim().min(1).max(20_000);
const iso = z.iso.datetime();
const nonnegative = z.number().int().min(0).max(1_000_000_000);
const sourceRef = z.url().refine(s => s.startsWith('https://'));
export const organizerSchema = z.object({ id, name: text.max(150), description: text, tagline: text.max(200).optional(), kind: text.max(64).optional(), logoUrl: z.url().optional(), tags: z.array(id).max(20).default([]), published: z.boolean(), sourceRef }).strict();
export const eventSchema = z.object({
  id, organizerId: id, title: text.max(200), subtitle: text.max(200).optional(), description: text, category: id, tags: z.array(id).max(20), imageUrl: z.url().optional(), status: z.enum(['draft', 'published', 'cancelled', 'completed']), visibility: z.enum(['public', 'private']),
  startAt: iso, endAt: iso, timezone: z.string().refine(tz => { try { new Intl.DateTimeFormat('en', { timeZone: tz }); return true; } catch { return false; } }), doorsOpenAt: iso.optional(), registrationClosesAt: iso.optional(), checkInStartAt: iso, checkInEndAt: iso,
  venue: z.object({ name: text.max(200), address: text.max(500).optional(), entranceLabel: text.max(100).optional(), latitude: z.number().min(-90).max(90).optional(), longitude: z.number().min(-180).max(180).optional(), checkInInstructions: text.optional(), accessibilityNotes: text.optional(), transitNotes: text.optional() }).strict().refine(v => (v.latitude === undefined) === (v.longitude === undefined)),
  audience: z.object({ scope: z.literal('everyone') }).strict(),
  benefits: z.array(z.object({ title: text.max(150), description: text }).strict()).max(30).default([]), participantRequirements: z.array(text).max(30).default([]),
  schedule: z.array(z.object({ id, title: text.max(200), startAt: iso, endAt: iso.optional(), description: text.optional(), locationLabel: text.max(200).optional() }).strict()).max(100).default([]), scheduleNote: text.optional(), featured: z.boolean().default(false), admissionNote: text.max(500).optional(), registrationTerms: z.object({ version: id.max(100), text }).strict().optional(),
  participationMode: z.enum(['registration', 'walk_in']), capacity: nonnegative.nullable(), depositCoins: nonnegative, attendanceRewardCoins: nonnegative, sourceRef,
}).strict().superRefine((v, ctx) => {
  const invalid = (message: string) => ctx.addIssue({ code: 'custom', message });
  if (Date.parse(v.startAt) >= Date.parse(v.endAt)) invalid('startAt must precede endAt');
  if (Date.parse(v.checkInStartAt) >= Date.parse(v.checkInEndAt)) invalid('Invalid check-in window');
  if (v.participationMode === 'registration' && !v.registrationTerms) invalid('Registration terms required');
  if (v.participationMode === 'walk_in' && v.depositCoins !== 0) invalid('Walk-in cannot hold a deposit');
  if (new Set(v.schedule.map(s => s.id)).size !== v.schedule.length) invalid('Duplicate schedule IDs');
  for (let i = 0; i < v.schedule.length; i++) {
    const item = v.schedule[i];
    if (item.endAt && Date.parse(item.endAt) < Date.parse(item.startAt)) invalid('Invalid schedule interval');
    if (i && Date.parse(item.startAt) < Date.parse(v.schedule[i - 1].startAt)) invalid('Schedule must be chronological');
  }
});
export const rewardSchema = z.object({ id, title: text.max(200), description: text, category: id, priceCoins: nonnegative, stockRemaining: nonnegative, status: z.enum(['active', 'inactive']), validDays: z.number().int().min(1).max(365).optional(), usageLocations: z.array(text.max(300)).max(30), termsText: text, termsVersion: id.max(100), redemptionSteps: z.array(text).min(1).max(20), fulfillmentType: z.enum(['voucher', 'physical']), redemptionInstructions: text.optional(), imageUrl: z.url().optional(), sourceRef }).strict();
export const interestSchema = z.object({ id, label: text.max(100), status: z.enum(['active', 'inactive']), sourceRef }).strict();
export const milestoneSchema = z.object({ id, title: text.max(150), description: z.string().trim().max(500).default(''), metric: z.literal('verified_events'), requiredEvents: z.number().int().min(1).max(100_000), rewardCoins: nonnegative.min(1), sortOrder: z.number().int().min(0).max(100_000).default(0), active: z.boolean().default(true) }).strict();
export const catalogSchema = z.object({ organizers: z.array(organizerSchema).max(100).default([]), events: z.array(eventSchema).max(100).default([]), rewards: z.array(rewardSchema).max(100).default([]), interests: z.array(interestSchema).max(100).default([]), milestones: z.array(milestoneSchema).max(100).default([]) }).strict().refine(v => Object.values(v).every(rows => new Set(rows.map(r => r.id)).size === rows.length), 'Duplicate IDs').refine(v => Object.values(v).some(rows => rows.length > 0), 'Empty catalog');
