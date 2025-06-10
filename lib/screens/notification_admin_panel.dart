import 'package:flutter/material.dart';
// Removed unused import: cloud_firestore.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/improved_notification_provider.dart';
import '../services/notification_migration_service.dart';
import '../utils/notification_utils.dart';

/// Admin panel for comprehensive notification management
/// Features:
/// - Send admin notifications to all users
/// - View notification analytics
/// - Manage notification system health
/// - Perform maintenance operations
/// - Monitor user engagement
class NotificationAdminPanel extends StatefulWidget {
  const NotificationAdminPanel({super.key});

  @override
  State<NotificationAdminPanel> createState() => _NotificationAdminPanelState();
}

class _NotificationAdminPanelState extends State<NotificationAdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedPriority = 'normal';
  String _selectedType = 'admin_broadcast';
  
  // State variables
  bool _isLoading = false;
  bool _isSending = false;
  Map<String, dynamic> _analytics = {};
  Map<String, dynamic> _systemHealth = {};
  Map<String, dynamic> _migrationStatus = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _loadAnalytics(),
        _checkSystemHealth(),
        _checkMigrationStatus(),
      ]);
    } catch (e) {
      _showSnackBar('Error loading data: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await NotificationUtils.generateNotificationAnalytics();
      setState(() => _analytics = analytics);
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
  }

  Future<void> _checkSystemHealth() async {
    try {
      final health = await NotificationUtils.testNotificationSystemHealth();
      setState(() => _systemHealth = health);
    } catch (e) {
      debugPrint('Error checking system health: $e');
    }
  }

  Future<void> _checkMigrationStatus() async {
    try {
      final migrationService = NotificationMigrationService();
      final status = await migrationService.getMigrationStatus();
      setState(() => _migrationStatus = status);
    } catch (e) {
      debugPrint('Error checking migration status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Admin Panel'),
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.blue[800],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Send'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.health_and_safety), text: 'Health'),
            Tab(icon: Icon(Icons.transform), text: 'Migration'),
            Tab(icon: Icon(Icons.settings), text: 'Maintenance'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSendNotificationTab(),
                _buildAnalyticsTab(),
                _buildHealthTab(),
                _buildMigrationTab(),
                _buildMaintenanceTab(),
              ],
            ),
    );
  }

  Widget _buildSendNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send Admin Notification',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  // Title field
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Notification Title',
                      hintText: 'Enter notification title...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  
                  // Message field
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Notification Message',
                      hintText: 'Enter notification message...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                    ),
                    maxLines: 4,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 16),
                  
                  // Priority selection
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedPriority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.priority_high),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'low', child: Text('Low Priority')),
                            DropdownMenuItem(value: 'normal', child: Text('Normal Priority')),
                            DropdownMenuItem(value: 'high', child: Text('High Priority')),
                            DropdownMenuItem(value: 'urgent', child: Text('Urgent Priority')),
                          ],
                          onChanged: (value) => setState(() => _selectedPriority = value!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'admin_broadcast', child: Text('Admin Broadcast')),
                            DropdownMenuItem(value: 'system_update', child: Text('System Update')),
                            DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                            DropdownMenuItem(value: 'feature_announcement', child: Text('Feature Announcement')),
                          ],
                          onChanged: (value) => setState(() => _selectedType = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendAdminNotification,
                      icon: _isSending 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isSending ? 'Sending...' : 'Send to All Users'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickActionButton(
                        'App Update Available',
                        'A new version of the app is available with exciting features!',
                        Icons.system_update,
                        'high',
                      ),
                      _buildQuickActionButton(
                        'Scheduled Maintenance',
                        'The app will undergo scheduled maintenance tonight from 2-4 AM.',
                        Icons.build,
                        'normal',
                      ),
                      _buildQuickActionButton(
                        'New Feature: Enhanced UI',
                        'Discover our improved user interface with better navigation and design!',
                        Icons.new_releases,
                        'normal',
                      ),
                      _buildQuickActionButton(
                        'Practice Encouragement',
                        'Keep up your spiritual journey! Your dedication is inspiring.',
                        Icons.favorite,
                        'low',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String title, String message, IconData icon, String priority) {
    return ElevatedButton.icon(
      onPressed: () {
        _titleController.text = title;
        _messageController.text = message;
        _selectedPriority = priority;
      },
      icon: Icon(icon, size: 16),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.grey[700],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notification Analytics',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: _loadAnalytics,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Analytics',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_analytics.isNotEmpty) ...[
            // Overview cards
            Row(
              children: [
                Expanded(child: _buildAnalyticsCard(
                  'Total Notifications',
                  _analytics['totalNotifications']?.toString() ?? '0',
                  Icons.notifications,
                  Colors.blue,
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildAnalyticsCard(
                  'Read Rate',
                  '${_analytics['readRate']?.toStringAsFixed(1) ?? '0'}%',
                  Icons.visibility,
                  Colors.green,
                )),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildAnalyticsCard(
                  'Unread',
                  _analytics['unreadNotifications']?.toString() ?? '0',
                  Icons.mark_email_unread,
                  Colors.orange,
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildAnalyticsCard(
                  'Read',
                  _analytics['readNotifications']?.toString() ?? '0',
                  Icons.mark_email_read,
                  Colors.green,
                )),
              ],
            ),
            const SizedBox(height: 24),
            
            // Type distribution
            if (_analytics['typeDistribution'] != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Types',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ...(_analytics['typeDistribution'] as Map<String, dynamic>).entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatNotificationType(entry.key)),
                              Chip(
                                label: Text(entry.value.toString()),
                                backgroundColor: Colors.blue[100],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Priority distribution
            if (_analytics['priorityDistribution'] != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority Distribution',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ...(_analytics['priorityDistribution'] as Map<String, dynamic>).entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatPriority(int.tryParse(entry.key.toString()) ?? 1)),
                              Chip(
                                label: Text(entry.value.toString()),
                                backgroundColor: _getPriorityColor(int.tryParse(entry.key.toString()) ?? 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.analytics, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No analytics data available'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Health',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: _checkSystemHealth,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Health Check',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_systemHealth.isNotEmpty) ...[
            // Overall health status
            Card(
              color: _systemHealth['overallHealth'] == 'HEALTHY' 
                  ? Colors.green[50] 
                  : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _systemHealth['overallHealth'] == 'HEALTHY' 
                          ? Icons.check_circle 
                          : Icons.error,
                      color: _systemHealth['overallHealth'] == 'HEALTHY' 
                          ? Colors.green 
                          : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Status: ${_systemHealth['overallHealth']}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: _systemHealth['overallHealth'] == 'HEALTHY' 
                                  ? Colors.green[800] 
                                  : Colors.red[800],
                            ),
                          ),
                          if (_systemHealth['testTimestamp'] != null)
                            Text(
                              'Last checked: ${_formatTimestamp(_systemHealth['testTimestamp'])}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Individual health checks
            ..._systemHealth.entries.where((e) => e.key != 'overallHealth' && e.key != 'testTimestamp').map(
              (entry) => Card(
                child: ListTile(
                  leading: Icon(
                    entry.value.toString().startsWith('PASS') 
                        ? Icons.check_circle 
                        : Icons.error,
                    color: entry.value.toString().startsWith('PASS') 
                        ? Colors.green 
                        : Colors.red,
                  ),
                  title: Text(_formatHealthCheckName(entry.key)),
                  subtitle: Text(entry.value.toString()),
                  trailing: Chip(
                    label: Text(
                      entry.value.toString().startsWith('PASS') ? 'PASS' : 'FAIL',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: entry.value.toString().startsWith('PASS') 
                        ? Colors.green[100] 
                        : Colors.red[100],
                  ),
                ),
              ),
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.health_and_safety, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No health data available'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMigrationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Migration Status',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          if (_migrationStatus.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _migrationStatus['migrationCompleted'] == true 
                              ? Icons.check_circle 
                              : Icons.pending,
                          color: _migrationStatus['migrationCompleted'] == true 
                              ? Colors.green 
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _migrationStatus['migrationCompleted'] == true 
                              ? 'Migration Completed' 
                              : 'Migration Pending',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_migrationStatus['migratedAt'] != null)
                      _buildInfoRow('Migration Date', _formatTimestamp(_migrationStatus['migratedAt'])),
                    
                    if (_migrationStatus['migratedNotificationsCount'] != null)
                      _buildInfoRow('Migrated Notifications', _migrationStatus['migratedNotificationsCount'].toString()),
                    
                    if (_migrationStatus['totalNotifications'] != null)
                      _buildInfoRow('Total Notifications', _migrationStatus['totalNotifications'].toString()),
                    
                    if (_migrationStatus['unreadCount'] != null)
                      _buildInfoRow('Unread Count', _migrationStatus['unreadCount'].toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Migration actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Migration Actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    ElevatedButton.icon(
                      onPressed: _performMigration,
                      icon: const Icon(Icons.transform),
                      label: const Text('Perform Migration'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    ElevatedButton.icon(
                      onPressed: _checkMigrationStatus,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.transform, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No migration data available'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maintenance Operations',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Database cleanup
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Database Cleanup',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Remove old notifications and maintain only the last 10 messages per user.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: _performGlobalCleanup,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Perform Global Cleanup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // System test
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Testing',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Test all notification system components to ensure proper functionality.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: _runSystemTest,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Run System Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // User statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Engagement',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'View detailed analytics and user engagement metrics.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: _generateDetailedReport,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Generate Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  // Event handlers
  Future<void> _sendAdminNotification() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      _showSnackBar('Please fill in both title and message', isError: true);
      return;
    }

    if (!NotificationUtils.validateNotificationData(
      title: _titleController.text,
      message: _messageController.text,
      type: _selectedType,
    )) {
      _showSnackBar('Invalid notification data', isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      final provider = context.read<ImprovedNotificationProvider>();
      final success = await provider.sendAdminNotification(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        priority: _selectedPriority,
        metadata: {
          'type': _selectedType,
          'sentBy': FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
          'sentAt': DateTime.now().toIso8601String(),
        },
      );

      if (success) {
        _showSnackBar('Notification sent successfully to all users!');
        _titleController.clear();
        _messageController.clear();
      } else {
        _showSnackBar('Failed to send notification', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error sending notification: $e', isError: true);
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _performMigration() async {
    final confirmed = await _showConfirmationDialog(
      'Perform Migration',
      'This will migrate the notification system to the new structure. Continue?',
    );

    if (confirmed) {
      try {
        final migrationService = NotificationMigrationService();
        final success = await migrationService.performMigration();
        
        if (success) {
          _showSnackBar('Migration completed successfully!');
          await _checkMigrationStatus();
        } else {
          _showSnackBar('Migration failed', isError: true);
        }
      } catch (e) {
        _showSnackBar('Migration error: $e', isError: true);
      }
    }
  }

  Future<void> _performGlobalCleanup() async {
    final confirmed = await _showConfirmationDialog(
      'Global Cleanup',
      'This will delete old notifications for all users, keeping only the last 10 per user. Continue?',
    );

    if (confirmed) {
      try {
        final results = await NotificationUtils.performGlobalCleanup();
        _showSnackBar('Cleanup completed: ${results['totalDeleted']} notifications deleted');
      } catch (e) {
        _showSnackBar('Cleanup error: $e', isError: true);
      }
    }
  }

  Future<void> _runSystemTest() async {
    try {
      _showSnackBar('Running system test...');
      final results = await NotificationUtils.testNotificationSystemHealth();
      
      setState(() => _systemHealth = results);
      
      final isHealthy = results['overallHealth'] == 'HEALTHY';
      _showSnackBar(
        isHealthy ? 'System test passed!' : 'System test found issues',
        isError: !isHealthy,
      );
    } catch (e) {
      _showSnackBar('System test error: $e', isError: true);
    }
  }

  Future<void> _generateDetailedReport() async {
    try {
      _showSnackBar('Generating detailed report...');
      
      // Generate comprehensive analytics
      final analytics = await NotificationUtils.generateNotificationAnalytics(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );
      
      setState(() => _analytics = analytics);
      _tabController.animateTo(1); // Switch to analytics tab
      
      _showSnackBar('Detailed report generated successfully!');
    } catch (e) {
      _showSnackBar('Report generation error: $e', isError: true);
    }
  }

  // Helper methods
  String _formatNotificationType(String type) {
    return type.replaceAll('_', ' ').split(' ').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatPriority(int priority) {
    switch (priority) {
      case 3: return 'High Priority';
      case 2: return 'Medium Priority';
      case 1: return 'Normal Priority';
      default: return 'Low Priority';
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 3: return Colors.red[100]!;
      case 2: return Colors.orange[100]!;
      case 1: return Colors.blue[100]!;
      default: return Colors.grey[100]!;
    }
  }

  String _formatHealthCheckName(String key) {
    return key.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim().split(' ').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM d, y HH:mm').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
