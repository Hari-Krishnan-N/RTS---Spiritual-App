# 🔧 NOTIFICATION SYSTEM TROUBLESHOOTING GUIDE

## 🚨 Common Issues & Solutions

### 📱 Notifications Not Appearing

#### Issue: No notifications showing in app
**Symptoms:**
- Empty notification list
- Badge shows 0 count
- No recent notifications

**Diagnosis Steps:**
```dart
// Check provider initialization
final provider = context.read<ImprovedNotificationProvider>();
print('Initialized: ${provider.isInitialized}');
print('System: ${provider.useImprovedSystem ? "Improved" : "Legacy"}');
print('Migration completed: ${provider.migrationCompleted}');

// Check Firebase connection
try {
  final testQuery = await FirebaseFirestore.instance
      .collection('user_notifications')
      .limit(1)
      .get();
  print('Firebase connected: ${testQuery.docs.isNotEmpty}');
} catch (e) {
  print('Firebase error: $e');
}
```

**Solutions:**
1. **Check Authentication:**
   ```dart
   final user = FirebaseAuth.instance.currentUser;
   if (user == null) {
     print('User not authenticated');
     // Redirect to login
   }
   ```

2. **Verify Provider Initialization:**
   ```dart
   // In your main app initialization
   WidgetsBinding.instance.addPostFrameCallback((_) async {
     final provider = context.read<ImprovedNotificationProvider>();
     await provider.initialize();
   });
   ```

3. **Check Firebase Rules:**
   ```javascript
   // Ensure user can read their notifications
   match /user_notifications/{notificationId} {
     allow read: if request.auth != null && 
                    request.auth.uid == resource.data.userId;
   }
   ```

4. **Generate Test Data:**
   ```bash
   dart run lib/utils/notification_sample_data_generator.dart notifications user123
   ```

#### Issue: Real-time updates not working
**Symptoms:**
- Notifications don't appear immediately
- Need to refresh manually
- Outdated counts

**Solutions:**
1. **Check Stream Listeners:**
   ```dart
   // Verify streams are active
   final provider = context.read<ImprovedNotificationProvider>();
   print('Has active listeners: ${provider.statistics['isLoading']}');
   ```

2. **Network Connection:**
   ```dart
   // Check connectivity
   await FirebaseFirestore.instance.enableNetwork();
   
   // Re-initialize if needed
   await provider.refresh();
   ```

3. **Force Refresh:**
   ```dart
   await context.refreshNotifications();
   ```

### 🔄 Migration Issues

#### Issue: Migration not completing
**Symptoms:**
- System shows "Migration in progress"
- Old notifications not transferred
- Performance issues

**Diagnosis:**
```dart
final migrationService = NotificationMigrationService();
final needsMigration = await migrationService.isMigrationNeeded();
final status = await migrationService.getMigrationStatus();
print('Needs migration: $needsMigration');
print('Status: $status');
```

**Solutions:**
1. **Force Migration:**
   ```dart
   final provider = context.read<NotificationProvider>();
   final success = await provider.forceMigration();
   print('Migration success: $success');
   ```

2. **Check Old Data:**
   ```dart
   // Verify old notifications exist
   final oldNotifications = await FirebaseFirestore.instance
       .collection('notifications')
       .where('userId', isEqualTo: currentUserId)
       .get();
   print('Old notifications found: ${oldNotifications.docs.length}');
   ```

3. **Reset Migration Status:**
   ```dart
   // Clear migration metadata
   await FirebaseFirestore.instance
       .collection('notification_metadata')
       .doc(userId)
       .delete();
   
   // Restart app to trigger fresh migration
   ```

4. **Manual Migration:**
   ```dart
   final migrationService = NotificationMigrationService();
   final results = await migrationService.performBulkMigration();
   print('Migration results: $results');
   ```

#### Issue: Data loss during migration
**Symptoms:**
- Notifications missing after migration
- Incorrect read statuses
- Missing metadata

**Recovery Steps:**
1. **Check Backup:**
   ```bash
   # Look for backup collections
   firebase firestore:data --project your-project-id
   ```

