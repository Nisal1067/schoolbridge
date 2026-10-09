import express from 'express';
import cors from 'cors';
import multer from 'multer';
import { rateLimit } from 'express-rate-limit';
import { v2 as cloudinary } from 'cloudinary';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { fileTypeFromBuffer } from 'file-type';
import { createHash } from 'node:crypto';
import { assigned, maxBytes, member, types } from './policy.mjs';

initializeApp({ credential: applicationDefault(), projectId: process.env.FIREBASE_PROJECT_ID || 'schoolbridge-7ade3' });
const db = getFirestore();
cloudinary.config({ cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY, api_secret: process.env.CLOUDINARY_API_SECRET, secure: true });
const configured = ['CLOUDINARY_CLOUD_NAME', 'CLOUDINARY_API_KEY', 'CLOUDINARY_API_SECRET'].every(k => process.env[k]);
export const app = express();
app.disable('x-powered-by');
const origins = (process.env.ALLOWED_ORIGINS || '').split(',').filter(Boolean);
app.use(cors({ origin(origin, callback) {
  let local = false;
  try { local = ['localhost', '127.0.0.1'].includes(new URL(origin).hostname); } catch { /* Not a browser origin. */ }
  callback(null, !origin || origins.includes(origin) || (process.env.NODE_ENV !== 'production' && local));
}, allowedHeaders: ['Authorization', 'Content-Type'], methods: ['GET', 'POST', 'DELETE'] }));
app.get('/health', (_, res) => res.json({ status: 'ok', attachmentsConfigured: configured }));
const fail = (status, message) => Object.assign(new Error(message), { status });
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: maxBytes, files: 1, fields: 0, parts: 1 } });
const profileUpload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 3 * 1024 * 1024, files: 1, fields: 0, parts: 1 } });

async function authorize(req, res, next) {
  try {
    if (!configured) throw fail(503, 'Attachment server needs Cloudinary configuration.');
    const match = /^Bearer (.+)$/.exec(req.get('Authorization') || '');
    if (!match) throw fail(401, 'Sign in to access attachments.');
    try { req.uid = (await getAuth().verifyIdToken(match[1], true)).uid; }
    catch { throw fail(401, 'Session expired. Sign in again.'); }
    if (![req.params.chatId, req.params.messageId].every(id => /^[A-Za-z0-9_%:-]{1,300}$/.test(id))) {
      throw fail(400, 'Invalid attachment identifier.');
    }
    req.chatRef = db.collection('chats').doc(req.params.chatId);
    const [profile, chat] = await Promise.all([
      db.collection('users').doc(req.uid).get(), req.chatRef.get(),
    ]);
    req.chat = chat.data();
    if (!member(req.uid, profile.data(), req.chat)) throw fail(403, 'Attachment access denied.');
    req.record = req.chatRef.collection('attachmentUploads').doc(req.params.messageId);
    req.message = req.chatRef.collection('messages').doc(req.params.messageId);
    next();
  } catch (error) { next(error); }
}

async function authorizeProfile(req, res, next) {
  try {
    if (!configured) throw fail(503, 'Profile photo server needs Cloudinary configuration.');
    const match = /^Bearer (.+)$/.exec(req.get('Authorization') || '');
    if (!match) throw fail(401, 'Sign in to access profile photos.');
    try { req.uid = (await getAuth().verifyIdToken(match[1], true)).uid; }
    catch { throw fail(401, 'Session expired. Sign in again.'); }
    req.userRef = db.collection('users').doc(req.uid);
    const profile = await req.userRef.get();
    if (!profile.exists || profile.data().active === false) throw fail(403, 'Profile photo access denied.');
    req.profile = profile.data();
    next();
  } catch (error) { next(error); }
}

const route = '/chats/:chatId/attachments/:messageId';
app.use('/chats', rateLimit({ windowMs: 60_000, limit: 60, standardHeaders: 'draft-8', legacyHeaders: false }));
const uploadLimit = rateLimit({ windowMs: 300_000, limit: 10,
  keyGenerator: req => req.uid, standardHeaders: 'draft-8', legacyHeaders: false });

