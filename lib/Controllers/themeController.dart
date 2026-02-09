import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light; // nếu mà hình là light thì là icon dark
    notifyListeners();
  }

  void setDark() {
    _themeMode = ThemeMode.dark; //đặt cế độ
    notifyListeners(); // truyền event
  }

  void setLight() {
    _themeMode = ThemeMode.light;
    notifyListeners();  // truyền event
  }
}
