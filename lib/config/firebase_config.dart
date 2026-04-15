import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseConfig {
  static bool _isReady = false;

  static bool get isReady => _isReady;

  static Future<void> initialize() async {
    try {
      // Use the generated DefaultFirebaseOptions for all platforms.
      // This is the recommended approach when using FlutterFire CLI.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _isReady = true;
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      _isReady = false;
      debugPrint('Firebase initialization error: $e');
      // Re-throw or handle based on your app's needs
    }
  }
}
