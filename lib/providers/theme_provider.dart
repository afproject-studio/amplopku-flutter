import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _preferenceKey = 'darkMode';

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedValue = prefs.getBool(_preferenceKey) ?? false;

      if (_isDarkMode == savedValue) return;

      _isDarkMode = savedValue;
      notifyListeners();
    } catch (_) {
      // Aplikasi tetap menggunakan light mode apabila penyimpanan
      // preferensi tidak dapat dibaca.
    }
  }

  Future<void> toggleTheme(bool value) async {
    if (_isDarkMode == value) return;

    _isDarkMode = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_preferenceKey, value);
    } catch (_) {
      // Perubahan tema tetap diterapkan untuk sesi saat ini.
    }
  }
}
