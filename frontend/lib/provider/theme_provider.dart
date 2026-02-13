import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:frontend/provider/shared_pref_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends StateNotifier<ThemeMode> {
  final SharedPreferences _pref;
  ThemeProvider(this._pref)
    : super(_pref.getBool('isDark') == true ? ThemeMode.dark : ThemeMode.light);

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _pref.setBool('isDark', state == ThemeMode.dark);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

final themeProvider = StateNotifierProvider<ThemeProvider, ThemeMode>(
  (ref) => ThemeProvider(ref.read(sharedPrefProvider)),
);
