export const maxBytes = 10 * 1024 * 1024;
export const types = {
  jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png',
  pdf: 'application/pdf', txt: 'text/plain',
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
};

export function member(uid, profile, chat) {
  return !!profile && !!chat && profile.active === true
    && ['teacher', 'parent'].includes(profile.role)
    && profile.schoolId === chat.schoolId
    && Array.isArray(chat.participantIds) && chat.participantIds.includes(uid);
}

export function assigned(chat, teacher, parent, child, classroom) {
  return !!teacher && !!parent && !!child && !!classroom
    && teacher.active === true && teacher.role === 'teacher'
    && parent.active === true && parent.role === 'parent'
    && [teacher, parent, child, classroom].every(d => d.schoolId === chat.schoolId)
    && child.classId === chat.classId && Array.isArray(child.parentIds) && child.parentIds.includes(chat.parentId)
    && (classroom.teacherId === chat.teacherId || (Array.isArray(classroom.teacherIds) && classroom.teacherIds.includes(chat.teacherId)));
}
