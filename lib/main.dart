import 'package:flutter/material.dart';

import 'auth/screens/splash_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const SchoolBridgeApp());
}

class SchoolBridgeApp extends StatelessWidget {
  const SchoolBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SchoolBridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
