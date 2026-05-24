// ignore_file: file_names
import 'package:flutter/material.dart';
import '../widgets/ChatNavigationRail.dart';
import '../widgets/ChatListPanel.dart';
import '../widgets/MainChatArea.dart';
import '../../settings/SettingsScreen.dart'; 
import '../../contacts/ContactsScreen.dart';
import '../../timeline/TimelineScreen.dart';
import '../../notifications/NotificationsScreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      // Đã loại bỏ Column và CustomTitleBar, dùng trực tiếp Row làm body chính
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Navigation (Sidebar màu tím)
          ChatNavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          
          // 2. Khu vực nội dung chính (Thay đổi dựa theo index)
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
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
                              border: Border(
                                right: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.2), 
                                  width: 1
                                )
                              ),
                            ),
                            child: const ChatListPanel(), 
                          ),
                          const Expanded(child: MainChatArea()), 
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
                          style: TextStyle(
                            fontSize: 18, 
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                          ),
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