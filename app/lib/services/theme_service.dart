import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  ThemeService() {
    _loadSettings();
  }

  ThemeMode _themeMode = ThemeMode.system;
  FlexScheme _scheme = FlexScheme.deepPurple;

  ThemeMode get themeMode => _themeMode;
  FlexScheme get scheme => _scheme;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('theme_mode');
    if (modeIndex != null) {
      _themeMode = ThemeMode.values[modeIndex];
    }
    final schemeIndex = prefs.getInt('theme_scheme');
    if (schemeIndex != null) {
      _scheme = FlexScheme.values[schemeIndex];
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  Future<void> setScheme(FlexScheme scheme) async {
    if (_scheme == scheme) return;
    _scheme = scheme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_scheme', scheme.index);
  }
}
