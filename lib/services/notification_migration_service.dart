import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Migration service to transition from old notification structure to new improved structure
/// This service helps migrate existing data without losing user notifications
class NotificationMigrationService {
  static final NotificationMigrationService _instance = NotificationMigrationService._internal();
  factory NotificationMigrationService() => _instance;
  NotificationMigrationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Old collection names
  static const String _oldNotificationsCollection = 'notifications';
  static const String _oldAdminNotificationsCollection = 'admin_notifications';

  // New collection names
  static const String _newUserNotificationsCollection = 'user_notifications';
  static const String _newAdminNotificationsCollection = 'admin_notifications';
  static const String _notificationMetadataCollection = 'notification_metadata';

  /// Check if migration is needed for the current user
  Future<bool> isMigrationNeeded() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Check if user has metadata document (indicates new structure is set up)
      final metadataDoc = await _firestore
          .collection(_notificationMetadataCollection)
          .doc(userId)
          .get();

      if (metadataDoc.exists) {
        final migrationCompleted = metadataDoc.data()?['migrationCompleted'] as bool? ?? false;
        return !migrationCompleted;
      }

      // Check if old notifications exist
      final oldNotifications = await _firestore
          .collection(_oldNotificationsCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return oldNotifications.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking migration need: $e');
      return false;
    }
  }

  /// Perform complete migration for the current user
  Future<bool> performMigration() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('❌ No authenticated user for migration');
        return false;
      }

      debugPrint('🔄 Starting notification migration for user: $userId');

      // Step 1: Migrate user notifications
      final migratedUserNotifications = await _migrateUserNotifications(userId);
      
      // Step 2: Setup metadata
      await _setupUserMetadata(userId, migratedUserNotifications);
      
      // Step 3: Clean up old notifications (optional - can be done later)
      await _cleanupOldUserNotifications(userId);
      
      debugPrint('✅ Migration completed successfully for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error during migration: $e');
      return false;
    }
  }

  /// Migrate user notifications from old structure to new structure
  Future<int> _migrateUserNotifications(String userId) async {
    try {
      // Get old user notifications (last 10 only)
      final oldNotificationsQuery = await _firestore
          .collection(_oldNotificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      if (oldNotificationsQuery.docs.isEmpty) {
        debugPrint('📭 No old notifications found for user: $userId');
        return 0;
      }

      final batch = _firestore.batch();
      int migratedCount = 0;

      for (final oldDoc in oldNotificationsQuery.docs) {
        final oldData = oldDoc.data();
        
        // Create new notification document with improved structure
        final newNotificationRef = _firestore
            .collection(_newUserNotificationsCollection)
            .doc();

        final newNotificationData = {
          'title': oldData['title'] ?? 'Notification',
          'message': oldData['message'] ?? '',
          'type': oldData['type'] ?? 'general',
          'createdAt': oldData['createdAt'] ?? FieldValue.serverTimestamp(),
          'isRead': oldData['isRead'] as bool? ?? false,
          'readAt': oldData['readAt'],
          'userId': userId,
          'metadata': oldData['metadata'] ?? {},
          'priority': oldData['priority'] as int? ?? 1,
          'userEmail': oldData['userEmail'] ?? _auth.currentUser?.email,
          'deviceInfo': oldData['deviceInfo'] ?? {
            'platform': 'migrated',
            'createdBy': 'migration',
          },
          // Add new index-friendly fields
          'year': (oldData['createdAt'] as Timestamp?)?.toDate().year ?? DateTime.now().year,
          'month': (oldData['createdAt'] as Timestamp?)?.toDate().month ?? DateTime.now().month,
          'day': (oldData['createdAt'] as Timestamp?)?.toDate().day ?? DateTime.now().day,
          // Migration tracking
          'migratedFrom': oldDoc.id,
          'migratedAt': FieldValue.serverTimestamp(),
        };

        batch.set(newNotificationRef, newNotificationData);
        migratedCount++;
      }

      await batch.commit();
      debugPrint('📦 Migrated $migratedCount user notifications');
      return migratedCount;
    } catch (e) {
      debugPrint('❌ Error migrating user notifications: $e');
      return 0;
    }
  }

  /// Setup metadata for the user after migration
  Future<void> _setupUserMetadata(String userId, int migratedCount) async {
    try {
      // Count unread notifications
      final unreadCount = await _firestore
          .collection(_newUserNotificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      // Create or update metadata document
      await _firestore
          .collection(_notificationMetadataCollection)
          .doc(userId)
          .set({
            'userId': userId,
            'totalNotifications': migratedCount,
            'unreadCount': unreadCount.count,
            'lastCleanupAt': FieldValue.serverTimestamp(),
            'lastAccessAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'migrationCompleted': true,
            'migratedAt': FieldValue.serverTimestamp(),
            'migratedNotificationsCount': migratedCount,
          }, SetOptions(merge: true));

      debugPrint('📊 Setup metadata - Total: $migratedCount, Unread: ${unreadCount.count}');
    } catch (e) {
      debugPrint('❌ Error setting up metadata: $e');
    }
  }

  /// Clean up old user notifications after successful migration
  Future<void> _cleanupOldUserNotifications(String userId) async {
    try {
      final oldNotifications = await _firestore
          .collection(_oldNotificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      if (oldNotifications.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('🗑️ Cleaned up ${oldNotifications.docs.length} old user notifications');
    } catch (e) {
      debugPrint('❌ Error cleaning up old notifications: $e');
    }
  }

  /// Migrate admin notifications (one-time global operation)
  Future<bool> migrateAdminNotifications() async {
    try {
      // Check if admin migration is already done
      final migrationStatusDoc = await _firestore
          .collection('migration_status')
          .doc('admin_notifications')
          .get();

      if (migrationStatusDoc.exists && migrationStatusDoc.data()?['completed'] == true) {
        debugPrint('✅ Admin notifications already migrated');
        return true;
      }

      debugPrint('🔄 Starting admin notifications migration');

      // Get all old admin notifications (last 10 only)
      final oldAdminNotifications = await _firestore
          .collection(_oldAdminNotificationsCollection)
          .orderBy('sentAt', descending: true)
          .limit(10)
          .get();

      if (oldAdminNotifications.docs.isEmpty) {
        debugPrint('📭 No old admin notifications found');
        await _markAdminMigrationComplete();
        return true;
      }

      final batch = _firestore.batch();
      int migratedCount = 0;

      for (final oldDoc in oldAdminNotifications.docs) {
        final oldData = oldDoc.data();
        
        // Create new admin notification with same structure but in new collection
        final newAdminNotificationRef = _firestore
            .collection(_newAdminNotificationsCollection)
            .doc();

        final newAdminNotificationData = {
          'title': oldData['title'] ?? 'Admin Notification',
          'message': oldData['message'] ?? '',
          'sentAt': oldData['sentAt'] ?? FieldValue.serverTimestamp(),
          'sentBy': oldData['sentBy'] ?? 'Unknown Admin',
          'type': oldData['type'] ?? 'admin_broadcast',
          'priority': oldData['priority'] ?? 'normal',
          'metadata': oldData['metadata'] ?? {},
          // Migration tracking
          'migratedFrom': oldDoc.id,
          'migratedAt': FieldValue.serverTimestamp(),
        };

        batch.set(newAdminNotificationRef, newAdminNotificationData);
        migratedCount++;
      }

      await batch.commit();
      await _markAdminMigrationComplete();
      
      debugPrint('📦 Migrated $migratedCount admin notifications');
      return true;
    } catch (e) {
      debugPrint('❌ Error migrating admin notifications: $e');
      return false;
    }
  }

  /// Mark admin migration as complete
  Future<void> _markAdminMigrationComplete() async {
    await _firestore
        .collection('migration_status')
        .doc('admin_notifications')
        .set({
          'completed': true,
          'completedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Get migration status for current user
  Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      final metadataDoc = await _firestore
          .collection(_notificationMetadataCollection)
          .doc(userId)
          .get();

      if (metadataDoc.exists) {
        return metadataDoc.data() ?? {};
      }

      return {'migrationCompleted': false};
    } catch (e) {
      debugPrint('❌ Error getting migration status: $e');
      return {};
    }
  }

  /// Force migration for all users (admin operation)
  Future<Map<String, int>> performBulkMigration() async {
    try {
      debugPrint('🔄 Starting bulk migration for all users');

      // Get all unique user IDs from old notifications
      final oldNotifications = await _firestore
          .collection(_oldNotificationsCollection)
          .get();

      final userIds = <String>{};
      for (final doc in oldNotifications.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId != null) {
          userIds.add(userId);
        }
      }

      int successCount = 0;
      int failCount = 0;

      for (final userId in userIds) {
        try {
          // Simulate auth context for each user (for admin operation)
          final migratedCount = await _migrateUserNotifications(userId);
          await _setupUserMetadata(userId, migratedCount);
          successCount++;
        } catch (e) {
          debugPrint('❌ Failed to migrate user $userId: $e');
          failCount++;
        }
      }

      // Migrate admin notifications
      await migrateAdminNotifications();

      debugPrint('✅ Bulk migration completed - Success: $successCount, Failed: $failCount');
      return {'success': successCount, 'failed': failCount, 'total': userIds.length};
    } catch (e) {
      debugPrint('❌ Error in bulk migration: $e');
      return {'success': 0, 'failed': 0, 'total': 0};
    }
  }

  /// Rollback migration (emergency use only)
  Future<bool> rollbackMigration() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      debugPrint('⚠️ Rolling back migration for user: $userId');

      // Delete migrated notifications
      final newNotifications = await _firestore
          .collection(_newUserNotificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in newNotifications.docs) {
        batch.delete(doc.reference);
      }

      // Reset metadata
      batch.delete(_firestore
          .collection(_notificationMetadataCollection)
          .doc(userId));

      await batch.commit();

      debugPrint('✅ Migration rollback completed for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error during rollback: $e');
      return false;
    }
  }
}
