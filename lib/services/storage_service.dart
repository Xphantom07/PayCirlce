import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  /// Save user ID locally
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKeyUserId, userId);
  }

  /// Retrieve stored user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(storageKeyUserId);
  }

  /// Save group ID locally
  static Future<void> saveGroupId(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKeyGroupId, groupId);
  }

  /// Retrieve stored group ID
  static Future<String?> getGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(storageKeyGroupId);
  }

  /// Check if user is already setup
  static Future<bool> isUserSetup() async {
    final userId = await getUserId();
    return userId != null && userId.isNotEmpty;
  }

  /// Check if user is in a group
  static Future<bool> isUserInGroup() async {
    final groupId = await getGroupId();
    return groupId != null && groupId.isNotEmpty;
  }

  /// Clear user data (logout)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyUserId);
    await prefs.remove(storageKeyGroupId);
    await prefs.remove(storageKeyPinHash);
    await prefs.remove(storageKeyPasswordHash);
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('photoUrl');
    await prefs.remove('createdAt');
  }

  /// Save arbitrary key-value pair
  static Future<void> save(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Retrieve arbitrary value
  static Future<String?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Remove arbitrary key
  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
