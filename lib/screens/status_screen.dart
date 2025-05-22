import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // Import for ImageFilter
import '../providers/sadhana_provider.dart';
import '../utils/app_theme.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    final dhyanamStatus = provider.dhyanamStatus;

    // Get current month
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    // Calculate stats
    final completionStats = provider.getCompletionStats();
    final totalJebam = provider.getTotalJebamCount();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.mainGradient,
          image: const DecorationImage(
            image: AssetImage('assets/images/subtle_pattern.png'),
            repeat: ImageRepeat.repeat,
            opacity: 0.05, // Very subtle pattern overlay
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Color(0x40000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              'Track your spiritual journey',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xCCFFFFFF), // White with 80% opacity
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 51),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 77),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                currentMonth,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Summary cards
                    _buildSummarySection(
                      jebamCount,
                      completionStats,
                      totalJebam,
                    ),

                    const SizedBox(height: 30),

                    // Current month status
                    _buildCurrentMonthStatus(
                      jebamCount,
                      tharpanamStatus,
                      homamStatus,
                      dhyanamStatus,
                    ),

                    const SizedBox(height: 30),

                    // Monthly history
                    _buildMonthlyHistory(provider),
                    
                    // Bottom padding
                    const SizedBox(height: 20),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 1,
              width: 40,
              color: Colors.white.withValues(alpha: 128),
            ),
          ],
        ),

        const SizedBox(height: 16),

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
              color: AppTheme.accentColor, // Accent color from theme
              iconBackgroundColor: AppTheme.accentColor.withValues(alpha: 38),
            ),

            // Total months active card
            _buildSummaryCard(
              title: 'Months Active',
              value:
                  '${completionStats.values.where((count) => count > 0).length}',
              icon: Icons.calendar_month,
              color: const Color(0xFF6BAAEC), // Sky blue
              iconBackgroundColor: const Color(0xFF6BAAEC).withValues(alpha: 38),
            ),

            // Tharpanam completion rate
            _buildSummaryCard(
              title: 'Tharpanam',
              value: '${(completionStats['tharpanam'] ?? 0)} times',
              icon: Icons.water_drop,
              color: const Color(0xFF7AC1D0), // Light blue
              iconBackgroundColor: const Color(0xFF7AC1D0).withValues(alpha: 38),
            ),

            // Homam completion rate
            _buildSummaryCard(
              title: 'Homam',
              value: '${(completionStats['homam'] ?? 0)} times',
              icon: Icons.local_fire_department,
              color: const Color(0xFFEE8B5E), // Soft orange
              iconBackgroundColor: const Color(0xFFEE8B5E).withValues(alpha: 38),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 128), // White with 50% opacity
                size: 14,
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 179), // White with 70% opacity
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
    bool dhyanamStatus,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Current Month',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 1,
              width: 40,
              color: Colors.white.withValues(alpha: 128), // White with 50% opacity
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Status cards
        _buildGlassmorphicContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Jebam status
              _buildStatusItem(
                title: 'Jebam',
                value: jebamCount.toString(),
                icon: Icons.format_list_numbered,
                isCount: true,
                color: AppTheme.accentColor, // Accent color from theme
              ),

              const Divider(color: Color(0x40FFFFFF), height: 32), // White with 25% opacity

              // Tharpanam status
              _buildStatusItem(
                title: 'Tharpanam',
                isCompleted: tharpanamStatus,
                icon: Icons.water_drop,
                color: const Color(0xFF7AC1D0), // Light blue
              ),

              const Divider(color: Color(0x40FFFFFF), height: 32), // White with 25% opacity

              // Homam status
              _buildStatusItem(
                title: 'Homam',
                isCompleted: homamStatus,
                icon: Icons.local_fire_department,
                color: const Color(0xFFEE8B5E), // Soft orange
              ),

              const Divider(color: Color(0x40FFFFFF), height: 32), // White with 25% opacity

              // Dhyanam status
              _buildStatusItem(
                title: 'Dhyanam',
                isCompleted: dhyanamStatus,
                icon: Icons.self_improvement,
                color: const Color(0xFF9C89CF), // Light purple
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 51),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 102), 
              width: 1
            ),
          ),
          child: Icon(icon, color: color, size: 20),
        ),

        const SizedBox(width: 16),

        // Title
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),

        // Value or status
        isCount
            ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 51),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 102), 
                  width: 1
                ),
              ),
              child: Text(
                value!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            )
            : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isCompleted! 
                    ? AppTheme.successColor 
                    : AppTheme.errorColor).withValues(alpha: 51),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isCompleted 
                    ? AppTheme.successColor 
                    : AppTheme.errorColor).withValues(alpha: 102),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted ? Icons.check : Icons.close,
                    color: isCompleted ? AppTheme.successColor : AppTheme.errorColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isCompleted ? 'Completed' : 'Pending',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? AppTheme.successColor : AppTheme.errorColor,
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 1,
              width: 40,
              color: Colors.white.withValues(alpha: 128), // White with 50% opacity
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildGlassmorphicContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ...List.generate(
                monthlyData.length,
                (index) => Column(
                  children: [
                    _buildMonthHistoryItem(monthlyData[index]),
                    if (index < monthlyData.length - 1)
                      const Divider(color: Color(0x40FFFFFF), height: 24), // White with 25% opacity
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
    final bool dhyanamStatus = monthData['dhyanamStatus'] ?? false;
    final int jebamCount = monthData['jebamCount'] ?? 0;
    final String monthName = monthData['monthName'] ?? '';
    final String year = monthData['year'] ?? '';

    // Calculate completion percentage
    int completedCount = 0;
    if (tharpanamStatus) completedCount++;
    if (homamStatus) completedCount++;
    if (dhyanamStatus) completedCount++;
    if (jebamCount > 0) completedCount++;

    final int percentage = (completedCount / 4 * 100).round();

    // Calculate progress color based on percentage
    Color progressColor;
    if (percentage == 100) {
      progressColor = AppTheme.successColor;
    } else if (percentage >= 75) {
      progressColor = const Color(0xFF9ECE6A); // Light green
    } else if (percentage >= 50) {
      progressColor = AppTheme.accentColor; // Accent gold
    } else if (percentage >= 25) {
      progressColor = const Color(0xFFEDA756); // Amber/orange
    } else {
      progressColor = AppTheme.errorColor;
    }

    return Row(
      children: [
        // Month indicator
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 38), // Gold with 15% opacity
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.accentColor.withValues(alpha: 77), // Gold with 30% opacity
              width: 1
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                monthName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                year,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 179), // White with 70% opacity
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Status and progress
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.white.withValues(alpha: 51), // White with 20% opacity
                  color: progressColor,
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 8),

              // Status icons row
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildStatusIcon(
                    tharpanamStatus,
                    Icons.water_drop,
                    const Color(0xFF7AC1D0), // Light blue
                  ),
                  const SizedBox(width: 12),
                  _buildStatusIcon(
                    homamStatus,
                    Icons.local_fire_department,
                    const Color(0xFFEE8B5E), // Soft orange
                  ),
                  const SizedBox(width: 12),
                  _buildStatusIcon(
                    dhyanamStatus,
                    Icons.self_improvement,
                    const Color(0xFF9C89CF), // Light purple
                  ),
                  const SizedBox(width: 12),
                  _buildStatusIcon(
                    jebamCount > 0,
                    Icons.format_list_numbered,
                    AppTheme.accentColor, // Gold
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Percentage label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: progressColor.withValues(alpha: 51),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: progressColor.withValues(alpha: 102),
              width: 1,
            ),
          ),
          child: Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 14,
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isCompleted 
            ? color.withValues(alpha: 51)
            : Colors.grey.withValues(alpha: 51), 
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted 
              ? color.withValues(alpha: 102)
              : Colors.grey.withValues(alpha: 102), 
          width: 1,
        ),
      ),
      child: Icon(
        icon, 
        color: isCompleted ? color : Colors.grey.withValues(alpha: 179), 
        size: 14
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
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 38), // White with 15% opacity
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 77), // White with 30% opacity
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 38), // Black with 15% opacity
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}