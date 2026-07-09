import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local user preferences (privacy hints, notifications, chat options and
/// the chat wallpaper), persisted in [SharedPreferences]. Cross-device account
/// privacy can be promoted to `profiles` columns later.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  // ---- Privacy (local hints for v1) ----
  bool _showLastSeen = true;
  bool _showOnline = true;
  bool _readReceipts = true;

  // ---- Notifications ----
  bool _notifications = true;
  bool _notifSound = true;
  bool _notifVibrate = true;
  bool _notifPreview = true;

  // ---- Chat ----
  bool _enterToSend = false;
  double _fontScale = 1.0; // 0.9 | 1.0 | 1.15

  // ---- Wallpaper ----
  String _wallpaperId = 'default'; // preset id, or 'custom'
  String? _wallpaperPath; // for a user-picked image

  bool get showLastSeen => _showLastSeen;
  bool get showOnline => _showOnline;
  bool get readReceipts => _readReceipts;
  bool get notifications => _notifications;
  bool get notifSound => _notifSound;
  bool get notifVibrate => _notifVibrate;
  bool get notifPreview => _notifPreview;
  bool get enterToSend => _enterToSend;
  double get fontScale => _fontScale;
  String get wallpaperId => _wallpaperId;
  String? get wallpaperPath => _wallpaperPath;

  void _load() {
    _showLastSeen = _prefs.getBool('showLastSeen') ?? true;
    _showOnline = _prefs.getBool('showOnline') ?? true;
    _readReceipts = _prefs.getBool('readReceipts') ?? true;
    _notifications = _prefs.getBool('notifications') ?? true;
    _notifSound = _prefs.getBool('notifSound') ?? true;
    _notifVibrate = _prefs.getBool('notifVibrate') ?? true;
    _notifPreview = _prefs.getBool('notifPreview') ?? true;
    _enterToSend = _prefs.getBool('enterToSend') ?? false;
    _fontScale = _prefs.getDouble('fontScale') ?? 1.0;
    _wallpaperId = _prefs.getString('wallpaperId') ?? 'default';
    _wallpaperPath = _prefs.getString('wallpaperPath');
  }

  Future<void> _setBool(String key, bool value, void Function() apply) async {
    apply();
    notifyListeners();
    await _prefs.setBool(key, value);
  }

  Future<void> setShowLastSeen(bool v) =>
      _setBool('showLastSeen', v, () => _showLastSeen = v);
  Future<void> setShowOnline(bool v) =>
      _setBool('showOnline', v, () => _showOnline = v);
  Future<void> setReadReceipts(bool v) =>
      _setBool('readReceipts', v, () => _readReceipts = v);
  Future<void> setNotifications(bool v) =>
      _setBool('notifications', v, () => _notifications = v);
  Future<void> setNotifSound(bool v) =>
      _setBool('notifSound', v, () => _notifSound = v);
  Future<void> setNotifVibrate(bool v) =>
      _setBool('notifVibrate', v, () => _notifVibrate = v);
  Future<void> setNotifPreview(bool v) =>
      _setBool('notifPreview', v, () => _notifPreview = v);
  Future<void> setEnterToSend(bool v) =>
      _setBool('enterToSend', v, () => _enterToSend = v);

  Future<void> setFontScale(double v) async {
    _fontScale = v;
    notifyListeners();
    await _prefs.setDouble('fontScale', v);
  }

  /// Selects a built-in wallpaper preset (clears any custom image).
  Future<void> setWallpaperPreset(String id) async {
    _wallpaperId = id;
    _wallpaperPath = null;
    notifyListeners();
    await _prefs.setString('wallpaperId', id);
    await _prefs.remove('wallpaperPath');
  }

  /// Sets a user-picked wallpaper image (absolute local path).
  Future<void> setWallpaperImage(String path) async {
    _wallpaperId = 'custom';
    _wallpaperPath = path;
    notifyListeners();
    await _prefs.setString('wallpaperId', 'custom');
    await _prefs.setString('wallpaperPath', path);
  }
}
