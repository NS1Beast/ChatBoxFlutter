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
import '../../profile/FriendProfileScreen.dart'; 
import '../../contacts/ContactsController.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _searchedUser; 
  final ContactsController _globalContactsController = ContactsController();

  // LƯU TOÀN BỘ THÔNG TIN NGƯỜI ĐANG CHAT ĐỂ BƠM VÀO MAIN CHAT AREA
  Map<String, dynamic>? _activeChatUser;

  @override
  void initState() {
    super.initState();
    _loadUserTheme();
  }

  Future<void> _loadUserTheme() async {
    final authController = AuthController();
    final settingsController = SettingsController();
    String userId = await authController.getCurrentUserId();
    await settingsController.loadSettingsForUser(userId);
    themeController.changePrimaryColor(Color(settingsController.primaryColorValue));
    themeController.toggleDarkMode(settingsController.isDarkMode);
    await ProfileController().loadUserProfile(userId);
  }

  // HÀM LẮNG NGHE YÊU CẦU "CHUYỂN SANG TAB CHAT" (Nhận Full Object User)
  void _handleStartChat(Map<String, dynamic> user) {
    setState(() {
      _selectedIndex = 0; // Kích hoạt tab Chat
      _activeChatUser = user; // Lưu thông tin người chat
      _searchedUser = null; // Đóng cái khung Profile bên phải (nếu đang mở)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChatNavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() { _selectedIndex = index; });
            },
          ),
          
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(animation), child: child));
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
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(right: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1))),
                            child: ChatListPanel(
                              // 🎯 ĐÃ ĐỔI TÊN THAM SỐ Ở ĐÂY LUÔN CHO ĐỒNG BỘ
                              onChatSelected: (userMap) {
                                setState(() {
                                  _activeChatUser = userMap; 
                                  _searchedUser = null; 
                                });
                              },
                              onGlobalSearchFound: (user) {
                                setState(() {
                                  _searchedUser = user;
                                  _activeChatUser = null; // Tắt chat để hiện Profile
                                });
                              },
                            ), 
                          ),
                          
                          Expanded(
                            child: _searchedUser != null 
                              ? FriendProfileScreen(
                                  userId: _searchedUser!['id'],
                                  userName: _searchedUser!['fullName'] ?? 'Người dùng',
                                  avatarUrl: _searchedUser!['avatarUrl'] ?? '',
                                  coverImageUrl: _searchedUser!['coverUrl'] ?? '',
                                  bio: _searchedUser!['bio'] ?? '',
                                  initialRelationStatus: _searchedUser!['relationStatus'] ?? 'none',
                                  contactController: _globalContactsController,
                                )
                              : _activeChatUser != null 
                                  ? MainChatArea(
                                      chatId: _activeChatUser!['id'],
                                      chatName: _activeChatUser!['fullName'] ?? _activeChatUser!['name'] ?? 'Người dùng',
                                      chatAvatar: _activeChatUser!['avatarUrl'] ?? '',
                                      chatCover: _activeChatUser!['coverUrl'] ?? '',
                                      chatBio: _activeChatUser!['bio'] ?? '',
                                      relationStatus: _activeChatUser!['relationStatus'] ?? 'friend',
                                    ) 
                                  : const WelcomeScreen(), 
                          ), 
                        ],
                      );

                    case 1: 
                      return ContactsScreen(
                        onStartChat: (String userId) {
                          _handleStartChat({
                            'id': userId,
                            'name': 'Người dùng', 
                            'avatarUrl': '',
                            'bio': '',
                          });
                        }
                      );
                    case 2: return const TimelineScreen();
                    case 3: return const NotificationsScreen();
                    case 4: return const SettingsScreen();

                    default:
                      return Center(child: Text('Tính năng đang phát triển', style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))));
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