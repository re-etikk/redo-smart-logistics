import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  String _selectedUnits = 'Metric (Kg, Km)';

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get selectedUnits => _selectedUnits;
  bool get isMetric => !_selectedUnits.toLowerCase().contains('imperial');
  bool get isDark => _themeMode == ThemeMode.dark;
  bool isDarkMode(BuildContext context) => _themeMode == ThemeMode.dark || (_themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

  static const String _themePrefKey = 'theme_mode';
  static const String _localePrefKey = 'locale_code';
  static const String _unitsPrefKey = 'redo_pref_units';

  ThemeViewModel() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themePrefKey);
    final savedLocale = prefs.getString(_localePrefKey);
    final savedUnits = prefs.getString(_unitsPrefKey);
    if (savedTheme != null) {
      _themeMode = _themeFromString(savedTheme);
    }
    if (savedLocale != null) {
      _locale = Locale(savedLocale);
    }
    if (savedUnits != null) {
      _selectedUnits = savedUnits;
    }
    notifyListeners();
  }

  Future<void> setUnits(String units) async {
    _selectedUnits = units;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitsPrefKey, units);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, _themeToString(mode));
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefKey, locale.languageCode);
  }

  String _themeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _themeFromString(String s) {
    switch (s) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }
}
