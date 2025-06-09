import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_user_management_screen.dart';
import 'screens/admin_analytics_screen.dart';
import 'providers/sadhana_provider.dart';
import 'utils/app_theme.dart';
import 'utils/navigation_transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with a check for existing instances
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If it's a duplicate app error, get the existing instance
    if (e.toString().contains('duplicate-app')) {
      Firebase.app(); // Get existing instance
    } else {
      // Rethrow if it's a different error
      rethrow;
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => SadhanaProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rhythmbhara Tara Sadhana',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData, // Use the consistent theme
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Use iOS-style transitions for all routes
        switch (settings.name) {
          case '/':
            return CupertinoStylePageRoute(
              page: const SplashScreen(),
              settings: settings,
            );
          case '/login':
            return CupertinoStylePageRoute(
              page: const LoginScreen(),
              settings: settings,
            );
          case '/dashboard':
            return CupertinoStylePageRoute(
              page: const DashboardScreen(),
              settings: settings,
            );
          case '/admin':
            return CupertinoStylePageRoute(
              page: const AdminDashboardScreen(),
              settings: settings,
            );
          case '/admin/users':
            return CupertinoStylePageRoute(
              page: const AdminUserManagementScreen(),
              settings: settings,
            );
          case '/admin/analytics':
            return CupertinoStylePageRoute(
              page: const AdminAnalyticsScreen(),
              settings: settings,
            );
          default:
            return CupertinoStylePageRoute(
              page: const SplashScreen(),
              settings: settings,
            );
        }
      },
      // Fallback routes if onGenerateRoute doesn't handle
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/admin/users': (context) => const AdminUserManagementScreen(),
        '/admin/analytics': (context) => const AdminAnalyticsScreen(),
      },
    );
  }
}