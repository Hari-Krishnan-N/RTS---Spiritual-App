import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/improved_notification_service.dart';

/// Utility functions for notification management
/// Provides convenient methods for common notification operations
class NotificationUtils {
  static final ImprovedNotificationService _notificationService = ImprovedNotificationService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send achievement notification with predefined templates
  static Future<bool> sendAchievementNotification({
    required String practiceType,
    required int streakCount,
    Map<String, dynamic>? customMetadata,
  }) async {
    try {
      final achievementTitles = {
        'tharpanam': '🌊 Tharpanam Achievement',
        'homam': '🔥 Homam Achievement',
        'dhanam': '💝 Dhanam Achievement',
        'jebam': '🙏 Jebam Achievement',
        'daily_practice': '⭐ Daily Practice Achievement',
      };

      final achievementMessages = {
        'tharpanam': streakCount > 1 
            ? 'Congratulations! You\'ve completed Tharpanam for $streakCount days in a row! Your devotion is inspiring.'
            : 'Great job completing your Tharpanam practice today!',
        'homam': streakCount > 1 
            ? 'Amazing! You\'ve maintained your Homam practice for $streakCount consecutive days! The divine fire burns bright.'
            : 'Wonderful! You\'ve completed your Homam practice today.',
        'dhanam': streakCount > 1 
            ? 'Incredible! You\'ve practiced Dhanam for $streakCount days straight! Your generosity knows no bounds.'
            : 'Beautiful! You\'ve completed your Dhanam practice today.',
        'jebam': 'Excellent Jebam practice! Your spiritual journey continues to flourish.',
        'daily_practice': streakCount > 1 
            ? 'Outstanding! You\'ve maintained your daily practice for $streakCount days! Keep up the spiritual momentum.'
            : 'Great work on your daily practice today!',
      };

      final title = achievementTitles[practiceType] ?? '🎉 Achievement Unlocked!';
      final message = achievementMessages[practiceType] ?? 'Congratulations on your spiritual achievement!';

      final metadata = {
        'practiceType': practiceType,
        'streakCount': streakCount,
        'achievedAt': DateTime.now().toIso8601String(),
        'category': 'achievement',
        'celebrationType': streakCount >= 7 ? 'major' : 'minor',
        ...?customMetadata,
      };

      return await _notificationService.saveNotificationToFirestore(
        title: title,
        message: message,
        type: 'achievement',
        metadata: metadata,
        priority: 2,
      ) != null;
    } catch (e) {
      debugPrint('❌ Error sending achievement notification: $e');
      return false;
    }
  }

  /// Send practice reminder with smart messaging
  static Future<bool> sendPracticeReminder({
    required String practiceType,
    String? customMessage,
    bool isUrgent = false,
    DateTime? scheduledFor,
  }) async {
    try {
      final reminderTitles = {
        'tharpanam': isUrgent ? '⚠️ Tharpanam Reminder' : '🌊 Time for Tharpanam',
        'homam': isUrgent ? '⚠️ Homam Reminder' : '🔥 Time for Homam',
        'dhanam': isUrgent ? '⚠️ Dhanam Reminder' : '💝 Time for Dhanam',
        'jebam': isUrgent ? '⚠️ Jebam Practice' : '🙏 Time for Jebam',
        'daily_practice': isUrgent ? '⚠️ Practice Reminder' : '⭐ Daily Practice Time',
      };

      final reminderMessages = {
        'tharpanam': customMessage ?? (isUrgent 
            ? 'Don\'t forget your Tharpanam practice today! It\'s getting late.'
            : 'Time to connect with your ancestors through Tharpanam practice.'),
        'homam': customMessage ?? (isUrgent 
            ? 'Your Homam practice is waiting! Please complete it today.'
            : 'Light the sacred fire and begin your Homam practice.'),
        'dhanam': customMessage ?? (isUrgent 
            ? 'Remember to practice Dhanam today - giving brings great merit.'
            : 'Time to practice generosity through Dhanam.'),
        'jebam': customMessage ?? (isUrgent 
            ? 'Your Jebam practice is important - please don\'t miss it today.'
            : 'Begin your peaceful Jebam practice session.'),
        'daily_practice': customMessage ?? (isUrgent 
            ? 'Your daily spiritual practice is waiting - please complete it today.'
            : 'Time for your daily spiritual practice session.'),
      };

      final title = reminderTitles[practiceType] ?? (isUrgent ? '⚠️ Practice Reminder' : '🕉️ Practice Time');
      final message = reminderMessages[practiceType] ?? (customMessage ?? 'Time for your spiritual practice.');

      final metadata = {
        'practiceType': practiceType,
        'isUrgent': isUrgent,
        'scheduledFor': scheduledFor?.toIso8601String(),
        'reminderType': isUrgent ? 'urgent' : 'gentle',
        'category': 'practice_reminder',
      };

      return await _notificationService.saveNotificationToFirestore(
        title: title,
        message: message,
        type: 'practice_reminder',
        metadata: metadata,
        priority: isUrgent ? 3 : 1,
      ) != null;
    } catch (e) {
      debugPrint('❌ Error sending practice reminder: $e');
      return false;
    }
  }

