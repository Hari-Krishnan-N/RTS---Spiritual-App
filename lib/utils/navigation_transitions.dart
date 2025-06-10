import 'package:flutter/material.dart';

/// iOS-style page route transition
class CupertinoStylePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  CupertinoStylePageRoute({
    required this.page,
    super.settings,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);
      
      // Apply a subtle fade along with the slide
      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// For returning to the previous screen (right to left slide)
class CupertinoStyleBackPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  CupertinoStyleBackPageRoute({
    required this.page,
    super.settings,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(-1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);
      
      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// Navigate with iOS-style transition
void navigateWithTransition(BuildContext context, Widget screen) {
  Navigator.push(
    context,
    CupertinoStylePageRoute(page: screen),
  );
}

/// Navigate and replace current screen with iOS-style transition
void navigateAndReplaceWithTransition(BuildContext context, Widget screen) {
  Navigator.pushReplacement(
    context,
    CupertinoStylePageRoute(page: screen),
  );
}

/// Pop current screen with specific animation
void popWithTransition(BuildContext context) {
  Navigator.pop(context);
}