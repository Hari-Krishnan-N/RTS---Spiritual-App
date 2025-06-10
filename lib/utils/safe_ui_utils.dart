import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Global utilities for safe UI operations
/// This prevents common Flutter errors like opacity assertion failures
class SafeUI {
  /// Safely clamp opacity values to the valid range [0.0, 1.0]
  /// Also handles NaN and infinity values
  static double clampOpacity(double value) {
    if (value.isNaN || value.isInfinite) {
      debugPrint('⚠️ Invalid opacity value detected: $value, using 1.0');
      return 1.0;
    }
    return math.max(0.0, math.min(1.0, value));
  }

  /// Safely create a color with opacity
  static Color safeColorWithOpacity(Color color, double opacity) {
    return color.withValues(alpha: clampOpacity(opacity));
  }

  /// Safe wrapper for Opacity widget
  static Widget safeOpacity({
    required Widget child,
    required double opacity,
  }) {
    return Opacity(
      opacity: clampOpacity(opacity),
      child: child,
    );
  }

  /// Safe wrapper for FadeTransition
  static Widget safeFadeTransition({
    required Animation<double> opacity,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: opacity,
      builder: (context, child) {
        return Opacity(
          opacity: clampOpacity(opacity.value),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Safe wrapper for AnimatedOpacity
  static Widget safeAnimatedOpacity({
    required Widget child,
    required double opacity,
    required Duration duration,
    Curve curve = Curves.linear,
    VoidCallback? onEnd,
  }) {
    return AnimatedOpacity(
      opacity: clampOpacity(opacity),
      duration: duration,
      curve: curve,
      onEnd: onEnd,
      child: child,
    );
  }

  /// Safe wrapper for Transform.scale that ensures positive scale values
  static Widget safeScale({
    required Widget child,
    required double scale,
    Alignment alignment = Alignment.center,
  }) {
    final safeScale = math.max(0.0, scale);
    return Transform.scale(
      scale: safeScale,
      alignment: alignment,
      child: child,
    );
  }

  /// Safe wrapper for alpha values (0-255 range)
  static int clampAlpha(int alpha) {
    return math.max(0, math.min(255, alpha));
  }

  /// Create a safe Color.fromARGB
  static Color safeColorFromARGB(int alpha, int red, int green, int blue) {
    return Color.fromARGB(
      clampAlpha(alpha),
      clampAlpha(red),
      clampAlpha(green),
      clampAlpha(blue),
    );
  }

  /// Safe color lerp that handles null values
  static Color? safeLerpColor(Color? a, Color? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    
    final safeLerpValue = clampOpacity(t);
    return Color.lerp(a, b, safeLerpValue);
  }

  /// Debug helper to log potentially problematic opacity values
  static double debugOpacity(double value, String context) {
    if (value < 0.0 || value > 1.0 || value.isNaN || value.isInfinite) {
      debugPrint('🚨 Unsafe opacity detected in $context: $value');
    }
    return clampOpacity(value);
  }
}

/// Enhanced extension for safer color operations
extension SafeColorExtensions on Color {
  /// Safely apply opacity
  Color safeWithOpacity(double opacity) {
    return withValues(alpha: SafeUI.clampOpacity(opacity));
  }

  /// Safely apply alpha (0-255 range)
  Color safeWithAlpha(int alpha) {
    return withAlpha(SafeUI.clampAlpha(alpha));
  }

  /// Safe color blending
  Color safeBlendWith(Color other, double ratio) {
    final safeRatio = SafeUI.clampOpacity(ratio);
    return Color.lerp(this, other, safeRatio) ?? this;
  }

  /// Get a safe lighter version of the color
  Color safeLighten([double factor = 0.1]) {
    final safeFactor = SafeUI.clampOpacity(factor);
    final hsl = HSLColor.fromColor(this);
    final lightness = math.min(1.0, hsl.lightness + safeFactor);
    return hsl.withLightness(lightness).toColor();
  }

  /// Get a safe darker version of the color
  Color safeDarken([double factor = 0.1]) {
    final safeFactor = SafeUI.clampOpacity(factor);
    final hsl = HSLColor.fromColor(this);
    final lightness = math.max(0.0, hsl.lightness - safeFactor);
    return hsl.withLightness(lightness).toColor();
  }
}

/// Safe animation builder for custom animations
class SafeAnimationBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext context, double value) builder;
  final Widget? child;

  const SafeAnimationBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final safeValue = SafeUI.clampOpacity(animation.value);
        return builder(context, safeValue);
      },
      child: child,
    );
  }
}

/// Safe wrapper for Dismissible widgets to prevent tree errors
class SafeDismissible extends StatefulWidget {
  final Widget child;
  final Widget? background;
  final Widget? secondaryBackground;
  final VoidCallback? onDismissed;
  final DismissDirection direction;
  final Map<DismissDirection, double> dismissThresholds;
  final Duration movementDuration;
  final double crossAxisEndOffset;
  final DragStartBehavior dragStartBehavior;
  final HitTestBehavior behavior;
  final ConfirmDismissCallback? confirmDismiss;

  const SafeDismissible({
    required super.key,
    required this.child,
    this.background,
    this.secondaryBackground,
    this.onDismissed,
    this.direction = DismissDirection.endToStart,
    this.dismissThresholds = const <DismissDirection, double>{},
    this.movementDuration = const Duration(milliseconds: 200),
    this.crossAxisEndOffset = 0.0,
    this.dragStartBehavior = DragStartBehavior.start,
    this.behavior = HitTestBehavior.opaque,
    this.confirmDismiss,
  });

  @override
  State<SafeDismissible> createState() => _SafeDismissibleState();
}

class _SafeDismissibleState extends State<SafeDismissible> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    // If already dismissed, return empty container to prevent tree errors
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: widget.key!,
      background: widget.background,
      secondaryBackground: widget.secondaryBackground,
      direction: widget.direction,
      dismissThresholds: widget.dismissThresholds,
      movementDuration: widget.movementDuration,
      crossAxisEndOffset: widget.crossAxisEndOffset,
      dragStartBehavior: widget.dragStartBehavior,
      behavior: widget.behavior,
      confirmDismiss: widget.confirmDismiss,
      onDismissed: (direction) {
        // Immediately mark as dismissed to prevent tree errors
        setState(() {
          _isDismissed = true;
        });
        
        // Call the original callback after widget is safely removed from tree
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onDismissed?.call();
        });
      },
      child: widget.child,
    );
  }
}

/// Utility to safely handle list animations and removals
class SafeListAnimations {
  /// Safely remove item from list with animation
  static void safeRemoveItem<T>({
    required AnimatedListState listState,
    required int index,
    required Widget Function(T item, Animation<double> animation) itemBuilder,
    required T item,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    listState.removeItem(
      index,
      (context, animation) => SafeAnimationBuilder(
        animation: animation,
        builder: (context, value) => SafeUI.safeOpacity(
          opacity: value,
          child: SafeUI.safeScale(
            scale: value,
            child: itemBuilder(item, animation),
          ),
        ),
      ),
      duration: duration,
    );
  }

  /// Safely insert item into list with animation
  static void safeInsertItem<T>({
    required AnimatedListState listState,
    required int index,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    listState.insertItem(index, duration: duration);
  }
}
