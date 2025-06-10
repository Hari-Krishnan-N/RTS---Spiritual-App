import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/improved_notification_service.dart';
import '../services/notification_migration_service.dart';
import 'dart:async';

/// Backward compatible notification provider that bridges old and new systems
/// This provider maintains compatibility while gradually migrating to the improved system
class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final ImprovedNotificationService _improvedService = ImprovedNotificationService();
  final NotificationMigrationService _migrationService = NotificationMigrationService();

  List<Map<String, dynamic>> _userNotifications = [];
  List<Map<String, dynamic>> _adminNotifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _hasNewNotifications = false;
  Timer? _notificationCheckTimer;
  
  // State tracking for operations
  final Set<String> _processingNotifications = <String>{};
  bool _isMarkingAllAsRead = false;
  bool _isInitialized = false;
  bool _useImprovedSystem = false;
  bool _migrationInProgress = false;

  // Getters
  List<Map<String, dynamic>> get userNotifications => _userNotifications;
  List<Map<String, dynamic>> get adminNotifications => _adminNotifications;
  
  // FIXED: Better notification merging with proper read status
  List<Map<String, dynamic>> get allNotifications {
    final all = <Map<String, dynamic>>[];

    // Add admin notifications with proper read status
    for (var notification in _adminNotifications) {
      final notificationCopy = Map<String, dynamic>.from(notification);
      notificationCopy['isAdminNotification'] = true;
      // Admin notification read status is already set in the service
      all.add(notificationCopy);
    }

    // Add user notifications with proper read status
    for (var notification in _userNotifications) {
      final notificationCopy = Map<String, dynamic>.from(notification);
      notificationCopy['isAdminNotification'] = false;
      // User notification read status comes directly from Firestore
      all.add(notificationCopy);
    }

    // Sort by priority first, then by timestamp
    all.sort((a, b) {
      // Priority sort (higher priority first)
      final aPriority = a['priority'] as int? ?? 0;
      final bPriority = b['priority'] as int? ?? 0;
      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority);
      }

      // Then by timestamp (newer first)
      final aTime = a['createdAt'] ?? a['sentAt'];
      final bTime = b['createdAt'] ?? b['sentAt'];

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;

      return bTime.compareTo(aTime);
    });

    return all;
  }

  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isMarkingAllAsRead => _isMarkingAllAsRead;
  bool get isInitialized => _isInitialized;
  bool get useImprovedSystem => _useImprovedSystem;
  bool get migrationInProgress => _migrationInProgress;
  
  // FIXED: Proper glow logic
  bool get hasNewNotifications {
    // Only show glow if there are actually unread notifications
    return _hasNewNotifications && _unreadCount > 0;
  }
  
  bool isNotificationProcessing(String notificationId) {
    return _processingNotifications.contains(notificationId);
  }

  /// Initialize with automatic migration handling
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🔄 Initializing notification provider (compatibility mode)...');
      
      // Initialize both systems
      await _notificationService.initialize();
      await _improvedService.initialize();
      
      // Check if migration is needed
      final needsMigration = await _migrationService.isMigrationNeeded();
      
      if (needsMigration) {
        debugPrint('🔄 Migration needed - switching to improved system');
        await _performMigration();
        _useImprovedSystem = true;
      } else {
        // Check if user already uses improved system
        final migrationStatus = await _migrationService.getMigrationStatus();
        _useImprovedSystem = migrationStatus['migrationCompleted'] == true;
      }
      
      await loadNotifications();
      await _updateUnreadCount();
      await _checkForNewNotifications();
      
      _startNotificationPolling();
      _isInitialized = true;
      
      debugPrint('✅ Notification provider initialized successfully (${_useImprovedSystem ? "improved" : "legacy"} mode)');
    } catch (e) {
      debugPrint('❌ Error initializing notification provider: $e');
    }
  }

  // FIXED: Better polling with proper error handling
  void _startNotificationPolling() {
    _notificationCheckTimer?.cancel();
    _notificationCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isLoading && !_isMarkingAllAsRead && _isInitialized) {
        try {
          await _checkForNewNotifications();
          await _updateUnreadCount();
        } catch (e) {
          debugPrint('❌ Error in polling cycle: $e');
        }
      }
    });
  }

  // FIXED: Proper new notifications detection
  Future<void> _checkForNewNotifications() async {
    try {
      final hasNew = await _notificationService.hasNewNotifications();
      if (_hasNewNotifications != hasNew) {
        _hasNewNotifications = hasNew;
        debugPrint('🔔 New notifications status changed: $hasNew');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error checking for new notifications: $e');
    }
  }

  /// Perform migration from old to new system
  Future<void> _performMigration() async {
    if (_migrationInProgress) return;
    
    _migrationInProgress = true;
    notifyListeners();
    
    try {
      debugPrint('🔄 Starting notification migration...');
      final success = await _migrationService.performMigration();
      
      if (success) {
        debugPrint('✅ Migration completed successfully');
        _useImprovedSystem = true;
      } else {
        debugPrint('❌ Migration failed, staying on legacy system');
        _useImprovedSystem = false;
      }
    } catch (e) {
      debugPrint('❌ Migration error: $e');
      _useImprovedSystem = false;
    } finally {
      _migrationInProgress = false;
      notifyListeners();
    }
  }

  /// Load notifications using appropriate service
  Future<void> loadNotifications() async {
    _setLoading(true);

    try {
      debugPrint('📱 Loading notifications (last 10 each)...');
      
      if (_useImprovedSystem) {
        // Use improved service
        final results = await Future.wait([
          _improvedService.getUserNotifications(limit: 10),
          _improvedService.getAdminNotifications(limit: 10),
        ]);
        
        _userNotifications = results[0];
        _adminNotifications = results[1];
      } else {
        // Use legacy service
        final results = await Future.wait([
          _notificationService.getUserNotifications(limit: 10),
          _notificationService.getAdminNotifications(limit: 10),
        ]);
        
        _userNotifications = results[0];
        _adminNotifications = results[1];
      }

      await _updateUnreadCount();
      
      debugPrint('✅ Loaded ${_userNotifications.length} user + ${_adminNotifications.length} admin notifications (last 10 each)');
    } catch (e) {
      debugPrint('❌ Error loading notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Update unread count using appropriate service
  Future<void> _updateUnreadCount() async {
    try {
      final newUnreadCount = _useImprovedSystem 
          ? await _improvedService.getUnreadNotificationsCount()
          : await _notificationService.getUnreadNotificationsCount();
          
      if (_unreadCount != newUnreadCount) {
        debugPrint('📊 Unread count updated: $_unreadCount → $newUnreadCount (${_useImprovedSystem ? "improved" : "legacy"} system)');
        _unreadCount = newUnreadCount;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error updating unread count: $e');
    }
  }

  /// Mark notification as read and immediately remove from UI (for Dismissible widgets)
  void markAsReadAndRemove(String notificationId, bool isAdminNotification) {
    try {
      // Immediately remove from local lists to prevent Dismissible tree errors
      if (isAdminNotification) {
        _adminNotifications.removeWhere((n) => n['id'] == notificationId);
        debugPrint('✅ Admin notification $notificationId removed from UI immediately');
      } else {
        _userNotifications.removeWhere((n) => n['id'] == notificationId);
        debugPrint('✅ User notification $notificationId removed from UI immediately');
      }
      
      // Update unread count immediately
      if (_unreadCount > 0) {
        _unreadCount--;
      }
      
      // Notify listeners to update UI immediately
      notifyListeners();
      
      // Update backend asynchronously without blocking UI
      _updateNotificationInBackground(notificationId, isAdminNotification);
    } catch (e) {
      debugPrint('❌ Error removing notification from UI: $e');
    }
  }
  
  /// Update notification in background after UI removal
  Future<void> _updateNotificationInBackground(String notificationId, bool isAdminNotification) async {
    try {
      bool success = false;
      
      if (_useImprovedSystem) {
        success = isAdminNotification
            ? await _improvedService.markAdminNotificationAsRead(notificationId)
            : await _improvedService.markNotificationAsRead(notificationId);
      } else {
        success = isAdminNotification
            ? await _notificationService.markAdminNotificationAsRead(notificationId)
            : await _notificationService.markNotificationAsRead(notificationId);
      }
      
      if (success) {
        debugPrint('✅ Notification $notificationId updated in backend successfully');
        // Update unread count from server to ensure consistency
        await _updateUnreadCount();
      } else {
        debugPrint('❌ Failed to update notification $notificationId in backend');
        // Could implement retry logic or revert local changes here
      }
    } catch (e) {
      debugPrint('❌ Error updating notification in background: $e');
      // Could implement retry logic or error reporting here
    }
  }

  /// Mark notification as read using appropriate service
  Future<bool> markAsRead(String notificationId, bool isAdminNotification) async {
    if (_processingNotifications.contains(notificationId)) {
      debugPrint('⚠️ Notification $notificationId already being processed');
      return false;
    }

    _processingNotifications.add(notificationId);
    notifyListeners();

    try {
      bool success = false;
      
      if (_useImprovedSystem) {
        // Use improved service
        success = isAdminNotification
            ? await _improvedService.markAdminNotificationAsRead(notificationId)
            : await _improvedService.markNotificationAsRead(notificationId);
      } else {
        // Use legacy service
        success = isAdminNotification
            ? await _notificationService.markAdminNotificationAsRead(notificationId)
            : await _notificationService.markNotificationAsRead(notificationId);
      }
      
      if (success) {
        // Update local state immediately
        if (isAdminNotification) {
          final index = _adminNotifications.indexWhere((n) => n['id'] == notificationId);
          if (index != -1) {
            _adminNotifications[index]['isRead'] = true;
            debugPrint('✅ Admin notification $notificationId marked as read locally');
          }
        } else {
          final index = _userNotifications.indexWhere((n) => n['id'] == notificationId);
          if (index != -1) {
            _userNotifications[index]['isRead'] = true;
            debugPrint('✅ User notification $notificationId marked as read locally');
          }
        }

        // Update unread count immediately
        if (_unreadCount > 0) {
          _unreadCount--;
        }
        notifyListeners();
        
        // Update from server to ensure consistency
        await _updateUnreadCount();
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      return false;
    } finally {
      _processingNotifications.remove(notificationId);
      notifyListeners();
    }
  }

  /// Mark all notifications as read using appropriate service
  Future<bool> markAllAsRead() async {
    if (_isMarkingAllAsRead) {
      debugPrint('⚠️ Already marking all notifications as read');
      return false;
    }

    _isMarkingAllAsRead = true;
    notifyListeners();

    try {
      int successCount = 0;
      List<Future<bool>> markingTasks = [];

      // Mark all unread user notifications
      for (var notification in _userNotifications) {
        if (!(notification['isRead'] as bool? ?? true)) {
          if (_useImprovedSystem) {
            markingTasks.add(_improvedService.markNotificationAsRead(notification['id']));
          } else {
            markingTasks.add(_notificationService.markNotificationAsRead(notification['id']));
          }
        }
      }

      // Mark all unread admin notifications
      for (var notification in _adminNotifications) {
        if (!(notification['isRead'] as bool? ?? true)) {
          if (_useImprovedSystem) {
            markingTasks.add(_improvedService.markAdminNotificationAsRead(notification['id']));
          } else {
            markingTasks.add(_notificationService.markAdminNotificationAsRead(notification['id']));
          }
        }
      }

      // Execute all marking operations
      final results = await Future.wait(markingTasks);
      successCount = results.where((result) => result).length;

      if (successCount > 0) {
        // Update local state
        for (var notification in _userNotifications) {
          notification['isRead'] = true;
        }
        for (var notification in _adminNotifications) {
          notification['isRead'] = true;
        }

        // Update last check time to remove glow effect
        if (_useImprovedSystem) {
          await _improvedService.updateLastNotificationCheck();
        } else {
          await _notificationService.updateLastNotificationCheck();
        }
        
        _hasNewNotifications = false;
        _unreadCount = 0;

        notifyListeners();
        
        debugPrint('✅ Marked $successCount notifications as read (${_useImprovedSystem ? "improved" : "legacy"} system)');
      }

      return successCount > 0;
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
      return false;
    } finally {
      _isMarkingAllAsRead = false;
      notifyListeners();
    }
  }

  /// Handle notification screen opened using appropriate service
  Future<void> onNotificationScreenOpened() async {
    try {
      if (_useImprovedSystem) {
        await _improvedService.updateLastNotificationCheck();
      } else {
        await _notificationService.updateLastNotificationCheck();
      }
      
      if (_hasNewNotifications) {
        _hasNewNotifications = false;
        debugPrint('🔔 Glow effect removed - notification screen opened (${_useImprovedSystem ? "improved" : "legacy"} system)');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error updating notification screen opened: $e');
    }
  }

  // ENHANCED: Send achievement notification
  Future<bool> sendAchievementNotification({
    required String achievementType,
    required String achievementName,
    required int streakCount,
  }) async {
    try {
      await _notificationService.sendAchievementNotification(
        achievementType: achievementType,
        achievementName: achievementName,
        streakCount: streakCount,
      );
      
      await loadNotifications();
      return true;
    } catch (e) {
      debugPrint('❌ Error sending achievement notification: $e');
      return false;
    }
  }

  // ENHANCED: Send practice reminder
  Future<bool> sendPracticeReminder({
    required String practiceType,
    required String reminderMessage,
    bool isUrgent = false,
  }) async {
    try {
      await _notificationService.sendPracticeReminder(
        practiceType: practiceType,
        reminderMessage: reminderMessage,
        isUrgent: isUrgent,
      );
      
      await loadNotifications();
      return true;
    } catch (e) {
      debugPrint('❌ Error sending practice reminder: $e');
      return false;
    }
  }

  // ENHANCED: Send admin notification
  Future<bool> sendAdminNotificationToAllUsers({
    required String title,
    required String message,
    String priority = 'normal',
  }) async {
    try {
      final success = await _notificationService.sendAdminNotificationToAllUsers(
        title: title,
        message: message,
        priority: priority,
      );

      if (success) {
        await loadNotifications();
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error sending admin notification: $e');
      return false;
    }
  }

  // Generate monthly reminders
  Future<bool> generateMonthlyReminders() async {
    try {
      await _notificationService.generateMonthlyReminderNotifications();
      await loadNotifications();
      return true;
    } catch (e) {
      debugPrint('❌ Error generating monthly reminders: $e');
      return false;
    }
  }

  // MISSING METHOD: Send test notification - called by notification_test_screen
  Future<bool> sendTestNotification() async {
    try {
      await _notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: '🧪 Test Notification',
        body: 'This is a test notification to check if everything is working!',
        payload: 'test_notification',
      );

      // Also save to Firestore
      await _notificationService.saveNotificationToFirestore(
        title: '🧪 Test Notification',
        message: 'This is a test notification to check if everything is working!',
        type: 'test',
      );

      await loadNotifications();
      debugPrint('✅ Test notification sent successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
      return false;
    }
  }

  // MISSING METHOD: Update monthly reminder status - called by sadhana_provider  
  Future<bool> updateMonthlyReminderStatus() async {
    try {
      await _notificationService.updateMonthlyReminderStatus();
      await loadNotifications();
      return true;
    } catch (e) {
      debugPrint('❌ Error updating monthly reminder status: $e');
      return false;
    }
  }

  // Refresh notifications
  Future<void> refresh() async {
    try {
      await loadNotifications();
      await _checkForNewNotifications();
    } catch (e) {
      debugPrint('❌ Error refreshing notifications: $e');
    }
  }

  // Get notifications by type
  List<Map<String, dynamic>> getNotificationsByType(String type) {
    return _userNotifications.where((n) => n['type'] == type).toList();
  }

  // Check for unread monthly reminders
  bool hasUnreadMonthlyReminders() {
    return _userNotifications.any(
      (n) => n['type'] == 'monthly_reminder' && !(n['isRead'] as bool? ?? true),
    );
  }

  // Check for unread admin notifications
  Future<bool> hasUnreadAdminNotifications() async {
    return _adminNotifications.any((n) => !(n['isRead'] as bool? ?? true));
  }

  /// Get comprehensive notification statistics including system status
  Map<String, dynamic> getNotificationStats() {
    // Removed unused variables userRead and adminRead
    final totalNotifications = _userNotifications.length + _adminNotifications.length;

    return {
      'total': totalNotifications,
      'unread': _unreadCount,
      'read': totalNotifications - _unreadCount,
      'userNotifications': _userNotifications.length,
      'adminNotifications': _adminNotifications.length,
      'hasNewNotifications': _hasNewNotifications,
      'isLoading': _isLoading,
      'isMarkingAllAsRead': _isMarkingAllAsRead,
      'processingCount': _processingNotifications.length,
      'isInitialized': _isInitialized,
      'useImprovedSystem': _useImprovedSystem,
      'migrationInProgress': _migrationInProgress,
      'systemStatus': _useImprovedSystem ? 'improved' : 'legacy',
    };
  }
  
  /// Force migration to improved system (admin function)
  Future<bool> forceMigration() async {
    if (_migrationInProgress || _useImprovedSystem) {
      return _useImprovedSystem;
    }
    
    await _performMigration();
    if (_useImprovedSystem) {
      await loadNotifications();
      await _updateUnreadCount();
    }
    
    return _useImprovedSystem;
  }
  
  /// Check if migration is available
  Future<bool> canMigrate() async {
    if (_useImprovedSystem || _migrationInProgress) {
      return false;
    }
    
    try {
      return await _migrationService.isMigrationNeeded();
    } catch (e) {
      debugPrint('❌ Error checking migration availability: $e');
      return false;
    }
  }

  // Clear all notifications (admin function)
  Future<void> clearAllNotifications() async {
    try {
      _userNotifications.clear();
      _adminNotifications.clear();
      _unreadCount = 0;
      _hasNewNotifications = false;
      _processingNotifications.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }

  @override
  void dispose() {
    _notificationCheckTimer?.cancel();
    _processingNotifications.clear();
    super.dispose();
  }
  
  /// Get migration status information
  Future<Map<String, dynamic>> getMigrationInfo() async {
    try {
      final migrationStatus = await _migrationService.getMigrationStatus();
      return {
        'currentSystem': _useImprovedSystem ? 'improved' : 'legacy',
        'migrationCompleted': _useImprovedSystem,
        'migrationInProgress': _migrationInProgress,
        'canMigrate': !_useImprovedSystem && !_migrationInProgress,
        'migrationStatus': migrationStatus,
      };
    } catch (e) {
      debugPrint('❌ Error getting migration info: $e');
      return {
        'currentSystem': _useImprovedSystem ? 'improved' : 'legacy',
        'migrationCompleted': _useImprovedSystem,
        'migrationInProgress': _migrationInProgress,
        'canMigrate': false,
        'error': e.toString(),
      };
    }
  }
}
