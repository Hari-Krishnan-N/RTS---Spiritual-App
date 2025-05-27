import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // Import for ImageFilter
import '../providers/sadhana_provider.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Profile Screen Theme Colors (matching profile_screen.dart)
  static const Color _primaryDark = Color(0xFF0D2B3E);    // Deep teal/midnight blue
  static const Color _primaryMedium = Color(0xFF1A4A6E);  // Medium teal blue
  static const Color _primaryLight = Color(0xFF2A5E80);   // Slightly lighter blue
  static const Color _accentColor = Color(0xFFD8B468);    // Gentle gold/amber
  static const Color _accentLightGold = Color(0xFFDAB35C); // Slightly brighter gold
  static const Color _errorColor = Color(0xFFCF6679);     // Soft rose for errors
  static const Color _textColor = Colors.white;
  static const Color _textSecondary = Color(0xCCFFFFFF);  // White with 80% opacity
  static const Color _textTertiary = Color(0x99FFFFFF);   // White with 60% opacity
  static const Color _inputBgColor = Color(0x26FFFFFF);   // White with 15% opacity
  static const Color _cardBorder = Color(0x40FFFFFF);     // White with 25% opacity
  
  // Additional colors for different statuses
  static const Color _successGreen = Color(0xFF66BB6A);
  static const Color _softTeal = Color(0xFF4DB6AC);
  static const Color _gentleOrange = Color(0xFFFF8A65);
  static const Color _lavenderPurple = Color(0xFF9575CD);

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SadhanaProvider>(context);
    final jebamCount = provider.jebamCount;
    final tharpanamStatus = provider.tharpanamStatus;
    final homamStatus = provider.homamStatus;
    final dhaanamStatus = provider.dhaanamStatus;

    // Get current month
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    // Calculate stats
    final completionStats = provider.getCompletionStats();
    final totalJebam = provider.getTotalJebamCount();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _primaryDark,
              _primaryMedium,
              _primaryLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          image: const DecorationImage(
            image: AssetImage('assets/images/subtle_pattern.png'),
            repeat: ImageRepeat.repeat,
            opacity: 0.05,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with animated title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MY PROGRESS',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _textColor,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Color(0x60000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              'Track your spiritual journey',
                              style: TextStyle(
                                fontSize: 16,
                                color: _textSecondary,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _inputBgColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _cardBorder,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: _accentColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                currentMonth,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Summary cards
                    _buildSummarySection(
                      jebamCount,
                      completionStats,
                      totalJebam,
                    ),

                    const SizedBox(height: 32),

                    // Current month status
                    _buildCurrentMonthStatus(
                      jebamCount,
                      tharpanamStatus,
                      homamStatus,
                      dhaanamStatus,
                    ),

                    const SizedBox(height: 32),

                    // Monthly history
                    _buildMonthlyHistory(provider),
                    
                    // Bottom padding
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(
    int jebamCount,
    Map<String, int> completionStats,
    int totalJebam,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accentColor, Colors.transparent],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Summary cards grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            // Total Jebam card
            _buildSummaryCard(
              title: 'Total Jebam',
              value: totalJebam.toString(),
              icon: Icons.format_list_numbered,
              color: _accentColor,
              iconBackgroundColor: _accentColor.withOpacity(0.2),
            ),

            // Total months active card
            _buildSummaryCard(
              title: 'Months Active',
              value:
                  '${completionStats.values.where((count) => count > 0).length}',
              icon: Icons.calendar_month,
              color: _softTeal,
              iconBackgroundColor: _softTeal.withOpacity(0.2),
            ),

            // Tharpanam completion rate
            _buildSummaryCard(
              title: 'Tharpanam',
              value: '${(completionStats['tharpanam'] ?? 0)} times',
              icon: Icons.water_drop,
              color: _softTeal,
              iconBackgroundColor: _softTeal.withOpacity(0.2),
            ),

            // Homam completion rate
            _buildSummaryCard(
              title: 'Homam',
              value: '${(completionStats['homam'] ?? 0)} times',
              icon: Icons.local_fire_department,
              color: _gentleOrange,
              iconBackgroundColor: _gentleOrange.withOpacity(0.2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color iconBackgroundColor,
  }) {
    return _buildGlassmorphicContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Icon(
                Icons.trending_up,
                color: _textTertiary,
                size: 16,
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _textColor,
              shadows: [
                Shadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: _textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMonthStatus(
    int jebamCount,
    bool tharpanamStatus,
    bool homamStatus,
    bool dhaanamStatus,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Current Month',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accentColor, Colors.transparent],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Status cards
        _buildGlassmorphicContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Jebam status
              _buildStatusItem(
                title: 'Jebam',
                value: jebamCount.toString(),
                icon: Icons.format_list_numbered,
                isCount: true,
                color: _accentColor,
              ),

              const Divider(color: _cardBorder, height: 36),

              // Tharpanam status
              _buildStatusItem(
                title: 'Tharpanam',
                isCompleted: tharpanamStatus,
                icon: Icons.water_drop,
                color: _softTeal,
              ),

              const Divider(color: _cardBorder, height: 36),

              // Homam status
              _buildStatusItem(
                title: 'Homam',
                isCompleted: homamStatus,
                icon: Icons.local_fire_department,
                color: _gentleOrange,
              ),

              const Divider(color: _cardBorder, height: 36),

              // Dhaanam status
              _buildStatusItem(
                title: 'Dhaanam',
                isCompleted: dhaanamStatus,
                icon: Icons.spa_rounded,
                color: _lavenderPurple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem({
    required String title,
    String? value,
    bool? isCompleted,
    required IconData icon,
    required Color color,
    bool isCount = false,
  }) {
    return Row(
      children: [
        // Icon container
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3), 
              width: 2
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 22),
        ),

        const SizedBox(width: 20),

        // Title
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
        ),

        // Value or status
        isCount
            ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.3), 
                  width: 1.5
                ),
              ),
              child: Text(
                value!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            )
            : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (isCompleted! 
                    ? _successGreen 
                    : _errorColor).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isCompleted 
                    ? _successGreen 
                    : _errorColor).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.cancel,
                    color: isCompleted ? _successGreen : _errorColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCompleted ? 'Completed' : 'Pending',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? _successGreen : _errorColor,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildMonthlyHistory(SadhanaProvider provider) {
    // Get past 6 months of data
    final List<Map<String, dynamic>> monthlyData = [];

    // Current month
    final now = DateTime.now();

    // Generate 6 months of data (including current)
    for (int i = 0; i < 6; i++) {
      final month = now.month - i <= 0 ? now.month - i + 12 : now.month - i;
      final year = now.month - i <= 0 ? now.year - 1 : now.year;
      final monthKey = DateFormat('MMMM yyyy').format(DateTime(year, month));

      final data = provider.getMonthData(monthKey) ?? {};
      data['monthName'] = DateFormat('MMM').format(DateTime(year, month));
      data['year'] = year.toString();

      monthlyData.add(data);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Monthly History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accentColor, Colors.transparent],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        _buildGlassmorphicContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ...List.generate(
                monthlyData.length,
                (index) => Column(
                  children: [
                    _buildMonthHistoryItem(monthlyData[index]),
                    if (index < monthlyData.length - 1)
                      const Divider(color: _cardBorder, height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthHistoryItem(Map<String, dynamic> monthData) {
    final bool tharpanamStatus = monthData['tharpanamStatus'] ?? false;
    final bool homamStatus = monthData['homamStatus'] ?? false;
    final bool dhaanamStatus = monthData['dhaanamStatus'] ?? false;
    final int jebamCount = monthData['jebamCount'] ?? 0;
    final String monthName = monthData['monthName'] ?? '';
    final String year = monthData['year'] ?? '';

    // Calculate completion percentage
    int completedCount = 0;
    if (tharpanamStatus) completedCount++;
    if (homamStatus) completedCount++;
    if (dhaanamStatus) completedCount++;
    if (jebamCount > 0) completedCount++;

    final int percentage = (completedCount / 4 * 100).round();

    // Calculate progress color based on percentage
    Color progressColor;
    if (percentage == 100) {
      progressColor = _successGreen;
    } else if (percentage >= 75) {
      progressColor = _accentLightGold;
    } else if (percentage >= 50) {
      progressColor = _softTeal;
    } else if (percentage >= 25) {
      progressColor = _gentleOrange;
    } else {
      progressColor = _errorColor;
    }

    return Row(
      children: [
        // Month indicator
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _accentColor.withOpacity(0.2),
                _accentLightGold.withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: _accentColor.withOpacity(0.4),
              width: 1.5
            ),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                monthName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              Text(
                year,
                style: const TextStyle(
                  fontSize: 12,
                  color: _textTertiary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Status and progress
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  color: progressColor,
                  minHeight: 10,
                ),
              ),

              const SizedBox(height: 12),

              // Status icons row
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildStatusIcon(
                    tharpanamStatus,
                    Icons.water_drop,
                    _softTeal,
                  ),
                  const SizedBox(width: 14),
                  _buildStatusIcon(
                    homamStatus,
                    Icons.local_fire_department,
                    _gentleOrange,
                  ),
                  const SizedBox(width: 14),
                  _buildStatusIcon(
                    dhaanamStatus,
                    Icons.spa_rounded,
                    _lavenderPurple,
                  ),
                  const SizedBox(width: 14),
                  _buildStatusIcon(
                    jebamCount > 0,
                    Icons.format_list_numbered,
                    _accentColor,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Percentage label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: progressColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: progressColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: progressColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(bool isCompleted, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isCompleted 
            ? color.withOpacity(0.2)
            : Colors.grey.withOpacity(0.15), 
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted 
              ? color.withOpacity(0.4)
              : Colors.grey.withOpacity(0.3), 
          width: 1.5,
        ),
        boxShadow: isCompleted ? [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ] : [],
      ),
      child: Icon(
        icon, 
        color: isCompleted ? color : Colors.grey.withOpacity(0.6), 
        size: 16
      ),
    );
  }
  
  // Helper method to build glassmorphic container
  Widget _buildGlassmorphicContainer({
    Widget? child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    double borderRadius = 24,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _inputBgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: _cardBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                blurRadius: 1,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}