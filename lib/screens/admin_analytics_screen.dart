import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../services/admin_service.dart';
import '../utils/app_theme.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _error;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadAnalytics();
    _animationController.forward();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final analytics = await _adminService.getMonthlyAnalytics();
      final statistics = await _adminService.getUserStatistics();

      setState(() {
        _analytics = analytics;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              );
            },
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Analytics Dashboard',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadAnalytics,
                      ),
                    ],
                  ),
                ),

                // Tab Selector
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton('Overview', 0),
                      _buildTabButton('Monthly Trends', 1),
                      _buildTabButton('User Activity', 2),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Content
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalytics,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildMonthlyTrendsTab();
      case 2:
        return _buildUserActivityTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildMetricCard(
                'Total Users',
                _statistics?['totalUsers']?.toString() ?? '0',
                Icons.people,
                Colors.blue,
                _statistics?['activeUsers']?.toString() ?? '0' ' active',
              ),
              _buildMetricCard(
                'Total Jebam',
                _formatLargeNumber(_statistics?['totalJebamCount'] ?? 0),
                Icons.format_list_numbered,
                Colors.orange,
                'Across all users',
              ),
              _buildMetricCard(
                'Tharpanam',
                _statistics?['totalTharpanamCompleted']?.toString() ?? '0',
                Icons.water_drop,
                Colors.blue,
                'Completed',
              ),
              _buildMetricCard(
                'Homam',
                _statistics?['totalHomamCompleted']?.toString() ?? '0',
                Icons.local_fire_department,
                Colors.red,
                'Completed',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // User Engagement Chart
          _buildSectionHeader('User Engagement'),
          const SizedBox(height: 16),
          _buildUserEngagementChart(),

          const SizedBox(height: 24),

          // Practice Distribution
          _buildSectionHeader('Practice Distribution'),
          const SizedBox(height: 16),
          _buildPracticeDistributionChart(),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendsTab() {
    final monthlyStats = _analytics?['monthlyStats'] as Map<String, dynamic>? ?? {};
    
    if (monthlyStats.isEmpty) {
      return const Center(
        child: Text(
          'No monthly data available',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    // Sort months chronologically
    final sortedMonths = monthlyStats.keys.toList()
      ..sort((a, b) {
        try {
          final aDate = DateTime.parse('${a.split(' ')[1]}-${_getMonthNumber(a.split(' ')[0])}-01');
          final bDate = DateTime.parse('${b.split(' ')[1]}-${_getMonthNumber(b.split(' ')[0])}-01');
          return aDate.compareTo(bDate);
        } catch (e) {
          return a.compareTo(b);
        }
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Monthly Growth Trends'),
          const SizedBox(height: 16),
          
          // Monthly stats chart
          Container(
            height: 250,
            margin: const EdgeInsets.only(bottom: 24),
            child: _buildMonthlyTrendsChart(sortedMonths, monthlyStats),
          ),

          // Monthly breakdown list
          _buildSectionHeader('Monthly Breakdown'),
          const SizedBox(height: 16),
          
          ...sortedMonths.map((month) {
            final data = monthlyStats[month] as Map<String, int>;
            return _buildMonthlyStatsCard(month, data);
          }),
        ],
      ),
    );
  }

  Widget _buildUserActivityTab() {
    final totalUsers = _statistics?['totalUsers'] ?? 0;
    final activeUsers = _statistics?['activeUsers'] ?? 0;
    final inactiveUsers = _statistics?['inactiveUsers'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('User Activity Overview'),
          const SizedBox(height: 16),

          // Activity summary
          Row(
            children: [
              Expanded(
                child: _buildActivityCard(
                  'Active',
                  activeUsers,
                  totalUsers > 0 ? (activeUsers / totalUsers * 100) : 0,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActivityCard(
                  'Inactive',
                  inactiveUsers,
                  totalUsers > 0 ? (inactiveUsers / totalUsers * 100) : 0,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Activity distribution chart
          _buildSectionHeader('Activity Distribution'),
          const SizedBox(height: 16),
          _buildActivityDistributionChart(),

          const SizedBox(height: 24),

          // Engagement metrics
          _buildSectionHeader('Engagement Metrics'),
          const SizedBox(height: 16),
          _buildEngagementMetrics(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildUserEngagementChart() {
    final totalUsers = _statistics?['totalUsers'] ?? 0;
    final activeUsers = _statistics?['activeUsers'] ?? 0;
    final inactiveUsers = totalUsers - activeUsers;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Pie chart representation
          Expanded(
            flex: 2,
            child: CustomPaint(
              painter: PieChartPainter([
                PieChartData('Active', activeUsers.toDouble(), Colors.green),
                PieChartData('Inactive', inactiveUsers.toDouble(), Colors.red),
              ]),
            ),
          ),
          // Legend
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem('Active Users', Colors.green, activeUsers, totalUsers),
                const SizedBox(height: 8),
                _buildLegendItem('Inactive Users', Colors.red, inactiveUsers, totalUsers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeDistributionChart() {
    final tharpanam = _statistics?['totalTharpanamCompleted'] ?? 0;
    final homam = _statistics?['totalHomamCompleted'] ?? 0;
    final dhaanam = _statistics?['totalDhaanamCompleted'] ?? 0;
    final total = tharpanam + homam + dhaanam;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Bar chart representation
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBarChartBar('Tharpanam', tharpanam, total, Colors.blue),
                _buildBarChartBar('Homam', homam, total, Colors.red),
                _buildBarChartBar('Dhaanam', dhaanam, total, Colors.purple),
              ],
            ),
          ),
          // Values
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildValueItem('Tharpanam', tharpanam, Colors.blue),
                _buildValueItem('Homam', homam, Colors.red),
                _buildValueItem('Dhaanam', dhaanam, Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendsChart(List<String> months, Map<String, dynamic> monthlyStats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: CustomPaint(
        painter: LineChartPainter(months, monthlyStats),
        child: Container(),
      ),
    );
  }

  Widget _buildMonthlyStatsCard(String month, Map<String, int> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            month,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Users', data['totalUsers'] ?? 0, Icons.people),
              _buildStatItem('Jebam', data['jebamTotal'] ?? 0, Icons.format_list_numbered),
              _buildStatItem('Practices', 
                (data['tharpanamCompleted'] ?? 0) + 
                (data['homamCompleted'] ?? 0) + 
                (data['dhaanamCompleted'] ?? 0), 
                Icons.check_circle
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String label, int value, double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDistributionChart() {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: const Center(
        child: Text(
          'Activity Distribution Chart\n(Placeholder for custom chart)',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEngagementMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildMetricRow('Average Jebam per User', 
            _statistics?['totalUsers'] != null && _statistics!['totalUsers'] > 0
              ? (_statistics!['totalJebamCount'] / _statistics!['totalUsers']).toStringAsFixed(1)
              : '0'
          ),
          _buildMetricRow('Practice Completion Rate',
            _statistics?['totalUsers'] != null && _statistics!['totalUsers'] > 0
              ? '${((_statistics!['totalTharpanamCompleted'] + _statistics!['totalHomamCompleted'] + _statistics!['totalDhaanamCompleted']) / (_statistics!['totalUsers'] * 3) * 100).toStringAsFixed(1)}%'
              : '0%'
          ),
          _buildMetricRow('User Retention Rate',
            _statistics?['totalUsers'] != null && _statistics!['totalUsers'] > 0
              ? '${(_statistics!['activeUsers'] / _statistics!['totalUsers'] * 100).toStringAsFixed(1)}%'
              : '0%'
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int value, int total) {
    final percentage = total > 0 ? (value / total * 100) : 0;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                '$value (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartBar(String label, int value, int total, Color color) {
    final height = total > 0 ? (value / total * 120) : 0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: height.toDouble(),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildValueItem(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLargeNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  int _getMonthNumber(String monthName) {
    const months = {
      'January': 1, 'February': 2, 'March': 3, 'April': 4,
      'May': 5, 'June': 6, 'July': 7, 'August': 8,
      'September': 9, 'October': 10, 'November': 11, 'December': 12
    };
    return months[monthName] ?? 1;
  }
}

// Custom painters for charts
class PieChartData {
  final String label;
  final double value;
  final Color color;

  PieChartData(this.label, this.value, this.color);
}

class PieChartPainter extends CustomPainter {
  final List<PieChartData> data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    
    final total = data.fold<double>(0, (sum, item) => sum + item.value);
    if (total == 0) return;

    double startAngle = -math.pi / 2;
    
    for (final item in data) {
      final sweepAngle = (item.value / total) * 2 * math.pi;
      
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  final List<String> months;
  final Map<String, dynamic> monthlyStats;

  LineChartPainter(this.months, this.monthlyStats);

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxValue = months.fold<double>(0, (max, month) {
      final data = monthlyStats[month] as Map<String, int>? ?? {};
      final total = (data['jebamTotal'] ?? 0).toDouble();
      return math.max(max, total);
    });

    if (maxValue == 0) return;

    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      final data = monthlyStats[month] as Map<String, int>? ?? {};
      final value = (data['jebamTotal'] ?? 0).toDouble();
      
      final x = (i / (months.length - 1)) * size.width;
      final y = size.height - (value / maxValue * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}