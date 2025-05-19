import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/sadhana_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/dashboard_widgets.dart';
import 'jebam_screen.dart';
import 'tharpanam_screen.dart';
import 'homam_screen.dart';
import 'dhyanam_screen.dart';
import 'profile_screen.dart';
import 'status_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Check if logged in, if not redirect to login
    if (!Provider.of<SadhanaProvider>(context).isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
    }

    // List of screen widgets
    final List<Widget> screens = [
      const DashboardHomeScreen(),
      const StatusScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: screens[_selectedIndex],
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
        ),
      ),
      extendBody: true,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(38),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(204),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withAlpha(128),
                      width: 1.5,
                    ),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  backgroundColor: Colors.transparent,
                  selectedItemColor: AppTheme.primaryColor,
                  unselectedItemColor: Colors.grey.withAlpha(179),
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  items: [
                    BottomNavigationBarItem(
                      icon: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _selectedIndex == 0
                                  ? AppTheme.primaryColor.withAlpha(51)
                                  : Colors.transparent,
                        ),
                        child: const Icon(Icons.home_rounded, size: 26),
                      ),
                      label: 'My Space',
                    ),
                    BottomNavigationBarItem(
                      icon: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _selectedIndex == 1
                                  ? AppTheme.primaryColor.withAlpha(51)
                                  : Colors.transparent,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 26,
                        ),
                      ),
                      label: 'Status',
                    ),
                    BottomNavigationBarItem(
                      icon: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _selectedIndex == 2
                                  ? AppTheme.primaryColor.withAlpha(51)
                                  : Colors.transparent,
                        ),
                        child: const Icon(Icons.person_rounded, size: 26),
                      ),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _itemsAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _itemsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SadhanaProvider>(context);
    final username = provider.username;
    final photoUrl = provider.userPhotoUrl;
    final size = MediaQuery.of(context).size;

    // New elegant background gradient - deep indigo to dark navy
    const backgroundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF2C3E50), // Dark blue-gray
        Color(0xFF1A2530), // Darker navy
      ],
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Section with User Info
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _headerAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _headerAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - _headerAnimation.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                        // User greeting row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Greeting text
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Namaste,",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withAlpha(204),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),

                            // User avatar with decoration
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withAlpha(179),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(51),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Hero(
                                tag: 'profile_avatar',
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.white.withAlpha(51),
                                  backgroundImage:
                                      photoUrl != null
                                          ? NetworkImage(photoUrl)
                                          : null,
                                  child:
                                      photoUrl == null
                                          ? const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 28,
                                          )
                                          : null,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Meditation illustration with enhanced animations
                        Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.9, end: 1.1),
                            duration: const Duration(milliseconds: 3000),
                            curve: Curves.easeInOutSine,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(77),
                                    blurRadius: 16,
                                    spreadRadius: 15,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Animated particle effect (simulated)
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: const Duration(
                                      milliseconds: 2000,
                                    ),
                                    curve: Curves.easeInOut,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Container(
                                          height: 100 * value,
                                          width: 100 * value,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                Colors.white.withAlpha(
                                                  (204 * value).toInt(),
                                                ),
                                                Colors.white.withAlpha(
                                                  (26 * value).toInt(),
                                                ),
                                                Colors.transparent,
                                              ],
                                              stops: const [0.0, 0.5, 1.0],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // Improved animated pulse effect
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.8, end: 1.2),
                                    duration: const Duration(
                                      milliseconds: 2000,
                                    ),
                                    curve: Curves.easeInOutSine,
                                    builder: (context, value, child) {
                                      return Container(
                                        height: 70 * value,
                                        width: 70 * value,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              Colors.white.withAlpha(77),
                                              Colors.white.withAlpha(26),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // Meditation icon with enhanced shimmer effect
                                  ShaderMask(
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
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Practices Grid with improved layout and animations
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: size.width > 600 ? 3 : 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 18, // Increased spacing
                    mainAxisSpacing: 24, // Increased spacing
                  ),
                  delegate: SliverChildListDelegate([
                    // Japam card with SWAPPED colors (now using muted green)
                    AnimatedBuilder(
                      animation: _itemsAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - _itemsAnimation.value)),
                          child: Opacity(
                            opacity: _itemsAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: PracticeTile(
                        title: 'Japam',
                        description: 'Track your daily chanting',
                        icon: Icons.format_list_numbered_rounded,
                        gradientColors: const [
                          Color(0xFF3A5F2E), // Dark muted green
                          Color(0xFF5C8D4A), // Muted green
                        ],
                        shadowColor: const Color(0xFF3A5F2E).withAlpha(102),
                        iconContainerColor: Colors.white.withAlpha(51),
                        onTap:
                            () => _navigateToPractice(
                              context,
                              const JebamScreen(),
                            ),
                      ),
                    ),

                    // Tharpanam card with enhanced animation and design
                    AnimatedBuilder(
                      animation: _itemsAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 70 * (1 - _itemsAnimation.value)),
                          child: Opacity(
                            opacity: _itemsAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: PracticeTile(
                        title: 'Tharpanam',
                        description: 'Monthly ritual tracking',
                        icon: Icons.water_drop_rounded,
                        gradientColors: const [
                          Color(0xFF1B4B47), // Deep muted teal
                          Color(0xFF2E706A), // Muted teal
                        ],
                        shadowColor: const Color(0xFF1B4B47).withAlpha(102),
                        iconContainerColor: Colors.white.withAlpha(51),
                        onTap:
                            () => _navigateToPractice(
                              context,
                              const TharpanamScreen(),
                            ),
                      ),
                    ),

                    // Homam card with enhanced animation and design
                    AnimatedBuilder(
                      animation: _itemsAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 90 * (1 - _itemsAnimation.value)),
                          child: Opacity(
                            opacity: _itemsAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: PracticeTile(
                        title: 'Homam',
                        description: 'Fire ritual status',
                        icon: Icons.local_fire_department_rounded,
                        gradientColors: const [
                          Color(0xFF7D3812), // Deep rust
                          Color(0xFFA35735), // Muted orange
                        ],
                        shadowColor: const Color(0xFF7D3812).withAlpha(102),
                        iconContainerColor: Colors.white.withAlpha(51),
                        onTap:
                            () => _navigateToPractice(
                              context,
                              const HomamScreen(),
                            ),
                      ),
                    ),

                    // Dhanam card with SWAPPED colors (now using muted purple)
                    AnimatedBuilder(
                      animation: _itemsAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 110 * (1 - _itemsAnimation.value)),
                          child: Opacity(
                            opacity: _itemsAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: PracticeTile(
                        title: 'Dhanam',
                        description: 'Meditation tracker',
                        icon: Icons.spa_rounded,
                        gradientColors: const [
                          Color(0xFF362358), // Deep muted purple
                          Color(0xFF4E3980), // Muted purple
                        ],
                        shadowColor: const Color(0xFF362358).withAlpha(102),
                        iconContainerColor: Colors.white.withAlpha(51),
                        onTap:
                            () => _navigateToPractice(
                              context,
                              const DhyanamScreen(),
                            ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPractice(BuildContext context, Widget screen) {
    // Add haptic feedback for better interaction
    HapticFeedback.lightImpact();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
