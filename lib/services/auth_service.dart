import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AuthService {
  static String _hashValue(String value) {
    return sha256.convert(value.codeUnits).toString();
  }

  /// Generate and hash a PIN
  static String hashPin(String pin) {
    return _hashValue(pin);
  }

  /// Generate and hash a password
  static String hashPassword(String password) {
    return _hashValue(password);
  }

  /// Verify a PIN against its hash
  static bool verifyPin(String pin, String pinHash) {
    final hashedPin = hashPin(pin);
    return hashedPin == pinHash;
  }

  /// Verify password against stored hash.
  static bool verifyPassword(String password, String passwordHash) {
    final hashedPassword = hashPassword(password);
    return hashedPassword == passwordHash;
  }

  /// Save PIN hash locally
  static Future<void> savePinHash(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final pinHash = hashPin(pin);
    await prefs.setString(storageKeyPinHash, pinHash);
  }

  /// Save an already computed PIN hash locally.
  static Future<void> savePinHashValue(String pinHash) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKeyPinHash, pinHash);
  }

  /// Save password hash locally.
  static Future<void> savePasswordHash(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final passwordHash = hashPassword(password);
    await prefs.setString(storageKeyPasswordHash, passwordHash);
  }

  /// Save an already computed password hash locally.
  static Future<void> savePasswordHashValue(String passwordHash) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKeyPasswordHash, passwordHash);
  }

  /// Retrieve stored password hash.
  static Future<String?> getPasswordHash() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(storageKeyPasswordHash);
  }

  /// Verify password against stored hash.
  static Future<bool> verifyStoredPassword(String password) async {
    final storedHash = await getPasswordHash();
    if (storedHash == null) return false;
    return verifyPassword(password, storedHash);
  }

  /// Retrieve stored PIN hash
  static Future<String?> getPinHash() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(storageKeyPinHash);
  }

  /// Verify PIN against stored hash
  static Future<bool> verifyStoredPin(String pin) async {
    final storedHash = await getPinHash();
    if (storedHash == null) return false;
    return verifyPin(pin, storedHash);
  }

  /// Validate PIN format (must be 4 digits)
  static bool isValidPin(String pin) {
    return pin.length == pinLength && int.tryParse(pin) != null;
  }

  /// Clear PIN from local storage
  static Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyPinHash);
  }
}
