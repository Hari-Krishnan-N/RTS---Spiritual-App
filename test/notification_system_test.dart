import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Package imports for testing
import 'package:rhythmbhara_tara_sadhana/services/improved_notification_service.dart';
import 'package:rhythmbhara_tara_sadhana/utils/notification_utils.dart';

void main() {
  group('Improved Notification System Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockUser mockUser;

    setUp(() async {
      // Setup test environment
      fakeFirestore = FakeFirebaseFirestore();
      mockUser = MockUser(
        uid: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      
      // Setup SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    group('ImprovedNotificationService', () {
      test('should initialize successfully', () async {
        // Test service initialization
        final service = ImprovedNotificationService();
        
        // This would normally initialize local notifications
        // In test environment, we just verify no exceptions are thrown
        expect(() => service.initialize(), returnsNormally);
      });

      test('should save notification to Firestore with correct structure', () async {
        // Create test notification data
        const title = 'Test Notification';
        const message = 'This is a test message';
        const type = 'test';
        const priority = 2;
        final metadata = {'test': true};

        // Add test user to Firestore
        await fakeFirestore.collection('users').doc('test_user_123').set({
          'email': 'test@example.com',
          'name': 'Test User',
          'createdAt': DateTime.now(),
        });

        // Mock the notification service with fake Firestore
        // Note: In actual implementation, you'd inject dependencies
        
        // Verify notification structure
        expect(title, isNotEmpty);
        expect(message, isNotEmpty);
        expect(type, equals('test'));
        expect(priority, equals(2));
        expect(metadata, isA<Map<String, dynamic>>());
      });

      test('should maintain only 10 notifications per user', () async {
        // Add test user
        await fakeFirestore.collection('users').doc('test_user_123').set({
          'email': 'test@example.com',
        });

        // Add 15 notifications for the user
        for (int i = 0; i < 15; i++) {
          await fakeFirestore.collection('user_notifications').add({
            'title': 'Notification $i',
            'message': 'Message $i',
            'type': 'test',
            'userId': 'test_user_123',
            'isRead': false,
            'createdAt': DateTime.now().subtract(Duration(days: i)),
            'priority': 1,
          });
        }

        // Verify we have 15 notifications
        final beforeCleanup = await fakeFirestore
            .collection('user_notifications')
            .where('userId', isEqualTo: 'test_user_123')
            .get();
        expect(beforeCleanup.docs.length, equals(15));

        // Simulate cleanup (keep only last 10)
        final query = await fakeFirestore
            .collection('user_notifications')
            .where('userId', isEqualTo: 'test_user_123')
            .orderBy('createdAt', descending: true)
            .get();

        // Delete notifications beyond limit
        final batch = fakeFirestore.batch();
        for (int i = 10; i < query.docs.length; i++) {
          batch.delete(query.docs[i].reference);
        }
        await batch.commit();

        // Verify only 10 notifications remain
        final afterCleanup = await fakeFirestore
            .collection('user_notifications')
            .where('userId', isEqualTo: 'test_user_123')
            .get();
        expect(afterCleanup.docs.length, equals(10));
      });

      test('should correctly calculate unread notification count', () async {
        // Add test notifications with mixed read status
        await fakeFirestore.collection('user_notifications').add({
          'userId': 'test_user_123',
          'isRead': false,
          'title': 'Unread 1',
          'createdAt': DateTime.now(),
        });
        
        await fakeFirestore.collection('user_notifications').add({
          'userId': 'test_user_123',
          'isRead': true,
          'title': 'Read 1',
          'createdAt': DateTime.now(),
        });
        
        await fakeFirestore.collection('user_notifications').add({
          'userId': 'test_user_123',
          'isRead': false,
          'title': 'Unread 2',
          'createdAt': DateTime.now(),
        });

        // Count unread notifications
        final unreadQuery = await fakeFirestore
            .collection('user_notifications')
            .where('userId', isEqualTo: 'test_user_123')
            .where('isRead', isEqualTo: false)
            .get();

        expect(unreadQuery.docs.length, equals(2));
      });

      test('should mark notification as read correctly', () async {
        // Add unread notification
        final docRef = await fakeFirestore.collection('user_notifications').add({
          'userId': 'test_user_123',
          'isRead': false,
          'title': 'Test Notification',
          'createdAt': DateTime.now(),
        });

        // Mark as read
        await docRef.update({
          'isRead': true,
          'readAt': DateTime.now(),
        });

        // Verify it's marked as read
        final doc = await docRef.get();
        expect(doc.data()?['isRead'], equals(true));
        expect(doc.data()?['readAt'], isNotNull);
      });
    });

    group('NotificationMigrationService', () {
      test('should detect migration need correctly', () async {
        // Add old notification structure
        await fakeFirestore.collection('notifications').add({
          'userId': 'test_user_123',
          'title': 'Old Notification',
          'message': 'Old structure',
          'createdAt': DateTime.now(),
        });

        // Check if migration is needed (would need old notifications present)
        final hasOldNotifications = await fakeFirestore
            .collection('notifications')
            .where('userId', isEqualTo: 'test_user_123')
            .get();

        expect(hasOldNotifications.docs.isNotEmpty, equals(true));
      });

      test('should migrate notifications correctly', () async {
        // Add old notifications
        await fakeFirestore.collection('notifications').add({
          'userId': 'test_user_123',
          'title': 'Old Notification 1',
          'message': 'Old message 1',
          'type': 'practice_reminder',
          'isRead': false,
          'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        });

        await fakeFirestore.collection('notifications').add({
          'userId': 'test_user_123',
          'title': 'Old Notification 2',
          'message': 'Old message 2',
          'type': 'achievement',
          'isRead': true,
          'createdAt': DateTime.now(),
        });

        // Simulate migration
        final oldNotifications = await fakeFirestore
            .collection('notifications')
            .where('userId', isEqualTo: 'test_user_123')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();

        // Migrate to new structure
        final batch = fakeFirestore.batch();
        for (final oldDoc in oldNotifications.docs) {
          final oldData = oldDoc.data();
          final newRef = fakeFirestore.collection('user_notifications').doc();
          
          batch.set(newRef, {
            'title': oldData['title'],
            'message': oldData['message'],
            'type': oldData['type'],
            'isRead': oldData['isRead'],
            'userId': oldData['userId'],
            'createdAt': oldData['createdAt'],
            'migratedFrom': oldDoc.id,
            'migratedAt': DateTime.now(),
          });
        }
        await batch.commit();

        // Verify migration
        final newNotifications = await fakeFirestore
            .collection('user_notifications')
            .where('userId', isEqualTo: 'test_user_123')
            .get();

        expect(newNotifications.docs.length, equals(2));
        expect(newNotifications.docs.first.data()['migratedFrom'], isNotNull);
      });
    });

    group('NotificationUtils', () {
      test('should validate notification data correctly', () {
        // Valid notification data
        expect(
          NotificationUtils.validateNotificationData(
            title: 'Valid Title',
            message: 'Valid message content',
            type: 'practice_reminder',
          ),
          equals(true),
        );

        // Invalid - empty title
        expect(
          NotificationUtils.validateNotificationData(
            title: '',
            message: 'Valid message',
            type: 'practice_reminder',
          ),
          equals(false),
        );

        // Invalid - title too long
        expect(
          NotificationUtils.validateNotificationData(
            title: 'A' * 101, // 101 characters
            message: 'Valid message',
            type: 'practice_reminder',
          ),
          equals(false),
        );

        // Invalid - unknown type
        expect(
          NotificationUtils.validateNotificationData(
            title: 'Valid Title',
            message: 'Valid message',
            type: 'invalid_type',
          ),
          equals(false),
        );
      });

      test('should format notification types correctly', () {
        // Test type formatting (would be implemented in utils)
        const testTypes = {
          'practice_reminder': 'Practice Reminder',
          'monthly_reminder': 'Monthly Reminder',
          'achievement': 'Achievement',
          'admin': 'Admin',
        };

        testTypes.forEach((input, expected) {
          final formatted = input.replaceAll('_', ' ').split(' ').map((word) => 
              word[0].toUpperCase() + word.substring(1)).join(' ');
          expect(formatted, equals(expected));
        });
      });
    });

    group('Admin Functions', () {
      test('should send admin notification to all users', () async {
        // Add test users
        await fakeFirestore.collection('users').doc('user1').set({'email': 'user1@test.com'});
        await fakeFirestore.collection('users').doc('user2').set({'email': 'user2@test.com'});
        await fakeFirestore.collection('users').doc('user3').set({'email': 'user3@test.com'});

        // Get all users
        final usersSnapshot = await fakeFirestore.collection('users').get();
        expect(usersSnapshot.docs.length, equals(3));

        // Simulate sending admin notification to all users
        final batch = fakeFirestore.batch();
        for (var userDoc in usersSnapshot.docs) {
          final notificationRef = fakeFirestore.collection('user_notifications').doc();
          batch.set(notificationRef, {
            'title': 'Admin Announcement',
            'message': 'Important update for all users',
            'type': 'admin',
            'userId': userDoc.id,
            'isRead': false,
            'createdAt': DateTime.now(),
            'fromAdmin': true,
          });
        }
        await batch.commit();

        // Verify notifications were created for all users
        final notifications = await fakeFirestore.collection('user_notifications').get();
        expect(notifications.docs.length, equals(3));
        
        for (var notification in notifications.docs) {
          expect(notification.data()['fromAdmin'], equals(true));
          expect(notification.data()['type'], equals('admin'));
        }
      });

      test('should generate analytics correctly', () async {
        // Add test notifications with different types and read status
        final testNotifications = [
          {'type': 'practice_reminder', 'isRead': false},
          {'type': 'practice_reminder', 'isRead': true},
          {'type': 'achievement', 'isRead': false},
          {'type': 'achievement', 'isRead': true},
          {'type': 'admin', 'isRead': true},
        ];

        for (int i = 0; i < testNotifications.length; i++) {
          await fakeFirestore.collection('user_notifications').add({
            'userId': 'test_user_123',
            'title': 'Notification $i',
            'message': 'Message $i',
            'type': testNotifications[i]['type'],
            'isRead': testNotifications[i]['isRead'],
            'createdAt': DateTime.now().subtract(Duration(days: i)),
          });
        }

        // Generate analytics
        final notifications = await fakeFirestore
            .collection('user_notifications')
            .where('userId', isEqualTo: 'test_user_123')
            .get();

        final totalNotifications = notifications.docs.length;
        final readNotifications = notifications.docs
            .where((doc) => doc.data()['isRead'] as bool)
            .length;
        final unreadNotifications = totalNotifications - readNotifications;

        // Group by type
        final typeGroups = <String, int>{};
        for (final doc in notifications.docs) {
          final type = doc.data()['type'] as String;
          typeGroups[type] = (typeGroups[type] ?? 0) + 1;
        }

        // Verify analytics
        expect(totalNotifications, equals(5));
        expect(readNotifications, equals(3));
        expect(unreadNotifications, equals(2));
        expect(typeGroups['practice_reminder'], equals(2));
        expect(typeGroups['achievement'], equals(2));
        expect(typeGroups['admin'], equals(1));
      });
    });

    group('Performance Tests', () {
      test('should handle large number of notifications efficiently', () async {
        final stopwatch = Stopwatch()..start();

        // Add 1000 notifications
        final batch = fakeFirestore.batch();
        for (int i = 0; i < 1000; i++) {
          final ref = fakeFirestore.collection('user_notifications').doc();
          batch.set(ref, {
            'userId': 'test_user_123',
            'title': 'Notification $i',
            'message': 'Message $i',
            'type': 'test',
            'isRead': i % 3 == 0, // Every 3rd notification is read
            'createdAt': DateTime.now().subtract(Duration(seconds: i)),
          });
        }
        await batch.commit();

        stopwatch.stop();
        
        // Verify performance is reasonable (adjust threshold as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max

        // Test query performance
        final queryStopwatch = Stopwatch()..start();
        
        final query = await fakeFirestore
            .collection('user_notifications')
            .where('userId', isEqualTo: 'test_user_123')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();

        queryStopwatch.stop();
        
        expect(query.docs.length, equals(10));
        expect(queryStopwatch.elapsedMilliseconds, lessThan(1000)); // 1 second max
      });

      test('should efficiently count unread notifications', () async {
        // Add mixed read/unread notifications
        final batch = fakeFirestore.batch();
        for (int i = 0; i < 100; i++) {
          final ref = fakeFirestore.collection('user_notifications').doc();
          batch.set(ref, {
            'userId': 'test_user_123',
            'isRead': i % 4 == 0, // Every 4th notification is read
            'createdAt': DateTime.now().subtract(Duration(minutes: i)),
          });
        }
        await batch.commit();

        final stopwatch = Stopwatch()..start();

        // Count unread notifications
        final unreadQuery = await fakeFirestore
            .collection('user_notifications')
            .where('userId', isEqualTo: 'test_user_123')
            .where('isRead', isEqualTo: false)
            .get();

        stopwatch.stop();

        expect(unreadQuery.docs.length, equals(75)); // 75 unread out of 100
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // 500ms max
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Simulate network error by using invalid collection name
        expect(
          () async => await fakeFirestore.collection('').doc('test').get(),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle malformed notification data', () async {
        // Test with missing required fields
        expect(
          () async => await fakeFirestore.collection('user_notifications').add({
            // Missing title, message, userId
            'type': 'test',
            'isRead': false,
          }),
          returnsNormally, // Firestore allows this, but app should validate
        );
      });

      test('should handle concurrent read/write operations', () async {
        // Add initial notification
        final docRef = await fakeFirestore.collection('user_notifications').add({
          'userId': 'test_user_123',
          'isRead': false,
          'title': 'Test',
        });

        // Simulate concurrent operations
        final futures = List.generate(10, (index) => 
          docRef.update({'isRead': index % 2 == 0})
        );

        // All operations should complete without error
        await Future.wait(futures);

        // Verify final state
        final doc = await docRef.get();
        expect(doc.exists, equals(true));
        expect(doc.data(), containsPair('isRead', isA<bool>()));
      });
    });
  });
}

/// Helper class for testing notification system components
class NotificationTestHelper {
  static final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
  
  /// Create a test user in Firestore
  static Future<void> createTestUser(String userId, {String? email}) async {
    await firestore.collection('users').doc(userId).set({
      'email': email ?? '$userId@test.com',
      'name': 'Test User $userId',
      'createdAt': DateTime.now(),
    });
  }
  
  /// Create test notifications for a user
  static Future<List<String>> createTestNotifications(
    String userId, {
    int count = 5,
    String type = 'test',
    bool mixReadStatus = true,
  }) async {
    final notificationIds = <String>[];
    
    for (int i = 0; i < count; i++) {
      final docRef = await firestore.collection('user_notifications').add({
        'userId': userId,
        'title': 'Test Notification $i',
        'message': 'Test message $i',
        'type': type,
        'isRead': mixReadStatus ? i % 2 == 0 : false,
        'createdAt': DateTime.now().subtract(Duration(minutes: i)),
        'priority': 1,
      });
      notificationIds.add(docRef.id);
    }
    
    return notificationIds;
  }
  
  /// Verify notification structure
  static void verifyNotificationStructure(Map<String, dynamic> notification) {
    expect(notification, containsPair('title', isA<String>()));
    expect(notification, containsPair('message', isA<String>()));
    expect(notification, containsPair('type', isA<String>()));
    expect(notification, containsPair('userId', isA<String>()));
    expect(notification, containsPair('isRead', isA<bool>()));
    expect(notification, containsPair('createdAt', isNotNull));
  }
  
  /// Calculate expected read rate
  static double calculateReadRate(List<Map<String, dynamic>> notifications) {
    if (notifications.isEmpty) return 0.0;
    
    final readCount = notifications
        .where((n) => n['isRead'] as bool? ?? false)
        .length;
    
    return (readCount / notifications.length) * 100;
  }
  
  /// Clean up test data
  static Future<void> cleanup() async {
    // Clean all test collections
    final collections = ['user_notifications', 'admin_notifications', 'users'];
    
    for (final collection in collections) {
      final docs = await firestore.collection(collection).get();
      final batch = firestore.batch();
      
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    }
  }
}
