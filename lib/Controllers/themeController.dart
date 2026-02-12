import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier { // controller chuyển theme
  ThemeMode _themeMode = ThemeMode.light; // mặc định theme sáng 

  ThemeMode get themeMode => _themeMode; // lấy ra theme hiện tại 

  bool get isDark => _themeMode == ThemeMode.dark; // kiểm tra có phải theme tối không, nếu có trả true 

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
