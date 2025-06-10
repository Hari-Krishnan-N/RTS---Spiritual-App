import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/improved_notification_service.dart';
import '../services/notification_migration_service.dart';

/// Enhanced notification provider with proper state management and reactive updates
/// Features:
/// - Real-time notification updates
/// - Proper state management for read/unread status
/// - Automatic migration handling
/// - Efficient caching and pagination
class ImprovedNotificationProvider with ChangeNotifier {
  final ImprovedNotificationService _notificationService = ImprovedNotificationService();
  final NotificationMigrationService _migrationService = NotificationMigrationService();

  // State variables
  List<Map<String, dynamic>> _userNotifications = [];
  List<Map<String, dynamic>> _adminNotifications = [];
  Map<String, int> _statistics = {'total': 0, 'unread': 0};
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _migrationCompleted = false;
  
  // Pagination
  DocumentSnapshot? _lastUserNotificationDoc;
  bool _hasMoreUserNotifications = true;
  
  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _userNotificationsSubscription;
  StreamSubscription<QuerySnapshot>? _adminNotificationsSubscription;

  // Getters
  List<Map<String, dynamic>> get userNotifications => _userNotifications;
  List<Map<String, dynamic>> get adminNotifications => _adminNotifications;
  List<Map<String, dynamic>> get allNotifications => [..._userNotifications, ..._adminNotifications]
    ..sort((a, b) {
      final aTime = a['createdAt'] ?? a['sentAt'];
      final bTime = b['createdAt'] ?? b['sentAt'];
      if (aTime == null || bTime == null) return 0;
      return (bTime as Timestamp).compareTo(aTime as Timestamp);
    });
  
  Map<String, int> get statistics => _statistics;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get migrationCompleted => _migrationCompleted;
  bool get hasMoreUserNotifications => _hasMoreUserNotifications;

  int get totalUnreadCount => _statistics['unread'] ?? 0;
  int get userUnreadCount => _userNotifications.where((n) => !(n['isRead'] as bool? ?? true)).length;
  int get adminUnreadCount => _adminNotifications.where((n) => !(n['isRead'] as bool? ?? true)).length;

  /// Initialize the provider with migration check
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Initialize notification service
      await _notificationService.initialize();
      
      // Check and perform migration if needed
      await _checkAndPerformMigration();
      
      // Setup real-time listeners
      await _setupRealtimeListeners();
      
      // Load initial data
      await _loadInitialData();
      
