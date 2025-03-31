import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Trạng thái chế độ tối
  bool _isDarkMode = false;

  // Getter để truy cập trạng thái hiện tại
  bool get isDarkMode => _isDarkMode;

  // Các theme tùy chỉnh
  ThemeData get lightTheme => ThemeData(
        primarySwatch: Colors.brown,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          primary: Colors.brown,
        ),
        useMaterial3: true,
      );

  ThemeData get darkTheme => ThemeData(
        primarySwatch: Colors.brown,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.dark(
          primary: Colors.brown.shade700,
        ),
        useMaterial3: true,
      );

  // Constructor
  ThemeProvider() {
    // Tải trạng thái theme từ SharedPreferences khi khởi tạo
    _loadThemeFromPrefs();
  }

  // Phương thức tải theme từ bộ nhớ cục bộ
  void _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Mặc định là chế độ sáng nếu chưa có cài đặt
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  // Phương thức chuyển đổi theme
  void toggleTheme() async {
    // Đảo ngược trạng thái hiện tại
    _isDarkMode = !_isDarkMode;

    // Lưu trạng thái mới vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);

    // Thông báo các widget đang lắng nghe
    notifyListeners();
  }

  // Phương thức đặt theme theo yêu cầu
  void setTheme(bool isDark) async {
    _isDarkMode = isDark;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);

    notifyListeners();
  }
}
