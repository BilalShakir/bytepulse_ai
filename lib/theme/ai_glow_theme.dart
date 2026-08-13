import 'package:flutter/material.dart';

class AIGlowColors {
  static const Color iceWhite = Color(0xFFFAFAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color softBorder = Color(0xFFE2E8F0);
  
  static const Color inkSlate = Color(0xFF0F172A);
  static const Color mediumSlate = Color(0xFF64748B);
  static const Color mutedSlate = Color(0xFF94A3B8);

  static const Color electricCyan = Color(0xFF06B6D4);
  static const Color hyperViolet = Color(0xFF8B5CF6);
  static const Color emeraldMint = Color(0xFF10B981);
  static const Color amberWarning = Color(0xFFD97706);
  static const Color roseCritical = Color(0xFFE11D48);

  static const LinearGradient iridescentGradient = LinearGradient(
    colors: [electricCyan, hyperViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient centerFabGradient = LinearGradient(
    colors: [electricCyan, hyperViolet, emeraldMint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AIGlowTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AIGlowColors.iceWhite,
      colorScheme: const ColorScheme.light(
        primary: AIGlowColors.electricCyan,
        secondary: AIGlowColors.hyperViolet,
        surface: AIGlowColors.cardWhite,
        error: AIGlowColors.roseCritical,
        onPrimary: Colors.white,
        onSurface: AIGlowColors.inkSlate,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AIGlowColors.inkSlate),
        titleTextStyle: TextStyle(
          color: AIGlowColors.inkSlate,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AIGlowColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AIGlowColors.softBorder, width: 1),
        ),
      ),
    );
  }
}
