import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import both old and new notification providers for gradual migration
import 'providers/notification_provider.dart';
import 'providers/improved_notification_provider.dart';
import 'providers/sadhana_provider.dart';

// Import notification services
// Removed unused imports: notification_service.dart and improved_notification_service.dart
import 'services/notification_migration_service.dart';

// Import screens
import 'screens/improved_notification_screen.dart';
import 'screens/notification_admin_panel.dart';

// Import Firebase options
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const RhythmbaraApp());
}

class RhythmbaraApp extends StatelessWidget {
  const RhythmbaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Existing providers
        ChangeNotifierProvider(create: (_) => SadhanaProvider()),
        
        // Keep old provider for backward compatibility during transition
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        
        // Add new improved notification provider
        ChangeNotifierProvider(create: (_) => ImprovedNotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Rhythmbhara Tara Sadhana',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AppWrapper(),
        routes: {
          '/notifications': (context) => const ImprovedNotificationScreen(),
          '/admin/notifications': (context) => const NotificationAdminPanel(),
        },
      ),
    );
  }
}

/// Wrapper to handle authentication and notification initialization
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isInitialized = false;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for authentication state to be determined
      await FirebaseAuth.instance.authStateChanges().first;
      
      // Initialize notification systems based on user authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _initializeNotificationSystems();
      }
      
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() {
        _isInitialized = true;
        _initializationError = e.toString();
      });
    }
  }

  Future<void> _initializeNotificationSystems() async {
    try {
      final improvedProvider = context.read<ImprovedNotificationProvider>();
      final oldProvider = context.read<NotificationProvider>();
      
      // Initialize improved notification system first
      await improvedProvider.initialize();
      
      // Check if migration is needed and inform user
      final migrationService = NotificationMigrationService();
      final needsMigration = await migrationService.isMigrationNeeded();
      
      if (needsMigration) {
        debugPrint('🔄 Notification migration needed - will be performed automatically');
        
        // Show migration progress if needed
        if (mounted) {
          _showMigrationProgress();
        }
      }
      
      // Initialize old provider for backward compatibility
      await oldProvider.initialize();
      
      debugPrint('✅ Notification systems initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notification systems: $e');
    }
  }

  void _showMigrationProgress() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const MigrationProgressDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing app...'),
            ],
          ),
        ),
      );
    }

    if (_initializationError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Initialization Error'),
              const SizedBox(height: 8),
              Text(_initializationError!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitialized = false;
                    _initializationError = null;
                  });
                  _initializeApp();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Return your main app screen here
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // User is logged in - show main app with notification support
          return const MainAppScreen();
        } else {
          // User is not logged in - show login screen
          return const LoginScreen();
        }
      },
    );
  }
}

/// Dialog to show migration progress
class MigrationProgressDialog extends StatefulWidget {
  const MigrationProgressDialog({super.key});

  @override
  State<MigrationProgressDialog> createState() => _MigrationProgressDialogState();
}

class _MigrationProgressDialogState extends State<MigrationProgressDialog> {
  bool _migrationCompleted = false;

  @override
  void initState() {
    super.initState();
    _performMigration();
  }

  Future<void> _performMigration() async {
    try {
      final migrationService = NotificationMigrationService();
      await migrationService.performMigration();
      
      setState(() => _migrationCompleted = true);
      
      // Close dialog after a brief delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _migrationCompleted = true);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_migrationCompleted) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Updating notification system...'),
          ] else ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text('Notification system updated successfully!'),
          ],
        ],
      ),
    );
  }
}

/// Example main app screen with notification integration
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rhythmbhara Tara Sadhana'),
        actions: [
          // Notification icon with badge
          Consumer<ImprovedNotificationProvider>(
            builder: (context, provider, child) {
              final unreadCount = provider.totalUnreadCount;
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          
          // Admin panel access (for admins only)
          Consumer<ImprovedNotificationProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'admin':
                      Navigator.pushNamed(context, '/admin/notifications');
                      break;
                    case 'test':
                      _sendTestNotification();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'admin',
                    child: ListTile(
                      leading: Icon(Icons.admin_panel_settings),
                      title: Text('Admin Panel'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'test',
                    child: ListTile(
                      leading: Icon(Icons.bug_report),
                      title: Text('Test Notification'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Your existing app screens
          const Center(child: Text('Home Screen')),
          const Center(child: Text('Practice Screen')),
          const Center(child: Text('Progress Screen')),
          const Center(child: Text('Profile Screen')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            label: 'Practice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      final provider = context.read<ImprovedNotificationProvider>();
      await provider.sendNotification(
        title: '🧪 Test Notification',
        message: 'This is a test notification to verify the system is working correctly.',
        type: 'test',
        metadata: {
          'testType': 'manual',
          'sentAt': DateTime.now().toIso8601String(),
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending test notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Placeholder login screen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.self_improvement, size: 100, color: Colors.orange),
            SizedBox(height: 24),
            Text(
              'Rhythmbhara Tara Sadhana',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Please log in to continue'),
            SizedBox(height: 32),
            // Add your login UI here
            Text('Login UI goes here'),
          ],
        ),
      ),
    );
  }
}
