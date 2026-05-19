import 'package:flutter/material.dart';

class AppTheme {
  // Hàm tạo Theme động dựa vào màu và chế độ sáng/tối
  static ThemeData getTheme({required Color primaryColor, required bool isDark}) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Segoe UI', // Hoặc font bạn đang dùng
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: brightness,
        // Tuỳ chỉnh màu nền cho chuẩn Dark/Light
        surface: isDark ? const Color(0xFF1E1E24) : Colors.white,
        surfaceContainerHighest: isDark ? const Color(0xFF2A2A35) : const Color(0xFFF4F4F9),
      ),
      // Giữ cho các thẻ Card, Dialog có màu nền chuẩn
      cardColor: isDark ? const Color(0xFF2A2A35) : Colors.white,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : Colors.white, // Nền sâu nhất
    );
  }
}