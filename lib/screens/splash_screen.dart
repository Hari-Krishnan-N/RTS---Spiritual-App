import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:ui';
import '../providers/sadhana_provider.dart';
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
      Navigator.pushReplacementNamed(context, '/dashboard');
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryLightColor,
              AppTheme.softGold.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Particles
              ...List.generate(_particles.length, (index) {
                return Positioned(
                  left: size.width / 2 + _particles[index]['x'],
                  top: size.height / 2 + _particles[index]['y'],
                  child: Opacity(
                    opacity: _particles[index]['opacity'],
                    child: Container(
                      width: _particles[index]['size'],
                      height: _particles[index]['size'],
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.4),
                            blurRadius: 3,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Radial glow
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    width: 250 * _scaleAnimation.value,
                    height: 250 * _scaleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
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

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo animation
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
                      height: 180,
                      width: 180,
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
                            color: AppTheme.deepGold.withOpacity(0.3),
                            blurRadius: 25,
                            spreadRadius: 5,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback:
                              (bounds) => const LinearGradient(
                                colors: [
                                  Colors.white,
                                  AppTheme.shimmerGold,
                                  Colors.white,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                          child: const Icon(
                            Icons.self_improvement,
                            size: 100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App name with fade-in animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ShaderMask(
                      shaderCallback:
                          (bounds) => LinearGradient(
                            colors: const [
                              Colors.white,
                              AppTheme.shimmerGold,
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: [0.0, 0.5, 1.0],
                            tileMode: TileMode.clamp,
                          ).createShader(bounds),
                      child: const Text(
                        "Rhythmbhara Tara Sadhana",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                  ),

                  const SizedBox(height: 60),

                  // Loading indicator with animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1500),
                      builder: (context, value, child) {
                        return SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: null,
                            strokeWidth: 3.0,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
