import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/improved_notification_provider.dart';

/// Enhanced notification screen with proper UI and functionality
/// Features:
/// - Real-time updates via provider
/// - Pull-to-refresh
/// - Mark as read functionality
/// - Proper error handling
/// - Loading states
/// - Pagination support
class ImprovedNotificationScreen extends StatefulWidget {
  const ImprovedNotificationScreen({Key? key}) : super(key: key);

  @override
  State<ImprovedNotificationScreen> createState() => _ImprovedNotificationScreenState();
}

class _ImprovedNotificationScreenState extends State<ImprovedNotificationScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreNotifications();
      }
    });
  }

  Future<void> _initializeNotifications() async {
    final provider = context.read<ImprovedNotificationProvider>();
    await provider.initialize();
    await provider.updateLastCheck();
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    
    final provider = context.read<ImprovedNotificationProvider>();
    await provider.loadMoreUserNotifications();
    
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ImprovedNotificationProvider>(
          builder: (context, provider, child) {
            final unreadCount = provider.totalUnreadCount;
            return Row(
              children: [
                const Text('Notifications'),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          Consumer<ImprovedNotificationProvider>(
            builder: (context, provider, child) {
              if (provider.totalUnreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  tooltip: 'Mark all as read',
                  onPressed: () => _markAllAsRead(provider),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _refreshNotifications(),
          ),
        ],
        backgroundColor: Colors.orange[100],
        foregroundColor: Colors.orange[800],
      ),
      body: Consumer<ImprovedNotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.allNotifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading notifications...'),
                ],
              ),
            );
          }

          if (provider.hasError) {
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
                    provider.errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _refreshNotifications(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.allNotifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'ll see practice reminders and updates here',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshNotifications,
            child: Column(
              children: [
                if (!provider.migrationCompleted)
                  Container(
                    width: double.infinity,
                    color: Colors.orange[100],
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Notification system is being updated...',
                            style: TextStyle(color: Colors.orange[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildStatistics(provider),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: provider.allNotifications.length + 
                        (provider.hasMoreUserNotifications ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.allNotifications.length) {
                        return _buildLoadingMoreIndicator();
                      }
                      
                      final notification = provider.allNotifications[index];
                      return _buildNotificationCard(notification, provider);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatistics(ImprovedNotificationProvider provider) {
    final stats = provider.statistics;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', stats['total']?.toString() ?? '0', Icons.notifications),
          _buildStatItem('Unread', stats['unread']?.toString() ?? '0', Icons.mark_email_unread),
          _buildStatItem('User', provider.userUnreadCount.toString(), Icons.person),
          _buildStatItem('Admin', provider.adminUnreadCount.toString(), Icons.admin_panel_settings),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange[600], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.orange[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.orange[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, ImprovedNotificationProvider provider) {
    final isRead = notification['isRead'] as bool? ?? false;
    final isAdmin = notification['isAdminNotification'] as bool? ?? false;
    final timestamp = notification['createdAt'] ?? notification['sentAt'];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isRead ? 1 : 3,
      color: isRead ? null : Colors.orange[50],
      child: InkWell(
        onTap: () => _onNotificationTap(notification, provider),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildNotificationIcon(notification),
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
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
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
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  _buildPriorityBadge(notification),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(Map<String, dynamic> notification) {
    final type = notification['type'] as String? ?? 'general';
    final isRead = notification['isRead'] as bool? ?? false;
    
    IconData iconData;
    Color iconColor;
    
    switch (type) {
      case 'practice_reminder':
        iconData = Icons.self_improvement;
        iconColor = Colors.green;
        break;
      case 'achievement':
        iconData = Icons.emoji_events;
        iconColor = Colors.amber;
        break;
      case 'admin':
        iconData = Icons.admin_panel_settings;
        iconColor = Colors.blue;
        break;
      case 'monthly_reminder':
        iconData = Icons.calendar_month;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isRead ? iconColor.withOpacity(0.1) : iconColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: isRead ? iconColor.withOpacity(0.6) : iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildPriorityBadge(Map<String, dynamic> notification) {
    final priority = notification['priority'] as int? ?? 1;
    
    if (priority <= 1) return const SizedBox.shrink();
    
    Color badgeColor;
    String label;
    
    switch (priority) {
      case 3:
        badgeColor = Colors.red;
        label = 'HIGH';
        break;
      case 2:
        badgeColor = Colors.orange;
        label = 'MEDIUM';
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? const CircularProgressIndicator()
          : const Text(
              'Tap to load more',
              style: TextStyle(color: Colors.grey),
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
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  Future<void> _onNotificationTap(Map<String, dynamic> notification, ImprovedNotificationProvider provider) async {
    final isRead = notification['isRead'] as bool? ?? false;
    
    if (!isRead) {
      final isAdmin = notification['isAdminNotification'] as bool? ?? false;
      await provider.markAsRead(notification['id'], isAdminNotification: isAdmin);
    }
    
    // Show notification details
    _showNotificationDetails(notification);
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title'] ?? 'Notification'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification['message'] ?? ''),
              const SizedBox(height: 16),
              if (notification['metadata'] != null && 
                  (notification['metadata'] as Map).isNotEmpty) ...[
                const Text(
                  'Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...((notification['metadata'] as Map<String, dynamic>).entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead(ImprovedNotificationProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark All as Read'),
        content: const Text('Are you sure you want to mark all notifications as read?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Mark All Read'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await provider.markAllAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _refreshNotifications() async {
    final provider = context.read<ImprovedNotificationProvider>();
    await provider.refresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
