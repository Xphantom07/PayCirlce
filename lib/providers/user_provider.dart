import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/helpers.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isSetup => _currentUser != null;

  Future<void> loadFromStorage() async {
    _isLoading = true;
    notifyListeners();

    final userId = await StorageService.getUserId();
    if (userId != null && userId.isNotEmpty) {
      _currentUser = User(
        userId: userId,
        name: await StorageService.get('userName') ?? 'User',
        email: await StorageService.get('userEmail') ?? '',
        photoUrl: await StorageService.get('photoUrl'),
        pinHash: await AuthService.getPinHash() ?? '',
        createdAt:
            DateTime.tryParse(await StorageService.get('createdAt') ?? '') ??
            DateTime.now(),
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setupUser({
    required String name,
    required String pin,
    String? photoUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    final userId = Helpers.generateUserId();
    final pinHash = AuthService.hashPin(pin);
    final createdAt = DateTime.now();

    await StorageService.saveUserId(userId);
    await StorageService.save('userName', name);
    await StorageService.save('createdAt', createdAt.toIso8601String());
    if (photoUrl != null && photoUrl.isNotEmpty) {
      await StorageService.save('photoUrl', photoUrl);
    }
    await AuthService.savePinHash(pin);

    _currentUser = User(
      userId: userId,
      name: name,
      email: '', // Empty for backward compatibility, auth provider sets this
      photoUrl: photoUrl,
      pinHash: pinHash,
      createdAt: createdAt,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await StorageService.clearUserData();
    _currentUser = null;
    notifyListeners();
  }

  /// Update current user (name, photoUrl, etc.)
  void updateCurrentUser({String? name, String? photoUrl}) {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      name: name ?? _currentUser!.name,
      photoUrl: photoUrl ?? _currentUser!.photoUrl,
    );

    notifyListeners();
  }

  /// Get stored group ID
  Future<String?> getStoredGroupId() async {
    return await StorageService.getGroupId();
  }
}
