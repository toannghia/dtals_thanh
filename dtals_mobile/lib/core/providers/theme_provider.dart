import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system; // Default before load
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      if (value == 'light') state = ThemeMode.light;
      else if (value == 'dark') state = ThemeMode.dark;
      else state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    String value = 'system';
    if (mode == ThemeMode.light) value = 'light';
    else if (mode == ThemeMode.dark) value = 'dark';
    await prefs.setString(_key, value);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
