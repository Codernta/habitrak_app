import 'package:flutter/material.dart';

/// Shared animation tokens for consistent motion across the app.
abstract final class AppAnimations {
  static const Duration instant = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration page = Duration(milliseconds: 450);
  static const Duration splash = Duration(milliseconds: 1800);

  static const Curve spring = Curves.easeOutCubic;
  static const Curve bounce = Curves.easeOutBack;
  static const Curve smooth = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;

  static const double staggerStepMs = 70;
  static const double slideDistance = 24;
  static const double scaleEnter = 0.92;

  /// Opacity must stay in [0, 1]; overshooting curves (e.g. easeOutBack) need this.
  static double clampOpacity(double value) => value.clamp(0.0, 1.0);
}
