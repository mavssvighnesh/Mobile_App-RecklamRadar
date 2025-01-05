import 'package:flutter/material.dart';

class AppTextStyles {
  // Headings
  static TextStyle heading1(BuildContext context) => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : const Color(0xFF2D3748),
    letterSpacing: -0.5,
  );

  static TextStyle heading2(BuildContext context) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : const Color(0xFF2D3748),
    letterSpacing: -0.3,
  );

  static TextStyle heading3(BuildContext context) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : const Color(0xFF2D3748),
  );

  // Body text
  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).brightness == Brightness.dark 
        ? Colors.white.withOpacity(0.9) 
        : const Color(0xFF4A5568),
    height: 1.5,
  );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).brightness == Brightness.dark 
        ? Colors.white.withOpacity(0.8) 
        : const Color(0xFF718096),
    height: 1.4,
  );

  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).brightness == Brightness.dark 
        ? Colors.white.withOpacity(0.7) 
        : const Color(0xFF718096),
    height: 1.3,
  );

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
  static TextStyle price(BuildContext context, {bool isOnSale = false}) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: isOnSale 
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).brightness == Brightness.dark 
            ? Colors.white 
            : const Color(0xFF2D3748),
    decoration: isOnSale ? TextDecoration.lineThrough : null,
  );

  // Card title
  static TextStyle cardTitle(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : const Color(0xFF2D3748),
    height: 1.3,
  );

  // Card subtitle
  static TextStyle cardSubtitle(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).brightness == Brightness.dark 
        ? Colors.white.withOpacity(0.7) 
        : const Color(0xFF718096),
    height: 1.2,
  );

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