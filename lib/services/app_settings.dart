import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = '@lukas_theme_mode';
const _kRefreshIntervalKey = '@lukas_refresh_interval';

const List<int> kRefreshIntervalChoices = [15, 30, 60];
const int kDefaultRefreshInterval = 30;

class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  int _refreshIntervalMinutes = kDefaultRefreshInterval;

  ThemeMode get themeMode => _themeMode;
  int get refreshIntervalMinutes => _refreshIntervalMinutes;
  Duration get refreshInterval => Duration(minutes: _refreshIntervalMinutes);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_kThemeModeKey);
    if (modeIndex != null &&
        modeIndex >= 0 &&
        modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    }
    final interval = prefs.getInt(_kRefreshIntervalKey);
    if (interval != null && kRefreshIntervalChoices.contains(interval)) {
      _refreshIntervalMinutes = interval;
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

  Future<void> setRefreshIntervalMinutes(int minutes) async {
    if (minutes == _refreshIntervalMinutes) return;
    if (!kRefreshIntervalChoices.contains(minutes)) return;
    _refreshIntervalMinutes = minutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kRefreshIntervalKey, minutes);
  }
}
