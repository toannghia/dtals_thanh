import 'package:flutter/material.dart';

class AppTheme {
  // Premium Modern Palette 
  // Slate Blue for trust & stability
  static const primaryColor = Color(0xFF22D3EE); // Light cyan
  static const primaryLight = Color(0xFF67E8F9);
  static const primaryDark = Color(0xFF0E7490);
  static const navAccent = primaryColor;
  
  // Neutral Colors (Backgrounds and Surfaces)
  static const backgroundColor = Color(0xFFF8FAFC); // Very light slate
  static const surfaceColor = Colors.white;
  static const textPrimary = Color(0xFF0F172A); // Almost black, easy on AMOLED
  static const textSecondary = Color(0xFF64748B); // Slate-500
  
  // Semantic Colors
  static const successColor = Color(0xFF10B981); // Emerald
  static const errorColor = Color(0xFFEF4444); // Red
  static const warningColor = Color(0xFFF59E0B); // Amber
  static const infoColor = Color(0xFF3B82F6); // Blue

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter', // Will gracefully fallback to system sans-serif if not found
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: primaryDark,
        error: errorColor,
        surface: surfaceColor,
        background: backgroundColor,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1, // Subtle shadow when scrolling Material 3
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Modern larger radius
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1), // Subtle border
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          // CRITICAL: Ensure touch target is at least 48px. 56px is premium mobile height.
          minimumSize: const Size(double.infinity, 56), 
          elevation: 0,
          shadowColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.2),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 0;
            return 4; // Floating effect when normal
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        hintStyle: const TextStyle(color: textSecondary, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        // Minimum 48px height guaranteed by vertical padding 16px + text > 48px total
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFF1F5F9),
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        elevation: 20,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }

  static ThemeData get darkTheme {
    // Premium Slate Dark Mode matching UI-UX Pro Max Guidelines
    const darkBg = Color(0xFF0F172A); // slate-900
    const darkSurface = Color(0xFF1E293B); // slate-800
    const borderDark = Color(0xFF334155); // slate-700
    const cyanAccent = Color(0xFF38BDF8); // sky-400

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: cyanAccent,
        brightness: Brightness.dark,
        primary: cyanAccent,
        secondary: primaryColor,
        error: errorColor,
        surface: darkSurface,
        background: darkBg,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderDark, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyanAccent,
          foregroundColor: const Color(0xFF0F172A),
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cyanAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkBg,
        elevation: 0,
        selectedItemColor: cyanAccent,
        unselectedItemColor: Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
