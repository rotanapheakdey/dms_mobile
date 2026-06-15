import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleAppStartup();
  }

  Future<void> _handleAppStartup() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final String? token = await AuthService.getToken();
    final bool isLoggedIn = token != null && token.isNotEmpty;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const DashboardScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1976D2), // Matches your primary app brand theme color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo Placeholder (Swap with Image.asset('assets/logo.png') later if needed)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.description_rounded, size: 60, color: Color(0xFF1976D2)),
            ),
            const SizedBox(height: 24),
            
            // App Name Branding
            const Text(
              'Digital Archive System',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ministry of Information',
              style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 48),
            
            // Circular Loading Accent
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}