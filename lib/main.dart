import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart'; // Import thư viện
import 'core/theme/AppTheme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/LoginScreen.dart'; 

void main() async {
  // 1. Phải có dòng này để khởi tạo các plugin Native
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Khởi tạo Window Manager
  await windowManager.ensureInitialized();

  // 3. Cấu hình cửa sổ Desktop
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1100, 750), // Kích thước mở lên mặc định
    minimumSize: Size(800, 600), // Không cho người dùng thu nhỏ quá mức này
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
  );

  // 4. Đợi cửa sổ sẵn sàng rồi mới Show lên (Tránh bị giật màn hình trắng lúc bật app)
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ChatAppDesktop());
}

class ChatAppDesktop extends StatelessWidget {
  const ChatAppDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, child) {
        return MaterialApp(
          title: 'Pro Chat Desktop',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(
            primaryColor: themeController.primaryColor, 
            isDark: false
          ),
          darkTheme: AppTheme.getTheme(
            primaryColor: themeController.primaryColor, 
            isDark: true
          ),
          themeMode: themeController.themeMode,
          home: const LoginScreen(),
        );
      },
    );
  }
}