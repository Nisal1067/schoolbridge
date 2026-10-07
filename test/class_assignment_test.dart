import 'package:flutter_test/flutter_test.dart';
import 'package:schoolbridge/features/user_management/services/class_assignment_service.dart';

void main() {
  test('Teacher and student class labels resolve to the same ID', () {
    expect(
      ClassAssignmentService.classId('school01', ' 11 '),
      ClassAssignmentService.classId('school01', '11'),
    );
  });
  test('Class IDs separate schools and safely encode slashes', () {
    expect(
      ClassAssignmentService.classId('school01', '11'),
      isNot(ClassAssignmentService.classId('school02', '11')),
    );
    expect(
      ClassAssignmentService.classId('school01', '11/A'),
      'school01_11%2FA',
    );
  });
}
