import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/improved_notification_provider.dart';

/// Reusable notification badge widget that shows unread count
/// Features:
/// - Automatically updates with provider changes
/// - Customizable appearance
/// - Handles large numbers (99+)
/// - Optional glow effect for new notifications
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? fontSize;
  final bool showGlow;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.fontSize,
    this.showGlow = true,
    this.onTap,
    this.padding,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ImprovedNotificationProvider>(
      builder: (context, provider, _) {
        final unreadCount = provider.totalUnreadCount;
        // Note: hasNewNotifications is async in the provider, using local state
        final hasNewNotifications = showGlow && provider.totalUnreadCount > 0;

        if (unreadCount == 0 && !showZero) {
          return GestureDetector(
            onTap: onTap,
            child: child,
          );
        }

        return GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Add glow effect for new notifications
              if (hasNewNotifications)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (badgeColor ?? Colors.red).withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Main child widget
              child,
              
              // Badge
              if (unreadCount > 0 || showZero)
                Positioned(
                  right: -6,
                  top: -6,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    padding: padding ?? const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: badgeColor ?? Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: fontSize ?? 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Notification status indicator showing read/unread status
class NotificationStatusIndicator extends StatelessWidget {
  final bool isRead;
  final double size;
  final Color? readColor;
  final Color? unreadColor;

  const NotificationStatusIndicator({
    super.key,
    required this.isRead,
    this.size = 8,
    this.readColor,
    this.unreadColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isRead 
            ? (readColor ?? Colors.grey[400])
            : (unreadColor ?? Colors.orange),
      ),
    );
  }
}

/// Priority badge for notifications
class NotificationPriorityBadge extends StatelessWidget {
  final int priority;
  final bool compact;

  const NotificationPriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (priority <= 1) return const SizedBox.shrink();

    final config = _getPriorityConfig(priority);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: config['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        config['label'],
        style: TextStyle(
          fontSize: compact ? 8 : 10,
          fontWeight: FontWeight.bold,
          color: config['color'],
        ),
      ),
    );
  }

  Map<String, dynamic> _getPriorityConfig(int priority) {
    switch (priority) {
      case 3:
        return {'color': Colors.red, 'label': 'HIGH'};
      case 2:
        return {'color': Colors.orange, 'label': 'MEDIUM'};
      default:
        return {'color': Colors.blue, 'label': 'NORMAL'};
    }
  }
}

/// Type icon for different notification types
class NotificationTypeIcon extends StatelessWidget {
  final String type;
  final double size;
  final bool isRead;

  const NotificationTypeIcon({
    super.key,
    required this.type,
    this.size = 20,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getTypeConfig(type);
    
    return Container(
      padding: EdgeInsets.all(size * 0.4),
      decoration: BoxDecoration(
        color: isRead 
            ? config['color'].withOpacity(0.1) 
            : config['color'].withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        config['icon'],
        color: isRead 
            ? config['color'].withOpacity(0.6) 
            : config['color'],
        size: size,
      ),
    );
  }

  Map<String, dynamic> _getTypeConfig(String type) {
    switch (type) {
      case 'practice_reminder':
        return {'icon': Icons.self_improvement, 'color': Colors.green};
      case 'achievement':
        return {'icon': Icons.emoji_events, 'color': Colors.amber};
      case 'admin':
        return {'icon': Icons.admin_panel_settings, 'color': Colors.blue};
      case 'monthly_reminder':
        return {'icon': Icons.calendar_month, 'color': Colors.purple};
      case 'system':
        return {'icon': Icons.settings, 'color': Colors.grey};
      case 'milestone':
        return {'icon': Icons.flag, 'color': Colors.green};
      default:
        return {'icon': Icons.notifications, 'color': Colors.grey};
    }
  }
}

/// Notification summary card showing stats
class NotificationSummaryCard extends StatelessWidget {
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const NotificationSummaryCard({
    super.key,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ImprovedNotificationProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistics;
        
        return Card(
          color: backgroundColor,
          margin: padding ?? const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      'Total',
                      stats['total']?.toString() ?? '0',
                      Icons.notifications,
                      Colors.blue,
                    ),
                    _buildStatItem(
                      context,
                      'Unread',
                      stats['unread']?.toString() ?? '0',
                      Icons.mark_email_unread,
                      Colors.orange,
                    ),
                    _buildStatItem(
                      context,
                      'User',
                      provider.userUnreadCount.toString(),
                      Icons.person,
                      Colors.green,
                    ),
                    _buildStatItem(
                      context,
                      'Admin',
                      provider.adminUnreadCount.toString(),
                      Icons.admin_panel_settings,
                      Colors.purple,
                    ),
                  ],
                ),
                
                if (provider.totalUnreadCount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.fiber_new, color: Colors.orange[600], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'You have new notifications!',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

/// Quick actions widget for notifications
class NotificationQuickActions extends StatelessWidget {
  const NotificationQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ImprovedNotificationProvider>(
      builder: (context, provider, child) {
        if (provider.totalUnreadCount == 0) {
          return const SizedBox.shrink();
        }
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction(
                  context,
                  'Mark All Read',
                  Icons.mark_email_read,
                  Colors.green,
                  () => _markAllAsRead(context, provider),
                ),
                _buildQuickAction(
                  context,
                  'View All',
                  Icons.list,
                  Colors.blue,
                  () => Navigator.pushNamed(context, '/notifications'),
                ),
                if (provider.totalUnreadCount > 0)
                  _buildQuickAction(
                    context,
                    'Clear New',
                    Icons.clear_all,
                    Colors.orange,
                    () => provider.updateLastCheck(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAllAsRead(
    BuildContext context,
    ImprovedNotificationProvider provider,
  ) async {
    final success = await provider.markAllAsRead();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'All notifications marked as read'
                : 'Failed to mark notifications as read',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

/// Loading indicator for notifications
class NotificationLoadingIndicator extends StatelessWidget {
  final String message;

  const NotificationLoadingIndicator({
    super.key,
    this.message = 'Loading notifications...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state widget for notifications
class NotificationEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onRefresh;

  const NotificationEmptyState({
    super.key,
    this.title = 'No notifications yet',
    this.subtitle = 'You\'ll see practice reminders and updates here',
    this.icon = Icons.notifications_none,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (onRefresh != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state widget for notifications
class NotificationErrorState extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const NotificationErrorState({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Notification item widget for lists
class NotificationListItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final bool showActions;

  const NotificationListItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification['isRead'] as bool? ?? false;
    final isAdmin = notification['isAdminNotification'] as bool? ?? false;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isRead ? 1 : 3,
      color: isRead ? null : Colors.orange[50],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NotificationTypeIcon(
                    type: notification['type'] ?? 'general',
                    isRead: isRead,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['title'] ?? 'Notification',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  NotificationStatusIndicator(isRead: isRead),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification['message'] ?? '',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTimestamp(notification['createdAt'] ?? notification['sentAt']),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NotificationPriorityBadge(
                        priority: notification['priority'] as int? ?? 1,
                        compact: true,
                      ),
                      if (showActions && !isRead && onMarkAsRead != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onMarkAsRead,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.mark_email_read,
                              size: 16,
                              color: Colors.green[600],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
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
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Notification floating action button with badge
class NotificationFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const NotificationFAB({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      badgeColor: Colors.red,
      showGlow: true,
      child: FloatingActionButton(
        onPressed: onPressed ?? () => Navigator.pushNamed(context, '/notifications'),
        backgroundColor: backgroundColor ?? Colors.orange,
        foregroundColor: foregroundColor ?? Colors.white,
        child: const Icon(Icons.notifications),
      ),
    );
  }
}
