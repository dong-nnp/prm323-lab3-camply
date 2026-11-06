import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { createHash, randomUUID } from 'node:crypto';
import { createRequire } from 'node:module';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';

const { values } = parseArgs({ options: {
  apply: { type: 'boolean', default: false },
  'firebase-cli': { type: 'string' },
} });
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const directory = resolve(root, 'firebase/event-images');
const manifest = JSON.parse(await readFile(resolve(directory, 'manifest.json'), 'utf8'));
if (manifest.projectId !== 'prm393-31822' || manifest.bucket !== 'prm393-31822.firebasestorage.app') {
  throw new Error('Unexpected project/bucket; inspect the manifest before uploading.');
}
if (process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_STORAGE_EMULATOR_HOST) {
  throw new Error('Do not mix this live image upload with emulator configuration.');
}
const images = [];
for (const entry of manifest.images) {
  if (!/^demo-[a-z0-9-]+$/.test(entry.eventId) || !/^pexels-\d+\.jpg$/.test(entry.file)) {
    throw new Error('Only approved demo IDs and local JPEG files are accepted.');
  }
  const bytes = await readFile(resolve(directory, entry.file));
  if (bytes.length > 2 * 1024 * 1024 || bytes[0] !== 0xff || bytes[1] !== 0xd8) {
    throw new Error(`Invalid JPEG: ${entry.file}`);
  }
  const hash = createHash('sha256').update(bytes).digest('hex');
  images.push({ ...entry, bytes, hash, object: `events/${entry.eventId}/cover-${hash.slice(0, 16)}.jpg` });
}
if (new Set(images.map(image => image.eventId)).size !== images.length) throw new Error('Duplicate event IDs.');
console.log(`Prepared ${images.length} JPEGs (${images.reduce((n, image) => n + image.bytes.length, 0)} bytes).`);
if (!values.apply) {
  console.log('DRY RUN: local files validated; no network reads or writes.');
  process.exit(0);
}
if (!values['firebase-cli']) throw new Error('Provide --firebase-cli PATH_TO_FIREBASE_TOOLS after firebase login.');
// shortcut: maintainer-only helper uses Firebase CLI 15.35.0 auth internals; use ADC for CI.
const require = createRequire(import.meta.url);
const cli = resolve(values['firebase-cli']);
const version = require(resolve(cli, 'package.json')).version;
if (version !== '15.35.0') throw new Error('This helper expects Firebase CLI 15.35.0.');
const auth = require(resolve(cli, 'lib/auth.js'));
const account = auth.getGlobalDefaultAccount();
if (!account?.tokens?.refresh_token) throw new Error('Run firebase login first. Never paste credentials into this script.');
async function request(url, options = {}, allowMissing = false) {
  const token = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const response = await fetch(url, {
    ...options,
    headers: { ...options.headers, Authorization: `Bearer ${token.access_token}` },
    signal: AbortSignal.timeout(60000),
  });
  if (allowMissing && response.status === 404) return null;
  if (!response.ok) throw new Error(`Cloud request failed: HTTP ${response.status}. No access credentials are logged.`);
  return response.json();
}
const bucket = encodeURIComponent(manifest.bucket);
const database = `https://firestore.googleapis.com/v1/projects/${manifest.projectId}/databases/(default)`;
await request(`https://storage.googleapis.com/storage/v1/b/${bucket}`);
// Read every target before uploading. Never create events or replace unrelated existing images.
const before = [];
for (const image of images) {
  const doc = await request(`${database}/documents/events/${image.eventId}`);
  if (!doc.fields?.title?.stringValue?.startsWith('[DEMO]')) throw new Error(`Not a demo event: ${image.eventId}`);
  const prior = doc.fields.imageUrl?.stringValue;
  const ownPrefix = `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodeURIComponent(`events/${image.eventId}/`)}`;
  if (prior && !prior.startsWith(ownPrefix)) throw new Error(`Event already has another image: ${image.eventId}`);
  before.push({ id: image.eventId, name: doc.name, updateTime: doc.updateTime, imageUrl: prior ?? null });
}
const local = resolve(root, '.local/event-images');
await mkdir(local, { recursive: true });
const run = Date.now();
await writeFile(resolve(local, `before-${run}.json`), JSON.stringify(before, null, 2));
const uploaded = [];
for (const image of images) {
  const metadataUrl = `https://storage.googleapis.com/storage/v1/b/${bucket}/o/${encodeURIComponent(image.object)}`;
  let metadata = await request(metadataUrl, {}, true);
  if (!metadata) {
    const boundary = `evia-${randomUUID()}`;
    const objectMetadata = {
      name: image.object,
      contentType: 'image/jpeg',
      cacheControl: 'public,max-age=31536000,immutable',
      metadata: { firebaseStorageDownloadTokens: randomUUID(), sha256: image.hash, sourceUrl: image.sourceUrl, illustrativeOnly: 'true' },
    };
    const body = Buffer.concat([
      Buffer.from(`--${boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${JSON.stringify(objectMetadata)}\r\n--${boundary}\r\nContent-Type: image/jpeg\r\n\r\n`),
      image.bytes,
      Buffer.from(`\r\n--${boundary}--\r\n`),
    ]);
    metadata = await request(`https://storage.googleapis.com/upload/storage/v1/b/${bucket}/o?uploadType=multipart&ifGenerationMatch=0`, {
      method: 'POST', headers: { 'Content-Type': `multipart/related; boundary=${boundary}` }, body,
    });
  }
  if (metadata.metadata?.sha256 !== image.hash || !metadata.metadata?.firebaseStorageDownloadTokens) {
    throw new Error(`Unexpected existing object: ${image.eventId}`);
  }
  const token = metadata.metadata.firebaseStorageDownloadTokens.split(',')[0];
  const imageUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodeURIComponent(image.object)}?alt=media&token=${encodeURIComponent(token)}`;
  uploaded.push({ id: image.eventId, object: image.object, generation: metadata.generation, imageUrl });
  console.log(`Storage ready: ${image.eventId}`);
}
// Atomic update with preconditions: concurrent edits fail rather than being overwritten.
const now = new Date().toISOString();
await request(`${database}/documents:commit`, {
  method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ writes: uploaded.map((image, index) => ({
    update: { name: before[index].name, fields: { imageUrl: { stringValue: image.imageUrl }, updatedAt: { timestampValue: now } } },
    updateMask: { fieldPaths: ['imageUrl', 'updatedAt'] },
    currentDocument: { updateTime: before[index].updateTime },
  })) }),
});
for (const image of uploaded) {
  const doc = await request(`${database}/documents/events/${image.id}`);
  if (doc.fields.imageUrl?.stringValue !== image.imageUrl) throw new Error(`Read-back mismatch: ${image.id}`);
  const photo = await fetch(image.imageUrl, { signal: AbortSignal.timeout(30000) });
  if (!photo.ok || !photo.headers.get('content-type')?.startsWith('image/jpeg')) throw new Error(`Image URL failed: ${image.id}`);
  await photo.arrayBuffer();
}
const catalogPath = resolve(root, 'firebase/demo-catalog.json');
const catalog = JSON.parse(await readFile(catalogPath, 'utf8'));
for (const event of catalog.events) {
  const image = uploaded.find(image => image.id === event.id);
  if (image) event.imageUrl = image.imageUrl;
}
await writeFile(catalogPath, `${JSON.stringify(catalog, null, 2)}\n`);
await writeFile(resolve(local, `uploaded-${run}.json`), JSON.stringify({ project: manifest.projectId, verified: true, images: uploaded }, null, 2));
console.log(`VERIFIED: ${uploaded.length} Storage objects and Firestore image URLs. Security Rules unchanged.`);
