import 'package:flutter/material.dart';
import 'core/theme/AppTheme.dart';
import 'core/theme/theme_controller.dart'; // Import controller
import 'features/auth/LoginScreen.dart';

void main() {
  runApp(const ChatAppDesktop());
}

class ChatAppDesktop extends StatelessWidget {
  const ChatAppDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder sẽ vẽ lại MaterialApp ngay khi themeController thay đổi
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, child) {
        return MaterialApp(
          title: 'Pro Chat Desktop',
          debugShowCheckedModeBanner: false,
          
          // Nạp Theme Sáng
          theme: AppTheme.getTheme(
            primaryColor: themeController.primaryColor, 
            isDark: false
          ),
          // Nạp Theme Tối
          darkTheme: AppTheme.getTheme(
            primaryColor: themeController.primaryColor, 
            isDark: true
          ),
          // Quyết định dùng Sáng hay Tối
          themeMode: themeController.themeMode,
          
          home: const LoginScreen(),
        );
      },
    );
  }
}