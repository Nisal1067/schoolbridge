import test from 'node:test';
import assert from 'node:assert/strict';
import { assigned, member, types } from './policy.mjs';
const chat = { schoolId: 'school01', teacherId: 'teacher1', parentId: 'parent1',
  classId: 'class1', participantIds: ['teacher1', 'parent1'] };
const teacher = { active: true, role: 'teacher', schoolId: 'school01' };
const parent = { active: true, role: 'parent', schoolId: 'school01' };
const child = { schoolId: 'school01', classId: 'class1', parentIds: ['parent1'] };
const classroom = { schoolId: 'school01', teacherIds: ['teacher1'] };

test('Only active, same-school teacher/parent participants have access', () => {
  assert.equal(member('teacher1', teacher, chat), true);
  assert.equal(member('parent1', parent, chat), true);
  assert.equal(member('outsider', teacher, chat), false);
  assert.equal(member('parent1', { ...parent, active: false }, chat), false);
  assert.equal(member('parent1', { ...parent, role: 'student' }, chat), false);
  assert.equal(member('parent1', { ...parent, schoolId: 'other' }, chat), false);
});
test('Uploads require the real class and parent assignment', () => {
  assert.equal(assigned(chat, teacher, parent, child, classroom), true);
  assert.equal(assigned(chat, teacher, parent, { ...child, parentIds: [] }, classroom), false);
  assert.equal(assigned(chat, teacher, parent, { ...child, classId: 'other' }, classroom), false);
  assert.equal(assigned(chat, teacher, parent, child, { ...classroom, teacherIds: [] }), false);
  assert.equal(assigned(chat, teacher, { ...parent, active: false }, child, classroom), false);
});
test('PDF is supported; executable files are not', () => {
  assert.equal(types.pdf, 'application/pdf');
  assert.equal(types.exe, undefined);
});
