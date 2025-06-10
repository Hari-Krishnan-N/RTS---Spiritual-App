import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/improved_notification_service.dart';
import '../utils/notification_utils.dart';

/// Advanced notification scheduler for managing automated notifications
/// Features:
/// - Schedule recurring notifications
/// - Smart timing based on user behavior
/// - Bulk scheduling for campaigns
/// - Conditional notifications based on user actions
class NotificationScheduler {
  static final NotificationScheduler _instance = NotificationScheduler._internal();
  factory NotificationScheduler() => _instance;
  NotificationScheduler._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImprovedNotificationService _notificationService = ImprovedNotificationService();

  final List<Timer> _activeTimers = [];
  bool _isInitialized = false;

  /// Initialize the notification scheduler
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadScheduledNotifications();
      await _startScheduler();
      _isInitialized = true;
      debugPrint('✅ Notification Scheduler initialized');
    } catch (e) {
      debugPrint('❌ Error initializing notification scheduler: $e');
    }
  }

  /// Load and start scheduled notifications
  Future<void> _loadScheduledNotifications() async {
    try {
      final scheduledQuery = await _firestore
          .collection('scheduled_notifications')
          .where('isActive', isEqualTo: true)
          .where('nextRun', isLessThanOrEqualTo: DateTime.now())
          .get();

      for (final doc in scheduledQuery.docs) {
        await _processScheduledNotification(doc.data(), doc.id);
      }
    } catch (e) {
      debugPrint('❌ Error loading scheduled notifications: $e');
    }
  }

  /// Start the main scheduler loop
  Future<void> _startScheduler() async {
    // Check for due notifications every minute
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkDueNotifications();
    });

    // Clean up old scheduled notifications daily
    Timer.periodic(const Duration(hours: 24), (timer) async {
      await _cleanupOldScheduledNotifications();
    });

    debugPrint('⏰ Notification scheduler started');
  }

  /// Check for notifications that are due to be sent
  Future<void> _checkDueNotifications() async {
    try {
      final now = DateTime.now();
      final dueQuery = await _firestore
          .collection('scheduled_notifications')
          .where('isActive', isEqualTo: true)
          .where('nextRun', isLessThanOrEqualTo: now)
          .get();

      for (final doc in dueQuery.docs) {
        await _processScheduledNotification(doc.data(), doc.id);
      }
    } catch (e) {
      debugPrint('❌ Error checking due notifications: $e');
    }
  }

  /// Process a scheduled notification
  Future<void> _processScheduledNotification(Map<String, dynamic> data, String docId) async {
    try {
      final type = data['type'] as String;
      final targetUsers = data['targetUsers'] as List<dynamic>?;
      final conditions = data['conditions'] as Map<String, dynamic>?;

      // Check conditions if any
      if (conditions != null && !await _checkConditions(conditions)) {
        debugPrint('⏭️ Skipping notification $docId - conditions not met');
        return;
      }

      // Send notification based on type
      switch (type) {
        case 'practice_reminder':
          await _sendPracticeReminder(data);
          break;
        case 'achievement_check':
          await _checkAndSendAchievements(data);
          break;
        case 'monthly_reminder':
          await _sendMonthlyReminders(data);
          break;
        case 'custom_broadcast':
          await _sendCustomBroadcast(data, targetUsers);
          break;
        default:
          debugPrint('❓ Unknown scheduled notification type: $type');
      }

      // Update next run time or mark as completed
      await _updateScheduledNotification(docId, data);

    } catch (e) {
      debugPrint('❌ Error processing scheduled notification $docId: $e');
    }
  }

  /// Send practice reminders to users who haven't practiced today
  Future<void> _sendPracticeReminder(Map<String, dynamic> data) async {
    try {
      final practiceType = data['practiceType'] as String;
      final users = await _getUsersNeedingPracticeReminder(practiceType);

      for (final userId in users) {
        await NotificationUtils.sendPracticeReminder(
          practiceType: practiceType,
          customMessage: data['message'] as String?,
        );
      }

      debugPrint('📿 Sent practice reminders to ${users.length} users for $practiceType');
    } catch (e) {
      debugPrint('❌ Error sending practice reminders: $e');
    }
  }

  /// Check for achievements and send notifications
  Future<void> _checkAndSendAchievements(Map<String, dynamic> data) async {
    try {
      final users = await _firestore.collection('users').get();
      
      for (final userDoc in users.docs) {
        final achievements = await _checkUserAchievements(userDoc.id);
        
        for (final achievement in achievements) {
          await NotificationUtils.sendAchievementNotification(
            practiceType: achievement['type'],
            streakCount: achievement['count'],
          );
        }
      }

      debugPrint('🏆 Checked achievements for ${users.docs.length} users');
    } catch (e) {
      debugPrint('❌ Error checking achievements: $e');
    }
  }

  /// Send monthly practice reminders
  Future<void> _sendMonthlyReminders(Map<String, dynamic> data) async {
    try {
      final users = await _getUsersNeedingMonthlyReminders();
      
      for (final user in users) {
        await NotificationUtils.sendMonthlyCompletionReminder(
          practiceType: user['practiceType'],
          monthYear: user['monthYear'],
          daysRemaining: user['daysRemaining'],
        );
      }

      debugPrint('📅 Sent monthly reminders to ${users.length} users');
    } catch (e) {
      debugPrint('❌ Error sending monthly reminders: $e');
    }
  }

  /// Send custom broadcast to specific users
  Future<void> _sendCustomBroadcast(Map<String, dynamic> data, List<dynamic>? targetUsers) async {
    try {
      final title = data['title'] as String;
      final message = data['message'] as String;
      final priority = data['priority'] as String? ?? 'normal';

      if (targetUsers != null && targetUsers.isNotEmpty) {
        // Send to specific users
        final results = await NotificationUtils.batchSendNotifications(
          userIds: targetUsers.cast<String>(),
          title: title,
          message: message,
          type: 'custom_broadcast',
          priority: priority == 'urgent' ? 3 : 1,
        );
        
        debugPrint('📢 Sent custom broadcast to ${results['success']} users');
      } else {
        // Send to all users
        await _notificationService.sendAdminNotificationToAllUsers(
          title: title,
          message: message,
          priority: priority,
        );
        
        debugPrint('📢 Sent custom broadcast to all users');
      }
    } catch (e) {
      debugPrint('❌ Error sending custom broadcast: $e');
    }
  }

  /// Schedule a notification
  Future<String?> scheduleNotification({
    required String type,
    required DateTime scheduledTime,
    required Map<String, dynamic> notificationData,
    bool recurring = false,
    Duration? recurringInterval,
    Map<String, dynamic>? conditions,
    List<String>? targetUsers,
  }) async {
    try {
      final scheduledDoc = {
        'type': type,
        'scheduledTime': scheduledTime,
        'nextRun': scheduledTime,
        'isActive': true,
        'recurring': recurring,
        'recurringInterval': recurringInterval?.inMilliseconds,
        'conditions': conditions,
        'targetUsers': targetUsers,
        'notificationData': notificationData,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.email,
        ...notificationData,
      };

      final docRef = await _firestore
          .collection('scheduled_notifications')
          .add(scheduledDoc);

      debugPrint('⏰ Scheduled notification: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
      return null;
    }
  }

  /// Schedule daily practice reminders for a user
  Future<void> scheduleDailyPracticeReminders({
    required String userId,
    required String practiceType,
    required TimeOfDay reminderTime,
    String? customMessage,
  }) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await scheduleNotification(
      type: 'practice_reminder',
      scheduledTime: scheduledTime,
      recurring: true,
      recurringInterval: const Duration(days: 1),
      notificationData: {
        'practiceType': practiceType,
        'message': customMessage,
        'userId': userId,
      },
      conditions: {
        'checkPracticeCompletion': true,
        'practiceType': practiceType,
      },
    );
  }

  /// Schedule achievement checks
  Future<void> scheduleAchievementChecks() async {
    // Schedule achievement checks to run daily at 10 PM
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 22, 0);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await scheduleNotification(
      type: 'achievement_check',
      scheduledTime: scheduledTime,
      recurring: true,
      recurringInterval: const Duration(days: 1),
      notificationData: {
        'checkAllUsers': true,
      },
    );
  }

  /// Schedule monthly reminders
  Future<void> scheduleMonthlyReminders() async {
    // Schedule monthly reminder checks to run daily at 9 AM
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 9, 0);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await scheduleNotification(
      type: 'monthly_reminder',
      scheduledTime: scheduledTime,
      recurring: true,
      recurringInterval: const Duration(days: 1),
      notificationData: {
        'checkMonthlyPractices': true,
      },
    );
  }

  /// Get users who need practice reminders
  Future<List<String>> _getUsersNeedingPracticeReminder(String practiceType) async {
    try {
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final users = await _firestore.collection('users').get();
      final usersNeedingReminder = <String>[];

      for (final userDoc in users.docs) {
        // Check if user has completed practice today
        final practiceDoc = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('daily_practices')
            .doc(todayString)
            .get();

        if (!practiceDoc.exists || !(practiceDoc.data()?[practiceType] as bool? ?? false)) {
          usersNeedingReminder.add(userDoc.id);
        }
      }

      return usersNeedingReminder;
    } catch (e) {
      debugPrint('❌ Error getting users needing practice reminder: $e');
      return [];
    }
  }

  /// Get users who need monthly reminders
  Future<List<Map<String, dynamic>>> _getUsersNeedingMonthlyReminders() async {
    try {
      final now = DateTime.now();
      final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysRemaining = daysInMonth - now.day;

      final users = await _firestore.collection('users').get();
      final usersNeedingReminder = <Map<String, dynamic>>[];

      for (final userDoc in users.docs) {
        // Check monthly practices
        final monthlyDoc = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('sadhana')
            .doc(currentMonth)
            .get();

        if (monthlyDoc.exists) {
          final data = monthlyDoc.data()!;
          
          // Check each monthly practice
          final practices = ['tharpanam', 'homam', 'dhanam'];
          for (final practice in practices) {
            final completed = data['${practice}Status'] as bool? ?? false;
            
            if (!completed && daysRemaining <= 5) {
              usersNeedingReminder.add({
                'userId': userDoc.id,
                'practiceType': practice,
                'monthYear': currentMonth,
                'daysRemaining': daysRemaining,
              });
            }
          }
        }
      }

      return usersNeedingReminder;
    } catch (e) {
      debugPrint('❌ Error getting users needing monthly reminders: $e');
      return [];
    }
  }

  /// Check user achievements
  Future<List<Map<String, dynamic>>> _checkUserAchievements(String userId) async {
    try {
      final achievements = <Map<String, dynamic>>[];
      
      // Check practice streaks
      final streaks = await _calculateUserStreaks(userId);
      
      for (final streak in streaks.entries) {
        final practiceType = streak.key;
        final streakCount = streak.value;
        
        // Check for milestone achievements (7, 30, 100 days)
        if ([7, 30, 100].contains(streakCount)) {
          achievements.add({
            'type': practiceType,
            'count': streakCount,
            'achievementType': 'streak',
          });
        }
      }

      return achievements;
    } catch (e) {
      debugPrint('❌ Error checking user achievements: $e');
      return [];
    }
  }

  /// Calculate user practice streaks
  Future<Map<String, int>> _calculateUserStreaks(String userId) async {
    try {
      final streaks = <String, int>{};
      final practices = ['tharpanam', 'homam', 'dhanam', 'jebam'];
      
      for (final practice in practices) {
        int currentStreak = 0;
        DateTime checkDate = DateTime.now();
        
        // Check backwards from today
        for (int i = 0; i < 365; i++) { // Check up to 1 year
          final dateString = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
          
          final practiceDoc = await _firestore
              .collection('users')
              .doc(userId)
              .collection('daily_practices')
              .doc(dateString)
              .get();

          if (practiceDoc.exists && (practiceDoc.data()?[practice] as bool? ?? false)) {
            currentStreak++;
          } else {
            break; // Streak broken
          }
          
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
        
        streaks[practice] = currentStreak;
      }
      
      return streaks;
    } catch (e) {
      debugPrint('❌ Error calculating user streaks: $e');
      return {};
    }
  }

  /// Check if conditions are met for a scheduled notification
  Future<bool> _checkConditions(Map<String, dynamic> conditions) async {
    try {
      if (conditions['checkPracticeCompletion'] == true) {
        final practiceType = conditions['practiceType'] as String;
        final userId = conditions['userId'] as String?;
        
        if (userId != null) {
          final today = DateTime.now();
          final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          
          final practiceDoc = await _firestore
              .collection('users')
              .doc(userId)
              .collection('daily_practices')
              .doc(todayString)
              .get();

          // Only send reminder if practice not completed
          return !practiceDoc.exists || !(practiceDoc.data()?[practiceType] as bool? ?? false);
        }
      }
      
      return true; // Default to true if no specific conditions
    } catch (e) {
      debugPrint('❌ Error checking conditions: $e');
      return false;
    }
  }

  /// Update scheduled notification after processing
  Future<void> _updateScheduledNotification(String docId, Map<String, dynamic> data) async {
    try {
      final isRecurring = data['recurring'] as bool? ?? false;
      
      if (isRecurring) {
        final intervalMs = data['recurringInterval'] as int?;
        if (intervalMs != null) {
          final nextRun = DateTime.now().add(Duration(milliseconds: intervalMs));
          
          await _firestore
              .collection('scheduled_notifications')
              .doc(docId)
              .update({
                'nextRun': nextRun,
                'lastRun': FieldValue.serverTimestamp(),
              });
        }
      } else {
        // Mark as completed for one-time notifications
        await _firestore
            .collection('scheduled_notifications')
            .doc(docId)
            .update({
              'isActive': false,
              'completedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      debugPrint('❌ Error updating scheduled notification: $e');
    }
  }

  /// Clean up old scheduled notifications
  Future<void> _cleanupOldScheduledNotifications() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      final oldNotifications = await _firestore
          .collection('scheduled_notifications')
          .where('isActive', isEqualTo: false)
          .where('completedAt', isLessThan: cutoffDate)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      debugPrint('🧹 Cleaned up ${oldNotifications.docs.length} old scheduled notifications');
    } catch (e) {
      debugPrint('❌ Error cleaning up old scheduled notifications: $e');
    }
  }

  /// Cancel a scheduled notification
  Future<bool> cancelScheduledNotification(String notificationId) async {
    try {
      await _firestore
          .collection('scheduled_notifications')
          .doc(notificationId)
          .update({
            'isActive': false,
            'cancelledAt': FieldValue.serverTimestamp(),
            'cancelledBy': _auth.currentUser?.email,
          });

      debugPrint('❌ Cancelled scheduled notification: $notificationId');
      return true;
    } catch (e) {
      debugPrint('❌ Error cancelling scheduled notification: $e');
      return false;
    }
  }

  /// Get all scheduled notifications
  Future<List<Map<String, dynamic>>> getScheduledNotifications({bool activeOnly = true}) async {
    try {
      Query query = _firestore.collection('scheduled_notifications');
      
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }
      
      final querySnapshot = await query.orderBy('nextRun').get();
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting scheduled notifications: $e');
      return [];
    }
  }

  /// Dispose of the scheduler
  void dispose() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    _isInitialized = false;
  }
}