app.post(route, authorize, uploadLimit, upload.single('file'), async (req, res) => {
  const file = req.file;
  if (!file || file.size === 0) throw fail(400, 'Select a non-empty file under 10 MB.');
  const name = file.originalname.replace(/[\\/\x00-\x1f]/g, '_');
  const extension = name.split('.').at(-1).toLowerCase();
  if (!types[extension] || name.length > 255) throw fail(400, 'Choose a JPG, PNG, PDF, TXT or DOCX file.');
  const detected = await fileTypeFromBuffer(file.buffer);
  if (extension === 'txt') {
    if (detected || file.buffer.includes(0)) throw fail(400, 'This file is not plain text.');
    try { new TextDecoder('utf-8', { fatal: true }).decode(file.buffer); }
    catch { throw fail(400, 'Choose a UTF-8 text file.'); }
  } else if (detected?.mime !== types[extension]) {
    throw fail(400, 'File content does not match its extension.');
  }
  const context = await Promise.all([
    db.collection('users').doc(req.chat.teacherId).get(), db.collection('users').doc(req.chat.parentId).get(),
    db.collection('students').doc(req.chat.studentId).get(), db.collection('classes').doc(req.chat.classId).get(),
  ]);
  if (!assigned(req.chat, ...context.map(d => d.data()))) throw fail(403, 'Teacher assignment or parent link is no longer valid.');
  const digest = createHash('sha256').update(file.buffer).digest('hex');
  const descriptor = { provider: 'cloudinary', path: `chats/${req.params.chatId}/${req.uid}/${req.params.messageId}/attachment`,
    name, size: file.size, contentType: types[extension] };
  const publicId = `schoolbridge/${createHash('sha256').update(descriptor.path).digest('hex')}.${extension}`;
  const existing = await db.runTransaction(async tx => {
    const [record, message] = await Promise.all([tx.get(req.record), tx.get(req.message)]);
    const previous = record.data();
    if (previous?.state === 'ready' && previous.uid === req.uid && previous.digest === digest && previous.attachment.name === name) return previous;
    if (message.exists) throw fail(409, 'This message has already been sent.');
    if (previous) throw fail(409, 'This upload is already pending. Retry later or remove the draft.');
    tx.create(req.record, { uid: req.uid, state: 'uploading', digest, publicId, extension,
      attachment: descriptor, createdAt: FieldValue.serverTimestamp() });
    return null;
  });
  if (existing) return res.json(existing.attachment);
  try {
    const result = await new Promise((resolve, reject) => {
      cloudinary.uploader.upload_stream({ resource_type: 'raw', type: 'private', public_id: publicId,
        overwrite: false, timeout: 60000 }, (error, result) => error ? reject(error) : resolve(result)).end(file.buffer);
    });
    if (result.bytes !== file.size || result.type !== 'private') throw Error('Unexpected attachment provider response.');
    await req.record.update({ state: 'ready' });
    res.status(201).json(descriptor);
  } catch {
    // Keep the draft so retries/cleanup cannot orphan an uploaded private asset.
    await req.record.update({ state: 'failed' });
    throw fail(502, 'Cloudinary upload failed. Remove the draft and choose the file again.');
  }
});