2. **Rollback Migration:**
   ```dart
   final migrationService = NotificationMigrationService();
   await migrationService.rollbackMigration();
   ```

3. **Restore from Old Format:**
   ```dart
   // Generate test data to replace lost notifications
   await NotificationSampleDataGenerator.generateMigrationTestData(
     userId: currentUserId,
   );
   ```

### ⚡ Performance Issues

#### Issue: Slow notification loading
**Symptoms:**
- Long loading times (>2 seconds)
- App freezing during notification operations
- High memory usage

**Diagnosis:**
```dart
final startTime = DateTime.now();
await provider.getUserNotifications();
final duration = DateTime.now().difference(startTime);
print('Load time: ${duration.inMilliseconds}ms');

// Check notification count
print('User notifications: ${provider.userNotifications.length}');
print('Admin notifications: ${provider.adminNotifications.length}');
```

**Solutions:**
1. **Check Database Indexes:**
   ```bash
   firebase firestore:indexes --project your-project-id
   ```

2. **Optimize Queries:**
   ```dart
   // Ensure proper limits
   final notifications = await _firestore
       .collection('user_notifications')
       .where('userId', isEqualTo: userId)
       .orderBy('createdAt', descending: true)
       .limit(10) // Ensure limit is applied
       .get();
   ```

3. **Clean Up Old Data:**
   ```dart
   final results = await NotificationUtils.performGlobalCleanup();
   print('Cleaned: ${results['totalDeleted']} notifications');
   ```

4. **Memory Optimization:**
   ```dart
   // Clear provider cache
   await provider.clearAllNotifications();
   await provider.refresh();
   ```

#### Issue: High database usage
**Symptoms:**
- Firestore quota exceeded
- Slow queries
- High billing costs

**Solutions:**
1. **Monitor Query Performance:**
   ```dart
   // Track query performance
   NotificationEnvironmentConfig.trackPerformance(
     'loadNotifications',
     duration,
   );
   ```

2. **Implement Better Caching:**
   ```dart
   // Use provider state instead of repeated queries
   final notifications = context.watch<ImprovedNotificationProvider>()
       .allNotifications;
   ```

3. **Optimize Cleanup:**
   ```dart
   // Run cleanup more frequently in development
   if (NotificationEnvironmentConfig.isDevelopment) {
     await NotificationUtils.performGlobalCleanup();
   }
   ```

### 🛡️ Security Issues

#### Issue: Unauthorized access to notifications
**Symptoms:**
- Users seeing other users' notifications
- Admin panel accessible to non-admins
- Security rule violations in console

**Immediate Actions:**
1. **Check Current Rules:**
   ```bash
   firebase firestore:rules --project your-project-id
   ```

2. **Verify User Authentication:**
   ```dart
   final user = FirebaseAuth.instance.currentUser;
   if (user == null) {
     // Redirect to login immediately
     Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
   }
   ```

3. **Test Security Rules:**
   ```bash
   firebase emulators:start --only firestore
   # Run security rule tests
   ```

**Long-term Solutions:**
1. **Deploy Updated Rules:**
   ```bash
   firebase deploy --only firestore:rules --project your-project-id
   ```

2. **Add Admin Role Verification:**
   ```dart
   Future<bool> isUserAdmin() async {
     final user = FirebaseAuth.instance.currentUser;
     if (user == null) return false;
     
     final adminDoc = await FirebaseFirestore.instance
         .collection('admins')
         .doc(user.uid)
         .get();
     
     return adminDoc.exists;
   }
   ```

3. **Audit Data Access:**
   ```dart
   // Log all sensitive operations
   if (NotificationEnvironmentConfig.enableDebugLogging) {
     print('Admin action: $action by ${user.email}');
   }
   ```

### 📲 Local Notification Issues

#### Issue: Local notifications not showing
**Symptoms:**
- No notification popups
- No sound or vibration
- Notifications appear only in app

