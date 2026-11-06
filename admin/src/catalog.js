import { catalogSchema, eventSchema, rewardSchema } from '../../functions/src/catalog.ts';

const timezone = 'Asia/Ho_Chi_Minh';
export const standardEventTerms = 'Số xu đặt cọc và thưởng check-in được hiển thị trong thông tin sự kiện. Hủy đăng ký được hoàn 30% xu đặt cọc (làm tròn xuống). Không tham dự mất toàn bộ tiền cọc. Vui lòng check-in trong thời gian quy định.';
const string = (fields, name) => String(fields.get(name) ?? '').trim();
const optional = (fields, name) => string(fields, name) || undefined;
const lines = (fields, name) => string(fields, name).split(/\r?\n/).map(line => line.trim()).filter(Boolean);
const integer = (fields, name) => {
  const value = optional(fields, name);
  return value === undefined ? undefined : Number(value);
};

function imageUrl(fields) {
  const url = optional(fields, 'imageUrl');
  if (url && !url.toLowerCase().startsWith('https://')) throw new Error('URL ảnh phải dùng HTTPS.');
  return url;
}

function vietnamDate(fields, name) {
  const value = string(fields, name);
  if (!value) return undefined;
  const date = new Date(value + '+07:00');
  if (!Number.isFinite(date.getTime())) throw new Error('Ngày giờ không hợp lệ. Hãy kiểm tra trường ' + name + '.');
  return date.toISOString();
}

function schedule(fields) {
  const input = string(fields, 'schedule');
  if (!input) return [];
  try {
    return JSON.parse(input);
  } catch {
    throw new Error('Lịch chi tiết phải là JSON hợp lệ.');
  }
}

export function eventImport(fields) {
  const registration = string(fields, 'participationMode') === 'registration';
  const event = eventSchema.parse({
    id: string(fields, 'id'),
    organizerId: string(fields, 'organizerId'),
    title: string(fields, 'title'),
    description: string(fields, 'description'),
    category: string(fields, 'category'),
    tags: lines(fields, 'tags'),
    imageUrl: imageUrl(fields),
    sourceRef: string(fields, 'sourceRef'),
    status: 'draft',
    visibility: optional(fields, 'visibility') ?? 'public',
    startAt: vietnamDate(fields, 'startAt'),
    endAt: vietnamDate(fields, 'endAt'),
    timezone,
    registrationClosesAt: registration ? vietnamDate(fields, 'registrationClosesAt') : undefined,
    checkInStartAt: vietnamDate(fields, 'checkInStartAt'),
    checkInEndAt: vietnamDate(fields, 'checkInEndAt'),
    venue: { name: string(fields, 'venue'), address: optional(fields, 'address') },
    audience: { scope: 'everyone' },
    schedule: schedule(fields),
    participationMode: string(fields, 'participationMode'),
    capacity: optional(fields, 'capacity') ? integer(fields, 'capacity') : null,
    depositCoins: registration ? integer(fields, 'depositCoins') : 0,
    attendanceRewardCoins: integer(fields, 'attendanceRewardCoins'),
    registrationTerms: registration ? {
      text: string(fields, 'registrationTerms'),
      version: string(fields, 'registrationTermsVersion'),
    } : undefined,
  });
  return catalogSchema.parse({ events: [event] });
}

export function voucherImport(fields) {
  const reward = rewardSchema.parse({
    id: string(fields, 'id'),
    title: string(fields, 'title'),
    description: string(fields, 'description'),
    category: string(fields, 'category'),
    sourceRef: string(fields, 'sourceRef'),
    imageUrl: imageUrl(fields),
    priceCoins: integer(fields, 'priceCoins'),
    stockRemaining: integer(fields, 'stockRemaining'),
    validDays: optional(fields, 'validDays') ? integer(fields, 'validDays') : undefined,
    status: optional(fields, 'status') ?? 'inactive',
    usageLocations: lines(fields, 'usageLocations'),
    termsText: string(fields, 'termsText'),
    termsVersion: string(fields, 'termsVersion'),
    redemptionSteps: lines(fields, 'redemptionSteps'),
    redemptionInstructions: optional(fields, 'redemptionInstructions'),
    fulfillmentType: 'voucher',
  });
  return catalogSchema.parse({ rewards: [reward] });
}

export function editorValues(entry) {
  const values = { ...entry };
  for (const field of ['startAt', 'endAt', 'checkInStartAt', 'checkInEndAt', 'registrationClosesAt']) {
    const timestamp = Date.parse(entry[field]);
    if (Number.isFinite(timestamp)) {
      values[field] = new Date(timestamp + 7 * 60 * 60 * 1000).toISOString().slice(0, -1);
    }
  }
  for (const field of ['tags', 'usageLocations', 'redemptionSteps']) {
    if (Array.isArray(entry[field])) values[field] = entry[field].join('\n');
  }
  values.venue = entry.venue?.name ?? '';
  values.address = entry.venue?.address ?? '';
  values.registrationTerms = entry.registrationTerms?.text ?? '';
  values.registrationTermsVersion = entry.registrationTerms?.version ?? '';
  values.schedule = entry.schedule?.length ? JSON.stringify(entry.schedule, null, 2) : '';
  return values;
}

export function catalogEntry(kind, fields, original, options = {}) {
  if (kind === 'rewards') return voucherImport(fields).rewards[0];

  fields = new Map(fields);
  const eventId = original?.id || string(fields, 'id') || options.id;
  fields.set('id', eventId);
  if (!fields.has('sourceRef')) {
    if (!original?.sourceRef && !options.projectId) throw new Error('Chưa có cấu hình dự án Firebase.');
    fields.set('sourceRef', original?.sourceRef ?? `https://console.firebase.google.com/project/${encodeURIComponent(options.projectId)}/firestore/data/~2Fevents~2F${encodeURIComponent(eventId)}`);
  }
  if (!fields.has('registrationTerms')) fields.set('registrationTerms', original?.registrationTerms?.text ?? standardEventTerms);
  if (!fields.has('registrationTermsVersion')) fields.set('registrationTermsVersion', original?.registrationTerms?.version ?? 'evia-standard-v1');
  if (!fields.has('schedule')) fields.set('schedule', JSON.stringify(original?.schedule ?? []));
  if (!fields.has('imageUrl')) fields.set('imageUrl', options.imageUrl ?? original?.imageUrl ?? '');
  if (!optional(fields, 'checkInStartAt')) fields.set('checkInStartAt', string(fields, 'startAt'));
  if (!optional(fields, 'checkInEndAt')) fields.set('checkInEndAt', string(fields, 'endAt'));

  if (original?.status === 'published') {
    for (const field of ['organizerId', 'visibility', 'participationMode']) fields.set(field, original[field]);
  }
  const [event] = eventImport(fields).events;
  if (!original) return event;

  const { revision, registeredCount, ...saved } = original;
  return eventSchema.parse({
    ...saved,
    ...event,
    status: original.status,
    timezone: original.timezone ?? event.timezone,
    audience: original.audience ?? event.audience,
    venue: { ...original.venue, ...event.venue },
    benefits: original.benefits,
    participantRequirements: original.participantRequirements,
    featured: original.featured,
  });
}
