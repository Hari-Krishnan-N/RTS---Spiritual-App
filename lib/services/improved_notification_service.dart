import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Removed unused import: intl.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced Notification Service with proper user-specific database organization
/// Features:
/// - Maintains only last 10 notifications per user
/// - Proper read/unread status management
/// - Efficient database structure with proper indexing
/// - Better performance with optimized queries
class ImprovedNotificationService {
  static final ImprovedNotificationService _instance = ImprovedNotificationService._internal();
  factory ImprovedNotificationService() => _instance;
  ImprovedNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Constants for better maintainability
  static const int _maxNotificationsPerUser = 10;
  static const String _userNotificationsCollection = 'user_notifications';
  static const String _adminNotificationsCollection = 'admin_notifications';
  static const String _notificationMetadataCollection = 'notification_metadata';

  /// Initialize the notification service with proper setup
  Future<void> initialize() async {
    try {
      await _initializeLocalNotifications();
      await _setupNotificationChannels();
      await _setupFirebaseStructure();
      await _performMaintenanceTasks();
      
      debugPrint('✅ Enhanced Notification Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
      rethrow;
    }
  }

  /// Initialize local notifications with proper configuration
  Future<void> _initializeLocalNotifications() async {
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
  }

  /// Setup notification channels for better organization
  Future<void> _setupNotificationChannels() async {
    final channels = [
      const AndroidNotificationChannel(
        'practice_reminders',
        'Practice Reminders',
        description: 'Notifications for spiritual practice reminders',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'admin_notifications',
        'Admin Announcements',
        description: 'Important announcements from administrators',
        importance: Importance.max,
      ),
      const AndroidNotificationChannel(
        'achievements',
        'Achievement Celebrations',
        description: 'Notifications for completed goals and milestones',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'system_alerts',
        'System Alerts',
        description: 'Important system notifications',
        importance: Importance.high,
      ),
    ];

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      for (final channel in channels) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }
  }

  /// Setup proper Firebase database structure with indexing
  Future<void> _setupFirebaseStructure() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Create user notification metadata document if it doesn't exist
      final metadataRef = _firestore
          .collection(_notificationMetadataCollection)
          .doc(userId);

