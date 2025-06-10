import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationIconWithGlow extends StatefulWidget {
  final VoidCallback onTap;
  final double size;
  final Color? iconColor;

  const NotificationIconWithGlow({
    super.key,
    required this.onTap,
    this.size = 24.0,
    this.iconColor,
  });

  @override
  State<NotificationIconWithGlow> createState() => _NotificationIconWithGlowState();
}

class _NotificationIconWithGlowState extends State<NotificationIconWithGlow>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _tapController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _tapAnimation;

  @override
  void initState() {
    super.initState();
    
    // Glow animation for new notifications
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for unread count badge
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Tap animation for feedback
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _tapAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _updateAnimations({
    required bool hasNewNotifications,
    required int unreadCount,
  }) {
    // FIXED: Proper glow logic - only glow when there are new AND unread notifications
    if (hasNewNotifications && unreadCount > 0) {
      if (!_glowController.isAnimating) {
        _glowController.repeat(reverse: true);
      }
    } else {
      if (_glowController.isAnimating) {
        _glowController.stop();
        _glowController.reset();
      }
    }

    // Pulse animation for unread badge
    if (unreadCount > 0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  Future<void> _handleTap() async {
    // Tap animation
    await _tapController.forward();
    await _tapController.reverse();
    
    // Call the onTap function
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final hasNewNotifications = provider.hasNewNotifications;
        final unreadCount = provider.unreadCount;
        final hasUnreadMessages = unreadCount > 0;

        // Update animations based on current state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateAnimations(
            hasNewNotifications: hasNewNotifications,
            unreadCount: unreadCount,
          );
        });

        return GestureDetector(
          onTap: () async {
            // Remove glow effect when tapped
            provider.onNotificationScreenOpened();
            await _handleTap();
          },
          child: AnimatedBuilder(
            animation: _tapAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _tapAnimation.value,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // FIXED: Main notification icon with proper glow effect
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: widget.size + 16,
                          height: widget.size + 16,
                          decoration: hasNewNotifications && hasUnreadMessages
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    // Inner glow - AMBER COLOR
                                    BoxShadow(
                                      color: Colors.amber.withValues(
                                        alpha: 0.4 + (0.6 * _glowAnimation.value),
                                      ),
                                      blurRadius: 15 + (15 * _glowAnimation.value),
                                      spreadRadius: 2 + (4 * _glowAnimation.value),
                                    ),
                                    // Outer glow - AMBER COLOR
                                    BoxShadow(
                                      color: Colors.amber.withValues(
                                        alpha: 0.2 + (0.3 * _glowAnimation.value),
                                      ),
                                      blurRadius: 25 + (20 * _glowAnimation.value),
                                      spreadRadius: 5 + (8 * _glowAnimation.value),
                                    ),
                                  ],
                                )
                              : null,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: hasUnreadMessages 
                                    ? (hasNewNotifications 
                                        ? Colors.amber.withValues(alpha: 0.2)  // AMBER for new notifications
                                        : Colors.red.withValues(alpha: 0.15))
                                    : Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: hasUnreadMessages
                                      ? (hasNewNotifications 
                                          ? Colors.amber.withValues(alpha: 0.6)  // AMBER border for new notifications
                                          : Colors.red.withValues(alpha: 0.4))
                                      : Colors.white.withValues(alpha: 0.2),
                                  width: hasUnreadMessages ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                // ENHANCED: Better icon selection
                                _getIconForState(hasUnreadMessages, hasNewNotifications),
                                size: widget.size,
                                color: _getIconColor(hasUnreadMessages, hasNewNotifications),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // ENHANCED: Unread count badge with pulse animation
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: hasNewNotifications ? _pulseAnimation.value : 1.0,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  // Enhanced gradient based on notification state - AMBER for new
                                  gradient: hasNewNotifications
                                      ? LinearGradient(
                                          colors: [
                                            Colors.amber,
                                            Colors.amber.withValues(alpha: 0.8),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.red,
                                            Colors.red.shade700,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: hasNewNotifications
                                          ? Colors.amber.withValues(alpha: 0.6)  // AMBER shadow for new notifications
                                          : Colors.red.withValues(alpha: 0.5),
                                      blurRadius: hasNewNotifications ? 10 : 6,
                                      spreadRadius: hasNewNotifications ? 3 : 1,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // ENHANCED: Animated glow ring for new notifications
                    if (hasNewNotifications && hasUnreadMessages)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.amber.withValues(  // AMBER glow ring
                                    alpha: 0.3 + (0.5 * _glowAnimation.value),
                                  ),
                                  width: 2 + (4 * _glowAnimation.value),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // ENHANCED: Success indicator when all notifications are read
                    if (unreadCount == 0 && provider.userNotifications.isNotEmpty)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.green,
                                Color(0xFF4CAF50),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getIconForState(bool hasUnread, bool hasNew) {
    if (hasUnread) {
      if (hasNew) {
        return Icons.notifications_active; // Active bell for new notifications
      } else {
        return Icons.notifications; // Regular bell for unread
      }
    } else {
      return Icons.notifications_none_outlined; // Outlined bell for all read
    }
  }

  Color _getIconColor(bool hasUnread, bool hasNew) {
    if (hasNew) {
      return Colors.amber; // AMBER for new notifications
    } else if (hasUnread) {
      return Colors.red; // Red for unread notifications
    } else {
      return widget.iconColor ?? Colors.white.withValues(alpha: 0.7); // Muted for all read
    }
  }
}

// ENHANCED: Simple notification icon for other use cases
class SimpleNotificationIcon extends StatefulWidget {
  final VoidCallback onTap;
  final double size;
  final Color? iconColor;

  const SimpleNotificationIcon({
    super.key,
    required this.onTap,
    this.size = 24.0,
    this.iconColor,
  });

  @override
  State<SimpleNotificationIcon> createState() => _SimpleNotificationIconState();
}

class _SimpleNotificationIconState extends State<SimpleNotificationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _tapAnimation;

  @override
  void initState() {
    super.initState();
    
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _tapAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _tapController.forward();
    await _tapController.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final unreadCount = provider.unreadCount;
        final hasNotifications = provider.userNotifications.isNotEmpty;

        return GestureDetector(
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: _tapAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _tapAnimation.value,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: unreadCount > 0 
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: unreadCount > 0 
                            ? Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Icon(
                        unreadCount > 0 
                            ? Icons.notifications_active
                            : (hasNotifications 
                                ? Icons.notifications_none_outlined
                                : Icons.notifications_outlined),
                        size: widget.size,
                        color: unreadCount > 0 
                            ? Colors.red
                            : (widget.iconColor ?? Colors.white.withValues(alpha: 0.7)),
                      ),
                    ),
                    
                    // Unread count badge
                    if (unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.red, Color(0xFFE53935)],
                            ),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Success indicator when all read
                    if (unreadCount == 0 && hasNotifications)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.green, Color(0xFF4CAF50)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.4),
                                blurRadius: 3,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ENHANCED: WhatsApp-style notification status widget
class NotificationStatusWidget extends StatelessWidget {
  final bool isRead;
  final bool isDelivered;
  final double size;

  const NotificationStatusWidget({
    super.key,
    required this.isRead,
    this.isDelivered = true,
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isRead 
            ? Colors.blue.withValues(alpha: 0.1)
            : (isDelivered 
                ? Colors.orange.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1)),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          isRead
              ? Icons.done_all // Double check for read
              : (isDelivered
                  ? Icons.done // Single check for delivered  
                  : Icons.access_time), // Clock for pending
          size: size * 0.8,
          color: isRead 
              ? Colors.blue 
              : (isDelivered 
                  ? Colors.orange 
                  : Colors.grey),
        ),
      ),
    );
  }
}
