import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  static const Color gradientStart = Color(0xFFFFC371); // Derived from the image's top-left shade
  static const Color gradientMid = Color(0xFFFF5F6D); // Derived from the image's mid shade
  static const Color gradientEnd = Color(0xFF6A0572); // Derived from the image's bottom-right shade

  static final _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: gradientMid,
      secondary: gradientEnd,
      tertiary: gradientStart,
      surface: gradientStart.withOpacity(0.2),
      background: gradientStart.withOpacity(0.1),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shadowColor: gradientMid.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: gradientStart,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: gradientEnd,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    scaffoldBackgroundColor: gradientStart.withOpacity(0.05),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gradientMid,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: gradientStart.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: gradientMid.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: gradientMid.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gradientMid, width: 2),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: gradientStart,
      selectedItemColor: gradientMid,
      unselectedItemColor: Colors.grey.shade400,
    ),
  );

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: gradientEnd,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: gradientEnd,
      secondary: gradientMid,
      tertiary: gradientStart,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gradientEnd,
        foregroundColor: Colors.white,
      ),
    ),
  );

  ThemeData get theme => _isDarkMode ? _darkTheme : _lightTheme;

  static LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: const [
      gradientStart,
      gradientMid,
      gradientEnd,
    ],
  );

  static LinearGradient get subtleGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: const [
      gradientStart,
      gradientMid,
      gradientEnd,
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  static LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: const [
      gradientMid,
      gradientEnd,
    ],
    stops: const [0.0, 1.0],
  );
}
