import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../providers/improved_notification_provider.dart';
import '../utils/notification_utils.dart';

/// Analytics dashboard widget for notification system insights
/// Features:
/// - Real-time metrics visualization
/// - User engagement tracking
/// - Performance monitoring
/// - Trend analysis
class NotificationAnalyticsDashboard extends StatefulWidget {
  final bool showDetailedCharts;
  final Duration refreshInterval;

  const NotificationAnalyticsDashboard({
    super.key,
    this.showDetailedCharts = true,
    this.refreshInterval = const Duration(minutes: 5),
  });

  @override
  State<NotificationAnalyticsDashboard> createState() => _NotificationAnalyticsDashboardState();
}

class _NotificationAnalyticsDashboardState extends State<NotificationAnalyticsDashboard> {
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(widget.refreshInterval, (_) {
      _loadAnalytics();
    });
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await NotificationUtils.generateNotificationAnalytics(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );
      
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading analytics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildOverviewCards(),
          const SizedBox(height: 20),
          if (widget.showDetailedCharts) ...[
            _buildEngagementChart(),
            const SizedBox(height: 20),
            _buildTypeDistributionChart(),
            const SizedBox(height: 20),
            _buildTrendChart(),
            const SizedBox(height: 20),
          ],
          _buildDetailedMetrics(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Notification Analytics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: _loadAnalytics,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
            ),
            Consumer<ImprovedNotificationProvider>(
              builder: (context, provider, child) {
                return Chip(
                  label: Text(
                    'Live: ${provider.totalUnreadCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.green[100],
                  avatar: Icon(
                    Icons.circle,
                    color: Colors.green,
                    size: 12,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    final total = _analytics['totalNotifications'] as int? ?? 0;
    final unread = _analytics['unreadNotifications'] as int? ?? 0;
    final readRate = _analytics['readRate'] as double? ?? 0.0;
    
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Total Sent',
            value: '$total',
            icon: Icons.send,
            color: Colors.blue,
            subtitle: 'Last 30 days',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Unread',
            value: '$unread',
            icon: Icons.mark_email_unread,
            color: Colors.orange,
            subtitle: '${(unread / (total > 0 ? total : 1) * 100).toStringAsFixed(1)}%',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Read Rate',
            value: '${readRate.toStringAsFixed(1)}%',
            icon: Icons.visibility,
            color: Colors.green,
            subtitle: readRate > 70 ? 'Excellent' : readRate > 50 ? 'Good' : 'Needs improvement',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementChart() {
    final readCount = (_analytics['readNotifications'] as int? ?? 0).toDouble();
    final unreadCount = (_analytics['unreadNotifications'] as int? ?? 0).toDouble();
    
    if (readCount + unreadCount == 0) {
      return _buildNoDataCard('No engagement data available');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engagement Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: readCount,
                      title: 'Read\n${readCount.toInt()}',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: unreadCount,
                      title: 'Unread\n${unreadCount.toInt()}',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDistributionChart() {
    final typeDistribution = _analytics['typeDistribution'] as Map<String, dynamic>? ?? {};
    
    if (typeDistribution.isEmpty) {
      return _buildNoDataCard('No type distribution data available');
    }

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
    final sections = typeDistribution.entries.map((entry) {
      final index = typeDistribution.keys.toList().indexOf(entry.key);
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: (entry.value as num).toDouble(),
        title: '${_formatNotificationType(entry.key)}\n${entry.value}',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 30,
                  sectionsSpace: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    // This would show notification trends over time
    // For now, showing a placeholder
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Trends (Last 7 Days)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Trend chart would show daily notification volumes\n(Requires historical data collection)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // System performance metrics
            Consumer<ImprovedNotificationProvider>(
              builder: (context, provider, child) {
                final stats = provider.statistics;
                return Column(
                  children: [
                    _buildMetricRow('Active Users', stats['total']?.toString() ?? '0'),
                    _buildMetricRow('Total Unread', stats['unread']?.toString() ?? '0'),
                    _buildMetricRow('System Status', provider.migrationCompleted ? 'Improved' : 'Legacy'),
                    _buildMetricRow('Real-time Updates', provider.isLoading ? 'Syncing...' : 'Up to date'),
                  ],
                );
              },
            ),
            
            const Divider(),
            
            // Analytics data
            if (_analytics.isNotEmpty) ...[
              _buildMetricRow('Date Range', _getDateRangeText()),
              _buildMetricRow('Average Daily', _getAverageDailyNotifications()),
              _buildMetricRow('Peak Usage', 'Analysis available in detailed reports'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard(String message) {
    return Card(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNotificationType(String type) {
    return type.replaceAll('_', ' ').split(' ').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _getDateRangeText() {
    final dateRange = _analytics['dateRange'] as Map<String, dynamic>?;
    if (dateRange == null) return 'Unknown';
    
    try {
      final start = DateTime.parse(dateRange['start']);
      final end = DateTime.parse(dateRange['end']);
      return '${_formatDate(start)} - ${_formatDate(end)}';
    } catch (e) {
      return 'Invalid date range';
    }
  }

  String _getAverageDailyNotifications() {
    final total = _analytics['totalNotifications'] as int? ?? 0;
    const days = 30; // Last 30 days
    final average = total / days;
    return '${average.toStringAsFixed(1)} per day';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Performance monitor widget for system health
class NotificationPerformanceMonitor extends StatefulWidget {
  const NotificationPerformanceMonitor({super.key});

  @override
  State<NotificationPerformanceMonitor> createState() => _NotificationPerformanceMonitorState();
}

class _NotificationPerformanceMonitorState extends State<NotificationPerformanceMonitor> {
  Map<String, dynamic> _healthData = {};
  bool _isMonitoring = false;
  Timer? _monitoringTimer;

  @override
  void initState() {
    super.initState();
    _runHealthCheck();
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }

  Future<void> _runHealthCheck() async {
    setState(() => _isMonitoring = true);
    
    try {
      final healthResults = await NotificationUtils.testNotificationSystemHealth();
      setState(() {
        _healthData = healthResults;
        _isMonitoring = false;
      });
    } catch (e) {
      setState(() {
        _healthData = {'error': e.toString()};
        _isMonitoring = false;
      });
    }
  }

  void _startContinuousMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _runHealthCheck();
    });
  }

  void _stopMonitoring() {
    _monitoringTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'System Performance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (_monitoringTimer?.isActive == true)
                      Chip(
                        label: const Text('Live Monitoring'),
                        backgroundColor: Colors.green[100],
                        avatar: Icon(Icons.monitor, size: 16, color: Colors.green),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isMonitoring ? null : _runHealthCheck,
                      icon: _isMonitoring
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_healthData.isEmpty) ...[
              const Center(
                child: Text('No health data available. Run a health check.'),
              ),
            ] else if (_healthData.containsKey('error')) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Health check failed: ${_healthData['error']}',
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Overall status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _healthData['overallHealth'] == 'HEALTHY' 
                      ? Colors.green[50] 
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _healthData['overallHealth'] == 'HEALTHY' 
                        ? Colors.green[200]! 
                        : Colors.red[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _healthData['overallHealth'] == 'HEALTHY' 
                          ? Icons.check_circle 
                          : Icons.error,
                      color: _healthData['overallHealth'] == 'HEALTHY' 
                          ? Colors.green 
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'System Status: ${_healthData['overallHealth']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _healthData['overallHealth'] == 'HEALTHY' 
                            ? Colors.green[800] 
                            : Colors.red[800],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Individual health checks
              ..._healthData.entries
                  .where((e) => e.key != 'overallHealth' && e.key != 'testTimestamp')
                  .map((entry) => _buildHealthCheckRow(entry.key, entry.value.toString())),
              
              const SizedBox(height: 16),
              
              // Monitoring controls
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _monitoringTimer?.isActive == true ? _stopMonitoring : _startContinuousMonitoring,
                    icon: Icon(
                      _monitoringTimer?.isActive == true ? Icons.stop : Icons.play_arrow,
                    ),
                    label: Text(
                      _monitoringTimer?.isActive == true ? 'Stop Monitoring' : 'Start Monitoring',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _monitoringTimer?.isActive == true ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCheckRow(String key, String value) {
    final isPassing = value.startsWith('PASS');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isPassing ? Icons.check_circle : Icons.error,
            color: isPassing ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatHealthCheckName(key),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isPassing ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPassing ? 'PASS' : 'FAIL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isPassing ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHealthCheckName(String key) {
    return key.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim().split(' ').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}
