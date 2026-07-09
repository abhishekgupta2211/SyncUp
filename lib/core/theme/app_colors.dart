import 'package:flutter/material.dart';

/// Central brand palette for LoveChat.
///
/// Premium Obsidian + Electric Cyan theme.
/// Names are kept the same to avoid breaking existing code.
class AppColors {
  AppColors._();

  // ---- Brand (SyncUp — deep purple / indigo / blue) ----
  static const Color pink = Color(0xFF6C63FF); // Primary (deep purple)
  static const Color pinkLight = Color(0xFF8B7CFF); // Light purple
  static const Color magenta = Color(0xFF4F46E5); // Indigo
  static const Color purple = Color(0xFF6C63FF); // Primary alias
  static const Color purpleDeep = Color(0xFF4338CA); // Deep indigo

  /// Signature gradient — used on FAB, sent bubbles and primary buttons.
  static const LinearGradient pinkGradient = LinearGradient(
    colors: [
      Color(0xFF6C63FF),
      Color(0xFF4F46E5),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Call screen gradient.
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [
      Color(0xFF6C63FF),
      Color(0xFF3B82F6),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Builds the signature 2-stop gradient from any accent colour, so the whole
  /// app can recolour to a user-selected accent.
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

  /// Accent choices offered in Appearance settings (first = default cyan).
  static const List<Color> accentPresets = [
    pink, // Deep Purple (default)
    Color(0xFF4F46E5), // Indigo
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF22C55E), // Green
    Color(0xFFF59E0B), // Amber
  ];

  // ---- Dark theme ----
  static const Color darkBg = Color(0xFF08090D);
  static const Color darkSurface = Color(0xFF12141A);
  static const Color darkSurfaceAlt = Color(0xFF1A1D24);
  static const Color darkBorder = Color(0xFF2A2F3A);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static const Color darkReceivedBubble = Color(0xFF1A1D24);

  // ---- Light theme ----
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  static const Color lightReceivedBubble = Color(0xFFFFFFFF);

  // ---- Shared semantic ----
  static const Color online = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);

  static const Color heartEmpty = Color(0xFFFFFFFF);

  // Existing name kept for compatibility.
  static const Color heartFilled = pink;
}