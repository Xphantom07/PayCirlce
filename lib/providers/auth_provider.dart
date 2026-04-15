import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/helpers.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  /// Load user from local storage
  Future<void> loadUserFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await StorageService.getUserId();
      if (userId != null && userId.isNotEmpty) {
        final name = await StorageService.get('userName') ?? 'User';
        final email = await StorageService.get('userEmail') ?? '';
        final photoUrl = await StorageService.get('photoUrl');
        final pinHash = await AuthService.getPinHash() ?? '';
        final createdAtStr = await StorageService.get('createdAt');
        final createdAt = createdAtStr != null
            ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
            : DateTime.now();

        _currentUser = User(
          userId: userId,
          name: name,
          email: email,
          photoUrl: photoUrl,
          pinHash: pinHash,
          createdAt: createdAt,
        );
        _error = null;
      }
    } catch (e) {
      _error = 'Error loading user: $e';
      print('❌ $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sign up new user
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String pin,
    required String confirmPin,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validation
      if (name.isEmpty) {
        _error = 'Name cannot be empty';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final normalizedEmail = email.trim().toLowerCase();

      if (!_isValidEmail(normalizedEmail)) {
        _error = 'Invalid email format';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _error = 'Password cannot be empty';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _error = 'Password must be at least 6 characters';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password != confirmPassword) {
        _error = 'Passwords do not match';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!AuthService.isValidPin(pin)) {
        _error = 'PIN must be exactly 4 digits';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (pin != confirmPin) {
        _error = 'PINs do not match';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if email already exists (in this simple app, we check local storage)
      final existingEmail = await StorageService.get('userEmail');
      if (existingEmail != null &&
          existingEmail.trim().toLowerCase() == normalizedEmail) {
        _error = 'Email already registered';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check duplicate in Firebase auth records as well.
      final firebaseExisting = await FirebaseService.getAuthUserByEmail(
        normalizedEmail,
      );
      if (firebaseExisting != null) {
        _error = 'Email already registered';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create new user
      final userId = Helpers.generateUserId();
      final pinHash = AuthService.hashPin(pin);
      final passwordHash = AuthService.hashPassword(password);
      final createdAt = DateTime.now();

      // Save to storage
      await StorageService.saveUserId(userId);
      await StorageService.save('userName', name);
      await StorageService.save('userEmail', normalizedEmail);
      await StorageService.save('createdAt', createdAt.toIso8601String());
      await AuthService.savePinHash(pin);
      await AuthService.savePasswordHash(password);

      // Persist login identity in Firebase for cross-device/reinstall login.
      await FirebaseService.upsertAuthUser(
        userId: userId,
        name: name,
        email: normalizedEmail,
        passwordHash: passwordHash,
        pinHash: pinHash,
        photoUrl: null,
        createdAt: createdAt,
      );

      _currentUser = User(
        userId: userId,
        name: name,
        email: normalizedEmail,
        photoUrl: null,
        pinHash: pinHash,
        createdAt: createdAt,
      );

      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Signup failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();

      // Validation
      if (!_isValidEmail(normalizedEmail)) {
        _error = 'Invalid email format';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _error = 'Password cannot be empty';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Load stored credentials
      final storedEmail = await StorageService.get('userEmail');
      final storedPasswordHash = await AuthService.getPasswordHash();
      final userId = await StorageService.getUserId();
      final enteredPasswordHash = AuthService.hashPassword(password);

      // Legacy migration path: user exists locally but without saved email.
      if ((storedEmail == null || storedEmail.trim().isEmpty) &&
          userId != null &&
          userId.isNotEmpty &&
          storedPasswordHash != null &&
          storedPasswordHash == enteredPasswordHash) {
        await StorageService.save('userEmail', normalizedEmail);
      }

      final effectiveEmail = (await StorageService.get(
        'userEmail',
      ))?.trim().toLowerCase();
      // Check local email first; if not found, try Firebase auth record.
      if (effectiveEmail == null || effectiveEmail != normalizedEmail) {
        final firebaseAuthUser = await FirebaseService.getAuthUserByEmail(
          normalizedEmail,
        );
        if (firebaseAuthUser == null) {
          _error = 'Email not found. Please sign up first';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final firebasePasswordHash =
            (firebaseAuthUser['passwordHash'] as String?) ?? '';
        final firebaseLegacyPinHash =
            (firebaseAuthUser['pinHash'] as String?) ?? '';
        final effectiveAuthHash = firebasePasswordHash.isNotEmpty
            ? firebasePasswordHash
            : firebaseLegacyPinHash;
        if (effectiveAuthHash != enteredPasswordHash) {
          _error = 'Invalid password';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // Rehydrate local storage from Firebase auth profile.
        final firebaseUserId =
            (firebaseAuthUser['userId'] as String?) ?? Helpers.generateUserId();
        final firebaseName = (firebaseAuthUser['name'] as String?) ?? 'User';
        final firebaseCreatedAt =
            (firebaseAuthUser['createdAt'] as String?) ??
            DateTime.now().toIso8601String();
        final firebasePhotoUrl = firebaseAuthUser['photoUrl'] as String?;
        final firebasePinHash = (firebaseAuthUser['pinHash'] as String?) ?? '';

        await StorageService.saveUserId(firebaseUserId);
        await StorageService.save('userName', firebaseName);
        await StorageService.save('userEmail', normalizedEmail);
        await StorageService.save('createdAt', firebaseCreatedAt);
        if (firebasePhotoUrl != null && firebasePhotoUrl.isNotEmpty) {
          await StorageService.save('photoUrl', firebasePhotoUrl);
        }
        await AuthService.savePasswordHashValue(effectiveAuthHash);
        if (firebasePinHash.isNotEmpty) {
          await AuthService.savePinHashValue(firebasePinHash);
        }

        _currentUser = User(
          userId: firebaseUserId,
          name: firebaseName,
          email: normalizedEmail,
          photoUrl: firebasePhotoUrl,
          pinHash: firebasePinHash,
          createdAt: DateTime.tryParse(firebaseCreatedAt) ?? DateTime.now(),
        );

        if (firebasePasswordHash.isEmpty) {
          await FirebaseService.upsertAuthUser(
            userId: firebaseUserId,
            name: firebaseName,
            email: normalizedEmail,
            passwordHash: enteredPasswordHash,
            pinHash: firebasePinHash,
            photoUrl: firebasePhotoUrl,
            createdAt: DateTime.tryParse(firebaseCreatedAt) ?? DateTime.now(),
          );
        }

        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Check password
      if (storedPasswordHash == null ||
          storedPasswordHash != enteredPasswordHash) {
        _error = 'Invalid password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Load full user data
      await loadUserFromStorage();
      _error = null;
      return true;
    } catch (e) {
      _error = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear current user (logout)
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await StorageService.clearUserData();
      _currentUser = null;
      _error = null;
    } catch (e) {
      _error = 'Logout failed: $e';
      print('❌ $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Email validation
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
