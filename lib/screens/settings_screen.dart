import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../widgets/app_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _passwordController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _showChangePinDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();

    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change PIN'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'New 4-digit PIN',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New PIN',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'PIN is used only for transaction verification.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Update PIN'),
            ),
          ],
        );
      },
    );

    if (changed != true) {
      return;
    }

    final password = _passwordController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    _passwordController.clear();
    _newPinController.clear();
    _confirmPinController.clear();

    if (password.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Password is required')),
      );
      return;
    }

    final validPassword = await AuthService.verifyStoredPassword(password);
    if (!validPassword) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Invalid password')));
      return;
    }

    if (!AuthService.isValidPin(newPin)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('PIN must be exactly 4 digits')),
      );
      return;
    }

    if (newPin != confirmPin) {
      messenger.showSnackBar(
        const SnackBar(content: Text('PINs do not match')),
      );
      return;
    }

    await AuthService.savePinHash(newPin);

    final user = userProvider.currentUser;
    final authUser = authProvider.currentUser;
    final passwordHash = await AuthService.getPasswordHash();
    if (user != null && authUser != null && passwordHash != null) {
      try {
        await FirebaseService.upsertAuthUser(
          userId: user.userId,
          name: user.name,
          email: user.email,
          passwordHash: passwordHash,
          pinHash: AuthService.hashPin(newPin),
          photoUrl: user.photoUrl,
          createdAt: authUser.createdAt,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('PIN changed successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, _) {
        return Scaffold(
          appBar: AppBar(
            leading: const Padding(
              padding: EdgeInsets.all(4),
              child: AppLogo(size: 40),
            ),
            title: const Text('Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Appearance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Card(
                child: SwitchListTile(
                  value: settings.isDarkMode,
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme across the app'),
                  secondary: const Icon(Icons.dark_mode_rounded),
                  onChanged: settings.setDarkMode,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: settings.transactionNotifications,
                      title: const Text('Transaction Alerts'),
                      subtitle: const Text(
                        'Notify when someone adds a transaction including you',
                      ),
                      secondary: const Icon(Icons.notifications_active_rounded),
                      onChanged: settings.setTransactionNotifications,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: settings.balanceReminderEnabled,
                      title: const Text('Balance Reminders'),
                      subtitle: const Text('Notify about your current balance'),
                      secondary: const Icon(
                        Icons.account_balance_wallet_rounded,
                      ),
                      onChanged: settings.setBalanceReminderEnabled,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded),
                      title: const Text('Reminder Frequency'),
                      subtitle: Text(
                        settings.balanceReminderEnabled
                            ? settings.balanceReminderFrequency
                            : 'Enable Balance Reminders to choose frequency',
                      ),
                      trailing: DropdownButton<String>(
                        value: settings.balanceReminderFrequency,
                        onChanged: settings.balanceReminderEnabled
                            ? (value) {
                                if (value != null) {
                                  settings.setBalanceReminderFrequency(value);
                                }
                              }
                            : null,
                        items: const [
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text('Daily'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('Weekly'),
                          ),
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('Monthly'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Security',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock_reset_rounded),
                  title: const Text('Change PIN'),
                  subtitle: const Text('Requires your password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showChangePinDialog,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
