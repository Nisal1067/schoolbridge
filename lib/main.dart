import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'auth/screens/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    runApp(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Firebase setup is incomplete. Run flutterfire configure '
                'in the schoolbridge directory, then restart the app.',
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }
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