  /// Send monthly completion reminder
  static Future<bool> sendMonthlyCompletionReminder({
    required String practiceType,
    required String monthYear,
    required int daysRemaining,
  }) async {
    try {
      final isUrgent = daysRemaining <= 5;
      
      final urgencyMessages = {
        1: 'This is your last day',
        2: 'Only 2 days left',
        3: 'Only 3 days left',
        4: 'Only 4 days left',
        5: 'Only 5 days left',
      };

      final urgencyMessage = daysRemaining <= 5 
          ? urgencyMessages[daysRemaining] ?? 'Very few days left'
          : 'Complete when convenient';

      final practiceNames = {
        'tharpanam': 'Tharpanam',
        'homam': 'Homam',
        'dhanam': 'Dhanam',
      };

      final practiceName = practiceNames[practiceType] ?? practiceType;
      
      final title = isUrgent 
          ? '⚠️ Monthly $practiceName Reminder'
          : '📅 Monthly $practiceName Reminder';

      final message = 'Don\'t forget to complete your monthly $practiceName practice for $monthYear. $urgencyMessage this month!';

      final metadata = {
        'practiceType': practiceType,
        'monthYear': monthYear,
        'daysRemaining': daysRemaining,
        'isUrgent': isUrgent,
        'category': 'monthly_reminder',
        'reminderLevel': isUrgent ? 'urgent' : 'normal',
      };

      return await _notificationService.saveNotificationToFirestore(
        title: title,
        message: message,
        type: 'monthly_reminder',
        metadata: metadata,
        priority: isUrgent ? 3 : 1,
      ) != null;
    } catch (e) {
      debugPrint('❌ Error sending monthly completion reminder: $e');
      return false;
    }
  }

  /// Send milestone celebration notification
  static Future<bool> sendMilestoneNotification({
    required String milestoneType,
    required int milestoneValue,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final milestoneMessages = {
        'streak_7': '🔥 Amazing! You\'ve maintained your practice for a full week!',
        'streak_30': '⭐ Incredible! You\'ve completed 30 days of consistent practice!',
        'streak_100': '🏆 Legendary! 100 days of dedication - you\'re truly committed!',
        'total_practices_50': '🎯 You\'ve completed 50 practice sessions - what dedication!',
        'total_practices_100': '💯 Century achieved! 100 practice sessions completed!',
        'monthly_completion': '🌟 Monthly goal achieved! You\'ve completed all practices this month.',
      };

      final title = '🎉 Milestone Achieved!';
      final message = milestoneMessages[milestoneType] ?? 'Congratulations on reaching this spiritual milestone!';

      final metadata = {
        'milestoneType': milestoneType,
        'milestoneValue': milestoneValue,
        'achievedAt': DateTime.now().toIso8601String(),
        'category': 'milestone',
        ...?extraData,
      };

      return await _notificationService.saveNotificationToFirestore(
        title: title,
        message: message,
        type: 'achievement',
        metadata: metadata,
        priority: 2,
      ) != null;
    } catch (e) {
      debugPrint('❌ Error sending milestone notification: $e');
      return false;
    }
  }

  /// Send system notification (for app updates, maintenance, etc.)
  static Future<bool> sendSystemNotification({
    required String title,
    required String message,
    String type = 'system',
    bool isUrgent = false,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final finalMetadata = {
        'category': 'system',
        'isUrgent': isUrgent,
        'sentAt': DateTime.now().toIso8601String(),
        ...?metadata,
      };

      return await _notificationService.saveNotificationToFirestore(
        title: title,
        message: message,
        type: type,
        metadata: finalMetadata,
        priority: isUrgent ? 3 : 1,
      ) != null;
    } catch (e) {
      debugPrint('❌ Error sending system notification: $e');
      return false;
    }
  }

