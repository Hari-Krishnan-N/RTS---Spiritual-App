import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../services/admin_service.dart';
import '../utils/app_theme.dart';
import '../widgets/notification_icon_widget.dart';

class NotificationTestScreen extends StatelessWidget {
  const NotificationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Testing'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: NotificationIconWithGlow(
              onTap: () {
                // Navigate to notifications screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Would navigate to notifications screen'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              size: 28,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.mainGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notification Status',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Unread Count:',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${notificationProvider.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Has New Notifications:',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: notificationProvider.hasNewNotifications
                                      ? Colors.green
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  notificationProvider.hasNewNotifications
                                      ? 'YES'
                                      : 'NO',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Notifications:',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${notificationProvider.userNotifications.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Test Buttons Section
                const Text(
                  'Test Functions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Send Test Notification
                _buildTestButton(
                  context,
                  'Send Test Notification',
                  'Sends a local notification immediately',
                  Icons.notifications_active,
                  () async {
                    try {
                      final notificationProvider = Provider.of<NotificationProvider>(
                        context,
                        listen: false,
                      );
                      await notificationProvider.sendTestNotification();
                      if (context.mounted) {
                        _showSuccessSnackBar(context, 'Test notification sent!');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        _showErrorSnackBar(context, 'Failed to send test notification: $e');
                      }
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Generate Monthly Reminders
                _buildTestButton(
                  context,
                  'Generate Monthly Reminders',
                  'Creates reminders for incomplete practices',
                  Icons.calendar_month,
                  () async {
                    try {
                      final notificationProvider = Provider.of<NotificationProvider>(
                        context,
                        listen: false,
                      );
                      await notificationProvider.generateMonthlyReminders();
                      if (context.mounted) {
                        _showSuccessSnackBar(context, 'Monthly reminders generated!');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        _showErrorSnackBar(context, 'Failed to generate reminders: $e');
                      }
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Send Admin Notification (Admin Only)
                _buildTestButton(
                  context,
                  'Send Admin Notification to All',
                  'Broadcasts a notification to all users',
                  Icons.admin_panel_settings,
                  () async {
                    final adminService = AdminService();
                    if (adminService.isCurrentUserAdmin()) {
                      await _showAdminNotificationDialog(context);
                    } else {
                      _showErrorSnackBar(context, 'Admin access required!');
                    }
                  },
                  isAdminOnly: true,
                ),

                const SizedBox(height: 12),

                // Mark All as Read
                _buildTestButton(
                  context,
                  'Mark All Notifications as Read',
                  'Removes glow effect and marks all as read',
                  Icons.mark_email_read,
                  () async {
                    try {
                      final notificationProvider = Provider.of<NotificationProvider>(
                        context,
                        listen: false,
                      );
                      await notificationProvider.markAllAsRead();
                      if (context.mounted) {
                        _showSuccessSnackBar(context, 'All notifications marked as read!');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        _showErrorSnackBar(context, 'Failed to mark as read: $e');
                      }
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Refresh Notifications
                _buildTestButton(
                  context,
                  'Refresh Notifications',
                  'Reloads notifications from database',
                  Icons.refresh,
                  () async {
                    try {
                      final notificationProvider = Provider.of<NotificationProvider>(
                        context,
                        listen: false,
                      );
                      await notificationProvider.refresh();
                      if (context.mounted) {
                        _showSuccessSnackBar(context, 'Notifications refreshed!');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        _showErrorSnackBar(context, 'Failed to refresh: $e');
                      }
                    }
                  },
                ),

                const SizedBox(height: 24),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Testing Info',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Notifications are set to 1-minute intervals for testing\n'
                        '• Only last 3 months of notifications are stored\n'
                        '• Glow effect appears when new notifications arrive\n'
                        '• Admin notifications go to all users\n'
                        '• Monthly reminders are generated automatically',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onPressed, {
    bool isAdminOnly = false,
  }) {
    final adminService = AdminService();
    final isAdmin = adminService.isCurrentUserAdmin();
    final isEnabled = !isAdminOnly || isAdmin;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isEnabled
              ? [
                  AppTheme.accentColor.withOpacity(0.8),
                  AppTheme.accentColor,
                ]
              : [
                  Colors.grey.withOpacity(0.5),
                  Colors.grey.withOpacity(0.7),
                ],
        ),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isAdminOnly) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAdminNotificationDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Send Admin Notification',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.accentColor),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.accentColor),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  messageController.text.isNotEmpty) {
                Navigator.of(context).pop();
                
                try {
                  final notificationProvider = Provider.of<NotificationProvider>(
                    context,
                    listen: false,
                  );
                  await notificationProvider.sendAdminNotificationToAllUsers(
                    title: titleController.text,
                    message: messageController.text,
                  );
                  if (context.mounted) {
                    _showSuccessSnackBar(context, 'Admin notification sent to all users!');
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showErrorSnackBar(context, 'Failed to send notification: $e');
                  }
                }
              } else {
                _showErrorSnackBar(context, 'Please fill in both title and message');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send to All'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