      _clearError();
    } catch (e) {
      _setError('Failed to initialize notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Check and perform migration if needed
  Future<void> _checkAndPerformMigration() async {
    try {
      final needsMigration = await _migrationService.isMigrationNeeded();
      if (needsMigration) {
        debugPrint('🔄 Migration needed, performing migration...');
        final migrationSuccess = await _migrationService.performMigration();
        _migrationCompleted = migrationSuccess;
        
        if (migrationSuccess) {
          debugPrint('✅ Migration completed successfully');
        } else {
          debugPrint('❌ Migration failed');
        }
      } else {
        _migrationCompleted = true;
        debugPrint('✅ No migration needed');
      }
    } catch (e) {
      debugPrint('❌ Error during migration check: $e');
      _migrationCompleted = false;
    }
  }

  /// Setup real-time listeners for notifications
  Future<void> _setupRealtimeListeners() async {
    try {
      // Listen to user notifications
      _userNotificationsSubscription = FirebaseFirestore.instance
          .collection('user_notifications')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots()
          .listen(
            _onUserNotificationsUpdate,
            onError: (error) => debugPrint('❌ User notifications stream error: $error'),
          );

      // Listen to admin notifications
      _adminNotificationsSubscription = FirebaseFirestore.instance
          .collection('admin_notifications')
          .orderBy('sentAt', descending: true)
          .limit(10)
          .snapshots()
          .listen(
            _onAdminNotificationsUpdate,
            onError: (error) => debugPrint('❌ Admin notifications stream error: $error'),
          );

      debugPrint('👂 Real-time listeners setup completed');
    } catch (e) {
      debugPrint('❌ Error setting up listeners: $e');
    }
  }

  /// Handle user notifications updates from Firestore stream
  void _onUserNotificationsUpdate(QuerySnapshot snapshot) async {
    try {
      _userNotifications = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'docSnapshot': doc,
          ...data,
          'isRead': data['isRead'] as bool? ?? false,
        };
      }).toList();

      // Update last document for pagination
      if (snapshot.docs.isNotEmpty) {
        _lastUserNotificationDoc = snapshot.docs.last;
      }

      await _updateStatistics();
      notifyListeners();
      debugPrint('📱 User notifications updated: ${_userNotifications.length} notifications');
    } catch (e) {
      debugPrint('❌ Error processing user notifications update: $e');
    }
  }

  /// Handle admin notifications updates from Firestore stream
  void _onAdminNotificationsUpdate(QuerySnapshot snapshot) async {
    try {
      final adminNotifications = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final notificationId = doc.id;
        
        // Check read status from user-specific subcollection
        final userId = FirebaseAuth.instance.currentUser?.uid;
        final readStatusDoc = await FirebaseFirestore.instance
            .collection('admin_notifications')
            .doc(notificationId)
            .collection('readStatus')
            .doc(userId)
            .get();
        
        final isRead = readStatusDoc.exists && (readStatusDoc.data()?['isRead'] as bool? ?? false);
        
        adminNotifications.add({
          'id': notificationId,
          ...data,
          'isRead': isRead,
          'isAdminNotification': true,
        });
      }
      
      _adminNotifications = adminNotifications;
      await _updateStatistics();
      notifyListeners();
      debugPrint('📢 Admin notifications updated: ${_adminNotifications.length} notifications');
    } catch (e) {
      debugPrint('❌ Error processing admin notifications update: $e');
    }
  }

  /// Load initial notification data
  Future<void> _loadInitialData() async {
    try {
      // Statistics will be updated by the stream listeners
      await _updateStatistics();
      debugPrint('📊 Initial data loaded');
    } catch (e) {
      debugPrint('❌ Error loading initial data: $e');
    }
  }

  /// Update notification statistics
  Future<void> _updateStatistics() async {
    try {
      _statistics = await _notificationService.getNotificationStatistics();
      
      // Also calculate real-time counts from current data
      final userUnread = _userNotifications.where((n) => !(n['isRead'] as bool? ?? true)).length;
      final adminUnread = _adminNotifications.where((n) => !(n['isRead'] as bool? ?? true)).length;
      
      _statistics['unread'] = userUnread + adminUnread;
      _statistics['total'] = _userNotifications.length + _adminNotifications.length;
      
      debugPrint('📊 Statistics updated: $_statistics');
    } catch (e) {
      debugPrint('❌ Error updating statistics: $e');
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId, {bool isAdminNotification = false}) async {
    try {
      bool success;
      
      if (isAdminNotification) {
        success = await _notificationService.markAdminNotificationAsRead(notificationId);
        if (success) {
          // Update local state
          final index = _adminNotifications.indexWhere((n) => n['id'] == notificationId);
          if (index != -1) {
            _adminNotifications[index]['isRead'] = true;
          }
        }
      } else {
        success = await _notificationService.markNotificationAsRead(notificationId);
        if (success) {
          // Update local state
          final index = _userNotifications.indexWhere((n) => n['id'] == notificationId);
          if (index != -1) {
            _userNotifications[index]['isRead'] = true;
          }
        }
      }
      
      if (success) {
        await _updateStatistics();
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      bool allSuccess = true;
      
      // Mark all unread user notifications as read
      for (final notification in _userNotifications) {
        if (!(notification['isRead'] as bool? ?? true)) {
          final success = await markAsRead(notification['id']);
          if (!success) allSuccess = false;
        }
      }
      
      // Mark all unread admin notifications as read
      for (final notification in _adminNotifications) {
        if (!(notification['isRead'] as bool? ?? true)) {
          final success = await markAsRead(notification['id'], isAdminNotification: true);
          if (!success) allSuccess = false;
        }
      }
      
      return allSuccess;
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Load more user notifications (pagination)
  Future<void> loadMoreUserNotifications() async {
    if (!_hasMoreUserNotifications || _isLoading) return;

    try {
      _setLoading(true);
      
      final moreNotifications = await _notificationService.getUserNotifications(
        limit: 10,
        startAfter: _lastUserNotificationDoc,
      );
      
      if (moreNotifications.isEmpty) {
        _hasMoreUserNotifications = false;
      } else {
        _userNotifications.addAll(moreNotifications);
        if (moreNotifications.isNotEmpty) {
          _lastUserNotificationDoc = moreNotifications.last['docSnapshot'] as DocumentSnapshot?;
        }
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load more notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Send a new notification
  Future<String?> sendNotification({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? metadata,
    int priority = 1,
  }) async {
    try {
      final notificationId = await _notificationService.saveNotificationToFirestore(
        title: title,
        message: message,
        type: type,
        metadata: metadata,
        priority: priority,
      );
      
      if (notificationId != null) {
        // The real-time listener will automatically update the UI
        debugPrint('✅ Notification sent successfully: $notificationId');
      }
      
      return notificationId;
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
      _setError('Failed to send notification: $e');
      return null;
    }
  }

  /// Send admin notification to all users
  Future<bool> sendAdminNotification({
    required String title,
    required String message,
    String priority = 'normal',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final success = await _notificationService.sendAdminNotificationToAllUsers(
        title: title,
        message: message,
        priority: priority,
        metadata: metadata,
      );
      
      if (success) {
        debugPrint('✅ Admin notification sent successfully');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error sending admin notification: $e');
      _setError('Failed to send admin notification: $e');
      return false;
    }
  }

  /// Refresh all notifications
  Future<void> refresh() async {
    try {
      _setLoading(true);
      await _updateStatistics();
      // Real-time listeners will automatically refresh the data
      _clearError();
    } catch (e) {
      _setError('Failed to refresh notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update last notification check time
  Future<void> updateLastCheck() async {
    try {
      await _notificationService.updateLastNotificationCheck();
    } catch (e) {
      debugPrint('❌ Error updating last check: $e');
    }
  }

  /// Check for new notifications
  Future<bool> hasNewNotifications() async {
    try {
      return await _notificationService.hasNewNotifications();
    } catch (e) {
      debugPrint('❌ Error checking for new notifications: $e');
      return false;
    }
  }

  /// Get notification by ID
  Map<String, dynamic>? getNotificationById(String id) {
    // Check user notifications first
    final userNotification = _userNotifications.where((n) => n['id'] == id).firstOrNull;
    if (userNotification != null) return userNotification;
    
    // Check admin notifications
    final adminNotification = _adminNotifications.where((n) => n['id'] == id).firstOrNull;
    return adminNotification;
  }

  /// Filter notifications by type
  List<Map<String, dynamic>> getNotificationsByType(String type) {
    return allNotifications.where((n) => n['type'] == type).toList();
  }

  /// Get unread notifications only
  List<Map<String, dynamic>> get unreadNotifications {
    return allNotifications.where((n) => !(n['isRead'] as bool? ?? true)).toList();
  }

  /// Clear all notifications (admin only)
  Future<bool> clearAllNotifications() async {
    try {
      await _notificationService.deleteAllUserNotifications();
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing all notifications: $e');
      _setError('Failed to clear notifications: $e');
      return false;
    }
  }

  /// Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _clearError();
    notifyListeners();
  }

  void _setError(String error) {
    _hasError = true;
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
    debugPrint('❌ Provider error: $error');
  }

  void _clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }

  /// Dispose of resources
  @override
  void dispose() {
    _userNotificationsSubscription?.cancel();
    _adminNotificationsSubscription?.cancel();
    super.dispose();
  }
}
