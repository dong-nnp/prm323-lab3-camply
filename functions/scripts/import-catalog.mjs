import { readFile } from 'node:fs/promises';
import { parseArgs } from 'node:util';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { catalogSchema } from '../lib/catalog.js';

const { values } = parseArgs({ options: { input: { type: 'string' }, project: { type: 'string' }, apply: { type: 'boolean', default: false } } });
if (!values.input || !values.project) throw new Error('Usage: node scripts/import-catalog.mjs --input approved.json --project PROJECT [--apply]');
const catalog = catalogSchema.parse(JSON.parse(await readFile(values.input, 'utf8')));
const counts = Object.fromEntries(Object.entries(catalog).map(([k, rows]) => [k, rows.length]));
console.log(JSON.stringify({ project: values.project, apply: values.apply, counts }));
if (!values.apply) { console.log('DRY RUN: valid input; no network reads or writes.'); process.exit(0); }
if (values.project.startsWith('demo-') && !process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Demo import requires Firestore emulator');
if (!values.project.startsWith('demo-') && process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Do not mix a live project ID and emulator import');
initializeApp({ projectId: values.project });
const db = getFirestore();
const convert = value => Array.isArray(value) ? value.map(convert) : value && typeof value === 'object' ? Object.fromEntries(Object.entries(value).map(([k, v]) => [k, k.endsWith('At') && typeof v === 'string' ? Timestamp.fromDate(new Date(v)) : convert(v)])) : value;
await db.runTransaction(async tx => {
  const refs = Object.entries(catalog).flatMap(([collection, rows]) => rows.map(row => db.doc(`${collection}/${row.id}`)));
  const prior = await tx.getAll(...refs);
  if (prior.some(d => d.exists)) throw new Error('Create-only import: an ID already exists; no documents were overwritten');
  for (const event of catalog.events) {
    const organizerIncluded = catalog.organizers.some(o => o.id === event.organizerId);
    if (!organizerIncluded && !(await tx.get(db.doc(`organizers/${event.organizerId}`))).exists) throw new Error(`Missing organizer for event ${event.id}`);
  }
  const now = Timestamp.now();
  for (const [collection, rows] of Object.entries(catalog)) for (const row of rows) {
    const { id, ...fields } = row;
    tx.create(db.doc(`${collection}/${id}`), { ...convert(fields), ...(collection === 'events' ? { registeredCount: 0 } : {}), ...(collection === 'organizers' ? { followerCount: 0 } : {}), createdAt: now, updatedAt: now });
  }
});
console.log('Created approved catalog records. No users, balances, tickets or attendance were seeded.');