  /// Batch send notifications to multiple users
  static Future<Map<String, dynamic>> batchSendNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? metadata,
    int priority = 1,
  }) async {
    try {
      int successCount = 0;
      int failCount = 0;
      List<String> failedUserIds = [];

      final batch = _firestore.batch();
      
      for (final userId in userIds) {
        try {
          final notificationRef = _firestore.collection('user_notifications').doc();
          
          final notificationData = {
            'title': title,
            'message': message,
            'type': type,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
            'userId': userId,
            'metadata': metadata ?? {},
            'priority': priority,
            'batchSent': true,
            'batchId': DateTime.now().millisecondsSinceEpoch.toString(),
          };

          batch.set(notificationRef, notificationData);
          successCount++;
        } catch (e) {
          failCount++;
          failedUserIds.add(userId);
          debugPrint('❌ Failed to prepare notification for user $userId: $e');
        }
      }

      await batch.commit();

      debugPrint('✅ Batch notifications sent: $successCount success, $failCount failed');
      
      return {
        'success': successCount,
        'failed': failCount,
        'total': userIds.length,
        'failedUserIds': failedUserIds,
      };
    } catch (e) {
      debugPrint('❌ Error in batch send notifications: $e');
      return {
        'success': 0,
        'failed': userIds.length,
        'total': userIds.length,
        'error': e.toString(),
      };
    }
  }

  /// Smart reminder scheduling based on user's practice patterns
  static Future<bool> scheduleSmartReminder({
    required String practiceType,
    required String userId,
  }) async {
    try {
      // Get user's practice history to determine optimal reminder time
      final userPracticeHistory = await _getUserPracticeHistory(userId, practiceType);
      
      // Analyze patterns and determine best reminder time
      final optimalHour = _calculateOptimalReminderTime(userPracticeHistory);
      
      // Schedule reminder for optimal time
      final reminderTime = DateTime.now().copyWith(
        hour: optimalHour,
        minute: 0,
        second: 0,
        millisecond: 0,
      );

      // If optimal time has passed today, schedule for tomorrow
      final scheduledTime = reminderTime.isBefore(DateTime.now()) 
          ? reminderTime.add(const Duration(days: 1))
          : reminderTime;

      return await sendPracticeReminder(
        practiceType: practiceType,
        customMessage: 'Based on your practice patterns, this might be a good time for $practiceType.',
        scheduledFor: scheduledTime,
      );
    } catch (e) {
      debugPrint('❌ Error scheduling smart reminder: $e');
      return false;
    }
  }

  /// Get user's practice history for analysis
  static Future<List<Map<String, dynamic>>> _getUserPracticeHistory(String userId, String practiceType) async {
    try {
      final historySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('practice_history')
          .where('practiceType', isEqualTo: practiceType)
          .orderBy('completedAt', descending: true)
          .limit(30) // Last 30 practices
          .get();

      return historySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting practice history: $e');
      return [];
    }
  }

  /// Calculate optimal reminder time based on practice patterns
  static int _calculateOptimalReminderTime(List<Map<String, dynamic>> practiceHistory) {
    if (practiceHistory.isEmpty) return 9; // Default: 9 AM

    // Extract hours when user typically practices
    final practiceHours = <int>[];
    
    for (final practice in practiceHistory) {
      final completedAt = practice['completedAt'] as Timestamp?;
      if (completedAt != null) {
        practiceHours.add(completedAt.toDate().hour);
      }
    }

    if (practiceHours.isEmpty) return 9;

    // Calculate average practice hour
    final averageHour = practiceHours.reduce((a, b) => a + b) / practiceHours.length;
    
    // Set reminder 1 hour before average practice time
    final reminderHour = (averageHour - 1).round();
    
    // Ensure reminder is within reasonable bounds (6 AM to 10 PM)
    return reminderHour.clamp(6, 22);
  }

  /// Generate notification analytics
  static Future<Map<String, dynamic>> generateNotificationAnalytics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final targetUserId = userId ?? _auth.currentUser?.uid;
      if (targetUserId == null) return {};

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Query notifications within date range
      final notificationsSnapshot = await _firestore
          .collection('user_notifications')
          .where('userId', isEqualTo: targetUserId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final notifications = notificationsSnapshot.docs.map((doc) => doc.data()).toList();

      // Calculate analytics
      final totalNotifications = notifications.length;
      final readNotifications = notifications.where((n) => n['isRead'] as bool? ?? false).length;
      final unreadNotifications = totalNotifications - readNotifications;

      // Group by type
      final typeGroups = <String, int>{};
      for (final notification in notifications) {
        final type = notification['type'] as String? ?? 'unknown';
        typeGroups[type] = (typeGroups[type] ?? 0) + 1;
      }

      // Group by priority
      final priorityGroups = <int, int>{};
      for (final notification in notifications) {
        final priority = notification['priority'] as int? ?? 1;
        priorityGroups[priority] = (priorityGroups[priority] ?? 0) + 1;
      }

      // Calculate read rate
      final readRate = totalNotifications > 0 ? (readNotifications / totalNotifications * 100) : 0;

      return {
        'totalNotifications': totalNotifications,
        'readNotifications': readNotifications,
        'unreadNotifications': unreadNotifications,
        'readRate': readRate,
        'typeDistribution': typeGroups,
        'priorityDistribution': priorityGroups,
        'dateRange': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error generating notification analytics: $e');
      return {'error': e.toString()};
    }
  }

  /// Clean up old notifications for all users (admin function)
  static Future<Map<String, dynamic>> performGlobalCleanup() async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      int cleanedUsers = 0;
      int totalDeleted = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Get user notifications, keep only last 10
        final userNotificationsQuery = await _firestore
            .collection('user_notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();

        if (userNotificationsQuery.docs.length > 10) {
          final batch = _firestore.batch();
          
          // Delete notifications beyond the limit
          for (int i = 10; i < userNotificationsQuery.docs.length; i++) {
            batch.delete(userNotificationsQuery.docs[i].reference);
            totalDeleted++;
          }
          
          await batch.commit();
          cleanedUsers++;
        }
      }

      // Clean admin notifications - keep only last 10
      final adminNotificationsQuery = await _firestore
          .collection('admin_notifications')
          .orderBy('sentAt', descending: true)
          .get();

      if (adminNotificationsQuery.docs.length > 10) {
        final batch = _firestore.batch();
        
        for (int i = 10; i < adminNotificationsQuery.docs.length; i++) {
          batch.delete(adminNotificationsQuery.docs[i].reference);
          totalDeleted++;
        }
        
        await batch.commit();
      }

      debugPrint('🧹 Global cleanup completed: $cleanedUsers users cleaned, $totalDeleted notifications deleted');
      
      return {
        'cleanedUsers': cleanedUsers,
        'totalDeleted': totalDeleted,
        'totalUsers': usersSnapshot.docs.length,
        'cleanupDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error in global cleanup: $e');
      return {'error': e.toString()};
    }
  }

  /// Validate notification data before sending
  static bool validateNotificationData({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? metadata,
  }) {
    // Basic validation
    if (title.trim().isEmpty || title.length > 100) return false;
    if (message.trim().isEmpty || message.length > 500) return false;
    if (type.trim().isEmpty) return false;

    // Valid types
    const validTypes = [
      'practice_reminder',
      'achievement',
      'monthly_reminder',
      'admin',
      'system',
      'milestone',
      'test',
    ];
    
    if (!validTypes.contains(type)) return false;

    // Metadata validation
    if (metadata != null) {
      try {
        // Ensure metadata can be serialized
        final jsonString = metadata.toString();
        if (jsonString.length > 1000) return false; // Limit metadata size
      } catch (e) {
        return false;
      }
    }

    return true;
  }

  /// Test notification system health
  static Future<Map<String, dynamic>> testNotificationSystemHealth() async {
    try {
      final results = <String, dynamic>{};
      
      // Test 1: Service initialization
      try {
        await _notificationService.initialize();
        results['serviceInitialization'] = 'PASS';
      } catch (e) {
        results['serviceInitialization'] = 'FAIL: $e';
      }

      // Test 2: Database connectivity
      try {
        await _firestore.collection('user_notifications').limit(1).get();
        results['databaseConnectivity'] = 'PASS';
      } catch (e) {
        results['databaseConnectivity'] = 'FAIL: $e';
      }

      // Test 3: Authentication
      try {
        final user = _auth.currentUser;
        results['authentication'] = user != null ? 'PASS' : 'FAIL: No authenticated user';
      } catch (e) {
        results['authentication'] = 'FAIL: $e';
      }

      // Test 4: Send test notification
      try {
        final notificationId = await _notificationService.saveNotificationToFirestore(
          title: '🧪 System Health Test',
          message: 'This is an automated health check notification.',
          type: 'test',
          metadata: {'healthCheck': true, 'timestamp': DateTime.now().toIso8601String()},
        );
        results['sendNotification'] = notificationId != null ? 'PASS' : 'FAIL: No notification ID returned';
      } catch (e) {
        results['sendNotification'] = 'FAIL: $e';
      }

      // Test 5: Statistics retrieval
      try {
        final stats = await _notificationService.getNotificationStatistics();
        results['statisticsRetrieval'] = stats.isNotEmpty ? 'PASS' : 'FAIL: Empty statistics';
      } catch (e) {
        results['statisticsRetrieval'] = 'FAIL: $e';
      }

      results['overallHealth'] = results.values.every((result) => result.toString().startsWith('PASS')) 
          ? 'HEALTHY' : 'UNHEALTHY';
      results['testTimestamp'] = DateTime.now().toIso8601String();

      return results;
    } catch (e) {
      debugPrint('❌ Error testing notification system health: $e');
      return {
        'overallHealth': 'UNHEALTHY',
        'error': e.toString(),
        'testTimestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
