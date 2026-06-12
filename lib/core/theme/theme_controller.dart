import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  // Màu mac định và chế độ sáng tối mặc định
  ThemeMode themeMode = ThemeMode.light;
  Color primaryColor = const Color(0xFF8470FF);

  bool get isDarkMode => themeMode == ThemeMode.dark;

  // Hàm bật/tắt Dark Mode
  void toggleDarkMode(bool isDark) {
    themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Báo cho toàn app biết để render lại
  }

  // Hàm đổi màu chủ đạo
  void changePrimaryColor(Color color) {
    primaryColor = color;
    notifyListeners();
  }
}

// Tạo một biến toàn cục để có thể gọi ở bất kỳ file nào
final themeController = ThemeController();