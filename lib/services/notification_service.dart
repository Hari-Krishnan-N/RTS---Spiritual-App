import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // FIXED: Better initialization
  Future<void> initialize() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      await _requestPermissions();
      await _setupNotificationChannels();
      await _cleanOldNotifications();
      
      debugPrint('✅ Notification Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }

  // Setup notification channels for better organization
  Future<void> _setupNotificationChannels() async {
    const AndroidNotificationChannel practiceChannel = AndroidNotificationChannel(
      'practice_reminders',
      'Practice Reminders',
      description: 'Notifications for spiritual practice reminders',
      importance: Importance.high,
    );

    const AndroidNotificationChannel adminChannel = AndroidNotificationChannel(
      'admin_notifications',
      'Admin Announcements',
      description: 'Important announcements from administrators',
      importance: Importance.max,
    );

    const AndroidNotificationChannel achievementChannel = AndroidNotificationChannel(
      'achievements',
      'Achievement Celebrations',
      description: 'Notifications for completed goals and milestones',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(practiceChannel);
    
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(adminChannel);
        
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(achievementChannel);
  }

  Future<void> _requestPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    // TODO: Add navigation logic based on notification type
  }

  // FIXED: Clean old notifications - keep only last 10 per user
  Future<void> _cleanOldNotifications() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get all user notifications ordered by creation time (newest first)
      final userNotificationsQuery = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      // Keep only the last 10, delete the rest
      final batch = _firestore.batch();
      for (int i = 10; i < userNotificationsQuery.docs.length; i++) {
        batch.delete(userNotificationsQuery.docs[i].reference);
      }

      // For admin notifications, keep only last 10 globally
      final adminNotificationsQuery = await _firestore
          .collection('admin_notifications')
          .orderBy('sentAt', descending: true)
          .get();

      for (int i = 10; i < adminNotificationsQuery.docs.length; i++) {
        batch.delete(adminNotificationsQuery.docs[i].reference);
      }

      await batch.commit();
      
      final userDeleted = userNotificationsQuery.docs.length > 10 ? userNotificationsQuery.docs.length - 10 : 0;
      final adminDeleted = adminNotificationsQuery.docs.length > 10 ? adminNotificationsQuery.docs.length - 10 : 0;
      
      if (userDeleted > 0 || adminDeleted > 0) {
        debugPrint('🧹 Cleaned $userDeleted user + $adminDeleted admin old notifications (keeping last 10 each)');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning old notifications: $e');
    }
  }

  // ENHANCED: Save notification with proper user data structure
  Future<String?> saveNotificationToFirestore({
    required String title,
    required String message,
    required String type,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUserId = userId ?? _auth.currentUser?.uid;
      if (currentUserId == null) {
        debugPrint('❌ No user ID available for notification');
        return null;
      }

      // First, clean old notifications to maintain limit of 10
      await _cleanOldNotifications();

      final notificationData = {
        'title': title,
        'message': message,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'userId': currentUserId,
        'metadata': metadata ?? {},
        'priority': _getPriorityForType(type),
        // Store user email for better tracking
        'userEmail': _auth.currentUser?.email,
        // Add device info for better debugging
        'deviceInfo': {
          'platform': 'mobile',
          'createdBy': 'app',
        },
      };

      final docRef = await _firestore.collection('notifications').add(notificationData);
      debugPrint('✅ Notification saved with ID: ${docRef.id} for user: $currentUserId');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error saving notification: $e');
      return null;
    }
  }

  int _getPriorityForType(String type) {
    switch (type) {
      case 'admin':
      case 'system':
        return 3; // High priority
      case 'achievement':
      case 'milestone':
        return 2; // Medium priority
      case 'practice_reminder':
      case 'monthly_reminder':
        return 1; // Normal priority
      default:
        return 0; // Low priority
    }
  }

  // FIXED: Get user notifications - only last 10 messages
  Future<List<Map<String, dynamic>>> getUserNotifications({int limit = 10}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final notifications = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          // Ensure isRead is always a boolean
          'isRead': data['isRead'] as bool? ?? false,
        };
      }).toList();

      debugPrint('📱 Loaded ${notifications.length} user notifications (last $limit)');
      return notifications;
    } catch (e) {
      debugPrint('❌ Error getting user notifications: $e');
      return [];
    }
  }

  // FIXED: Get admin notifications - only last 10 messages
  Future<List<Map<String, dynamic>>> getAdminNotifications({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('admin_notifications')
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .get();

      final prefs = await SharedPreferences.getInstance();
      final userId = _auth.currentUser?.uid ?? '';

      final notifications = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final notificationId = doc.id;
        
        // Check if this admin notification has been read by current user
        final isRead = prefs.getBool('admin_notification_${userId}_$notificationId') ?? false;
        
        return {
          'id': notificationId,
          ...data,
          'isRead': isRead,
          'isAdminNotification': true,
        };
      }).toList();

      debugPrint('📢 Loaded ${notifications.length} admin notifications (last $limit)');
      return notifications;
    } catch (e) {
      debugPrint('❌ Error getting admin notifications: $e');
      return [];
    }
  }

  // FIXED: Properly mark notification as read in Firestore
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Marked notification $notificationId as read');
      return true;
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      return false;
    }
  }

  // FIXED: Mark admin notification as read with proper user tracking
  Future<bool> markAdminNotificationAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _auth.currentUser?.uid ?? '';
      
      await prefs.setBool('admin_notification_${userId}_$notificationId', true);
      await prefs.setInt('admin_notification_read_time_${userId}_$notificationId', 
          DateTime.now().millisecondsSinceEpoch);

      debugPrint('✅ Marked admin notification $notificationId as read for user $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error marking admin notification as read: $e');
      return false;
    }
  }

  // FIXED: Accurate unread count calculation for last 10 notifications
  Future<int> getUnreadNotificationsCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      // Count unread user notifications (last 10 only)
      final userNotifications = await getUserNotifications();
      final userUnreadCount = userNotifications
          .where((n) => !(n['isRead'] as bool? ?? true))
          .length;

      // Count unread admin notifications (last 10 only)
      final adminNotifications = await getAdminNotifications();
      final adminUnreadCount = adminNotifications
          .where((n) => !(n['isRead'] as bool? ?? true))
          .length;

      final totalUnread = userUnreadCount + adminUnreadCount;
      debugPrint('📊 Unread count: $userUnreadCount user + $adminUnreadCount admin = $totalUnread total (from last 10 each)');
      
      return totalUnread;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }

  // FIXED: Better new notifications detection
  Future<bool> hasNewNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _auth.currentUser?.uid ?? '';
      final lastCheckTime = prefs.getInt('last_notification_check_$userId') ?? 0;

      if (userId.isEmpty) return false;

      // Check for new user notifications
      final newUserNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(lastCheckTime))
          .limit(1)
          .get();

      // Check for new admin notifications
      final newAdminNotifications = await _firestore
          .collection('admin_notifications')
          .where('sentAt', isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(lastCheckTime))
          .limit(1)
          .get();

      final hasNew = newUserNotifications.docs.isNotEmpty || newAdminNotifications.docs.isNotEmpty;
      debugPrint('🔔 Has new notifications: $hasNew');
      
      return hasNew;
    } catch (e) {
      debugPrint('❌ Error checking for new notifications: $e');
      return false;
    }
  }

  // FIXED: Update last check time per user
  Future<void> updateLastNotificationCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _auth.currentUser?.uid ?? '';
      if (userId.isNotEmpty) {
        await prefs.setInt('last_notification_check_$userId', DateTime.now().millisecondsSinceEpoch);
        debugPrint('✅ Updated last notification check time for user $userId');
      }
    } catch (e) {
      debugPrint('❌ Error updating last notification check: $e');
    }
  }

  // ENHANCED: Send practice achievement notification
  Future<void> sendAchievementNotification({
    required String achievementType,
    required String achievementName,
    required int streakCount,
  }) async {
    final title = '🎉 Achievement Unlocked!';
    final message = streakCount > 1 
        ? 'Congratulations! You\'ve completed $achievementName for $streakCount days in a row!'
        : 'Great job completing your $achievementName practice!';

    await saveNotificationToFirestore(
      title: title,
      message: message,
      type: 'achievement',
      metadata: {
        'achievementType': achievementType,
        'streakCount': streakCount,
        'achievedAt': DateTime.now().toIso8601String(),
      },
    );

    // Show local notification
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: message,
      payload: 'achievement_$achievementType',
      channelId: 'achievements',
      channelName: 'Achievement Celebrations',
    );
  }

  // ENHANCED: Send practice reminder with smart timing
  Future<void> sendPracticeReminder({
    required String practiceType,
    required String reminderMessage,
    bool isUrgent = false,
  }) async {
    final title = isUrgent ? '⚠️ Practice Reminder' : '🕉️ Time for Practice';
    
    await saveNotificationToFirestore(
      title: title,
      message: reminderMessage,
      type: 'practice_reminder',
      metadata: {
        'practiceType': practiceType,
        'isUrgent': isUrgent,
        'scheduledAt': DateTime.now().toIso8601String(),
      },
    );

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: reminderMessage,
      payload: 'practice_$practiceType',
      channelId: 'practice_reminders',
      channelName: 'Practice Reminders',
    );
  }

  // ENHANCED: Send admin notification to all users
  Future<bool> sendAdminNotificationToAllUsers({
    required String title,
    required String message,
    String priority = 'normal',
  }) async {
    try {
      // Save to admin_notifications collection
      await _firestore.collection('admin_notifications').add({
        'title': title,
        'message': message,
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': _auth.currentUser?.email ?? 'Unknown',
        'type': 'admin_broadcast',
        'priority': priority,
      });

      // Get all users and send individual notifications
      final usersSnapshot = await _firestore.collection('users').get();
      
      final batch = _firestore.batch();
      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'title': title,
          'message': message,
          'type': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'userId': userDoc.id,
          'fromAdmin': true,
          'adminEmail': _auth.currentUser?.email,
          'priority': priority == 'urgent' ? 3 : 2,
        });
      }

      await batch.commit();

      // Send local notification to current user
      await showNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: title,
        body: message,
        payload: 'admin_notification',
        channelId: 'admin_notifications',
        channelName: 'Admin Announcements',
      );

      debugPrint('📢 Admin notification sent to ${usersSnapshot.docs.length} users');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending admin notification: $e');
      return false;
    }
  }

  // ENHANCED: Show notification with better configuration
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'general_notifications',
    String channelName = 'General Notifications',
  }) async {
    try {
      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Notifications for spiritual practice app',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: channelId,
          threadIdentifier: channelId,
          sound: 'default',
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      debugPrint('📱 Local notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  // ENHANCED: Generate smart monthly reminders
  Future<void> generateMonthlyReminderNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
      
      final monthData = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sadhana')
          .doc(currentMonth)
          .get();

      final practices = ['Tharpanam', 'Homam', 'Dhanam'];
      final statusFields = ['tharpanamStatus', 'homamStatus', 'dhaanamStatus'];
      
      for (int i = 0; i < practices.length; i++) {
        final practice = practices[i];
        final statusField = statusFields[i];
        
        bool isCompleted = false;
        if (monthData.exists) {
          final data = monthData.data() as Map<String, dynamic>;
          isCompleted = data[statusField] as bool? ?? false;
        }

        if (!isCompleted) {
          final daysRemaining = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day - DateTime.now().day;
          final urgencyMessage = daysRemaining <= 5 
              ? 'Only $daysRemaining days left this month!'
              : 'Complete your monthly practice when convenient.';

          await saveNotificationToFirestore(
            title: '$practice Reminder',
            message: 'Don\'t forget to complete your monthly $practice practice for $currentMonth. $urgencyMessage',
            type: 'monthly_reminder',
            metadata: {
              'practice': practice.toLowerCase(),
              'month': currentMonth,
              'daysRemaining': daysRemaining,
              'isUrgent': daysRemaining <= 5,
            },
          );
        }
      }

      debugPrint('📅 Monthly reminder notifications generated');
    } catch (e) {
      debugPrint('❌ Error generating monthly reminders: $e');
    }
  }

  // Check if admin notification is read
  Future<bool> isAdminNotificationRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _auth.currentUser?.uid ?? '';
      return prefs.getBool('admin_notification_${userId}_$notificationId') ?? false;
    } catch (e) {
      debugPrint('❌ Error checking admin notification read status: $e');
      return false;
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // MISSING METHOD: Update monthly reminder status - called by sadhana_provider
  Future<void> updateMonthlyReminderStatus() async {
    // This method is called when user completes a monthly practice
    // It should reschedule or cancel relevant reminders
    await generateMonthlyReminderNotifications();
    debugPrint('✅ Monthly reminder status updated');
  }

  // Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return pendingNotifications.length;
  }
}
