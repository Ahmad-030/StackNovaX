import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00E5FF);
  static const Color secondary = Color(0xFF1DE9B6);
  static const Color accent = Color(0xFF40C4FF);
  static const Color bgDark = Color(0xFF030814);
  static const Color bgMid = Color(0xFF050D20);
  static const Color bgLight = Color(0xFF0A1A35);
  static const Color surface = Color(0xFF0D1F3C);
  static const Color surfaceLight = Color(0xFF132848);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted = Color(0xFF546E7A);
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFB0BEC5);
  static const Color bronze = Color(0xFFCD7F32);

  static const List<Color> blockColors = [
    Color(0xFF00E5FF),
    Color(0xFF1DE9B6),
    Color(0xFF40C4FF),
    Color(0xFF64FFDA),
    Color(0xFF18FFFF),
    Color(0xFF84FFFF),
    Color(0xFF80D8FF),
    Color(0xFFB2EBF2),
    Color(0xFF00BCD4),
    Color(0xFF00ACC1),
  ];
}

class AppGradients {
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF030814),
      Color(0xFF050D20),
      Color(0xFF061228),
      Color(0xFF040A18),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const LinearGradient primaryButton = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF1DE9B6)],
  );

  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1F3C), Color(0xFF0A1A30)],
  );
}