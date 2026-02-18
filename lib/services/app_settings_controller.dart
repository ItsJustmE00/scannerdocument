import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController(this._preferences);

  static const _themeModeKey = 'theme_mode';

  final SharedPreferences _preferences;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  static Future<AppSettingsController> create() async {
    final preferences = await SharedPreferences.getInstance();
    final controller = AppSettingsController(preferences);
    controller._load();
    return controller;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }

    _themeMode = mode;
    notifyListeners();
    await _preferences.setString(_themeModeKey, _themeModeToKey(mode));
  }

  void _load() {
    final saved = _preferences.getString(_themeModeKey);
    _themeMode = _keyToThemeMode(saved);
  }

  ThemeMode _keyToThemeMode(String? key) {
    switch (key) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToKey(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
