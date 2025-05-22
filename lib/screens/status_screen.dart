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

  // Enhanced Color Palette
  static const Color primaryDeepBlue = Color(0xFF1A237E);
  static const Color primaryIndigo = Color(0xFF3949AB);
  static const Color accentGold = Color(0xFFFFB300);
  static const Color accentLightGold = Color(0xFFFFCC02);
  static const Color softTeal = Color(0xFF4DB6AC);
  static const Color gentleOrange = Color(0xFFFF8A65);
  static const Color lavenderPurple = Color(0xFF9575CD);
  static const Color deepPurple = Color(0xFF512DA8);
  static const Color successGreen = Color(0xFF66BB6A);
  static const Color errorCoral = Color(0xFFEF5350);
  static const Color cardBackground = Color(0x28FFFFFF); // White with 16% opacity
  static const Color cardBorder = Color(0x40FFFFFF); // White with 25% opacity
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xCCFFFFFF); // White with 80% opacity
  static const Color textTertiary = Color(0x99FFFFFF); // White with 60% opacity

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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryDeepBlue,
              primaryIndigo,
              deepPurple,
            ],
            stops: [0.0, 0.6, 1.0],
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
                                color: textPrimary,
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
                                color: textSecondary,
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
                            color: cardBackground,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: cardBorder,
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
                                color: accentLightGold,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                currentMonth,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
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
                      dhyanamStatus,
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
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentGold, Colors.transparent],
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
              color: accentGold,
              iconBackgroundColor: accentGold.withOpacity(0.2),
            ),

            // Total months active card
            _buildSummaryCard(
              title: 'Months Active',
              value:
                  '${completionStats.values.where((count) => count > 0).length}',
              icon: Icons.calendar_month,
              color: softTeal,
              iconBackgroundColor: softTeal.withOpacity(0.2),
            ),

            // Tharpanam completion rate
            _buildSummaryCard(
              title: 'Tharpanam',
              value: '${(completionStats['tharpanam'] ?? 0)} times',
              icon: Icons.water_drop,
              color: softTeal,
              iconBackgroundColor: softTeal.withOpacity(0.2),
            ),

            // Homam completion rate
            _buildSummaryCard(
              title: 'Homam',
              value: '${(completionStats['homam'] ?? 0)} times',
              icon: Icons.local_fire_department,
              color: gentleOrange,
              iconBackgroundColor: gentleOrange.withOpacity(0.2),
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
                color: textTertiary,
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
              color: textPrimary,
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
              color: textSecondary,
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentGold, Colors.transparent],
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
                color: accentGold,
              ),

              const Divider(color: cardBorder, height: 36),

              // Tharpanam status
              _buildStatusItem(
                title: 'Tharpanam',
                isCompleted: tharpanamStatus,
                icon: Icons.water_drop,
                color: softTeal,
              ),

              const Divider(color: cardBorder, height: 36),

              // Homam status
              _buildStatusItem(
                title: 'Homam',
                isCompleted: homamStatus,
                icon: Icons.local_fire_department,
                color: gentleOrange,
              ),

              const Divider(color: cardBorder, height: 36),

              // Dhyanam status
              _buildStatusItem(
                title: 'Dhyanam',
                isCompleted: dhyanamStatus,
                icon: Icons.self_improvement,
                color: lavenderPurple,
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
              color: textPrimary,
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
                    ? successGreen 
                    : errorCoral).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isCompleted 
                    ? successGreen 
                    : errorCoral).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.cancel,
                    color: isCompleted ? successGreen : errorCoral,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCompleted ? 'Completed' : 'Pending',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? successGreen : errorCoral,
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
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentGold, Colors.transparent],
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
                      const Divider(color: cardBorder, height: 32),
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
      progressColor = successGreen;
    } else if (percentage >= 75) {
      progressColor = accentLightGold;
    } else if (percentage >= 50) {
      progressColor = softTeal;
    } else if (percentage >= 25) {
      progressColor = gentleOrange;
    } else {
      progressColor = errorCoral;
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
                accentGold.withOpacity(0.2),
                accentLightGold.withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: accentGold.withOpacity(0.4),
              width: 1.5
            ),
            boxShadow: [
              BoxShadow(
                color: accentGold.withOpacity(0.2),
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
                  color: textPrimary,
                ),
              ),
              Text(
                year,
                style: const TextStyle(
                  fontSize: 12,
                  color: textTertiary,
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
                    softTeal,
                  ),
                  const SizedBox(width: 14),
                  _buildStatusIcon(
                    homamStatus,
                    Icons.local_fire_department,
                    gentleOrange,
                  ),
                  const SizedBox(width: 14),
                  _buildStatusIcon(
                    dhyanamStatus,
                    Icons.self_improvement,
                    lavenderPurple,
                  ),
                  const SizedBox(width: 14),
                  _buildStatusIcon(
                    jebamCount > 0,
                    Icons.format_list_numbered,
                    accentGold,
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
            color: cardBackground,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: cardBorder,
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