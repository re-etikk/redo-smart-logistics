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

  ThemeViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('theme_mode');
    if (themeStr == 'light') { _themeMode = ThemeMode.light; }
    else if (themeStr == 'dark') { _themeMode = ThemeMode.dark; }
    
    final langCode = prefs.getString('language_code');
    if (langCode != null) {
      _locale = Locale(langCode);
    }

    final units = prefs.getString('redo_pref_units');
    if (units != null) {
      _selectedUnits = units;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('theme_mode', mode.name);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('language_code', locale.languageCode);
  }

  Future<void> setUnits(String units) async {
    _selectedUnits = units;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('redo_pref_units', units);
  }
}
