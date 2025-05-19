import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math';
import '../providers/sadhana_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/auth_widgets.dart';

class HomamScreen extends StatefulWidget {
  const HomamScreen({super.key});

  @override
  State<HomamScreen> createState() => _HomamScreenState();
}

class _HomamScreenState extends State<HomamScreen>
    with TickerProviderStateMixin {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  late AnimationController _flameController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Fire animation variables
  final List<Map<String, dynamic>> _flames = [];

  @override
  void initState() {
    super.initState();

    _flameController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    // Generate flames for animation
    _generateFlames();

    _fadeController.forward();
  }

  void _generateFlames() {
    // Create multiple flame particles with different properties
    final Random random = Random();
    for (int i = 0; i < 12; i++) {
      _flames.add({
        'x':
            -20.0 + random.nextDouble() * 40.0, // X position relative to center
        'y': 10.0 + random.nextDouble() * 30.0, // Y position (bottom to up)
        'size': 10.0 + random.nextDouble() * 25.0, // Size of flame
        'speed': 0.5 + random.nextDouble() * 1.5, // Animation speed
        'opacity': 0.6 + random.nextDouble() * 0.4, // Opacity
        'color':
            random.nextBool()
                ? AppTheme.deepGold
                : (random.nextBool()
                    ? Colors.orange
                    : Colors.deepOrange), // Random color
      });
    }
  }

  @override
  void dispose() {
    _flameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SadhanaProvider>(context);
    final homamStatus = provider.homamStatus;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: const Text(
            'HOMAM',
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
              AppTheme.primaryColor,
              Colors.deepOrange.shade600,
              Colors.amber.shade700,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                      // Month selector with improved design
                      _buildMonthSelector(),

                      const SizedBox(height: 30),

                      // Animated fire ritual illustration
                      _buildFireAnimation(homamStatus),

                      const SizedBox(height: 40),

                      // Status section with improved design
                      _buildStatusSection(homamStatus),

                      const SizedBox(height: 30),

                      // Monthly history calendar
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 20,
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

                // Update the active month in provider
                Provider.of<SadhanaProvider>(
                  context,
                  listen: false,
                ).setActiveMonth(selectedYear, selectedMonth);
              });
            },
          ),

          // Current month display
          Column(
            children: [
              Text(
                '$selectedMonth/$selectedYear',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "${DateTime(selectedYear, selectedMonth).month}",
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

                // Update the active month in provider
                Provider.of<SadhanaProvider>(
                  context,
                  listen: false,
                ).setActiveMonth(selectedYear, selectedMonth);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFireAnimation(bool homamStatus) {
    return Center(
      child: GestureDetector(
        onTap: () {
          _showInfoDialog(context);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.amber.withOpacity(0.4),
                    Colors.deepOrange.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.2, 0.6, 1.0],
                ),
              ),
            ),

            // Main circle
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Bottom glow for fire
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.amber.withOpacity(0.6),
                          Colors.deepOrange.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),

                  // Animated flames
                  ...List.generate(_flames.length, (index) {
                    return AnimatedBuilder(
                      animation: _flameController,
                      builder: (context, child) {
                        // Calculate animated properties
                        double size =
                            _flames[index]['size'] *
                            (0.8 +
                                sin(
                                      _flameController.value *
                                          pi *
                                          _flames[index]['speed'],
                                    ) *
                                    0.3);

                        double opacity =
                            _flames[index]['opacity'] *
                            (0.7 +
                                sin(
                                      _flameController.value *
                                          pi *
                                          _flames[index]['speed'],
                                    ) *
                                    0.3);

                        return Positioned(
                          left: 80 + (_flames[index]['x'] as num).toDouble(),
                          bottom:
                              80 -
                              _flames[index]['y'] -
                              (sin(
                                    _flameController.value *
                                        pi *
                                        _flames[index]['speed'],
                                  ) *
                                  10),
                          child: Opacity(
                            opacity: homamStatus ? opacity : opacity * 0.3,
                            child: Container(
                              width: size,
                              height: size * 1.5,
                              decoration: BoxDecoration(
                                color: _flames[index]['color'],
                                borderRadius: BorderRadius.circular(size / 2),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  // Fire icon
                  AnimatedBuilder(
                    animation: _flameController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + sin(_flameController.value * pi) * 0.1,
                        child: ShaderMask(
                          shaderCallback:
                              (bounds) => LinearGradient(
                                colors: [
                                  Colors.amber,
                                  Colors.deepOrange,
                                  Colors.red,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(bounds),
                          child: Icon(
                            Icons.local_fire_department_rounded,
                            size: 80,
                            color:
                                homamStatus
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      );
                    },
                  ),

                  // Status indicator
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            homamStatus
                                ? Colors.green.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              homamStatus
                                  ? Colors.green.withOpacity(0.6)
                                  : Colors.grey.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        homamStatus ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          color:
                              homamStatus
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(bool homamStatus) {
    final provider = Provider.of<SadhanaProvider>(context);
    final currentMonth = DateTime(selectedYear, selectedMonth);
    final monthName = "${currentMonth.month}/${currentMonth.year}";

    return GlassmorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Homam Status',
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
                  color:
                      homamStatus
                          ? AppTheme.successColor.withOpacity(0.2)
                          : AppTheme.errorColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        homamStatus
                            ? AppTheme.successColor.withOpacity(0.4)
                            : AppTheme.errorColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      homamStatus ? Icons.check_circle : Icons.cancel_outlined,
                      color:
                          homamStatus
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      homamStatus ? 'Completed' : 'Pending',
                      style: TextStyle(
                        color:
                            homamStatus
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Status description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        homamStatus
                            ? AppTheme.successColor.withOpacity(0.2)
                            : AppTheme.errorColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          homamStatus
                              ? AppTheme.successColor.withOpacity(0.4)
                              : AppTheme.errorColor.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    homamStatus
                        ? Icons.local_fire_department_rounded
                        : Icons.fireplace_outlined,
                    color:
                        homamStatus
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homamStatus ? 'Homam Completed' : 'Homam Not Completed',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        homamStatus
                            ? 'You have successfully performed the Homam ritual for $monthName.'
                            : 'You have not yet performed the Homam ritual for $monthName.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Yes/No buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusButton(
                title: 'YES',
                icon: Icons.check_circle_outline,
                color: AppTheme.successColor,
                isSelected: homamStatus,
                onTap: () {
                  provider.updateHomamStatus(true);
                  _showStatusUpdateConfirmation(context, true);
                },
              ),

              _buildStatusButton(
                title: 'NO',
                icon: Icons.cancel_outlined,
                color: AppTheme.errorColor,
                isSelected: !homamStatus,
                onTap: () {
                  provider.updateHomamStatus(false);
                  _showStatusUpdateConfirmation(context, false);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyHistory() {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemCount: 6, // Last 6 months
            itemBuilder: (context, index) {
              // Calculate month
              int month, year;
              if (selectedMonth - index <= 0) {
                month = 12 + (selectedMonth - index);
                year = selectedYear - 1;
              } else {
                month = selectedMonth - index;
                year = selectedYear;
              }

              final monthName = "$month/$year";

              // Randomly generate status for demo
              // In a real app, this would come from stored data
              final bool hasPerformed = Random().nextBool();

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      monthName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            hasPerformed
                                ? AppTheme.successColor.withOpacity(0.2)
                                : AppTheme.errorColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              hasPerformed
                                  ? AppTheme.successColor.withOpacity(0.4)
                                  : AppTheme.errorColor.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        hasPerformed ? 'Completed' : 'Missed',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              hasPerformed
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
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
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Completed',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Missed',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
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
              width: 120,
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
                    ? 'Homam marked as completed for $selectedMonth/$selectedYear'
                    : 'Homam marked as not completed for $selectedMonth/$selectedYear',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor:
            isCompleted ? AppTheme.successColor : AppTheme.errorColor,
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

  void _showInfoDialog(BuildContext context) {
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
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
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
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Homam is a sacred fire ritual performed to invoke divine energies and create spiritual transformation. '
                        'It involves making offerings into a consecrated fire while reciting specific mantras.',
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
                              backgroundColor: Colors.deepOrange,
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
}
