import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/sadhana_provider.dart';
import '../providers/notification_provider.dart';
import '../services/admin_service.dart';
import '../utils/app_theme.dart';
import '../widgets/dashboard_widgets.dart';
import '../screens/practice_screens_controller.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/notifications_screen.dart';
import '../utils/navigation_transitions.dart';
import 'profile_screen.dart';
import 'status_screen.dart';

// Extension to convert opacity values to alpha (0-255)
extension ColorExtension on Color {
  Color withValues({double? alpha}) {
    if (alpha == null) return this;
    int alphaInt = (alpha * 255).round();
    return withAlpha(alphaInt);
  }
}

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

  // FIXED: Add flag to prevent repeated redirects
  bool _hasCheckedAuth = false;

  // Admin service for checking admin status
  final AdminService _adminService = AdminService();

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

    // Initialize notifications when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      notificationProvider.initialize();
    });
  }

  void _setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SadhanaProvider>(context);

    // FIXED: Only check auth once and handle navigation properly
    if (!provider.isLoggedIn &&
        !provider.isInSignupProcess &&
        !_hasCheckedAuth) {
      _hasCheckedAuth = true;
      // Use a post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !provider.isLoggedIn && !provider.isInSignupProcess) {
          Navigator.pushReplacementNamed(context, '/');
        }
      });
      // Return a loading screen while checking
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // FIXED: Reset the flag when user is logged in
    if (provider.isLoggedIn && !_hasCheckedAuth) {
      _hasCheckedAuth = true;
    }

    // Check if current user is admin and show admin button
    final isAdmin = _adminService.isCurrentUserAdmin();

    // List of screen widgets
    final List<Widget> screens = [
      DashboardHomeScreen(onNavigateToTab: _setSelectedIndex, isAdmin: isAdmin),
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
                color: Colors.black.withValues(alpha: 0.15),
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
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
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
                  selectedItemColor: AppTheme.accentColor,
                  unselectedItemColor: Colors.grey.withValues(alpha: 0.7),
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
                                  ? AppTheme.accentColor.withValues(alpha: 0.2)
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
                                  ? AppTheme.accentColor.withValues(alpha: 0.2)
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
                                  ? AppTheme.accentColor.withValues(alpha: 0.2)
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
  final Function(int) onNavigateToTab;
  final bool isAdmin;

  const DashboardHomeScreen({
    super.key,
    required this.onNavigateToTab,
    this.isAdmin = false,
  });

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
    // Removed unused variable 'size'

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.dashboardGradient,
          image: const DecorationImage(
            image: AssetImage('assets/images/subtle_pattern.png'),
            repeat: ImageRepeat.repeat,
            opacity: 0.05, // Very subtle pattern overlay
          ),
        ),
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
                        // User greeting row with admin button and notification icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Greeting text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Namaste,",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                                      if (widget.isAdmin) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.amber.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            'ADMIN',
                                            style: TextStyle(
                                              color: Colors.amber,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
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
                            ),

                            // Notification icon
                            Consumer<NotificationProvider>(
                              builder: (context, notificationProvider, child) {
                                final unreadCount =
                                    notificationProvider.unreadCount;

                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      CupertinoStylePageRoute(
                                        page: const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            unreadCount > 0
                                                ? AppTheme.accentColor
                                                    .withValues(alpha: 0.5)
                                                : Colors.white.withValues(alpha: 0.2),
                                        width: unreadCount > 0 ? 2 : 1,
                                      ),
                                      boxShadow:
                                          unreadCount > 0
                                              ? [
                                                BoxShadow(
                                                  color: AppTheme.accentColor
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
                                                ),
                                              ]
                                              : null,
                                    ),
                                    child: Stack(
                                      children: [
                                        Icon(
                                          unreadCount > 0
                                              ? Icons.notifications_active
                                              : Icons.notifications_outlined,
                                          color:
                                              unreadCount > 0
                                                  ? AppTheme.accentColor
                                                  : Colors.white.withValues(
                                                    alpha: 0.7,
                                                  ),
                                          size: 24,
                                        ),
                                        if (unreadCount > 0)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1,
                                                ),
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              child: Text(
                                                unreadCount > 99
                                                    ? '99+'
                                                    : unreadCount.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 12),

                            // Admin access button (if admin)
                            if (widget.isAdmin) ...[
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    CupertinoStylePageRoute(
                                      page: const AdminDashboardScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.amber.withValues(alpha: 0.5),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.admin_panel_settings,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],

                            // User avatar with decoration - clickable to profile
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onNavigateToTab(
                                  2,
                                ); // Navigate to profile tab
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        widget.isAdmin
                                            ? Colors.amber.withValues(alpha: 0.7)
                                            : Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                    width: widget.isAdmin ? 3 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          widget.isAdmin
                                              ? Colors.amber.withValues(alpha: 0.3)
                                              : Colors.black.withValues(
                                                alpha: 0.2,
                                              ),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Hero(
                                  tag: 'profile_avatar',
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.2,
                                    ),
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
                                    color: Colors.black.withValues(alpha: 0.3),
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
                                                Colors.white.withValues(
                                                  alpha: 0.8 * value,
                                                ),
                                                Colors.white.withValues(
                                                  alpha: 0.1 * value,
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
                                              Colors.white.withValues(
                                                alpha: 0.3,
                                              ),
                                              Colors.white.withValues(
                                                alpha: 0.1,
                                              ),
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

              // Practices Grid with consistent 2x2 layout for all screen sizes
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Always 2 columns for consistent layout
                    childAspectRatio: 1.0, // Square cards for all screen sizes
                    crossAxisSpacing: 16, // Consistent spacing
                    mainAxisSpacing: 16, // Consistent spacing
                  ),
                  delegate: SliverChildListDelegate([
                    // Japam card (Top Left)
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
                          Color(0xFF4A7843), // Muted green to match image
                          Color(0xFF6B9B5A), // Lighter muted green
                        ],
                        shadowColor: const Color(
                          0xFF4A7843,
                        ).withValues(alpha: 0.4),
                        iconContainerColor: Colors.white.withValues(alpha: 0.2),
                        onTap:
                            () => _navigateToPractice(
                              context,
                              0, // Index for JebamScreen
                            ),
                      ),
                    ),

                    // Tharpanam card (Top Right)
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
                          Color(0xFF2E5B5B), // Muted teal to match image
                          Color(0xFF4A7A7A), // Lighter muted teal
                        ],
                        shadowColor: const Color(
                          0xFF2E5B5B,
                        ).withValues(alpha: 0.4),
                        iconContainerColor: Colors.white.withValues(alpha: 0.2),
                        onTap:
                            () => _navigateToPractice(
                              context,
                              1, // Index for TharpanamScreen
                            ),
                      ),
                    ),

                    // Homam card (Bottom Left)
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
                          Color(0xFF8B4513), // Rich brown to match image
                          Color(0xFFA0603C), // Lighter brown
                        ],
                        shadowColor: const Color(
                          0xFF8B4513,
                        ).withValues(alpha: 0.4),
                        iconContainerColor: Colors.white.withValues(alpha: 0.2),
                        onTap:
                            () => _navigateToPractice(
                              context,
                              2, // Index for HomamScreen
                            ),
                      ),
                    ),

                    // Dhanam card (Bottom Right)
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
                        description: 'Charity & giving tracker',
                        icon: Icons.spa_rounded,
                        gradientColors: const [
                          Color(0xFF4A3A6B), // Muted purple to match image
                          Color(0xFF6B5A8A), // Lighter muted purple
                        ],
                        shadowColor: const Color(
                          0xFF4A3A6B,
                        ).withValues(alpha: 0.4),
                        iconContainerColor: Colors.white.withValues(alpha: 0.2),
                        onTap:
                            () => _navigateToPractice(
                              context,
                              3, // Index for DhaanamScreen
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

  void _navigateToPractice(BuildContext context, int practiceIndex) {
    // Add haptic feedback for better interaction
    HapticFeedback.lightImpact();

    // Use our custom iOS-style transition
    Navigator.push(
      context,
      CupertinoStylePageRoute(
        page: PracticeScreensController(initialPage: practiceIndex),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
