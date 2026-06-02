// ignore_file: file_names
import 'package:flutter/material.dart';
import '../widgets/ChatNavigationRail.dart';
import '../widgets/ChatListPanel.dart';
import '../widgets/MainChatArea.dart';
import '../widgets/WelcomeScreen.dart';
import '../../settings/SettingsScreen.dart'; 
import '../../contacts/ContactsScreen.dart';
import '../../timeline/TimelineScreen.dart';
import '../../notifications/NotificationsScreen.dart';
import '../../profile/ProfileController.dart';
import '../../../core/theme/theme_controller.dart'; 
import '../../settings/settings_controller.dart'; 
import '../../auth/AuthController.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String? _activeChatId;

  @override
  void initState() {
    super.initState();
    // VỪA VÀO DASHBOARD LÀ ÉP NẠP GIAO DIỆN NGAY!
    _loadUserTheme();
  }

  Future<void> _loadUserTheme() async {
    final authController = AuthController();
    final settingsController = SettingsController();
    
    // 1. Lấy ID của tài khoản đang đăng nhập
    String userId = await authController.getCurrentUserId();
    
    // 2. Chui vào ổ cứng móc cấu hình của riêng user này ra
    await settingsController.loadSettingsForUser(userId);
    
    // 3. Thay áo cho toàn bộ App ngay tắp lự
    themeController.changePrimaryColor(Color(settingsController.primaryColorValue));
    themeController.toggleDarkMode(settingsController.isDarkMode);
    await ProfileController().loadUserProfile(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Navigation
          ChatNavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          
          // 2. Khu vực nội dung chính
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                );
              },
              
              child: Builder(
                key: ValueKey(_selectedIndex),
                builder: (context) {
                  switch (_selectedIndex) {
                    case 0:
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch, 
                        children: [
                          Container(
                            width: 320,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(right: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1)),
                            ),
                            child: ChatListPanel(
                              onChatSelected: (chatId) {
                                setState(() {
                                  _activeChatId = chatId;
                                });
                              },
                            ), 
                          ),
                          
                          Expanded(
                            child: _activeChatId != null 
                                ? const MainChatArea() 
                                : const WelcomeScreen(), 
                          ), 
                        ],
                      );

                    case 1: return const ContactsScreen();
                    case 2: return const TimelineScreen();
                    case 3: return const NotificationsScreen();
                    case 4: return const SettingsScreen();

                    default:
                      return Center(
                        child: Text(
                          'Tính năng đang phát triển',
                          style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        )
                      );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}