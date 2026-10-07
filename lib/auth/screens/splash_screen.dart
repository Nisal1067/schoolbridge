import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../services/session_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;
  @override
  void initState() {
    super.initState();

    _restore();
  }

  Future<void> _restore() async {
    setState(() => _error = null);
    try {
      final page = await SessionNavigation.restore();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Could not restore your session. Check your connection.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              TextButton(onPressed: _restore, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: const SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(
                  Icons.school_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 24),

              Text(
                'SchoolBridge',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'Connecting school and home',
                style: TextStyle(color: Color(0xDDFFFFFF), fontSize: 15),
              ),

              SizedBox(height: 40),

              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
