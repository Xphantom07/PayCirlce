import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/firebase_config.dart';
import 'constants/app_constants.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_signup_screen.dart';
import 'screens/user_setup_screen.dart';
import 'screens/join_group_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/random_payer_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/group_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/balance_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Firebase and wait for it
  await FirebaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider()..loadUserFromStorage(),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider()..loadFromStorage(),
        ),
        ChangeNotifierProvider<GroupProvider>(
          create: (_) => GroupProvider()..loadStoredGroup(),
        ),
        ChangeNotifierProvider<TransactionProvider>(
          create: (_) => TransactionProvider(),
        ),
        ChangeNotifierProvider<BalanceProvider>(
          create: (_) => BalanceProvider(),
        ),
        ChangeNotifierProvider<AppSettingsProvider>(
          create: (_) => AppSettingsProvider()..loadSettings(),
        ),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          initialRoute: routeSplash,
          routes: {
            routeSplash: (_) => const SplashScreen(),
            routeLoginSignup: (_) => const LoginSignupScreen(),
            routeUserSetup: (_) => const UserSetupScreen(),
            routeJoinGroup: (_) => const JoinGroupScreen(),
            routeDashboard: (_) => const DashboardScreen(),
            routeAddExpense: (_) => const AddExpenseScreen(),
            routeRandomPayer: (_) => const RandomPayerScreen(),
            routeTransactionHistory: (_) => const TransactionHistoryScreen(),
            routeProfile: (_) => const ProfileScreen(),
            routeSettings: (_) => const SettingsScreen(),
          },
        ),
      ),
    );
  }
}
