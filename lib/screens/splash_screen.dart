import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/sadhana_provider.dart';
import '../services/admin_service.dart';
import '../utils/app_theme.dart';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

  // Add particle animation states
  final List<Map<String, dynamic>> _particles = [];
  Timer? _particleTimer;
  
  // Admin service for checking admin status
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Generate particles
    _generateParticles();

    // Start particle animation
    _particleTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _updateParticles();
        });
      }
    });

    // Check auth state after a delay
    Future.delayed(const Duration(seconds: 3), () { 
      _checkAuthState();
    });
  }

  void _generateParticles() {
    // Create 20 animated particles
    for (int i = 0; i < 20; i++) {
      _particles.add({
        'x': -100.0 + (Random().nextDouble() * 200), // Random x position
        'y': -100.0 + (Random().nextDouble() * 200), // Random y position
        'size': 2.0 + (Random().nextDouble() * 6), // Random size
        'speed': 0.5 + (Random().nextDouble() * 1.5), // Random speed
        'opacity': 0.1 + (Random().nextDouble() * 0.6), // Random opacity
      });
    }
  }

  void _updateParticles() {
    for (int i = 0; i < _particles.length; i++) {
      // Move particles outward
      double distance = sqrt(
        pow(_particles[i]['x'], 2) + pow(_particles[i]['y'], 2),
      );
      if (distance < 200) {
        double angle = atan2(_particles[i]['y'], _particles[i]['x']);
        _particles[i]['x'] += cos(angle) * _particles[i]['speed'];
        _particles[i]['y'] += sin(angle) * _particles[i]['speed'];
      } else {
        // Reset particle if it goes too far
        _particles[i]['x'] = -20.0 + (Random().nextDouble() * 40);
        _particles[i]['y'] = -20.0 + (Random().nextDouble() * 40);
        _particles[i]['opacity'] = 0.1 + (Random().nextDouble() * 0.6);
      }
    }
  }

  void _checkAuthState() {
    final sadhanaProvider = Provider.of<SadhanaProvider>(
      context,
      listen: false,
    );
    
    if (sadhanaProvider.isLoggedIn) {
      // Check if user is admin and navigate accordingly
      if (_adminService.isCurrentUserAdmin()) {
        debugPrint('Admin user detected: ${_adminService.getCurrentAdminUser()?.email}');
        // Admin users still go to dashboard, but with admin access
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // Regular user navigation
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isSmallDevice = size.width < 360;
    
    // Responsive dimensions
    final logoSize = isTablet ? 220.0 : (isSmallDevice ? 140.0 : 180.0);
    final iconSize = isTablet ? 120.0 : (isSmallDevice ? 80.0 : 100.0);
    final glowSize = isTablet ? 300.0 : (isSmallDevice ? 200.0 : 250.0);
    
    // Responsive font size
    final titleFontSize = isTablet ? 32.0 : (isSmallDevice ? 22.0 : 28.0);
    
    // Responsive spacing
    final verticalSpacing1 = size.height * 0.05; // 5% of screen height
    final verticalSpacing2 = size.height * 0.08; // 8% of screen height

    // Check if admin is detected for special effects
    final isAdminDetected = _adminService.isCurrentUserAdmin();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isAdminDetected 
                ? [
                    // Special admin gradient with gold accents
                    AppTheme.primaryColor,
                    const Color(0xFF1A4A6E),
                    const Color(0xFFD8B468),
                    AppTheme.softGold.withOpacity(0.9),
                  ]
                : [
                    AppTheme.primaryColor,
                    AppTheme.primaryLightColor,
                    AppTheme.softGold.withOpacity(0.9),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Particles with responsive positioning
                ...List.generate(_particles.length, (index) {
                  return Positioned(
                    left: size.width / 2 + (_particles[index]['x'] * (size.width / 400)),
                    top: size.height / 2 + (_particles[index]['y'] * (size.height / 800)),
                    child: Opacity(
                      opacity: _particles[index]['opacity'],
                      child: Container(
                        width: _particles[index]['size'] * (isTablet ? 1.5 : 1.0),
                        height: _particles[index]['size'] * (isTablet ? 1.5 : 1.0),
                        decoration: BoxDecoration(
                          color: isAdminDetected ? Colors.amber : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isAdminDetected ? Colors.amber : Colors.white).withOpacity(0.4),
                              blurRadius: 3,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Radial glow with responsive size and admin detection
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      width: glowSize * _scaleAnimation.value,
                      height: glowSize * _scaleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: isAdminDetected
                              ? [
                                  Colors.amber.withOpacity(0.6),
                                  AppTheme.deepGold.withOpacity(0.3),
                                  Colors.transparent,
                                ]
                              : [
                                  AppTheme.shimmerGold.withOpacity(0.4),
                                  AppTheme.deepGold.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    );
                  },
                ),

                // Main content with flexible layout
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.1, // 10% horizontal padding
                    vertical: size.height * 0.05, // 5% vertical padding
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo animation with responsive size and admin effects
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: sin(_rotateAnimation.value * 3 * pi) * 0.05,
                            child: Transform.scale(
                              scale: _scaleAnimation.value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          height: logoSize,
                          width: logoSize,
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
                              BoxShadow(
                                color: (isAdminDetected ? Colors.amber : AppTheme.deepGold).withOpacity(0.3),
                                blurRadius: 25,
                                spreadRadius: 5,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Admin crown effect
                              if (isAdminDetected)
                                Positioned(
                                  top: logoSize * 0.1,
                                  child: Icon(
                                    Icons.admin_panel_settings,
                                    size: logoSize * 0.2,
                                    color: Colors.amber.withOpacity(0.7),
                                  ),
                                ),
                              
                              // Main meditation icon
                              Center(
                                child: ShaderMask(
                                  shaderCallback:
                                      (bounds) => LinearGradient(
                                        colors: isAdminDetected
                                            ? [
                                                Colors.white,
                                                Colors.amber,
                                                Colors.white,
                                              ]
                                            : [
                                                Colors.white,
                                                AppTheme.shimmerGold,
                                                Colors.white,
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                  child: Icon(
                                    Icons.self_improvement,
                                    size: iconSize,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: verticalSpacing1),

                      // App name with fade-in animation and responsive text
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback:
                                    (bounds) => LinearGradient(
                                      colors: isAdminDetected
                                          ? [
                                              Colors.white,
                                              Colors.amber,
                                              Colors.white,
                                            ]
                                          : [
                                              Colors.white,
                                              AppTheme.shimmerGold,
                                              Colors.white,
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      stops: [0.0, 0.5, 1.0],
                                      tileMode: TileMode.clamp,
                                    ).createShader(bounds),
                                child: Text(
                                  "Rhythmbhara Tara Sadhana",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: isSmallDevice ? 0.5 : 1.0,
                                    height: 1.2, // Line height for better readability
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  // Handle text overflow for very small screens
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ),
                              
                              // Admin badge if detected
                              if (isAdminDetected) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.amber.withOpacity(0.5),
                                    ),
                                  ),
                                  child: const Text(
                                    'ADMIN ACCESS DETECTED',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: verticalSpacing2),

                      // Loading indicator with responsive size and admin styling
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1500),
                          builder: (context, value, child) {
                            return SizedBox(
                              width: isTablet ? 50 : (isSmallDevice ? 35 : 40),
                              height: isTablet ? 50 : (isSmallDevice ? 35 : 40),
                              child: CircularProgressIndicator(
                                value: null,
                                strokeWidth: isTablet ? 4.0 : 3.0,
                                backgroundColor: (isAdminDetected ? Colors.amber : Colors.white).withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  (isAdminDetected ? Colors.amber : Colors.white).withOpacity(0.8),
                                ),
                              ),
                            );
                          },
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
    );
  }
}