import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  static const String _themeKey = 'is_dark_mode';

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  // Light Theme Gradients
  static LinearGradient get lightBackgroundGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFB6C1),  // Light pink
      Color(0xFFB5B8FF),  // Light purple-blue
      Color(0xFF9198FF),  // Medium purple
      Color(0xFF7B6FF0),  // Deep purple
    ],
    stops: [0.0, 0.3, 0.6, 1.0],
  );

  static LinearGradient get lightCardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9198FF),  // Medium purple
      Color(0xFF7B6FF0),  // Deep purple
    ],
  );

  // Dark Theme Gradients
  static LinearGradient get darkBackgroundGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A2E),  // Deep blue-black
      Color(0xFF16213E),  // Dark navy
      Color(0xFF1B2430),  // Dark slate
      Color(0xFF0F172A),  // Darkest blue
    ],
    stops: [0.0, 0.3, 0.6, 1.0],
  );

  static LinearGradient get darkCardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1F2937),  // Dark gray-blue
      Color(0xFF1B2430),  // Dark slate
    ],
  );

  // Current gradients based on theme
  LinearGradient get backgroundGradient => 
      _isDarkMode ? darkBackgroundGradient : lightBackgroundGradient;

  LinearGradient get cardGradient => 
      _isDarkMode ? darkCardGradient : lightCardGradient;

  LinearGradient get subtleGradient => _isDarkMode
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F2937),
            Color(0xFF374151),
          ],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFB6C1),
            Color(0xFFB5B8FF),
          ],
        );

  ThemeData get theme => _isDarkMode ? _darkTheme : _lightTheme;

  // Light Theme
  static final ThemeData _lightTheme = ThemeData(
    primaryColor: const Color(0xFF7B6FF0),
    primaryColorLight: const Color(0xFFB5B8FF),
    primaryColorDark: const Color(0xFF6357CC),
    scaffoldBackgroundColor: Colors.transparent,
    
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF7B6FF0),
      secondary: Color(0xFFFFB6C1),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFB5B8FF),
      error: Color(0xFFFF8B94),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFF000000),
      onBackground: Color(0xFF000000),
      onError: Color(0xFFFFFFFF),
      brightness: Brightness.light,
    ),
    // ... rest of your light theme configuration
  );

  // Dark Theme
  static final ThemeData _darkTheme = ThemeData(
    primaryColor: const Color(0xFF7B6FF0),
    primaryColorLight: const Color(0xFF9198FF),
    primaryColorDark: const Color(0xFF6357CC),
    scaffoldBackgroundColor: Colors.transparent,
    
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7B6FF0),
      secondary: Color(0xFFFFB6C1),
      surface: Color(0xFF1F2937),
      background: Color(0xFF0F172A),
      error: Color(0xFFEF4444),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFFFFFFFF),
      onBackground: Color(0xFFFFFFFF),
      onError: Color(0xFFFFFFFF),
      brightness: Brightness.dark,
    ),

    cardTheme: CardTheme(
      color: const Color(0xFF1F2937).withOpacity(0.9),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7B6FF0).withOpacity(0.9),
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1F2937).withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: const Color(0xFF7B6FF0).withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: const Color(0xFF7B6FF0).withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7B6FF0), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white60),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white60),
    ),
  );

  static BoxDecoration get glassEffect => BoxDecoration(
    color: Colors.white.withOpacity(0.15),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        spreadRadius: 2,
      ),
    ],
  );

  Future<void> loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }
}
