import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../services/storage_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _transactionNotifications = true;
  bool _balanceReminderEnabled = false;
  String _balanceReminderFrequency = 'weekly';

  bool get isDarkMode => _isDarkMode;
  bool get transactionNotifications => _transactionNotifications;
  bool get balanceReminderEnabled => _balanceReminderEnabled;
  String get balanceReminderFrequency => _balanceReminderFrequency;

  Future<void> loadSettings() async {
    final darkMode = await StorageService.get(storageKeyDarkMode);
    final txnNotifications = await StorageService.get(
      storageKeyTxnNotifications,
    );
    final balanceReminder = await StorageService.get(storageKeyBalanceReminder);
    final reminderFrequency = await StorageService.get(
      storageKeyBalanceReminderFrequency,
    );

    _isDarkMode = darkMode == 'true';
    _transactionNotifications = txnNotifications != 'false';
    _balanceReminderEnabled = balanceReminder == 'true';
    _balanceReminderFrequency =
        (reminderFrequency == 'daily' ||
            reminderFrequency == 'weekly' ||
            reminderFrequency == 'monthly')
        ? reminderFrequency!
        : 'weekly';

    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await StorageService.save(storageKeyDarkMode, value.toString());
    notifyListeners();
  }

  Future<void> setTransactionNotifications(bool value) async {
    _transactionNotifications = value;
    await StorageService.save(storageKeyTxnNotifications, value.toString());
    notifyListeners();
  }

  Future<void> setBalanceReminderEnabled(bool value) async {
    _balanceReminderEnabled = value;
    await StorageService.save(storageKeyBalanceReminder, value.toString());
    notifyListeners();
  }

  Future<void> setBalanceReminderFrequency(String value) async {
    _balanceReminderFrequency = value;
    await StorageService.save(storageKeyBalanceReminderFrequency, value);
    notifyListeners();
  }
}
