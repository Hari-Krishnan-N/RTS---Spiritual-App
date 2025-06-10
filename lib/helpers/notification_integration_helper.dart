import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/improved_notification_provider.dart';
import '../providers/notification_provider.dart';
import '../services/notification_scheduler.dart';
import '../widgets/notification_widgets.dart';

/// Helper class to integrate notification system into existing app
/// Provides easy-to-use methods for common notification operations
class NotificationIntegrationHelper {
  static final NotificationIntegrationHelper _instance = NotificationIntegrationHelper._internal();
  factory NotificationIntegrationHelper() => _instance;
  NotificationIntegrationHelper._internal();

  static bool _isInitialized = false;

  /// Initialize the notification system in your app
  /// Call this in your main.dart or app initialization
  static Future<void> initializeNotificationSystem(BuildContext context) async {
    if (_isInitialized) return;

    try {
      // Initialize providers
      final improvedProvider = context.read<ImprovedNotificationProvider>();
      final legacyProvider = context.read<NotificationProvider>();
      final scheduler = NotificationScheduler();

      // Initialize services
      await Future.wait([
        improvedProvider.initialize(),
        legacyProvider.initialize(),
        scheduler.initialize(),
      ]);

      // Setup default scheduled notifications
      await _setupDefaultScheduledNotifications(scheduler);

      _isInitialized = true;
      debugPrint('✅ Notification system fully initialized');
    } catch (e) {
      debugPrint('❌ Error initializing notification system: $e');
      rethrow;
    }
  }

  /// Setup default scheduled notifications (call once per app lifecycle)
  static Future<void> _setupDefaultScheduledNotifications(NotificationScheduler scheduler) async {
    try {
      // Schedule daily achievement checks
      await scheduler.scheduleAchievementChecks();
      
      // Schedule monthly reminder checks
      await scheduler.scheduleMonthlyReminders();
      
      debugPrint('✅ Default scheduled notifications setup');
    } catch (e) {
      debugPrint('❌ Error setting up default scheduled notifications: $e');
    }
  }

  /// Add notification badge to any widget
  static Widget addNotificationBadge({
    required Widget child,
    VoidCallback? onTap,
    Color? badgeColor,
    bool showGlow = true,
  }) {
    return NotificationBadge(
      badgeColor: badgeColor,
      showGlow: showGlow,
      onTap: onTap,
      child: child,
    );
  }

