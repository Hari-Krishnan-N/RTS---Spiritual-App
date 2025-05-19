import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:math';
import '../providers/sadhana_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/auth_widgets.dart';

class DhyanamScreen extends StatefulWidget {
  const DhyanamScreen({super.key});

  @override
  State<DhyanamScreen> createState() => _DhyanamScreenState();
}

class _DhyanamScreenState extends State<DhyanamScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _breatheAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _breatheAnimation;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  // Particle animation states
  final List<Map<String, dynamic>> _particles = [];
  bool _isAnimatingParticles = false;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _breatheAnimationController = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOut),
    );

    _breatheAnimation = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(
        parent: _breatheAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Generate particles
    _generateParticles();

    _mainAnimationController.forward();
    _breatheAnimationController.repeat(reverse: true);
  }

  void _generateParticles() {
    // Create 30 meditation particles with different properties
    final Random random = Random();
    for (int i = 0; i < 30; i++) {
      _particles.add({
        'x': -100.0 + random.nextDouble() * 200.0, // X position
        'y': -100.0 + random.nextDouble() * 200.0, // Y position
        'size': 3.0 + random.nextDouble() * 5.0, // Size of particle
        'speed': 0.2 + random.nextDouble() * 0.6, // Animation speed
        'opacity': 0.3 + random.nextDouble() * 0.7, // Opacity
        'color':
            random.nextBool()
                ? Colors.deepPurple
                : (random.nextBool()
                    ? Colors.indigo
                    : Colors.blue), // Random color
        'angle': random.nextDouble() * 2 * pi, // Movement angle
      });
    }
  }

  void _animateParticles() {
    if (!_isAnimatingParticles) {
      setState(() {
        _isAnimatingParticles = true;

        // Reset particle positions
        for (int i = 0; i < _particles.length; i++) {
          _particles[i]['x'] = -20.0 + Random().nextDouble() * 40.0;
          _particles[i]['y'] = -20.0 + Random().nextDouble() * 40.0;
          _particles[i]['angle'] = Random().nextDouble() * 2 * pi;
        }
      });

      // Animation loop
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _updateParticles();
        }
      });
    }
  }

  void _updateParticles() {
    if (!mounted || !_isAnimatingParticles) return;

    setState(() {
      bool allParticlesGone = true;

      for (int i = 0; i < _particles.length; i++) {
        // Move particle outward
        double distance = sqrt(
          pow(_particles[i]['x'], 2) + pow(_particles[i]['y'], 2),
        );

        if (distance < 300) {
          allParticlesGone = false;
          _particles[i]['x'] +=
              cos(_particles[i]['angle']) * _particles[i]['speed'] * 3;
          _particles[i]['y'] +=
              sin(_particles[i]['angle']) * _particles[i]['speed'] * 3;

          // Fade out as they move outward
          if (distance > 50) {
            _particles[i]['opacity'] = max(0, _particles[i]['opacity'] - 0.01);
          }
        }
      }

      // Stop animation if all particles are gone
      if (allParticlesGone) {
        _isAnimatingParticles = false;
      }
    });

    // Continue animation loop
    if (_isAnimatingParticles) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _updateParticles();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SadhanaProvider>(context);
    final dhyanamStatus = provider.dhyanamStatus;
    final size = MediaQuery.of(context).size;

    // Get current month name
    final currentMonthName = DateFormat(
      'MMMM',
    ).format(DateTime(selectedYear, selectedMonth));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: const Text(
            'DHYANAM',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF7953D2), // Deep purple
              const Color(0xFF9575CD), // Medium purple
              Colors.indigo.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
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

                      // Meditation illustration with breathing animation
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            _animateParticles();
                            _showMeditationInfoDialog(context);
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow
                              AnimatedBuilder(
                                animation: _breatheAnimationController,
                                builder: (context, child) {
                                  return Container(
                                    width: 220 * _breatheAnimation.value,
                                    height: 220 * _breatheAnimation.value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.deepPurple.withOpacity(0.3),
                                          Colors.indigo.withOpacity(0.1),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.2, 0.6, 1.0],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Particles
                              if (_isAnimatingParticles)
                                ...List.generate(_particles.length, (index) {
                                  return Positioned(
                                    left:
                                        size.width / 2 -
                                        20 +
                                        _particles[index]['x'],
                                    top:
                                        160 +
                                        (_particles[index]['y'] as num)
                                            .toDouble(),
                                    child: Opacity(
                                      opacity: _particles[index]['opacity'],
                                      child: Container(
                                        width: _particles[index]['size'],
                                        height: _particles[index]['size'],
                                        decoration: BoxDecoration(
                                          color: _particles[index]['color'],
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: _particles[index]['color']
                                                  .withOpacity(0.8),
                                              blurRadius: 3,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),

                              // Main circle
                              AnimatedBuilder(
                                animation: _breatheAnimationController,
                                builder: (context, child) {
                                  return Container(
                                    height: 160 * _breatheAnimation.value,
                                    width: 160 * _breatheAnimation.value,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Inner glowing circle
                                        Container(
                                          height: 120 * _breatheAnimation.value,
                                          width: 120 * _breatheAnimation.value,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                Colors.deepPurple.withOpacity(
                                                  0.6,
                                                ),
                                                Colors.deepPurple.withOpacity(
                                                  0.2,
                                                ),
                                                Colors.transparent,
                                              ],
                                              stops: const [0.0, 0.5, 1.0],
                                            ),
                                          ),
                                        ),

                                        // Meditation icon
                                        ShaderMask(
                                          shaderCallback:
                                              (bounds) => const LinearGradient(
                                                colors: [
                                                  Colors.white,
                                                  Colors.white70,
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ).createShader(bounds),
                                          child: Transform.scale(
                                            scale: _breatheAnimation.value,
                                            child: const Icon(
                                              Icons.self_improvement,
                                              size: 100,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),

                                        // "Breathe" text that fades in and out
                                        Positioned(
                                          bottom: 30,
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween<double>(
                                              begin: 0.0,
                                              end: 1.0,
                                            ),
                                            duration: const Duration(
                                              milliseconds: 3000,
                                            ),
                                            curve: Curves.easeInOut,
                                            builder: (context, value, child) {
                                              return Opacity(
                                                opacity: sin(value * pi) * 0.8,
                                                child: const Text(
                                                  "Breathe",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w300,
                                                    letterSpacing: 3.0,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Status section with card design
                      GlassmorphicContainer(
                        child: Column(
                          children: [
                            // Title row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Meditation Status',
                                  style: TextStyle(
                                    fontSize: 20,
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
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    currentMonthName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Status description with animation
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Container(
                                key: ValueKey<bool>(dhyanamStatus),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      dhyanamStatus
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        dhyanamStatus
                                            ? Colors.green.withOpacity(0.4)
                                            : Colors.red.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      dhyanamStatus
                                          ? Icons.check_circle
                                          : Icons.cancel_outlined,
                                      color:
                                          dhyanamStatus
                                              ? Colors.green
                                              : Colors.red,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        dhyanamStatus
                                            ? 'You have practiced meditation this month'
                                            : 'You have not yet practiced meditation this month',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Yes/No buttons with animations
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatusButton(
                                  title: 'YES',
                                  icon: Icons.check_circle_outline,
                                  color: Colors.green,
                                  isSelected: dhyanamStatus,
                                  onTap: () {
                                    provider.updateDhyanamStatus(true);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Dhyanam status updated to YES',
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                _buildStatusButton(
                                  title: 'NO',
                                  icon: Icons.cancel_outlined,
                                  color: Colors.red,
                                  isSelected: !dhyanamStatus,
                                  onTap: () {
                                    provider.updateDhyanamStatus(false);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Dhyanam status updated to NO',
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Monthly practice log with enhanced design
                      _buildMonthlyHistory(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return GlassmorphicContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous month button
          AnimatedIconButton(
            icon: Icons.chevron_left,
            size: 24,
            onPressed: () {
              setState(() {
                if (selectedMonth > 1) {
                  selectedMonth--;
                } else {
                  selectedMonth = 12;
                  selectedYear--;
                }
              });
              // Update provider's active month
              Provider.of<SadhanaProvider>(
                context,
                listen: false,
              ).setActiveMonth(selectedYear, selectedMonth);
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
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),

          // Next month button
          AnimatedIconButton(
            icon: Icons.chevron_right,
            size: 24,
            onPressed: () {
              setState(() {
                if (selectedMonth < 12) {
                  selectedMonth++;
                } else {
                  selectedMonth = 1;
                  selectedYear++;
                }
              });
              // Update provider's active month
              Provider.of<SadhanaProvider>(
                context,
                listen: false,
              ).setActiveMonth(selectedYear, selectedMonth);
            },
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
                color: isSelected ? color : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isSelected
                          ? Colors.white.withOpacity(0.3)
                          : color.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
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
                    color: isSelected ? Colors.white : color.withOpacity(0.8),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : color.withOpacity(0.8),
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

  Widget _buildMonthlyHistory() {
    return GlassmorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly History',
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insights,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$selectedYear',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: 12, // 12 months
            itemBuilder: (context, index) {
              final month = index + 1;
              final monthName = DateFormat('MMM').format(DateTime(2022, month));

              // For demo purposes, randomly assign status
              // In a real app, this would come from stored data
              final bool hasPerformed = (month % 2 == 1);
              final bool isCurrentMonth = month == selectedMonth;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedMonth = month;
                  });
                  // Update provider's active month
                  Provider.of<SadhanaProvider>(
                    context,
                    listen: false,
                  ).setActiveMonth(selectedYear, selectedMonth);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color:
                        isCurrentMonth
                            ? Colors.white.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        isCurrentMonth
                            ? Border.all(color: Colors.white, width: 2)
                            : Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                    boxShadow:
                        isCurrentMonth
                            ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            monthName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  isCurrentMonth
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            hasPerformed
                                ? Icons.check_circle
                                : Icons.cancel_outlined,
                            color: hasPerformed ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ],
                      ),
                      if (isCurrentMonth)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: const Icon(Icons.check, color: Colors.green, size: 12),
              ),
              const SizedBox(width: 4),
              Text(
                'Completed',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 1),
                ),
                child: const Icon(Icons.close, color: Colors.red, size: 10),
              ),
              const SizedBox(width: 4),
              Text(
                'Missed',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMeditationInfoDialog(BuildContext context) {
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
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.self_improvement,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'About Dhyanam',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Dhyanam refers to meditation practice in the Hindu tradition. '
                        'It involves focusing the mind on a particular object, thought, or activity to train attention and awareness.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.deepPurple.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.tips_and_updates,
                              color: Colors.deepPurple,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Regular meditation has been shown to reduce stress, improve focus, and promote emotional well-being.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.auto_stories),
                            label: const Text('Learn More'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
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

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _breatheAnimationController.dispose();
    super.dispose();
  }
}
