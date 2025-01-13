import 'package:flutter/material.dart';

class AppTextStyles {
  // Headings
  static TextStyle heading1(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white.withOpacity(0.95) : Colors.black87,
    );
  }

  static TextStyle heading2(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black87,
    );
  }

  static TextStyle heading3(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black87,
    );
  }

  // Body text
  static TextStyle bodyLarge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 16,
      color: isDark ? Colors.white.withOpacity(0.87) : Colors.black87,
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 14,
      color: isDark ? Colors.white.withOpacity(0.87) : Colors.black87,
    );
  }

  static TextStyle bodySmall(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 12,
      color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
    );
  }

  // Button text
  static TextStyle buttonLarge(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : Colors.white,
    letterSpacing: 0.5,
  );

  static TextStyle buttonMedium(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : Colors.white,
    letterSpacing: 0.3,
  );

  // Label text
  static TextStyle label(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).brightness == Brightness.dark 
        ? Colors.white.withOpacity(0.9) 
        : const Color(0xFF4A5568),
    letterSpacing: 0.2,
  );

  // Price text
  static TextStyle price(BuildContext context, {bool isOnSale = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: isOnSale 
          ? (isDark ? Colors.redAccent : Colors.red)
          : (isDark ? Colors.white.withOpacity(0.95) : Colors.black87),
    );
  }

  // Card title
  static TextStyle cardTitle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black87,
    );
  }

  // Card subtitle
  static TextStyle cardSubtitle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 14,
      color: isDark ? Colors.white.withOpacity(0.7) : Colors.black54,
    );
  }

  // Link text
  static TextStyle link(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).primaryColor,
    decoration: TextDecoration.underline,
  );

  // Error text
  static TextStyle error(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.error,
    height: 1.2,
  );
} 