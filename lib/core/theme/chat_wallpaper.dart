import 'package:flutter/material.dart';

/// A chat-background wallpaper: either a built-in gradient/solid preset, the
/// "default" (no wallpaper — uses the scaffold background), or a user image
/// (handled separately via a stored file path).
class ChatWallpaper {
  final String id;
  final String label;
  final Gradient? gradient;
  final Color? color;

  const ChatWallpaper({
    required this.id,
    required this.label,
    this.gradient,
    this.color,
  });

  bool get isDefault => id == 'default';

  /// A small decoration used to preview the swatch in the picker grid.
  Decoration get preview => BoxDecoration(
        gradient: gradient,
        color: color,
        borderRadius: BorderRadius.circular(14),
      );
}

/// Built-in wallpaper presets. `default` renders nothing (scaffold bg).
const List<ChatWallpaper> kChatWallpapers = [
  ChatWallpaper(id: 'default', label: 'Default'),
  ChatWallpaper(
    id: 'midnight',
    label: 'Midnight',
    gradient: LinearGradient(
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  ChatWallpaper(
    id: 'dusk',
    label: 'Dusk',
    gradient: LinearGradient(
      colors: [Color(0xFF232526), Color(0xFF414345)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ChatWallpaper(
    id: 'ocean',
    label: 'Ocean',
    gradient: LinearGradient(
      colors: [Color(0xFF141E30), Color(0xFF243B55)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  ChatWallpaper(
    id: 'grape',
    label: 'Grape',
    gradient: LinearGradient(
      colors: [Color(0xFF20002c), Color(0xFF3a1c71)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ChatWallpaper(
    id: 'rose',
    label: 'Rose',
    gradient: LinearGradient(
      colors: [Color(0xFF3a0d2a), Color(0xFF6d214f)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  ChatWallpaper(
    id: 'forest',
    label: 'Forest',
    gradient: LinearGradient(
      colors: [Color(0xFF0B2027), Color(0xFF1B3A2B), Color(0xFF2C503B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ChatWallpaper(
    id: 'ember',
    label: 'Ember',
    gradient: LinearGradient(
      colors: [Color(0xFF2b1216), Color(0xFF5a1f24)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  ChatWallpaper(
    id: 'teal',
    label: 'Teal',
    gradient: LinearGradient(
      colors: [Color(0xFF0A2E2E), Color(0xFF0F4C4C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ChatWallpaper(id: 'charcoal', label: 'Charcoal', color: Color(0xFF121316)),
  ChatWallpaper(id: 'ink', label: 'Ink', color: Color(0xFF0A0A0F)),
  ChatWallpaper(id: 'slate', label: 'Slate', color: Color(0xFF1B1F27)),
];

/// Looks up a preset by id (falls back to Default).
ChatWallpaper wallpaperById(String id) => kChatWallpapers.firstWhere(
      (w) => w.id == id,
      orElse: () => kChatWallpapers.first,
    );
