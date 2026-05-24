import 'package:flutter/material.dart';

class AppTheme {
  // ===== COLORS =====

  // Primary Brand
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFF00D4FF);

  // Backgrounds
  static const Color darkBackground = Color.fromARGB(255, 0, 0, 0);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1E293B);

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;

  // Text
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ===== DARK THEME =====

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    scaffoldBackgroundColor: darkBackground,

    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: darkSurface,
      error: error,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimaryDark,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: textPrimaryDark),
    ),

    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF334155)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,

      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),

      hintStyle: const TextStyle(color: textSecondaryDark),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primary,
      unselectedItemColor: textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textPrimaryDark,
        fontSize: 34,
        fontWeight: FontWeight.bold,
      ),

      headlineMedium: TextStyle(
        color: textPrimaryDark,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),

      titleLarge: TextStyle(
        color: textPrimaryDark,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),

      bodyLarge: TextStyle(color: textPrimaryDark, fontSize: 16),

      bodyMedium: TextStyle(color: textSecondaryDark, fontSize: 14),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: darkCard,
      selectedColor: primary.withOpacity(0.2),
      labelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFF1E293B),
      thickness: 1,
    ),
  );

  // ===== LIGHT THEME =====

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    scaffoldBackgroundColor: lightBackground,

    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: lightSurface,
      error: error,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimaryLight,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: textPrimaryLight),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textPrimaryLight,
        fontSize: 34,
        fontWeight: FontWeight.bold,
      ),

      headlineMedium: TextStyle(
        color: textPrimaryLight,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),

      titleLarge: TextStyle(
        color: textPrimaryLight,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),

      bodyLarge: TextStyle(color: textPrimaryLight, fontSize: 16),

      bodyMedium: TextStyle(color: textSecondaryLight, fontSize: 14),
    ),
  );
}
