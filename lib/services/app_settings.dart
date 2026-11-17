import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = '@lukas_theme_mode';

class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_kThemeModeKey);
    if (modeIndex != null &&
        modeIndex >= 0 &&
        modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeModeKey, mode.index);
  }
}
