import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../providers/notification_provider.dart';
import '../utils/app_theme.dart';
import '../utils/safe_ui_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // Load notifications and remove glow effect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      notificationProvider.loadNotifications();
      notificationProvider.onNotificationScreenOpened();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.dashboardGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernHeader(),
              Expanded(
                child: Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return _buildLoadingState();
                    }

                    final notifications = provider.allNotifications;
                    
                    if (notifications.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildNotificationsList(notifications, provider);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        children: [
          // Top row with back button and actions
          Row(
            children: [
              _buildBackButton(),
              const Spacer(),
              _buildMarkAllAsReadButton(),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Title and stats
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              final stats = provider.getNotificationStats();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (provider.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.safeWithOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            '${provider.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    _getStatusMessage(stats),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.safeWithOpacity(0.8),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.safeWithOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.safeWithOpacity(0.2)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMarkAllAsReadButton() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.unreadCount == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: provider.isMarkingAllAsRead ? null : () async {
            HapticFeedback.mediumImpact();
            
            final success = await provider.markAllAsRead();
            
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text('All notifications marked as read!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: provider.isMarkingAllAsRead
                  ? LinearGradient(
                      colors: [
                        Colors.grey.shade600,
                        Colors.grey.shade700,
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        AppTheme.accentColor,
                        AppTheme.accentColor.safeWithOpacity(0.8),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.safeWithOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.isMarkingAllAsRead)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.done_all,
                    color: Colors.white,
                    size: 18,
                  ),
                const SizedBox(width: 8),
                Text(
                  provider.isMarkingAllAsRead ? 'Marking...' : 'Mark All Read',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Loading notifications...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.safeWithOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.safeWithOpacity(0.2), width: 2),
              ),
              child: const Icon(
                Icons.notifications_none_outlined,
                size: 64,
                color: Colors.white60,
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'All caught up! 🎉',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'You have no notifications right now.\nWe\'ll notify you about important updates\nand practice reminders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.safeWithOpacity(0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
    List<Map<String, dynamic>> notifications,
    NotificationProvider provider,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: () => provider.refresh(),
        backgroundColor: Colors.white,
        color: AppTheme.accentColor,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildModernNotificationCard(notification, provider);
          },
        ),
      ),
    );
  }

  Widget _buildModernNotificationCard(
    Map<String, dynamic> notification,
    NotificationProvider provider,
  ) {
    final isAdminNotification = notification['isAdminNotification'] as bool? ?? false;
    final isRead = notification['isRead'] as bool? ?? false;
    final title = notification['title'] as String? ?? 'Notification';
    final message = notification['message'] as String? ?? '';
    final type = notification['type'] as String? ?? 'general';
    final priority = notification['priority'] as int? ?? 0;
    final timestamp = notification['createdAt'] ?? notification['sentAt'];
    final notificationId = notification['id'] as String;

    final iconData = _getIconForType(type, isAdminNotification);
    final colors = _getColorsForType(type, isAdminNotification, priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key(notificationId),
        direction: isRead ? DismissDirection.none : DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.done, color: Colors.white, size: 28),
              const SizedBox(height: 4),
              Text(
                'Mark Read',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: !isRead ? (direction) async {
          HapticFeedback.mediumImpact();
          return true;
        } : null,
        onDismissed: !isRead ? (direction) {
          // Immediately remove from provider to prevent tree errors
          provider.markAsReadAndRemove(notificationId, isAdminNotification);
        } : null,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _showNotificationDetails(notification);
            if (!isRead) {
              provider.markAsRead(notificationId, isAdminNotification);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isRead
                  ? LinearGradient(
                      colors: [
                        Colors.white.safeWithOpacity(0.05),
                        Colors.white.safeWithOpacity(0.08),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.safeWithOpacity(0.15),
                        Colors.white.safeWithOpacity(0.18),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRead
                    ? Colors.white.safeWithOpacity(0.1)
                    : colors['accent']!.safeWithOpacity(0.3),
                width: isRead ? 1 : 2,
              ),
              boxShadow: isRead
                  ? null
                  : [
                      BoxShadow(
                        color: colors['accent']!.safeWithOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors['primary']!,
                            colors['primary']!.safeWithOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colors['primary']!.safeWithOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        iconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and badges row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                    color: Colors.white.safeWithOpacity(isRead ? 0.7 : 1.0),
                                  ),
                                ),
                              ),
                              
                              if (isAdminNotification) _buildAdminBadge(),
                              if (priority > 2) _buildUrgentBadge(),
                            ],
                          ),

                          if (message.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              message,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.safeWithOpacity(isRead ? 0.6 : 0.85),
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Footer row
                          Row(
                            children: [
                              Text(
                                _formatTimestamp(timestamp),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.safeWithOpacity(isRead ? 0.4 : 0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              
                              const Spacer(),
                              
                              _buildStatusIndicator(isRead),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Quick action button for unread notifications
                if (!isRead) ...[
                  const SizedBox(height: 16),
                  _buildQuickActionButton(notificationId, isAdminNotification, provider),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Color(0xFFFFB300)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.safeWithOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Text(
        'ADMIN',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUrgentBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.red, Color(0xFFE53935)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.red.safeWithOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Text(
        'URGENT',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isRead) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isRead 
            ? Colors.blue.safeWithOpacity(0.1)
            : Colors.orange.safeWithOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isRead ? Icons.done_all : Icons.circle,
        size: 16,
        color: isRead ? Colors.blue : Colors.orange,
      ),
    );
  }

  Widget _buildQuickActionButton(
    String notificationId,
    bool isAdminNotification,
    NotificationProvider provider,
  ) {
    final isProcessing = provider.isNotificationProcessing(notificationId);

    return Row(
      children: [
        const Spacer(),
        GestureDetector(
          onTap: isProcessing ? null : () async {
            HapticFeedback.mediumImpact();
            final success = await provider.markAsRead(notificationId, isAdminNotification);
            
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text('Marked as read'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  duration: const Duration(seconds: 1),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: isProcessing
                  ? LinearGradient(
                      colors: [Colors.grey.shade600, Colors.grey.shade700],
                    )
                  : LinearGradient(
                      colors: [Colors.green, Colors.green.shade600],
                    ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.safeWithOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isProcessing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.done, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  isProcessing ? 'Reading...' : 'Mark as Read',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    final isAdminNotification = notification['isAdminNotification'] as bool? ?? false;
    final title = notification['title'] as String? ?? 'Notification';
    final message = notification['message'] as String? ?? '';
    final type = notification['type'] as String? ?? 'general';
    final timestamp = notification['createdAt'] ?? notification['sentAt'];
    final metadata = notification['metadata'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.cardColor,
                AppTheme.cardColor.safeWithOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.safeWithOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.safeWithOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getColorsForType(type, isAdminNotification, 0).values.toList(),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForType(type, isAdminNotification),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _getTypeDisplayName(type),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.safeWithOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (isAdminNotification) _buildAdminBadge(),
                ],
              ),

              const SizedBox(height: 20),

              // Message
              if (message.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.safeWithOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.safeWithOpacity(0.1)),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.safeWithOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Metadata
              if (metadata.isNotEmpty) ...[
                ...metadata.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        '${entry.key}:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.safeWithOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.value.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.safeWithOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ],

              // Timestamp
              Text(
                _formatTimestamp(timestamp),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.safeWithOpacity(0.6),
                ),
              ),

              const SizedBox(height: 24),

              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.accentColor.safeWithOpacity(0.2),
                    foregroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusMessage(Map<String, dynamic> stats) {
    final unread = stats['unread'] as int;
    final total = stats['total'] as int;

    if (total == 0) {
      return 'No notifications yet';
    } else if (unread == 0) {
      return 'All $total notifications read! 🎉';
    } else {
      return '$unread unread of $total notifications';
    }
  }

  IconData _getIconForType(String type, bool isAdminNotification) {
    if (isAdminNotification) return Icons.admin_panel_settings;
    
    switch (type) {
      case 'achievement':
        return Icons.emoji_events;
      case 'practice_reminder':
      case 'monthly_reminder':
        return Icons.event_repeat;
      case 'admin':
        return Icons.campaign;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Map<String, Color> _getColorsForType(String type, bool isAdminNotification, int priority) {
    if (isAdminNotification) {
      return {
        'primary': Colors.amber,
        'accent': Colors.amber.shade300,
      };
    }

    switch (type) {
      case 'achievement':
        return {
          'primary': Colors.purple,
          'accent': Colors.purple.shade300,
        };
      case 'practice_reminder':
      case 'monthly_reminder':
        return {
          'primary': Colors.blue,
          'accent': Colors.blue.shade300,
        };
      case 'admin':
        return {
          'primary': Colors.red,
          'accent': Colors.red.shade300,
        };
      case 'system':
        return {
          'primary': Colors.grey,
          'accent': Colors.grey.shade300,
        };
      default:
        return {
          'primary': AppTheme.accentColor,
          'accent': AppTheme.accentColor.safeWithOpacity(0.7),
        };
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'achievement':
        return 'Achievement';
      case 'practice_reminder':
        return 'Practice Reminder';
      case 'monthly_reminder':
        return 'Monthly Reminder';
      case 'admin':
        return 'Admin Announcement';
      case 'system':
        return 'System Notification';
      default:
        return 'Notification';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Unknown time';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(dateTime);
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}
