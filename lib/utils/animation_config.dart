import 'package:flutter/material.dart';

class AnimationConfig {
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeInOutCubic;
  
  static const double swipeThreshold = 0.4;
  static const double swipeVelocityThreshold = 700.0;
  
  static final dismissibleBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.green.withOpacity(0.7),
        Colors.red.withOpacity(0.7),
      ],
    ),
  );
} 