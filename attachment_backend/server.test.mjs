import test from 'node:test';
import assert from 'node:assert/strict';
import { fileTypeFromBuffer } from 'file-type';

test('PDF magic bytes are detected as PDF', async () => {
  const result = await fileTypeFromBuffer(Buffer.from('%PDF-1.4\n1 0 obj\n<<>>\nendobj\n%%EOF'));
  assert.equal(result.mime, 'application/pdf');
});

test('Unconfigured backend fails quickly instead of leaving uploads pending', async () => {
  process.env.NODE_ENV = 'test';
  delete process.env.CLOUDINARY_API_SECRET;
  const { app } = await import('./server.mjs');
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  try {
    const url = `http://127.0.0.1:${server.address().port}`;
    const health = await (await fetch(`${url}/health`)).json();
    assert.equal(health.attachmentsConfigured, false);
    const response = await fetch(`${url}/chats/teacher_parent/attachments/message`, { method: 'POST' });
    assert.equal(response.status, 503);
    assert.match((await response.json()).error, /Cloudinary configuration/);
  } finally { await new Promise(resolve => server.close(resolve)); }
});
