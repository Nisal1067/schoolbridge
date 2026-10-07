import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schoolbridge/features/attendance/widgets/attendance_navigation.dart';

void main() {
  testWidgets('Attendance navigation fits mobile and desktop widths', (
    tester,
  ) async {
    for (final width in [320.0, 1024.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 640);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AttendanceNavigation(
              teacher: true,
              enabled: false,
            ),
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
