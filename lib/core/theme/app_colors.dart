import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  
  // Rider Palette: Racer Orange + Asphalt Charcoal
  static const Color primary = Color(0xFFFF5722); // Racer Orange
  static const Color primaryLight = Color(0xFFFF8A65);
  static const Color primaryDark = Color(0xFFE64A19);
  
  static const Color asphalt = Color(0xFF263238); // Asphalt Grey
  static const Color charcoal = Color(0xFF121212); // Deep Charcoal
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFFFF5722),
      Color(0xFFFF9100),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Call screen gradient.
  static const LinearGradient asphaltGradient = LinearGradient(
    colors: [
      Color(0xFF37474F),
      Color(0xFF263238),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient gradientFrom(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    final end = hsl
        .withHue((hsl.hue + 16) % 360)
        .withLightness((hsl.lightness * 0.86).clamp(0.0, 1.0))
        .toColor();
    return LinearGradient(
      colors: [accent, end],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static const List<Color> accentPresets = [
    primary, // Racer Orange (default)
    Color(0xFFF5C400), // Vibrant Yellow
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFF00C853), // Safety Green
    Color(0xFFCFD8DC), // Chrome
    Color(0xFF22C55E), // Green
    Color(0xFFF44336), // Red
  ];

  // ---- Dark theme ----
  static const Color darkBg = Color(0xFF0C0C0C);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurfaceAlt = Color(0xFF262626);
  static const Color darkBorder = Color(0xFF333333);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  static const Color darkReceivedBubble = Color(0xFF262626);

  // ---- Light theme ----
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEEEEEE);
  static const Color lightBorder = Color(0xFFE0E0E0);

  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);

  static const Color lightReceivedBubble = Color(0xFFFFFFFF);

  // ---- Shared semantic ----
  static const Color online = Color(0xFF00C853); // Safety Green
  static const Color danger = Color(0xFFD50000); // Stop Red

  static const Color heartEmpty = Color(0xFFFFFFFF);
  static const Color heartFilled = primary;

  // Compatibility aliases
  static const Color pink = primary;
  static const Color purple = primary;
  static const LinearGradient pinkGradient = primaryGradient;
}
