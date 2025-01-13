import 'package:flutter/material.dart';

class SmoothScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
  
  @override
  Widget buildOverscrollIndicator(
    BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
} 