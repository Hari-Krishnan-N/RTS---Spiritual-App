import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:math';
import '../providers/sadhana_provider.dart';

class DhaanamScreen extends StatefulWidget {
  const DhaanamScreen({super.key});

  @override
  State<DhaanamScreen> createState() => _DhaanamScreenState();
}

class _DhaanamScreenState extends State<DhaanamScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotateAnimation;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool _dhaanamStatus = false;

  // Wave animation variables
  final List<Map<String, dynamic>> _waves = [];

  // Deep Purple Theme Colors
  final Color _deepPurple = const Color(
    0xFF362358,
  ); // Deep purple from dashboard card
  final Color _lightPurple = const Color(
    0xFF4E3980,
  ); // Light purple from dashboard card
  final Color _accentPurple = const Color(0xFF9C89CF); // Light accent purple

  @override
  void initState() {
    super.initState();

    // Setup animations with reduced intensity for stability
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Reduced rotation angle to minimize visual disruption
    _rotateAnimation = Tween<double>(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Create wave animations
    _createWaves();

    // Initialize status from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SadhanaProvider>(context, listen: false);
      setState(() {
        _dhaanamStatus = provider.dhaanamStatus;
      });

      // Set animation to repeat with slower speed for stability
      _animationController.repeat(
        reverse: true,
        period: const Duration(milliseconds: 2500),
      );
    });

    _animationController.forward();
  }

  void _createWaves() {
    // Create 3 circular waves with different speeds and sizes
    for (int i = 0; i < 3; i++) {
      _waves.add({
        'scale': 0.75 + (i * 0.12),
        'speed': 1.0 + (i * 0.3), // reduced speed difference
        'opacity': 0.7 - (i * 0.15),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SadhanaProvider>(context);

    // Get current month name
    final currentMonthName = DateFormat(
      'MMMM',
    ).format(DateTime(selectedYear, selectedMonth));
    final yearString = selectedYear.toString();

    // Deep purple gradient
    final backgroundGradient = LinearGradient(
      colors: [
        _deepPurple, // Deep purple
        _lightPurple, // Medium purple
        const Color(0xFF644A99), // Lighter purple
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'DHAANAM',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(77), width: 1),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month selector
                  _buildMonthSelector(),

                  const SizedBox(height: 30),

                  // Annual calendar visualization with enhanced design
                  _buildCalendarVisualization(),

                  const SizedBox(height: 40),

                  // Ritual status illustration with fixed size container to prevent layout shifts
                  Center(
                    child: SizedBox(
                      width:
                          200, // Fixed width container to prevent layout shifts
                      height:
                          200, // Fixed height container to prevent layout shifts
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showInformationDialog(context);
                        },
                        child: Stack(
                          clipBehavior:
                              Clip.none, // Allow overflow without affecting layout
                          alignment: Alignment.center,
                          children: [
                            // Waves container with fixed position, using RepaintBoundary for performance
                            RepaintBoundary(
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children:
                                    _waves.map((wave) {
                                      return AnimatedBuilder(
                                        animation: _animationController,
                                        builder: (context, child) {
                                          // Calculate wave scale and opacity
                                          double waveScale =
                                              wave['scale'] +
                                              sin(
                                                    _animationController.value *
                                                        pi *
                                                        wave['speed'],
                                                  ) *
                                                  0.1;

                                          double waveOpacity =
                                              wave['opacity'] *
                                              (1.0 -
                                                  sin(
                                                        _animationController
                                                                .value *
                                                            pi *
                                                            wave['speed'],
                                                      ) *
                                                      0.3);

                                          return Positioned(
                                            // Center position for wave
                                            top: 100 - (100 * waveScale),
                                            left: 100 - (100 * waveScale),
                                            // Fixed width container for wave
                                            child: Opacity(
                                              opacity: waveOpacity,
                                              child: Container(
                                                width: 200 * waveScale,
                                                height: 200 * waveScale,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withAlpha(
                                                          (waveOpacity * 255)
                                                              .toInt(),
                                                        ),
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }).toList(),
                              ),
                            ),

                            // Main icon container with fixed position
                            Container(
                              height: 160,
                              width: 160,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF221540,
                                ), // Deep purple to match theme
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(77),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Static energy ripple background - no animation
                                  Container(
                                    height: 120,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          _accentPurple.withAlpha(153),
                                          _accentPurple.withAlpha(77),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),

                                  // ONLY the charity icon gets animated with RepaintBoundary
                                  RepaintBoundary(
                                    child: AnimatedBuilder(
                                      animation: _rotateAnimation,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: _rotateAnimation.value,
                                          child: ShaderMask(
                                            shaderCallback:
                                                (
                                                  bounds,
                                                ) => const LinearGradient(
                                                  colors: [
                                                    Colors.white,
                                                    Color(0xFFC8B6EC),
                                                    Colors.white,
                                                  ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ).createShader(bounds),
                                            child: const Icon(
                                              Icons.spa_rounded,
                                              size: 80,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Static info icon without animation
                                  Positioned(
                                    right: 30,
                                    bottom: 30,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(77),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.info_outline,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Status text with enhanced typography
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Dhaanam Status',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(77),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$currentMonthName $yearString',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withAlpha(230),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status description with animation
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.2),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        key: ValueKey<bool>(_dhaanamStatus),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              _dhaanamStatus
                                  ? const Color(0xFF2E7D32).withAlpha(51)
                                  : const Color(0xFFC62828).withAlpha(51),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                _dhaanamStatus
                                    ? const Color(0xFF2E7D32).withAlpha(102)
                                    : const Color(0xFFC62828).withAlpha(102),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _dhaanamStatus
                                  ? Icons.check_circle
                                  : Icons.remove_circle_outline,
                              color:
                                  _dhaanamStatus
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFE57373),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                _dhaanamStatus
                                    ? 'You have performed Dhaanam this month'
                                    : 'You have not yet performed Dhaanam this month',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withAlpha(230),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Yes/No buttons with enhanced animations
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Yes button
                      _buildStatusButton(
                        title: 'YES',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF4CAF50), // Brighter green
                        isSelected: _dhaanamStatus,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _dhaanamStatus = true;
                          });
                          provider.updateDhaanamStatus(true);

                          // Show confirmation animation
                          _showStatusUpdateConfirmation(context, true);
                        },
                      ),

                      const SizedBox(width: 20),

                      // No button
                      _buildStatusButton(
                        title: 'NO',
                        icon: Icons.cancel_outlined,
                        color: const Color(0xFFE57373), // Softer red
                        isSelected: !_dhaanamStatus,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _dhaanamStatus = false;
                          });
                          provider.updateDhaanamStatus(false);

                          // Show confirmation animation
                          _showStatusUpdateConfirmation(context, false);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // History section with improved design
                  _buildHistorySection(),

                  // Add padding at the bottom for better scrolling
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return GlassmorphicContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 20,
      blur: 10,
      opacity: 0.15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous month button
          AnimatedIconButton(
            icon: Icons.chevron_left,
            size: 24,
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (selectedMonth > 1) {
                  selectedMonth--;
                } else {
                  selectedMonth = 12;
                  selectedYear--;
                }
                // Update status for the selected month
                _loadMonthStatus();
              });
            },
          ),

          // Current month display
          Column(
            children: [
              Text(
                DateFormat(
                  'MMMM',
                ).format(DateTime(selectedYear, selectedMonth)),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                selectedYear.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withAlpha(204),
                ),
              ),
            ],
          ),

          // Next month button
          AnimatedIconButton(
            icon: Icons.chevron_right,
            size: 24,
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (selectedMonth < 12) {
                  selectedMonth++;
                } else {
                  selectedMonth = 1;
                  selectedYear++;
                }
                // Update status for the selected month
                _loadMonthStatus();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarVisualization() {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      blur: 10,
      opacity: 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Annual View',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withAlpha(51),
                    width: 1,
                  ),
                ),
                child: Text(
                  selectedYear.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final monthName = DateFormat('MMM').format(DateTime(2023, month));

              // Determine if this month has been completed
              bool isCompleted = _getMonthStatus(selectedYear, month);

              // Highlight current month
              bool isCurrentMonth = month == selectedMonth;

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: isCurrentMonth ? 1.05 : scale,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          selectedMonth = month;
                          _loadMonthStatus();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color:
                              isCurrentMonth
                                  ? Colors.white.withAlpha(77)
                                  : Colors.white.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              isCurrentMonth
                                  ? Border.all(color: Colors.white, width: 2)
                                  : Border.all(
                                    color: Colors.white.withAlpha(51),
                                    width: 1,
                                  ),
                          boxShadow:
                              isCurrentMonth
                                  ? [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(26),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              monthName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    isCurrentMonth
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                fontSize: isCurrentMonth ? 16 : 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color:
                                    isCompleted
                                        ? const Color(
                                          0xFF4CAF50,
                                        ).withAlpha(isCurrentMonth ? 102 : 51)
                                        : Colors.white.withAlpha(26),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isCompleted
                                          ? const Color(0xFF4CAF50)
                                          : Colors.white.withAlpha(77),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                isCompleted ? Icons.check : Icons.remove,
                                color:
                                    isCompleted
                                        ? const Color(0xFF4CAF50)
                                        : Colors.white.withAlpha(153),
                                size: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 16),

          // Legend with improved design
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withAlpha(51),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF4CAF50),
                  size: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Completed',
                style: TextStyle(
                  color: Colors.white.withAlpha(204),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(77),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.remove,
                  color: Colors.white.withAlpha(153),
                  size: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Pending',
                style: TextStyle(
                  color: Colors.white.withAlpha(204),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: isSelected ? 1.05 : 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 130,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withAlpha(51),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isSelected
                          ? Colors.white.withAlpha(77)
                          : color.withAlpha(77),
                  width: 1.5,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: color.withAlpha(102),
                            blurRadius: 15,
                            spreadRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                        ]
                        : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : color.withAlpha(204),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : color.withAlpha(204),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistorySection() {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      blur: 10,
      opacity: 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withAlpha(51),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insights,
                      size: 14,
                      color: Colors.white.withAlpha(230),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Last 3 Months',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(230),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Past 3 months history with improved design
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              // Calculate previous months
              int month, year;
              if (selectedMonth - index - 1 <= 0) {
                month = 12 + (selectedMonth - index - 1);
                year = selectedYear - 1;
              } else {
                month = selectedMonth - index - 1;
                year = selectedYear;
              }

              final monthName = DateFormat(
                'MMMM',
              ).format(DateTime(year, month));
              final isCompleted = _getMonthStatus(year, month);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white.withAlpha(26),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withAlpha(51), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Month icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(38),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          month.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Month and year
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              year.toString(),
                              style: TextStyle(
                                color: Colors.white.withAlpha(179),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isCompleted
                                  ? const Color(0xFF4CAF50).withAlpha(51)
                                  : const Color(0xFFE57373).withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isCompleted
                                    ? const Color(0xFF4CAF50).withAlpha(102)
                                    : const Color(0xFFE57373).withAlpha(102),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCompleted
                                  ? Icons.check_circle
                                  : Icons.cancel_outlined,
                              color:
                                  isCompleted
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFE57373),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCompleted ? 'Completed' : 'Missed',
                              style: TextStyle(
                                color:
                                    isCompleted
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFE57373),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateConfirmation(BuildContext context, bool isCompleted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                isCompleted
                    ? 'Dhaanam marked as completed for ${DateFormat('MMMM').format(DateTime(selectedYear, selectedMonth))}'
                    : 'Dhaanam marked as not completed for ${DateFormat('MMMM').format(DateTime(selectedYear, selectedMonth))}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor:
            isCompleted ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          right: 20,
          left: 20,
        ),
      ),
    );
  }

  void _showInformationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 16,
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withAlpha(51),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _deepPurple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.spa_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'About Dhaanam',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF362358),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Dhaanam is the Sanskrit term for charitable giving and donation. '
                        'It represents the act of selfless giving to support others in need, '
                        'cultivate generosity, and create positive karma through compassionate action.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.auto_stories),
                            label: const Text('Learn More'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              // Could add more detailed information in the future
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  bool _getMonthStatus(int year, int month) {
    // Get status for the specific month from provider
    final provider = Provider.of<SadhanaProvider>(context, listen: false);
    final monthKey = DateFormat('MMMM yyyy').format(DateTime(year, month));
    final monthData = provider.getMonthData(monthKey);

    if (monthData != null && monthData.containsKey('dhaanamStatus')) {
      return monthData['dhaanamStatus'] as bool;
    }

    return false;
  }

  void _loadMonthStatus() {
    // Load status for the currently selected month
    final provider = Provider.of<SadhanaProvider>(context, listen: false);
    provider.setActiveMonth(selectedYear, selectedMonth);

    final monthKey = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(selectedYear, selectedMonth));
    final monthData = provider.getMonthData(monthKey);

    if (monthData != null && monthData.containsKey('dhaanamStatus')) {
      setState(() {
        _dhaanamStatus = monthData['dhaanamStatus'] as bool;
      });
    } else {
      setState(() {
        _dhaanamStatus = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Enhanced glassmorphic container with additional properties
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final double opacity;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    required this.padding,
    this.borderRadius = 16.0,
    this.blur = 10.0,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((opacity * 255).toInt()),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withAlpha(51), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// Enhanced animated icon button
class AnimatedIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onPressed;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    required this.size,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        builder: (context, scale, child) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: size),
          );
        },
      ),
    );
  }
}