**Solutions:**
1. **Check Permissions:**
   ```dart
   final androidImplementation = notificationsPlugin
       .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
   
   final granted = await androidImplementation?.areNotificationsEnabled();
   if (granted != true) {
     // Request permissions
     await androidImplementation?.requestPermission();
   }
   ```

2. **Verify Channel Setup:**
   ```dart
   const AndroidNotificationChannel channel = AndroidNotificationChannel(
     'high_importance_channel',
     'High Importance Notifications',
     importance: Importance.high,
   );
   
   await androidImplementation?.createNotificationChannel(channel);
   ```

3. **Test Local Notifications:**
   ```dart
   await _notificationService.showNotification(
     id: 1,
     title: 'Test Notification',
     body: 'This is a test',
     channelId: 'test_channel',
   );
   ```

### 🎯 Admin Panel Issues

#### Issue: Admin panel not loading
**Symptoms:**
- Blank screen
- "Access denied" errors
- Missing analytics data

**Solutions:**
1. **Verify Admin Status:**
   ```dart
   final isAdmin = await isUserAdmin();
   if (!isAdmin) {
     // Show access denied message
     return AccessDeniedScreen();
   }
   ```

2. **Check Firebase Permissions:**
   ```javascript
   // Ensure admin rules are correct
   function isAdmin() {
     return request.auth != null && 
            exists(/databases/$(database)/documents/admins/$(request.auth.uid));
   }
   ```

3. **Initialize Analytics:**
   ```dart
   final analytics = await NotificationUtils.generateNotificationAnalytics();
   if (analytics.isEmpty) {
     // Generate sample data for testing
     await NotificationSampleDataGenerator.generatePerformanceTestData();
   }
   ```

#### Issue: Admin notifications not reaching users
**Symptoms:**
- Admin sends notification but users don't receive
- No errors shown
- Analytics show 0 deliveries

**Diagnosis:**
```dart
// Check admin notification creation
final adminNotifications = await FirebaseFirestore.instance
    .collection('admin_notifications')
    .orderBy('sentAt', descending: true)
    .limit(5)
    .get();

print('Recent admin notifications: ${adminNotifications.docs.length}');

// Check user notification creation
final userNotifications = await FirebaseFirestore.instance
    .collection('user_notifications')
    .where('fromAdmin', isEqualTo: true)
    .orderBy('createdAt', descending: true)
    .limit(5)
    .get();

print('Admin notifications delivered to users: ${userNotifications.docs.length}');
```

**Solutions:**
1. **Verify User Collection:**
   ```dart
   final users = await FirebaseFirestore.instance
       .collection('users')
       .get();
   print('Total users: ${users.docs.length}');
   ```

2. **Check Batch Operations:**
   ```dart
   // Test batch notification sending
   final results = await NotificationUtils.batchSendNotifications(
     userIds: ['test_user_1', 'test_user_2'],
     title: 'Test Admin Notification',
     message: 'Testing admin broadcast',
     type: 'admin',
   );
   print('Batch send results: $results');
   ```

### 🔧 Development Issues

#### Issue: Hot reload not working with notifications
**Symptoms:**
- Changes not reflected
- Provider state inconsistent
- Streams not updating

**Solutions:**
1. **Restart App:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Reset Provider State:**
   ```dart
   // In development, reset provider
   if (kDebugMode) {
     final provider = context.read<ImprovedNotificationProvider>();
     await provider.clearAllNotifications();
     await provider.initialize();
   }
   ```

3. **Clear Local Storage:**
   ```dart
   // Clear shared preferences in development
   if (kDebugMode) {
     final prefs = await SharedPreferences.getInstance();
     await prefs.clear();
   }
   ```

#### Issue: Testing data interference
**Symptoms:**
- Production data in development
- Test notifications in production
- Inconsistent test results

**Solutions:**
1. **Environment Separation:**
   ```dart
   // Use environment-specific collections
   final collection = NotificationEnvironmentConfig.isDevelopment 
       ? 'dev_user_notifications'
       : 'user_notifications';
   ```

2. **Clean Test Data:**
   ```bash
   dart run lib/utils/notification_sample_data_generator.dart cleanup
   ```

