import 'package:flutter/material.dart';

class AppTheme {
  // === COLOR PALETTE ===
  static const Color bgDeep = Color(0xFF020818);
  static const Color bgPrimary = Color(0xFF050A18);
  static const Color bgSurface = Color(0xFF0A1628);
  static const Color bgCard = Color(0xFF0D1F3C);
  static const Color bgGlass = Color(0x1A1E3A5F);

  static const Color neonCyan = Color(0xFF00F5FF);
  static const Color neonBlue = Color(0xFF0066FF);
  static const Color neonPurple = Color(0xFF7B2FFF);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonOrange = Color(0xFFFF6B35);
  static const Color neonRed = Color(0xFFFF2D55);
  static const Color neonYellow = Color(0xFFFFD60A);

  static const Color textPrimary = Color(0xFFE8F4FD);
  static const Color textSecondary = Color(0xFF8BAAC8);
  static const Color textMuted = Color(0xFF4A6B8A);

  static const Color borderGlass = Color(0x3300F5FF);
  static const Color borderSubtle = Color(0x1A4A90D9);

  // === GRADIENTS ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0066FF), Color(0xFF7B2FFF)],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00F5FF), Color(0xFF0066FF)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00FF88), Color(0xFF00C9A7)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD60A), Color(0xFFFF6B35)],
  );

  // === THEME DATA ===
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonBlue,
        tertiary: neonPurple,
        surface: bgSurface,
        error: neonRed,
        onPrimary: bgDeep,
        onSecondary: bgDeep,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      fontFamily: 'SpaceMono',
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      cardTheme: _buildCardTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: neonCyan),
      bottomNavigationBarTheme: _buildBottomNavTheme(),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 2,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 1.5,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 1.2,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 1,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.8,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.6,
      ),
      titleLarge: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: 0.5,
      ),
      titleMedium: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: textSecondary,
        letterSpacing: 0.3,
      ),
      titleSmall: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: textSecondary,
        letterSpacing: 0.2,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 14,
        color: textPrimary,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 12,
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 10,
        color: textMuted,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: neonCyan,
        letterSpacing: 1.2,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme() {
    return const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 1,
      ),
      iconTheme: IconThemeData(color: neonCyan),
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderGlass, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonCyan,
        foregroundColor: bgDeep,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: neonCyan,
        side: const BorderSide(color: neonCyan, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: bgSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGlass, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderSubtle, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neonCyan, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neonRed, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(
        color: textMuted,
        fontFamily: 'SpaceMono',
        fontSize: 13,
      ),
      labelStyle: const TextStyle(
        color: textSecondary,
        fontFamily: 'SpaceMono',
        fontSize: 13,
      ),
      floatingLabelStyle: const TextStyle(
        color: neonCyan,
        fontFamily: 'SpaceMono',
        fontSize: 12,
      ),
      prefixIconColor: neonCyan,
      suffixIconColor: textMuted,
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme() {
    return const BottomNavigationBarThemeData(
      backgroundColor: bgSurface,
      selectedItemColor: neonCyan,
      unselectedItemColor: textMuted,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 10,
      ),
      elevation: 0,
    );
  }

  // === UTILITY METHODS ===
  static Color getRiskColor(double risk) {
    if (risk < 0.3) return neonGreen;
    if (risk < 0.6) return neonYellow;
    if (risk < 0.8) return neonOrange;
    return neonRed;
  }

  static LinearGradient getRiskGradient(double risk) {
    if (risk < 0.3) return successGradient;
    if (risk < 0.6) return warningGradient;
    return dangerGradient;
  }

  static Color getStabilityColor(double score) {
    if (score > 0.8) return neonGreen;
    if (score > 0.6) return neonCyan;
    if (score > 0.4) return neonYellow;
    return neonRed;
  }

  static BoxDecoration glassDecoration({
    double borderRadius = 16,
    Color? borderColor,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: backgroundColor ?? bgGlass,
      border: Border.all(
        color: borderColor ?? borderGlass,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: neonCyan.withOpacity(0.05),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ],
    );
  }

  static BoxDecoration neonCardDecoration({
    Color glowColor = neonCyan,
    double glowIntensity = 0.15,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: bgCard,
      border: Border.all(
        color: glowColor.withOpacity(0.4),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(glowIntensity),
          blurRadius: 16,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: glowColor.withOpacity(0.05),
          blurRadius: 32,
          spreadRadius: 8,
        ),
      ],
    );
  }
}