app.post('/profile-photo', authorizeProfile, uploadLimit, profileUpload.single('file'), async (req, res) => {
  const file = req.file;
  if (!file || file.size === 0) throw fail(400, 'Choose a non-empty image under 3 MB.');
  const name = file.originalname.replace(/[\\/\x00-\x1f]/g, '_');
  const extension = name.split('.').at(-1).toLowerCase();
  const allowed = { jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png' };
  if (!allowed[extension] || name.length > 255) throw fail(400, 'Choose a JPG or PNG image.');
  const detected = await fileTypeFromBuffer(file.buffer);
  if (detected?.mime !== allowed[extension]) throw fail(400, 'Image content does not match its extension.');
  const publicId = `schoolbridge/profile-photos/${req.uid}`;
  const result = await new Promise((resolve, reject) => {
    cloudinary.uploader.upload_stream({
      resource_type: 'image', type: 'private', public_id: publicId,
      overwrite: true, invalidate: true, timeout: 60000,
      transformation: [{ width: 512, height: 512, crop: 'fill', gravity: 'face:auto' }],
    }, (error, result) => error ? reject(error) : resolve(result)).end(file.buffer);
  });
  if (result.type !== 'private') throw fail(502, 'Cloudinary upload failed.');
  await req.userRef.update({
    photoProvider: 'cloudinary',
    photoPublicId: publicId,
    photoFormat: extension === 'jpeg' ? 'jpg' : extension,
    photoContentType: allowed[extension],
    updatedAt: FieldValue.serverTimestamp(),
  });
  res.status(201).json({ photoProvider: 'cloudinary', photoPublicId: publicId });
});

app.get('/profile-photo', authorizeProfile, async (req, res) => {
  const publicId = req.profile.photoPublicId;
  if (req.profile.photoProvider !== 'cloudinary' || typeof publicId !== 'string' || !publicId.startsWith(`schoolbridge/profile-photos/${req.uid}`)) {
    throw fail(404, 'Profile photo is not available.');
  }
  const url = cloudinary.utils.private_download_url(publicId, req.profile.photoFormat || 'jpg', {
    resource_type: 'image', type: 'private', expires_at: Math.floor(Date.now() / 1000) + 60,
  });
  const upstream = await fetch(url, { signal: AbortSignal.timeout(30000), redirect: 'error' });
  if (!upstream.ok) throw fail(502, 'Cloudinary blocked this profile photo.');
  const reader = upstream.body.getReader();
  const chunks = []; let size = 0;
  while (true) {
    const { done, value } = await reader.read(); if (done) break;
    size += value.length;
    if (size > 3 * 1024 * 1024) { await reader.cancel(); throw fail(502, 'Profile photo exceeded its size limit.'); }
    chunks.push(Buffer.from(value));
  }
  res.set({ 'Content-Type': req.profile.photoContentType || 'image/jpeg', 'Cache-Control': 'private, no-store', 'X-Content-Type-Options': 'nosniff' });
  res.send(Buffer.concat(chunks));
});

app.get(route, authorize, async (req, res) => {
  const [record, message] = await Promise.all([req.record.get(), req.message.get()]);
  const data = record.data();
  if (data?.state !== 'ready' || !message.exists || message.data().attachment?.path !== data.attachment.path) {
    throw fail(404, 'Attachment is not available.');
  }
  const url = cloudinary.utils.private_download_url(data.publicId, '', {
    resource_type: 'raw', type: 'private', expires_at: Math.floor(Date.now() / 1000) + 60,
  });
  const upstream = await fetch(url, { signal: AbortSignal.timeout(30000), redirect: 'error' });
  if (!upstream.ok) throw fail(502, 'Cloudinary blocked this download. Check account PDF delivery settings.');
  const reader = upstream.body.getReader();
  const chunks = []; let size = 0;
  while (true) {
    const { done, value } = await reader.read(); if (done) break;
    size += value.length;
    if (size > maxBytes) { await reader.cancel(); throw fail(502, 'Attachment exceeded its size limit.'); }
    chunks.push(Buffer.from(value));
  }
  res.set({ 'Content-Type': data.attachment.contentType, 'Cache-Control': 'private, no-store', 'X-Content-Type-Options': 'nosniff' });
  res.send(Buffer.concat(chunks));
});

app.delete(route, authorize, async (req, res) => {
  const data = await db.runTransaction(async tx => {
    const [record, message] = await Promise.all([tx.get(req.record), tx.get(req.message)]);
    if (message.exists) throw fail(409, 'Sent attachments cannot be removed.');
    if (!record.exists) return null;
    if (record.data().uid !== req.uid) throw fail(403, 'Only the sender can remove this draft.');
    if (record.data().state === 'uploading'
      && Date.now() - (record.data().createdAt?.toMillis() ?? Date.now()) < 300_000) {
      throw fail(409, 'Upload is still processing. Retry later.');
    }
    tx.update(req.record, { state: 'deleting' });
    return record.data();
  });
  if (data) {
    await cloudinary.uploader.destroy(data.publicId, { resource_type: 'raw', type: 'private' });
    await req.record.delete();
  }
  res.status(204).end();
});

app.use((error, req, res, next) => {
  if (res.headersSent) return next(error);
  const status = error instanceof multer.MulterError ? 400 : error.status || 500;
  const message = error instanceof multer.MulterError ? 'Choose one attachment under 10 MB.'
    : status < 500 || error.status ? error.message : 'Attachment service unavailable. Check server configuration.';
  res.status(status).json({ error: message });
});
if (process.env.NODE_ENV !== 'test') {
  const port = Number(process.env.PORT || 8081);
  const host = process.env.HOST || '127.0.0.1';
  const server = app.listen(port, host, () => {
    console.log(`Attachment API listening on http://${host}:${port}; Cloudinary configured: ${!!configured}`);
  });
  server.on('error', error => {
    console.error('Attachment API failed to start:', error);
    process.exitCode = 1;
  });
  server.on('close', () => console.log('Attachment API stopped.'));
}