  /// Create a notification icon button with badge
  static Widget createNotificationIconButton({
    VoidCallback? onPressed,
    Color? iconColor,
    Color? badgeColor,
    double? iconSize,
  }) {
    return NotificationBadge(
      badgeColor: badgeColor ?? Colors.red,
      showGlow: true,
      child: IconButton(
        onPressed: onPressed ?? () {
          // Default navigation to notifications screen
        },
        icon: Icon(
          Icons.notifications,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }

  /// Send achievement notification when user completes a practice
  static Future<void> sendAchievementNotification({
    required BuildContext context,
    required String practiceType,
    required int streakCount,
  }) async {
    try {
      // Send via both providers for compatibility
      final improvedProvider = context.read<ImprovedNotificationProvider>();
      final legacyProvider = context.read<NotificationProvider>();

      await Future.wait([
        improvedProvider.sendNotification(
          title: '🎉 Achievement Unlocked!',
          message: 'Congratulations! You\'ve completed $practiceType for $streakCount days in a row!',
          type: 'achievement',
          metadata: {
            'practiceType': practiceType,
            'streakCount': streakCount,
          },
        ),
        legacyProvider.sendAchievementNotification(
          achievementType: practiceType,
          achievementName: practiceType,
          streakCount: streakCount,
        ),
      ]);

      debugPrint('✅ Achievement notification sent for $practiceType (streak: $streakCount)');
    } catch (e) {
      debugPrint('❌ Error sending achievement notification: $e');
    }
  }

  /// Send practice reminder notification
  static Future<void> sendPracticeReminder({
    required BuildContext context,
    required String practiceType,
    String? customMessage,
    bool isUrgent = false,
  }) async {
    try {
      final improvedProvider = context.read<ImprovedNotificationProvider>();
      final legacyProvider = context.read<NotificationProvider>();

      final title = isUrgent ? '⚠️ Practice Reminder' : '🕉️ Time for Practice';
      final message = customMessage ?? 'Time for your $practiceType practice';

      await Future.wait([
        improvedProvider.sendNotification(
          title: title,
          message: message,
          type: 'practice_reminder',
          priority: isUrgent ? 3 : 1,
          metadata: {
            'practiceType': practiceType,
            'isUrgent': isUrgent,
          },
        ),
        legacyProvider.sendPracticeReminder(
          practiceType: practiceType,
          reminderMessage: message,
          isUrgent: isUrgent,
        ),
      ]);

      debugPrint('✅ Practice reminder sent for $practiceType');
    } catch (e) {
      debugPrint('❌ Error sending practice reminder: $e');
    }
  }

  /// Check if user has completed practice today (for conditional notifications)
  static Future<bool> hasCompletedPracticeToday(String practiceType) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      // Note: Future implementation would check practice completion for today
      
      // This would check your existing practice completion data structure
      // Adjust according to your actual database structure
      
      return false; // Placeholder - implement based on your data structure
    } catch (e) {
      debugPrint('❌ Error checking practice completion: $e');
      return false;
    }
  }

  /// Schedule personalized practice reminders for a user
  static Future<void> setupPersonalizedReminders({
    required String userId,
    required Map<String, TimeOfDay> practiceSchedule, // practiceType -> preferred time
  }) async {
    try {
      final scheduler = NotificationScheduler();

      for (final entry in practiceSchedule.entries) {
        await scheduler.scheduleDailyPracticeReminders(
          userId: userId,
          practiceType: entry.key,
          reminderTime: entry.value,
        );
      }

      debugPrint('✅ Personalized reminders setup for user $userId');
    } catch (e) {
      debugPrint('❌ Error setting up personalized reminders: $e');
    }
  }

  /// Get notification summary widget for dashboard
  static Widget getNotificationSummaryWidget({
    EdgeInsets? padding,
    Color? backgroundColor,
  }) {
    return NotificationSummaryCard(
      padding: padding,
      backgroundColor: backgroundColor,
    );
  }

  /// Get quick actions widget
  static Widget getQuickActionsWidget() {
    return const NotificationQuickActions();
  }

  /// Show notification details dialog
  static void showNotificationDetails({
    required BuildContext context,
    required Map<String, dynamic> notification,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title'] ?? 'Notification'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification['message'] ?? ''),
              const SizedBox(height: 16),
              if (notification['metadata'] != null) ...[
                const Text(
                  'Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...((notification['metadata'] as Map<String, dynamic>).entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead({
    required BuildContext context,
    required String notificationId,
    bool isAdminNotification = false,
  }) async {
    try {
      final improvedProvider = context.read<ImprovedNotificationProvider>();
      final legacyProvider = context.read<NotificationProvider>();

      await Future.wait([
        improvedProvider.markAsRead(notificationId, isAdminNotification: isAdminNotification),
        legacyProvider.markAsRead(notificationId, isAdminNotification),
      ]);
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllNotificationsAsRead(BuildContext context) async {
    try {
      final improvedProvider = context.read<ImprovedNotificationProvider>();
      final legacyProvider = context.read<NotificationProvider>();

      await Future.wait([
        improvedProvider.markAllAsRead(),
        legacyProvider.markAllAsRead(),
      ]);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  /// Get unread notifications count
  static int getUnreadCount(BuildContext context) {
    try {
      final improvedProvider = context.watch<ImprovedNotificationProvider>();
      return improvedProvider.totalUnreadCount;
    } catch (e) {
      // Fallback to legacy provider
      try {
        final legacyProvider = context.watch<NotificationProvider>();
        return legacyProvider.unreadCount;
      } catch (e2) {
        debugPrint('❌ Error getting unread count: $e2');
        return 0;
      }
    }
  }

  /// Check if there are new notifications (for glow effect)
  static Future<bool> hasNewNotifications(BuildContext context) async {
    try {
      final improvedProvider = context.read<ImprovedNotificationProvider>();
      return await improvedProvider.hasNewNotifications();
    } catch (e) {
      try {
        final legacyProvider = context.read<NotificationProvider>();
        return legacyProvider.hasNewNotifications;
      } catch (e2) {
        debugPrint('❌ Error checking new notifications: $e2');
        return false;
      }
    }
  }

  /// Handle notification screen opened (remove glow effect)
  static Future<void> onNotificationScreenOpened(BuildContext context) async {
    try {
      final improvedProvider = context.read<ImprovedNotificationProvider>();
      final legacyProvider = context.read<NotificationProvider>();

      await Future.wait([
        improvedProvider.updateLastCheck(),
        legacyProvider.onNotificationScreenOpened(),
      ]);
    } catch (e) {
      debugPrint('❌ Error handling notification screen opened: $e');
    }
  }

  /// Create floating action button with notification badge
  static Widget createNotificationFAB({
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return NotificationFAB(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }

  /// Create notification list item
  static Widget createNotificationListItem({
    required Map<String, dynamic> notification,
    VoidCallback? onTap,
    VoidCallback? onMarkAsRead,
    bool showActions = true,
  }) {
    return NotificationListItem(
      notification: notification,
      onTap: onTap,
      onMarkAsRead: onMarkAsRead,
      showActions: showActions,
    );
  }

  /// Refresh notifications
  static Future<void> refreshNotifications(BuildContext context) async {
    try {
      final improvedProvider = context.read<ImprovedNotificationProvider>();
      final legacyProvider = context.read<NotificationProvider>();

      await Future.wait([
        improvedProvider.refresh(),
        legacyProvider.refresh(),
      ]);
    } catch (e) {
      debugPrint('❌ Error refreshing notifications: $e');
    }
  }

  /// Check system health
  static Future<Map<String, dynamic>> checkSystemHealth() async {
    try {
      // This would integrate with your health checking utilities
      return {
        'status': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error checking system health: $e');
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Show notification settings dialog
  static void showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Notification settings would go here'),
            Text('- Enable/disable types'),
            Text('- Set reminder times'),
            Text('- Configure preferences'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Widget that wraps your app with notification functionality
class NotificationWrapper extends StatefulWidget {
  final Widget child;
  final bool enableAutomaticMigration;
  final bool showMigrationProgress;

  const NotificationWrapper({
    super.key,
    required this.child,
    this.enableAutomaticMigration = true,
    this.showMigrationProgress = true,
  });

  @override
  State<NotificationWrapper> createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<NotificationWrapper> {
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationIntegrationHelper.initializeNotificationSystem(context);
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Notification System Error'),
              const SizedBox(height: 8),
              Text(_errorMessage ?? 'Unknown error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = null;
                  });
                  _initializeNotifications();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing notification system...'),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}

/// Extension methods for easy notification integration
extension NotificationExtensions on BuildContext {
  /// Send achievement notification
  Future<void> sendAchievement(String practiceType, int streakCount) async {
    await NotificationIntegrationHelper.sendAchievementNotification(
      context: this,
      practiceType: practiceType,
      streakCount: streakCount,
    );
  }

  /// Send practice reminder
  Future<void> sendPracticeReminder(String practiceType, {bool isUrgent = false}) async {
    await NotificationIntegrationHelper.sendPracticeReminder(
      context: this,
      practiceType: practiceType,
      isUrgent: isUrgent,
    );
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId, {bool isAdmin = false}) async {
    await NotificationIntegrationHelper.markNotificationAsRead(
      context: this,
      notificationId: notificationId,
      isAdminNotification: isAdmin,
    );
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsRead() async {
    await NotificationIntegrationHelper.markAllNotificationsAsRead(this);
  }

  /// Get unread notifications count
  int get unreadNotificationsCount => NotificationIntegrationHelper.getUnreadCount(this);

  /// Check if there are new notifications
  Future<bool> get hasNewNotifications => NotificationIntegrationHelper.hasNewNotifications(this);

  /// Handle notification screen opened
  Future<void> onNotificationScreenOpened() async {
    await NotificationIntegrationHelper.onNotificationScreenOpened(this);
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    await NotificationIntegrationHelper.refreshNotifications(this);
  }
}
