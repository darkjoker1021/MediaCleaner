import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Standard push: subtle horizontal slide (5%) + fade-in.
/// Feels modern and light compared to the full-screen cupertino slide.
class SlideRightFadeTransition extends CustomTransition {

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final a = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutExpo,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.05, 0),
        end: Offset.zero,
      ).animate(a),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(a),
        child: child,
      ),
    );
  }
}

/// Modal push: slides up from the bottom (sheet-style).
class ModalUpTransition extends CustomTransition {

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final a = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutExpo,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(a),
      child: child,
    );
  }
}

/// Fade only — used for onboarding / info screens.
class FadeTransitionPage extends CustomTransition {

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
      child: child,
    );
  }
}
