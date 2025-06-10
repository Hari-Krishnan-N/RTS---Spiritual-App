import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/improved_notification_service.dart';


/// Sample data generator for testing the notification system
/// Provides realistic test data for development and testing
class NotificationSampleDataGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  // Sample notification templates
  static const List<Map<String, String>> _achievementTemplates = [
    {
      'title': '🎉 7-Day Streak!',
      'message': 'Amazing! You\'ve completed your Tharpanam practice for 7 consecutive days!',
      'type': 'achievement',
      'practiceType': 'tharpanam',
    },
    {
      'title': '🔥 Homam Master!',
      'message': 'Incredible! You\'ve maintained your Homam practice for 30 days straight!',
      'type': 'achievement',
      'practiceType': 'homam',
    },
    {
      'title': '💝 Generosity Champion!',
      'message': 'Wonderful! Your Dhanam practice shows true compassion.',
      'type': 'achievement',
      'practiceType': 'dhanam',
    },
    {
      'title': '🙏 Jebam Excellence!',
      'message': 'Beautiful practice today! Your dedication to Jebam is inspiring.',
      'type': 'achievement',
      'practiceType': 'jebam',
    },
  ];

  static const List<Map<String, String>> _reminderTemplates = [
    {
      'title': '🌊 Tharpanam Reminder',
      'message': 'Time to honor your ancestors with today\'s Tharpanam practice.',
      'type': 'practice_reminder',
      'practiceType': 'tharpanam',
    },
    {
      'title': '🔥 Homam Time',
      'message': 'Light the sacred fire and begin your daily Homam practice.',
      'type': 'practice_reminder',
      'practiceType': 'homam',
    },
    {
      'title': '💝 Dhanam Practice',
      'message': 'Practice generosity and compassion through Dhanam today.',
      'type': 'practice_reminder',
      'practiceType': 'dhanam',
    },
    {
      'title': '🙏 Jebam Session',
      'message': 'Find peace and centeredness in today\'s Jebam practice.',
      'type': 'practice_reminder',
      'practiceType': 'jebam',
    },
  ];

  static const List<Map<String, String>> _adminTemplates = [
    {
      'title': '📱 App Update Available',
      'message': 'A new version is available with improved meditation features!',
      'type': 'admin',
    },
    {
      'title': '🎊 Community Milestone',
      'message': 'Our community has completed over 10,000 practice sessions this month!',
      'type': 'admin',
    },
    {
      'title': '🌟 Feature Announcement',
      'message': 'New guided meditation sessions are now available in the app.',
      'type': 'admin',
    },
    {
      'title': '🔧 Scheduled Maintenance',
      'message': 'The app will undergo brief maintenance tonight from 2-4 AM.',
      'type': 'admin',
    },
  ];

  static const List<Map<String, String>> _monthlyTemplates = [
    {
      'title': '📅 Monthly Tharpanam Reminder',
      'message': 'Don\'t forget to complete your monthly Tharpanam practice. Only 5 days left this month!',
      'type': 'monthly_reminder',
      'practiceType': 'tharpanam',
    },
    {
      'title': '📅 Monthly Homam Reminder',
      'message': 'Time to complete your monthly Homam practice. Schedule it when convenient.',
      'type': 'monthly_reminder',
      'practiceType': 'homam',
    },
    {
      'title': '📅 Monthly Dhanam Reminder',
      'message': 'Complete your monthly Dhanam practice to maintain your spiritual growth.',
      'type': 'monthly_reminder',
      'practiceType': 'dhanam',
    },
  ];

  /// Generate sample users for testing
  static Future<List<String>> generateSampleUsers({int count = 10}) async {
    final userIds = <String>[];
    
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < count; i++) {
        final userId = 'test_user_${DateTime.now().millisecondsSinceEpoch}_$i';
        final userRef = _firestore.collection('users').doc(userId);
        
        batch.set(userRef, {
          'email': 'testuser$i@example.com',
          'name': 'Test User $i',
          'createdAt': FieldValue.serverTimestamp(),
          'isTestUser': true,
          'practiceLevel': _random.nextInt(5) + 1,
          'preferredPractices': _getRandomPractices(),
        });
        
        userIds.add(userId);
      }
      
      await batch.commit();
      debugPrint('✅ Generated $count sample users');
      return userIds;
    } catch (e) {
      debugPrint('❌ Error generating sample users: $e');
      return [];
    }
  }

  /// Generate sample notifications for testing
  static Future<void> generateSampleNotifications({
    required String userId,
    int achievementCount = 5,
    int reminderCount = 8,
    int adminCount = 3,
    int monthlyCount = 2,
  }) async {
    try {
      final notificationService = ImprovedNotificationService();
      await notificationService.initialize();
      
      // Generate achievement notifications
      for (int i = 0; i < achievementCount; i++) {
        final template = _achievementTemplates[_random.nextInt(_achievementTemplates.length)];
        await _createSampleNotification(
          userId: userId,
          template: template,
          daysAgo: _random.nextInt(30),
          isRead: _random.nextBool(),
        );
      }
      
      // Generate practice reminder notifications
      for (int i = 0; i < reminderCount; i++) {
        final template = _reminderTemplates[_random.nextInt(_reminderTemplates.length)];
        await _createSampleNotification(
          userId: userId,
          template: template,
          daysAgo: _random.nextInt(7),
          isRead: _random.nextBool(),
        );
      }
      
      // Generate monthly reminder notifications
      for (int i = 0; i < monthlyCount; i++) {
        final template = _monthlyTemplates[_random.nextInt(_monthlyTemplates.length)];
        await _createSampleNotification(
          userId: userId,
          template: template,
          daysAgo: _random.nextInt(5),
          isRead: _random.nextBool(),
        );
      }
      
      debugPrint('✅ Generated ${achievementCount + reminderCount + monthlyCount} notifications for user $userId');
    } catch (e) {
      debugPrint('❌ Error generating sample notifications: $e');
    }
  }

  /// Generate sample admin notifications
  static Future<void> generateSampleAdminNotifications({int count = 5}) async {
    try {
      for (int i = 0; i < count; i++) {
        final template = _adminTemplates[_random.nextInt(_adminTemplates.length)];
        
        await _firestore.collection('admin_notifications').add({
          'title': template['title'],
          'message': template['message'],
          'type': template['type'],
          'sentAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: _random.nextInt(30))),
          ),
          'sentBy': 'test_admin@example.com',
          'priority': ['low', 'normal', 'high'][_random.nextInt(3)],
          'isTestData': true,
        });
      }
      
      debugPrint('✅ Generated $count sample admin notifications');
    } catch (e) {
      debugPrint('❌ Error generating sample admin notifications: $e');
    }
  }

  /// Generate sample scheduled notifications
  static Future<void> generateSampleScheduledNotifications({int count = 10}) async {
    try {
      for (int i = 0; i < count; i++) {
        final isRecurring = _random.nextBool();
        final scheduledTime = DateTime.now().add(
          Duration(
            hours: _random.nextInt(24),
            minutes: _random.nextInt(60),
          ),
        );
        
        await _firestore.collection('scheduled_notifications').add({
          'type': ['practice_reminder', 'achievement_check', 'monthly_reminder'][_random.nextInt(3)],
          'title': 'Scheduled Test Notification $i',
          'message': 'This is a test scheduled notification',
          'scheduledTime': scheduledTime,
          'nextRun': scheduledTime,
          'isActive': _random.nextBool(),
          'recurring': isRecurring,
          'recurringInterval': isRecurring ? Duration(days: 1).inMilliseconds : null,
          'createdAt': FieldValue.serverTimestamp(),
          'isTestData': true,
        });
      }
      
      debugPrint('✅ Generated $count sample scheduled notifications');
    } catch (e) {
      debugPrint('❌ Error generating sample scheduled notifications: $e');
    }
  }

  /// Generate sample notification metadata
  static Future<void> generateSampleMetadata({required String userId}) async {
    try {
      await _firestore.collection('notification_metadata').doc(userId).set({
        'userId': userId,
        'totalNotifications': _random.nextInt(50) + 10,
        'unreadCount': _random.nextInt(10),
        'lastCleanupAt': FieldValue.serverTimestamp(),
        'lastAccessAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'migrationCompleted': true,
        'isTestData': true,
      });
      
      debugPrint('✅ Generated sample metadata for user $userId');
    } catch (e) {
      debugPrint('❌ Error generating sample metadata: $e');
    }
  }

  /// Generate performance test data
  static Future<void> generatePerformanceTestData({
    int userCount = 100,
    int notificationsPerUser = 20,
  }) async {
    try {
      debugPrint('🚀 Generating performance test data...');
      debugPrint('Users: $userCount, Notifications per user: $notificationsPerUser');
      
      // Generate users in batches
      const batchSize = 25;
      final allUserIds = <String>[];
      
      for (int i = 0; i < userCount; i += batchSize) {
        final endIndex = (i + batchSize < userCount) ? i + batchSize : userCount;
        final batchCount = endIndex - i;
        
        final userIds = await generateSampleUsers(count: batchCount);
        allUserIds.addAll(userIds);
        
        debugPrint('Generated users batch ${i ~/ batchSize + 1}: $batchCount users');
      }
      
      // Generate notifications for each user
      for (int i = 0; i < allUserIds.length; i++) {
        final userId = allUserIds[i];
        
        await generateSampleNotifications(
          userId: userId,
          achievementCount: notificationsPerUser ~/ 4,
          reminderCount: notificationsPerUser ~/ 2,
          adminCount: notificationsPerUser ~/ 8,
          monthlyCount: notificationsPerUser ~/ 8,
        );
        
        await generateSampleMetadata(userId: userId);
        
        if (i % 10 == 0) {
          debugPrint('Generated notifications for ${i + 1}/${allUserIds.length} users');
        }
      }
      
      // Generate admin notifications
      await generateSampleAdminNotifications(count: 20);
      
      // Generate scheduled notifications
      await generateSampleScheduledNotifications(count: 50);
      
      debugPrint('✅ Performance test data generation completed!');
      debugPrint('Total users: ${allUserIds.length}');
      debugPrint('Total notifications: ${allUserIds.length * notificationsPerUser}');
    } catch (e) {
      debugPrint('❌ Error generating performance test data: $e');
    }
  }

  /// Clean up test data
  static Future<void> cleanupTestData() async {
    try {
      debugPrint('🧹 Cleaning up test data...');
      
      // Clean test users
      final testUsers = await _firestore
          .collection('users')
          .where('isTestUser', isEqualTo: true)
          .get();
      
      final batch1 = _firestore.batch();
      for (final doc in testUsers.docs) {
        batch1.delete(doc.reference);
      }
      await batch1.commit();
      debugPrint('Deleted ${testUsers.docs.length} test users');
      
      // Clean test notifications
      final testNotifications = await _firestore
          .collection('user_notifications')
          .where('metadata.isTestData', isEqualTo: true)
          .get();
      
      final batch2 = _firestore.batch();
      for (final doc in testNotifications.docs) {
        batch2.delete(doc.reference);
      }
      await batch2.commit();
      debugPrint('Deleted ${testNotifications.docs.length} test notifications');
      
      // Clean test admin notifications
      final testAdminNotifications = await _firestore
          .collection('admin_notifications')
          .where('isTestData', isEqualTo: true)
          .get();
      
      final batch3 = _firestore.batch();
      for (final doc in testAdminNotifications.docs) {
        batch3.delete(doc.reference);
      }
      await batch3.commit();
      debugPrint('Deleted ${testAdminNotifications.docs.length} test admin notifications');
      
      // Clean test scheduled notifications
      final testScheduled = await _firestore
          .collection('scheduled_notifications')
          .where('isTestData', isEqualTo: true)
          .get();
      
      final batch4 = _firestore.batch();
      for (final doc in testScheduled.docs) {
        batch4.delete(doc.reference);
      }
      await batch4.commit();
      debugPrint('Deleted ${testScheduled.docs.length} test scheduled notifications');
      
      // Clean test metadata
      final testMetadata = await _firestore
          .collection('notification_metadata')
          .where('isTestData', isEqualTo: true)
          .get();
      
      final batch5 = _firestore.batch();
      for (final doc in testMetadata.docs) {
        batch5.delete(doc.reference);
      }
      await batch5.commit();
      debugPrint('Deleted ${testMetadata.docs.length} test metadata documents');
      
      debugPrint('✅ Test data cleanup completed!');
    } catch (e) {
      debugPrint('❌ Error cleaning up test data: $e');
    }
  }

  /// Generate migration test scenario
  static Future<void> generateMigrationTestData({required String userId}) async {
    try {
      debugPrint('🔄 Generating migration test data for user $userId...');
      
      // Create old-style notifications in the 'notifications' collection
      final batch = _firestore.batch();
      
      for (int i = 0; i < 15; i++) {
        final oldNotificationRef = _firestore.collection('notifications').doc();
        
        batch.set(oldNotificationRef, {
          'title': 'Old Notification $i',
          'message': 'This is an old-style notification that needs migration',
          'type': ['practice_reminder', 'achievement', 'monthly_reminder'][i % 3],
          'userId': userId,
          'isRead': i % 3 == 0, // Some read, some unread
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: 30 - i)),
          ),
          'metadata': {
            'oldFormat': true,
            'migrationTest': true,
          },
        });
      }
      
      await batch.commit();
      
      // Create old admin notifications
      for (int i = 0; i < 5; i++) {
        await _firestore.collection('admin_notifications').add({
          'title': 'Old Admin Notification $i',
          'message': 'This is an old admin notification',
          'sentAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: 10 - i)),
          ),
          'sentBy': 'old_admin@example.com',
          'type': 'admin_broadcast',
          'oldFormat': true,
          'migrationTest': true,
        });
      }
      
      debugPrint('✅ Generated migration test data (15 old notifications + 5 admin)');
    } catch (e) {
      debugPrint('❌ Error generating migration test data: $e');
    }
  }

  /// Helper method to create a sample notification
  static Future<void> _createSampleNotification({
    required String userId,
    required Map<String, String> template,
    required int daysAgo,
    required bool isRead,
  }) async {
    await _firestore.collection('user_notifications').add({
      'title': template['title']!,
      'message': template['message']!,
      'type': template['type']!,
      'userId': userId,
      'isRead': isRead,
      'readAt': isRead ? Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: daysAgo - 1)),
      ) : null,
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: daysAgo)),
      ),
      'priority': _random.nextInt(3) + 1,
      'metadata': {
        'practiceType': template['practiceType'],
        'isTestData': true,
        'streakCount': template['type'] == 'achievement' ? _random.nextInt(30) + 1 : null,
      },
    });
  }

  /// Helper method to get random practices
  static List<String> _getRandomPractices() {
    final allPractices = ['tharpanam', 'homam', 'dhanam', 'jebam'];
    final practiceCount = _random.nextInt(3) + 1; // 1-3 practices
    
    allPractices.shuffle(_random);
    return allPractices.take(practiceCount).toList();
  }

  /// Generate realistic notification interaction patterns
  static Future<void> generateRealisticUsagePattern({required String userId}) async {
    try {
      debugPrint('📊 Generating realistic usage pattern for user $userId...');
      
      // Simulate 30 days of app usage
      for (int day = 30; day >= 0; day--) {
        
        // Morning practice reminder (80% chance)
        if (_random.nextDouble() < 0.8) {
          await _createSampleNotification(
            userId: userId,
            template: _reminderTemplates[_random.nextInt(_reminderTemplates.length)],
            daysAgo: day,
            isRead: _random.nextDouble() < 0.9, // 90% read rate for reminders
          );
        }
        
        // Achievement notification (20% chance)
        if (_random.nextDouble() < 0.2) {
          await _createSampleNotification(
            userId: userId,
            template: _achievementTemplates[_random.nextInt(_achievementTemplates.length)],
            daysAgo: day,
            isRead: _random.nextDouble() < 0.95, // 95% read rate for achievements
          );
        }
        
        // Weekly admin notification (once per week)
        if (day % 7 == 0 && _random.nextDouble() < 0.7) {
          // This would be handled by admin notification generation
        }
      }
      
      debugPrint('✅ Generated realistic usage pattern for 30 days');
    } catch (e) {
      debugPrint('❌ Error generating usage pattern: $e');
    }
  }
}

