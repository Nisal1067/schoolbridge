enum UserRole {
  parent,
  teacher,
  student,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.parent:
        return 'Parent';

      case UserRole.teacher:
        return 'Teacher';

      case UserRole.student:
        return 'Student';

      case UserRole.admin:
        return 'Administrator';
    }
  }
}