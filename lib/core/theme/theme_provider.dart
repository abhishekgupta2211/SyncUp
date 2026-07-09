import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

/// Holds the active [ThemeMode] and persists it. Defaults to dark — the
/// LoveChat identity is dark-first.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefs);

  static const _key = 'theme_mode';
  static const _accentKey = 'accent_color';
  static const _brandKey = 'brand_version';
  static const _brandVersion = 2; // bumped on the SyncUp purple rebrand
  final SharedPreferences _prefs;

  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;

  Color _accent = AppColors.pink;
  Color get accent => _accent;

  bool get isDark => _mode == ThemeMode.dark;

  void load() {
    final stored = _prefs.getString(_key);
    _mode = switch (stored) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    // Rebrand migration: reset a pre-rebrand custom accent to the new SyncUp
    // default (purple) once, so the new identity lands. Users can re-pick after.
    final brand = _prefs.getInt(_brandKey) ?? 1;
    if (brand < _brandVersion) {
      _accent = AppColors.pink;
      _prefs.setInt(_brandKey, _brandVersion);
      _prefs.remove(_accentKey);
    } else {
      final a = _prefs.getInt(_accentKey);
      if (a != null) _accent = Color(a);
    }
    notifyListeners();
  }

  Future<void> setAccent(Color color) async {
    if (_accent == color) return;
    _accent = color;
    notifyListeners();
    await _prefs.setInt(_accentKey, color.toARGB32());
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setString(_key, mode.name);
  }

  Future<void> toggle() =>
      setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