/// Widget for managing scheduled notifications
class ScheduledNotificationManager extends StatefulWidget {
  const ScheduledNotificationManager({Key? key}) : super(key: key);

  @override
  State<ScheduledNotificationManager> createState() => _ScheduledNotificationManagerState();
}

class _ScheduledNotificationManagerState extends State<ScheduledNotificationManager> {
  final NotificationScheduler _scheduler = NotificationScheduler();
  List<Map<String, dynamic>> _scheduledNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledNotifications();
  }

  Future<void> _loadScheduledNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final notifications = await _scheduler.getScheduledNotifications();
      setState(() {
        _scheduledNotifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading scheduled notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled Notifications'),
        actions: [
          IconButton(
            onPressed: _loadScheduledNotifications,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scheduledNotifications.isEmpty
              ? const Center(
                  child: Text('No scheduled notifications'),
                )
              : ListView.builder(
                  itemCount: _scheduledNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = _scheduledNotifications[index];
                    return _buildScheduledNotificationCard(notification);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showScheduleDialog,
        child: const Icon(Icons.add_alarm),
      ),
    );
  }

  Widget _buildScheduledNotificationCard(Map<String, dynamic> notification) {
    final isActive = notification['isActive'] as bool? ?? false;
    final nextRun = notification['nextRun'] as Timestamp?;
    final type = notification['type'] as String? ?? 'unknown';
    final recurring = notification['recurring'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.all(8),
      color: isActive ? null : Colors.grey[100],
      child: ListTile(
        leading: Icon(
          _getTypeIcon(type),
          color: isActive ? Colors.blue : Colors.grey,
        ),
        title: Text(
          _formatNotificationType(type),
          style: TextStyle(
            color: isActive ? null : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Next run: ${_formatDateTime(nextRun)}'),
            if (recurring)
              const Text(
                'Recurring',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: isActive
            ? IconButton(
                onPressed: () => _cancelNotification(notification['id']),
                icon: const Icon(Icons.cancel, color: Colors.red),
              )
            : const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'practice_reminder':
        return Icons.self_improvement;
      case 'achievement_check':
        return Icons.emoji_events;
      case 'monthly_reminder':
        return Icons.calendar_month;
      case 'custom_broadcast':
        return Icons.campaign;
      default:
        return Icons.schedule;
    }
  }

  String _formatNotificationType(String type) {
    return type.replaceAll('_', ' ').split(' ').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _cancelNotification(String notificationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Notification'),
        content: const Text('Are you sure you want to cancel this scheduled notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _scheduler.cancelScheduledNotification(notificationId);
      if (success) {
        _loadScheduledNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification cancelled')),
          );
        }
      }
    }
  }

  void _showScheduleDialog() {
    // This would show a dialog to schedule new notifications
    // Implementation would include forms for different notification types
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Notification'),
        content: const Text('Notification scheduling UI would go here'),
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