      final metadataDoc = await metadataRef.get();
      if (!metadataDoc.exists) {
        await metadataRef.set({
          'userId': userId,
          'totalNotifications': 0,
          'unreadCount': 0,
          'lastCleanupAt': FieldValue.serverTimestamp(),
          'lastAccessAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('✅ Firebase structure setup completed for user: $userId');
    } catch (e) {
      debugPrint('❌ Error setting up Firebase structure: $e');
    }
  }

  /// Perform maintenance tasks (cleanup, optimization)
  Future<void> _performMaintenanceTasks() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Check if cleanup is needed (run only once per day per user)
      final prefs = await SharedPreferences.getInstance();
      final lastCleanup = prefs.getInt('last_cleanup_$userId') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const oneDayInMs = 24 * 60 * 60 * 1000;

      if (now - lastCleanup > oneDayInMs) {
        await _performDatabaseCleanup();
        await prefs.setInt('last_cleanup_$userId', now);
        debugPrint('🧹 Daily maintenance completed for user: $userId');
      }
    } catch (e) {
      debugPrint('❌ Error performing maintenance: $e');
    }
  }

  /// Efficient database cleanup maintaining only last 10 notifications per user
  Future<void> _performDatabaseCleanup() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Clean user notifications - keep only last 10
      await _cleanUserNotifications(userId);
      
      // Clean admin notifications globally - keep only last 10
      await _cleanAdminNotifications();
      
      // Update metadata
      await _updateNotificationMetadata(userId);
      
      debugPrint('🧹 Database cleanup completed for user: $userId');
    } catch (e) {
      debugPrint('❌ Error during database cleanup: $e');
    }
  }

  /// Clean user notifications keeping only the last 10
  Future<void> _cleanUserNotifications(String userId) async {
    final userNotificationsQuery = await _firestore
        .collection(_userNotificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    if (userNotificationsQuery.docs.length > _maxNotificationsPerUser) {
      final batch = _firestore.batch();
      
      // Delete notifications beyond the limit
      for (int i = _maxNotificationsPerUser; i < userNotificationsQuery.docs.length; i++) {
        batch.delete(userNotificationsQuery.docs[i].reference);
      }
      
      await batch.commit();
      
      final deletedCount = userNotificationsQuery.docs.length - _maxNotificationsPerUser;
      debugPrint('🗑️ Deleted $deletedCount old user notifications for user: $userId');
    }
  }

  /// Clean admin notifications keeping only the last 10 globally
  Future<void> _cleanAdminNotifications() async {
    final adminNotificationsQuery = await _firestore
        .collection(_adminNotificationsCollection)
        .orderBy('sentAt', descending: true)
        .get();

    if (adminNotificationsQuery.docs.length > _maxNotificationsPerUser) {
      final batch = _firestore.batch();
      
      // Delete admin notifications beyond the limit
      for (int i = _maxNotificationsPerUser; i < adminNotificationsQuery.docs.length; i++) {
        batch.delete(adminNotificationsQuery.docs[i].reference);
      }
      
      await batch.commit();
      
      final deletedCount = adminNotificationsQuery.docs.length - _maxNotificationsPerUser;
      debugPrint('🗑️ Deleted $deletedCount old admin notifications');
    }
  }

  /// Update notification metadata for the user
  Future<void> _updateNotificationMetadata(String userId) async {
    try {
      // Count current notifications
      final userNotificationsCount = await _firestore
          .collection(_userNotificationsCollection)
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      final unreadCount = await _firestore
          .collection(_userNotificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      // Update metadata
      await _firestore
          .collection(_notificationMetadataCollection)
          .doc(userId)
          .update({
            'totalNotifications': userNotificationsCount.count,
            'unreadCount': unreadCount.count,
            'lastCleanupAt': FieldValue.serverTimestamp(),
          });

      debugPrint('📊 Updated metadata - Total: ${userNotificationsCount.count}, Unread: ${unreadCount.count}');
    } catch (e) {
      debugPrint('❌ Error updating notification metadata: $e');
    }
  }

  /// Save notification with proper database structure and automatic cleanup
  Future<String?> saveNotificationToFirestore({
    required String title,
    required String message,
    required String type,
    String? userId,
    Map<String, dynamic>? metadata,
    int priority = 1,
  }) async {
    try {
      final currentUserId = userId ?? _auth.currentUser?.uid;
      if (currentUserId == null) {
        debugPrint('❌ No user ID available for notification');
        return null;
      }

      // Check if cleanup is needed before adding new notification
      await _checkAndPerformCleanupIfNeeded(currentUserId);

      // Create notification document
      final notificationData = {
        'title': title,
        'message': message,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'readAt': null,
        'userId': currentUserId,
        'metadata': metadata ?? {},
        'priority': priority,
        'userEmail': _auth.currentUser?.email,
        'deviceInfo': {
          'platform': defaultTargetPlatform.name,
          'createdBy': 'app',
          'version': '1.0.0',
        },
        // Add index-friendly fields
        'year': DateTime.now().year,
        'month': DateTime.now().month,
        'day': DateTime.now().day,
      };

      // Save to user notifications collection
      final docRef = await _firestore
          .collection(_userNotificationsCollection)
          .add(notificationData);

      // Update metadata atomically
      await _firestore
          .collection(_notificationMetadataCollection)
          .doc(currentUserId)
          .update({
            'unreadCount': FieldValue.increment(1),
            'totalNotifications': FieldValue.increment(1),
            'lastNotificationAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Notification saved with ID: ${docRef.id} for user: $currentUserId');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error saving notification: $e');
      return null;
    }
  }

  /// Check if cleanup is needed and perform it efficiently
  Future<void> _checkAndPerformCleanupIfNeeded(String userId) async {
    try {
      // Get current count efficiently
      final countQuery = await _firestore
          .collection(_userNotificationsCollection)
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      // Only cleanup if we're over the limit
      if ((countQuery.count ?? 0) >= _maxNotificationsPerUser) {
        await _cleanUserNotifications(userId);
      }
    } catch (e) {
      debugPrint('❌ Error checking cleanup need: $e');
    }
  }

  /// Get user notifications with proper pagination and caching
  Future<List<Map<String, dynamic>>> getUserNotifications({
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      Query query = _firestore
          .collection(_userNotificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      final notifications = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'docSnapshot': doc, // For pagination
          ...data,
          'isRead': data['isRead'] as bool? ?? false,
          'createdAt': data['createdAt'],
        };
      }).toList();

      debugPrint('📱 Loaded ${notifications.length} user notifications');
      return notifications;
    } catch (e) {
      debugPrint('❌ Error getting user notifications: $e');
      return [];
    }
  }

  /// Get admin notifications with proper read status tracking
  Future<List<Map<String, dynamic>>> getAdminNotifications({
    int limit = 10,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection(_adminNotificationsCollection)
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .get();

      final notifications = <Map<String, dynamic>>[];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final notificationId = doc.id;
        
        // Check read status from user-specific subcollection
        final readStatusDoc = await _firestore
            .collection(_adminNotificationsCollection)
            .doc(notificationId)
            .collection('readStatus')
            .doc(userId)
            .get();

        final isRead = readStatusDoc.exists && (readStatusDoc.data()?['isRead'] as bool? ?? false);
        
        notifications.add({
          'id': notificationId,
          ...data,
          'isRead': isRead,
          'isAdminNotification': true,
        });
      }

      debugPrint('📢 Loaded ${notifications.length} admin notifications');
      return notifications;
    } catch (e) {
      debugPrint('❌ Error getting admin notifications: $e');
      return [];
    }
  }

  /// Mark user notification as read with proper error handling
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Update notification document
      await _firestore
          .collection(_userNotificationsCollection)
          .doc(notificationId)
          .update({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });

      // Update metadata unread count
      await _firestore
          .collection(_notificationMetadataCollection)
          .doc(userId)
          .update({
            'unreadCount': FieldValue.increment(-1),
          });

      debugPrint('✅ Marked notification $notificationId as read');
      return true;
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark admin notification as read with proper tracking
  Future<bool> markAdminNotificationAsRead(String notificationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Store read status in admin notification's subcollection
      await _firestore
          .collection(_adminNotificationsCollection)
          .doc(notificationId)
          .collection('readStatus')
          .doc(userId)
          .set({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
            'userId': userId,
          });

      debugPrint('✅ Marked admin notification $notificationId as read for user $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error marking admin notification as read: $e');
      return false;
    }
  }

  /// Get accurate unread notifications count
  Future<int> getUnreadNotificationsCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      // Get user notifications unread count
      final userUnreadQuery = await _firestore
          .collection(_userNotificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      // Count unread admin notifications
      final adminNotifications = await getAdminNotifications();
      final adminUnreadCount = adminNotifications
          .where((n) => !(n['isRead'] as bool))
          .length;

      final totalUnread = (userUnreadQuery.count ?? 0) + adminUnreadCount;
      debugPrint('📊 Unread count: ${userUnreadQuery.count} user + $adminUnreadCount admin = $totalUnread total');
      
      return totalUnread;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Check for new notifications efficiently
  Future<bool> hasNewNotifications() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final lastCheckTime = prefs.getInt('last_notification_check_$userId') ?? 0;

      // Check for new user notifications
      final newUserNotifications = await _firestore
          .collection(_userNotificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(lastCheckTime))
          .limit(1)
          .get();

      // Check for new admin notifications
      final newAdminNotifications = await _firestore
          .collection(_adminNotificationsCollection)
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

  /// Update last notification check time
  Future<void> updateLastNotificationCheck() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_notification_check_$userId', DateTime.now().millisecondsSinceEpoch);
      
      // Also update in metadata
      await _firestore
          .collection(_notificationMetadataCollection)
          .doc(userId)
          .update({
            'lastAccessAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Updated last notification check time for user $userId');
    } catch (e) {
      debugPrint('❌ Error updating last notification check: $e');
    }
  }

  /// Send admin notification to all users with proper structure
  Future<bool> sendAdminNotificationToAllUsers({
    required String title,
    required String message,
    String priority = 'normal',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Save to admin notifications collection first
      final adminNotificationRef = await _firestore.collection(_adminNotificationsCollection).add({
        'title': title,
        'message': message,
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': _auth.currentUser?.email ?? 'Unknown',
        'type': 'admin_broadcast',
        'priority': priority,
        'metadata': metadata ?? {},
      });

      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      // Create individual notifications for each user
      final batch = _firestore.batch();
      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection(_userNotificationsCollection).doc();
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
          'adminNotificationId': adminNotificationRef.id,
          'metadata': metadata ?? {},
        });
      }

      await batch.commit();

      debugPrint('📢 Admin notification sent to ${usersSnapshot.docs.length} users');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending admin notification: $e');
      return false;
    }
  }

  /// Show local notification with enhanced configuration
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
          styleInformation: BigTextStyleInformation(
            body,
            htmlFormatBigText: true,
            contentTitle: title,
            htmlFormatContentTitle: true,
          ),
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

  /// Get notification statistics for the user
  Future<Map<String, int>> getNotificationStatistics() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      final metadataDoc = await _firestore
          .collection(_notificationMetadataCollection)
          .doc(userId)
          .get();

      if (metadataDoc.exists) {
        final data = metadataDoc.data()!;
        return {
          'total': data['totalNotifications'] as int? ?? 0,
          'unread': data['unreadCount'] as int? ?? 0,
        };
      }

      return {'total': 0, 'unread': 0};
    } catch (e) {
      debugPrint('❌ Error getting notification statistics: $e');
      return {'total': 0, 'unread': 0};
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    // TODO: Add navigation logic based on notification type
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Delete all user notifications (for testing/admin purposes)
  Future<void> deleteAllUserNotifications() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Delete all user notifications
      final batch = _firestore.batch();
      final userNotifications = await _firestore
          .collection(_userNotificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in userNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Reset metadata
      await _firestore
          .collection(_notificationMetadataCollection)
          .doc(userId)
          .update({
            'totalNotifications': 0,
            'unreadCount': 0,
          });

      debugPrint('🗑️ Deleted all notifications for user: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting all notifications: $e');
    }
  }
}