/// Command-line tool for generating test data
/// Run with: dart run lib/utils/notification_sample_data_generator.dart
void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    debugPrint('''
Notification Sample Data Generator

Usage:
  dart run lib/utils/notification_sample_data_generator.dart <command> [options]

Commands:
  users <count>              Generate sample users
  notifications <userId>     Generate notifications for user
  admin <count>             Generate admin notifications
  scheduled <count>         Generate scheduled notifications
  performance <users> <notifications>  Generate performance test data
  migration <userId>        Generate migration test data
  realistic <userId>        Generate realistic usage pattern
  cleanup                   Clean up all test data

Examples:
  dart run lib/utils/notification_sample_data_generator.dart users 10
  dart run lib/utils/notification_sample_data_generator.dart performance 100 20
  dart run lib/utils/notification_sample_data_generator.dart cleanup
    ''');
    return;
  }

  final command = arguments[0];
  
  try {
    switch (command) {
      case 'users':
        final count = arguments.length > 1 ? int.parse(arguments[1]) : 10;
        await NotificationSampleDataGenerator.generateSampleUsers(count: count);
        break;
        
      case 'notifications':
        if (arguments.length < 2) {
          debugPrint('Error: userId required');
          return;
        }
        await NotificationSampleDataGenerator.generateSampleNotifications(userId: arguments[1]);
        break;
        
      case 'admin':
        final count = arguments.length > 1 ? int.parse(arguments[1]) : 5;
        await NotificationSampleDataGenerator.generateSampleAdminNotifications(count: count);
        break;
        
      case 'scheduled':
        final count = arguments.length > 1 ? int.parse(arguments[1]) : 10;
        await NotificationSampleDataGenerator.generateSampleScheduledNotifications(count: count);
        break;
        
      case 'performance':
        final userCount = arguments.length > 1 ? int.parse(arguments[1]) : 100;
        final notificationCount = arguments.length > 2 ? int.parse(arguments[2]) : 20;
        await NotificationSampleDataGenerator.generatePerformanceTestData(
          userCount: userCount,
          notificationsPerUser: notificationCount,
        );
        break;
        
      case 'migration':
        if (arguments.length < 2) {
          debugPrint('Error: userId required');
          return;
        }
        await NotificationSampleDataGenerator.generateMigrationTestData(userId: arguments[1]);
        break;
        
      case 'realistic':
        if (arguments.length < 2) {
          debugPrint('Error: userId required');
          return;
        }
        await NotificationSampleDataGenerator.generateRealisticUsagePattern(userId: arguments[1]);
        break;
        
      case 'cleanup':
        await NotificationSampleDataGenerator.cleanupTestData();
        break;
        
      default:
        debugPrint('Error: Unknown command "$command"');
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}
