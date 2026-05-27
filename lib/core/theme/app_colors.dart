import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0B0B1A);
  static const Color surface = Color(0xFF141428);
  static const Color card = Color(0xFF1A1A32);
  static const Color cardElevated = Color(0xFF20203C);

  // Brand
  static const Color primary = Color(0xFFA855F7);      // purple
  static const Color primaryLight = Color(0xFFD08BFF);
  static const Color primaryDark = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFF00E5CC);    // cyan/teal
  static const Color secondaryDark = Color(0xFF00B4A0);
  static const Color accent = Color(0xFF667EEA);       // blue-purple

  // Text
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textMuted = Color(0xFF555570);

  // States
  static const Color success = Color(0xFF00E5CC);
  static const Color warning = Color(0xFFFFB347);
  static const Color danger = Color(0xFFFF6B9D);
  static const Color info = Color(0xFF667EEA);

  // Event colors
  static const Color snoreEvent = Color(0xFFA855F7);
  static const Color movementEvent = Color(0xFF667EEA);
  static const Color envNoiseEvent = Color(0xFF00E5CC);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary, Color(0xFFE879F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF667EEA), secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFF0F0F22)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Borders
  static const Color border = Color(0xFF2A2A45);
  static const Color borderLight = Color(0xFF33334D);

  // Divider
  static const Color divider = Color(0xFF1E1E35);

  // Glow
  static Color primaryGlow = primary.withAlpha(60);
  static Color cyanGlow = secondary.withAlpha(60);
}
