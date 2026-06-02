import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:chatapp/core/theme/AppTheme.dart';
import 'package:chatapp/core/theme/theme_controller.dart';
import 'package:chatapp/features/auth/LoginScreen.dart';

void main(List<String> args) async {
  if (runWebViewTitleBarWidget(args)) {
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1100, 750),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
  );

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
            isDark: false,
          ),
          darkTheme: AppTheme.getTheme(
            primaryColor: themeController.primaryColor, 
            isDark: true,
          ),
          themeMode: themeController.themeMode,
          home: const LoginScreen(), 
        );
      },
    );
  }
}