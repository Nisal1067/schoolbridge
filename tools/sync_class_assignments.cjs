const fs = require('node:fs');
const path = require('node:path');
const { execSync } = require('node:child_process');

// Run from schoolbridge. Dry-run by default; --apply publishes and repairs links.
async function main() {
  const root = execSync('npm root -g', { encoding: 'utf8' }).trim();
  const auth = require(path.join(root, 'firebase-tools/lib/auth.js'));
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw Error('Run firebase login first.');
  const token = await auth.getAccessToken(account.tokens.refresh_token,
    ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase']);
  const headers = { Authorization: `Bearer ${token.access_token}`, 'Content-Type': 'application/json' };
  const project = fs.readFileSync('lib/firebase_options.dart', 'utf8').match(/projectId: '([^']+)'/)[1];
  const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
  async function api(url, method = 'GET', body) {
    const response = await fetch(url, { method, headers,
      body: body ? JSON.stringify(body) : undefined, signal: AbortSignal.timeout(30000) });
    const data = await response.json();
    if (!response.ok) throw Error(JSON.stringify(data));
    return data;
  }
  async function list(collection) {
    const docs = [];
    let page = '';
    do {
      const result = await api(`${base}/${collection}?pageSize=100${page ? `&pageToken=${encodeURIComponent(page)}` : ''}`);
      docs.push(...(result.documents || []));
      page = result.nextPageToken;
    } while (page);
    return docs;
  }
  const users = await list('users');
  const authIds = new Set();
  for (let i = 0; i < users.length; i += 100) {
    const found = await api(`https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts:lookup`,
      'POST', { localId: users.slice(i, i + 100).map(d => d.name.split('/').pop()) });
    for (const user of found.users || []) authIds.add(user.localId);
  }
  const classes = new Map((await list('classes')).map(d => [d.name.split('/').pop(), d.fields]));
  const students = new Map((await list('students')).map(d => [d.name.split('/').pop(), d.fields]));
  const writes = [];
  let repaired = 0, skipped = 0;
  for (const user of users) {
    const f = user.fields, uid = user.name.split('/').pop();
    const role = f.role?.stringValue;
    const label = (f.gradeOrClass?.stringValue || f.class?.stringValue || '').trim();
    if (!['teacher', 'student'].includes(role) || !label) continue;
    if (!authIds.has(uid)) { skipped++; continue; }
    // Registration uses school01; repair older profiles missing that field.
    const school = f.schoolId?.stringValue || 'school01';
    const id = `${school}_${encodeURIComponent(label)}`;
    const classroom = classes.get(id) || { name: { stringValue: label }, schoolId: { stringValue: school } };
    if (classroom.schoolId.stringValue !== school) throw Error('Class school mismatch');
    const ids = new Set((classroom.teacherIds?.arrayValue?.values ||
      (classroom.teacherId?.stringValue ? [{ stringValue: classroom.teacherId.stringValue }] : []))
      .map(v => v.stringValue));
    if (role === 'teacher') {
      ids.delete(uid);
      if (f.active?.booleanValue === true) ids.add(uid);
    }
    classroom.teacherIds = { arrayValue: { values: [...ids].map(stringValue => ({ stringValue })) } };
    classroom.teacherId = { stringValue: [...ids][0] || '' };
    classes.set(id, classroom);
    writes.push({ update: { name: user.name, fields: { classId: { stringValue: id }, schoolId: { stringValue: school } } }, updateMask: { fieldPaths: ['classId', 'schoolId'] } });
    if (role === 'student') {
      const fields = { name: f.name, email: f.email || { stringValue: '' }, schoolId: { stringValue: school },
        active: f.active, classId: { stringValue: id },
        parentIds: students.get(uid)?.parentIds || { arrayValue: { values: [] } } };
      writes.push({ update: { name: `${base.replace('https://firestore.googleapis.com/v1/', '')}/students/${uid}`, fields },
        updateMask: { fieldPaths: Object.keys(fields) } });
    }
    repaired++;
  }
  for (const [id, fields] of classes) {
    if (!id.includes('_')) continue;
    writes.push({ update: { name: `${base.replace('https://firestore.googleapis.com/v1/', '')}/classes/${id}`, fields } });
  }

  const release = await api(`https://firebaserules.googleapis.com/v1/projects/${project}/releases/cloud.firestore`);
  const published = await api(`https://firebaserules.googleapis.com/v1/${release.rulesetName}`);
  const local = fs.readFileSync('firestore.rules', 'utf8');
  let merged = published.source.files[0].content;
  function block(source, needle) {
    const start = source.indexOf(needle);
    if (start < 0) throw Error(`Missing rule block: ${needle}`);
    const opening = needle.startsWith('match') ? source.indexOf(' {', start) + 1 : source.indexOf('{', start);
    let depth = 1, end = opening + 1;
    while (depth && end < source.length) {
      if (source[end] === '{') depth++;
      if (source[end] === '}') depth--;
      end++;
    }
    if (depth) throw Error('Unbalanced rule block');
    return { start, end, text: source.slice(start, end) };
  }
  for (const needle of ['function teaches(', 'match /classes/', 'match /students/', 'match /users/', 'match /attendance/']) {
    const remote = block(merged, needle);
    merged = merged.slice(0, remote.start) + block(local, needle).text + merged.slice(remote.end);
  }
  if (!process.argv.includes('--apply')) {
    console.log(JSON.stringify({ repaired, skipped, writes: writes.length, dryRun: true }));
    return;
  }
  const ruleset = await api(`https://firebaserules.googleapis.com/v1/projects/${project}/rulesets`, 'POST',
    { source: { files: [{ name: 'firestore.rules', content: merged }] } });
  await api(`https://firebaserules.googleapis.com/v1/projects/${project}/releases/cloud.firestore`, 'PATCH',
    { release: { name: `projects/${project}/releases/cloud.firestore`, rulesetName: ruleset.name }, updateMask: 'ruleset_name' });
  for (let i = 0; i < writes.length; i += 100) await api(`${base}:commit`, 'POST', { writes: writes.slice(i, i + 100) });
  const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/collectionGroups/classes/indexes`;
  const indexes = await api(url);
  if (!(indexes.indexes || []).some(i => i.fields.some(f => f.fieldPath === 'teacherIds') && i.fields.some(f => f.fieldPath === 'schoolId'))) {
    await api(url, 'POST', { queryScope: 'COLLECTION', fields: [
      { fieldPath: 'teacherIds', arrayConfig: 'CONTAINS' }, { fieldPath: 'schoolId', order: 'ASCENDING' } ] });
  }
  console.log(JSON.stringify({ repaired, skipped, rules: merged }));
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