3. **Use Test Users:**
   ```dart
   // Always use test users in development
   if (NotificationEnvironmentConfig.isDevelopment) {
     final testUsers = await NotificationSampleDataGenerator.generateSampleUsers();
     print('Using test users: $testUsers');
   }
   ```

## 🛠️ Diagnostic Tools

### System Health Check
```dart
Future<void> runFullDiagnostic() async {
  print('🔍 Running notification system diagnostic...');
  
  // 1. Check environment
  NotificationEnvironmentConfig.printConfiguration();
  
  // 2. Check authentication
  final user = FirebaseAuth.instance.currentUser;
  print('Authentication: ${user != null ? "✅ OK" : "❌ Failed"}');
  
  // 3. Check Firebase connection
  try {
    await FirebaseFirestore.instance.enableNetwork();
    print('Firebase connection: ✅ OK');
  } catch (e) {
    print('Firebase connection: ❌ Failed - $e');
  }
  
  // 4. Check provider status
  final provider = context.read<ImprovedNotificationProvider>();
  print('Provider initialized: ${provider.isInitialized ? "✅ OK" : "❌ Failed"}');
  print('System type: ${provider.useImprovedSystem ? "Improved" : "Legacy"}');
  
  // 5. Check migration status
  print('Migration completed: ${provider.migrationCompleted ? "✅ OK" : "⚠️ Pending"}');
  
  // 6. Test notification creation
  try {
    final testId = await provider.sendNotification(
      title: '🧪 Diagnostic Test',
      message: 'System diagnostic test notification',
      type: 'test',
    );
    print('Notification creation: ${testId != null ? "✅ OK" : "❌ Failed"}');
  } catch (e) {
    print('Notification creation: ❌ Failed - $e');
  }
  
  // 7. Performance test
  final startTime = DateTime.now();
  await provider.getUserNotifications(limit: 10);
  final loadTime = DateTime.now().difference(startTime);
  print('Load performance: ${loadTime.inMilliseconds}ms ${loadTime.inMilliseconds < 100 ? "✅ OK" : "⚠️ Slow"}');
  
  print('🔍 Diagnostic completed');
}
```

### Quick Fix Commands
```bash
# Reset notification system
flutter clean && flutter pub get

# Clean test data
dart run lib/utils/notification_sample_data_generator.dart cleanup

# Deploy latest rules
firebase deploy --only firestore:rules

# Generate sample data for testing
dart run lib/utils/notification_sample_data_generator.dart performance 10 5

# Check system health
dart run lib/utils/notification_health_check.dart
```

## 📞 Getting Help

### Debug Information Collection
When reporting issues, include this debug information:

```dart
Future<Map<String, dynamic>> collectDebugInfo() async {
  final provider = context.read<ImprovedNotificationProvider>();
  final user = FirebaseAuth.instance.currentUser;
  
  return {
    'timestamp': DateTime.now().toIso8601String(),
    'environment': NotificationEnvironmentConfig.environment,
    'user_id': user?.uid,
    'provider_initialized': provider.isInitialized,
    'system_type': provider.useImprovedSystem ? 'improved' : 'legacy',
    'migration_completed': provider.migrationCompleted,
    'statistics': provider.statistics,
    'flutter_version': 'Get from pubspec.yaml',
    'firebase_version': 'Get from pubspec.yaml',
  };
}
```

### Common Log Patterns
Look for these patterns in your logs:

```
✅ Success patterns:
- "Notification Service initialized successfully"
- "Migration completed successfully"
- "Notification saved with ID: xxx"

❌ Error patterns:
- "Permission denied"
- "Migration failed"
- "Error loading notifications"
- "Firebase connection error"

⚠️ Warning patterns:
- "Migration needed"
- "Old notifications found"
- "Slow query detected"
```

### Support Channels
1. **Documentation**: Check all README files
2. **Code Examples**: Review implementation examples
3. **Test Suite**: Run verification checklist
4. **Performance**: Use diagnostic tools

Remember: Most issues are related to authentication, Firebase rules, or environment configuration. Start with the basics! 🔧
