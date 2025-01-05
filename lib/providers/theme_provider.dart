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
      Color(0xFF2C3E50),  // Deep blue-gray
      Color(0xFF3A506B),  // Steel blue
      Color(0xFF5C6B7F),  // Slate gray
      Color(0xFF8B4367),  // Dusty rose
      Color(0xFFC34C74),  // Rose
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  static LinearGradient get darkCardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3A506B),  // Steel blue
      Color(0xFF2C3E50),  // Deep blue-gray
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

  // Update both light and dark theme text themes
  static const TextTheme _baseTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.3,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    ),
  );

  static final TextTheme _lightTextTheme = _baseTextTheme.apply(
    bodyColor: const Color(0xFF2D3748),
    displayColor: const Color(0xFF2D3748),
  );

  static final TextTheme _darkTextTheme = _baseTextTheme.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  );

  // Light Theme
  static final ThemeData _lightTheme = ThemeData(
    primaryColor: const Color(0xFF7B6FF0),
    primaryColorLight: const Color(0xFFB5B8FF),
    primaryColorDark: const Color(0xFF6357CC),
    scaffoldBackgroundColor: Colors.transparent,
    
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF7B6FF0),      // Deep purple
      secondary: Color(0xFFFFB6C1),    // Light pink
      surface: Color(0xFFFFFFFF),   // Light purple-blue
      error: Color(0xFFFF8B94),        // Light red
      onPrimary: Color(0xFFFFFFFF),    // White
      onSecondary: Color(0xFF000000),  // Black
      onSurface: Color(0xFF000000),  // Black
      onError: Color(0xFFFFFFFF),      // White
      brightness: Brightness.light,
    ),

    // Enhanced AppBar theme for light mode
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF7B6FF0).withOpacity(0.95),
      elevation: 0,
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
      actionsIconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      toolbarTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Enhanced button styling for light mode
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7B6FF0),
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: const Color(0xFF7B6FF0).withOpacity(0.4),
      ),
    ),

    // Text button theme for light mode
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF7B6FF0),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Outlined button theme for light mode
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF7B6FF0),
        side: const BorderSide(color: Color(0xFF7B6FF0), width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),

    textTheme: _lightTextTheme,
    // ... rest of your light theme configuration
  );

  // Dark Theme
  static final ThemeData _darkTheme = ThemeData(
    primaryColor: const Color(0xFFC34C74),      // Rose
    primaryColorLight: const Color(0xFFE57498),  // Light rose
    primaryColorDark: const Color(0xFF8B4367),   // Dark rose
    scaffoldBackgroundColor: Colors.transparent,
    
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFC34C74),     // Rose
      secondary: Color(0xFF66A6FF),    // Sky blue
      surface: Color(0xFF2C3E50),   // Darker blue-gray
      error: Color(0xFFFF6B6B),        // Soft red
      onPrimary: Color(0xFFFFFFFF),    // White
      onSecondary: Color(0xFF1A1F25),  // Dark blue-gray
      onSurface: Color(0xFFFFFFFF),  // White
      onError: Color(0xFFFFFFFF),      // White
      brightness: Brightness.dark,
    ),

    cardTheme: CardTheme(
      color: const Color(0xFF2C3E50).withOpacity(0.7),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: const Color(0xFFC34C74).withOpacity(0.2),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF2C3E50).withOpacity(0.7),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Enhanced button styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFC34C74).withOpacity(0.9),
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: const Color(0xFFC34C74).withOpacity(0.5),
      ),
    ),

    // Enhanced input styling
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C3E50).withOpacity(0.7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.9),
      ),
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.5),
      ),
    ),

    textTheme: _darkTextTheme.copyWith(
      bodyLarge: _darkTextTheme.bodyLarge?.copyWith(
        color: Colors.white.withOpacity(0.9),
      ),
      bodyMedium: _darkTextTheme.bodyMedium?.copyWith(
        color: Colors.white.withOpacity(0.7),
      ),
      bodySmall: _darkTextTheme.bodySmall?.copyWith(
        color: Colors.white.withOpacity(0.5),
      ),
    ),

    iconTheme: IconThemeData(
      color: Colors.white.withOpacity(0.9),
    ),

    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.1),
      thickness: 1,
    ),

    listTileTheme: ListTileThemeData(
      titleTextStyle: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 14,
      ),
      iconColor: Colors.white.withOpacity(0.9),
      textColor: Colors.white.withOpacity(0.9),
      tileColor: Colors.transparent,
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

  static BoxDecoration get darkGlassEffect => BoxDecoration(
    color: const Color(0xFF3A506B).withOpacity(0.15),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withOpacity(0.1),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFFC34C74).withOpacity(0.2),
        blurRadius: 12,
        spreadRadius: 2,
      ),
    ],
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.1),
        Colors.white.withOpacity(0.05),
      ],
    ),
  );

  Future<void> loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  // Add duration for animations
  static const Duration themeDuration = Duration(milliseconds: 300);
  static const Curve themeCurve = Curves.easeInOut;
}
