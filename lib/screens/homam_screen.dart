import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:math';
import '../providers/sadhana_provider.dart';

class HomamScreen extends StatefulWidget {
  const HomamScreen({super.key});

  @override
  State<HomamScreen> createState() => _HomamScreenState();
}

class _HomamScreenState extends State<HomamScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotateAnimation;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool _homamStatus = false;

  // Fire animation variables
  final List<Map<String, dynamic>> _flames = [];

  // Homam Theme Colors - from Dashboard card
  final Color _deepRust = const Color(
    0xFF7D3812,
  ); // Deep rust from dashboard card
  final Color _mutedOrange = const Color(
    0xFFA35735,
  ); // Muted orange from dashboard card
  final Color _lightOrange = const Color(0xFFEE8B5E); // Light orange accent

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

    // Create flame animations
    _createFlames();

    // Initialize status from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SadhanaProvider>(context, listen: false);
      setState(() {
        _homamStatus = provider.homamStatus;
      });

      // Set animation to repeat with slower speed for stability
      _animationController.repeat(
        reverse: true,
        period: const Duration(milliseconds: 2500),
      );
    });

    _animationController.forward();
  }

  void _createFlames() {
    // Create 12 flame particles with different properties
    final Random random = Random();
    for (int i = 0; i < 12; i++) {
      _flames.add({
        'x': -20.0 + random.nextDouble() * 40.0, // Random X offset from center
        'y': random.nextDouble() * 20.0, // Random Y offset (bottom to up)
        'size': 5.0 + random.nextDouble() * 15.0, // Random size
        'speed': 0.5 + random.nextDouble() * 1.0, // Random speed
        'opacity': 0.6 + random.nextDouble() * 0.4, // Random opacity
        'color':
            random.nextBool()
                ? _deepRust
                : (random.nextBool() ? _mutedOrange : _lightOrange),
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

    // Homam orange-to-red gradient from dashboard card
    final backgroundGradient = LinearGradient(
      colors: [
        _deepRust, // Deep rust
        _mutedOrange, // Muted orange
        const Color(0xFFB36E4C), // Lighter orange-brown
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'HOMAM',
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

                  // Fire ritual illustration with fixed size container to prevent layout shifts
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
                            // Animated flames with fixed position
                            RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Stack(
                                    alignment: Alignment.center,
                                    children:
                                        _flames.map((flame) {
                                          // Calculate animated flame properties
                                          final double flameX =
                                              flame['x'] as double;
                                          final double flameY =
                                              flame['y'] as double;
                                          final double flameSize =
                                              flame['size'] as double;
                                          final double flameSpeed =
                                              flame['speed'] as double;
                                          final double flameOpacity =
                                              flame['opacity'] as double;

                                          // Calculate animated flame properties
                                          double yOffset =
                                              flameY -
                                              sin(
                                                    _animationController.value *
                                                        pi *
                                                        flameSpeed,
                                                  ) *
                                                  15.0;

                                          double opacity =
                                              flameOpacity *
                                              (0.7 +
                                                  sin(
                                                        _animationController
                                                                .value *
                                                            pi *
                                                            flameSpeed,
                                                      ) *
                                                      0.3);

                                          double size =
                                              flameSize *
                                              (0.8 +
                                                  sin(
                                                        _animationController
                                                                .value *
                                                            pi *
                                                            flameSpeed,
                                                      ) *
                                                      0.2);

                                          return Positioned(
                                            left: 100.0 + flameX,
                                            bottom: 80.0 - yOffset,
                                            child: Opacity(
                                              opacity:
                                                  _homamStatus
                                                      ? opacity
                                                      : opacity * 0.5,
                                              child: Container(
                                                width: size,
                                                height:
                                                    size *
                                                    1.5, // Taller than wide for flame shape
                                                decoration: BoxDecoration(
                                                  color:
                                                      flame['color'] as Color,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        size / 2.0,
                                                      ), // Explicitly use double
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  );
                                },
                              ),
                            ),

                            // Main icon container with fixed position
                            Container(
                              height: 160,
                              width: 160,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF5D2A0E,
                                ), // Deep rust to match theme
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
                                  // Fire glow background
                                  Container(
                                    height: 120,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          _lightOrange.withAlpha(153),
                                          _deepRust.withAlpha(77),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),

                                  // Fire icon with animation
                                  RepaintBoundary(
                                    child: AnimatedBuilder(
                                      animation: _rotateAnimation,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: _rotateAnimation.value,
                                          child: ShaderMask(
                                            shaderCallback:
                                                (bounds) => LinearGradient(
                                                  colors: [
                                                    Colors.amber,
                                                    _lightOrange,
                                                    Colors.amber,
                                                  ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ).createShader(bounds),
                                            child: Icon(
                                              Icons
                                                  .local_fire_department_rounded,
                                              size: 80,
                                              color:
                                                  _homamStatus
                                                      ? Colors.white
                                                      : Colors.white.withAlpha(
                                                        128,
                                                      ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Info icon
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
                          'Homam Status',
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
                        key: ValueKey<bool>(_homamStatus),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              _homamStatus
                                  ? const Color(0xFF2E7D32).withAlpha(51)
                                  : const Color(0xFFC62828).withAlpha(51),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                _homamStatus
                                    ? const Color(0xFF2E7D32).withAlpha(102)
                                    : const Color(0xFFC62828).withAlpha(102),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _homamStatus
                                  ? Icons.check_circle
                                  : Icons.remove_circle_outline,
                              color:
                                  _homamStatus
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFE57373),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                _homamStatus
                                    ? 'You have performed Homam this month'
                                    : 'You have not yet performed Homam this month',
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
                        isSelected: _homamStatus,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _homamStatus = true;
                          });
                          provider.updateHomamStatus(true);

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
                        isSelected: !_homamStatus,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _homamStatus = false;
                          });
                          provider.updateHomamStatus(false);

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
                    ? 'Homam marked as completed for ${DateFormat('MMMM').format(DateTime(selectedYear, selectedMonth))}'
                    : 'Homam marked as not completed for ${DateFormat('MMMM').format(DateTime(selectedYear, selectedMonth))}',
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
                          color: _deepRust,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'About Homam',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7D3812),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Homam is a sacred fire ritual where offerings are made into a consecrated fire. '
                        'It is performed with specific mantras and ingredients to invoke divine energies and create spiritual transformation.',
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
                              backgroundColor: _deepRust,
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

    if (monthData != null && monthData.containsKey('homamStatus')) {
      return monthData['homamStatus'] as bool;
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

    if (monthData != null && monthData.containsKey('homamStatus')) {
      setState(() {
        _homamStatus = monthData['homamStatus'] as bool;
      });
    } else {
      setState(() {
        _homamStatus = false;
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
