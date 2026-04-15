import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();

      // Always restore persisted auth before deciding route.
      await authProvider.loadUserFromStorage();

      // If user is authenticated
      if (authProvider.isAuthenticated) {
        // Load user into user provider
        await userProvider.loadFromStorage();

        // If user has a group, go to dashboard
        final groupId = await userProvider.getStoredGroupId();
        if (groupId != null && groupId.isNotEmpty) {
          Navigator.of(context).pushReplacementNamed(routeDashboard);
        } else {
          // User exists but not in a group - go to join group
          Navigator.of(context).pushReplacementNamed(routeJoinGroup);
        }
      } else {
        // No user authenticated - go to login/signup
        Navigator.of(context).pushReplacementNamed(routeLoginSignup);
      }
    } catch (e) {
      print('❌ Navigation error: $e');
      // On error, go to login
      Navigator.of(context).pushReplacementNamed(routeLoginSignup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B5B95), Color(0xFF00B4D8)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(
                size: 110,
                backgroundColor: Colors.white,
                padding: EdgeInsets.all(12),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              const SizedBox(height: 24),
              const Text(
                appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Split expenses with friends',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
