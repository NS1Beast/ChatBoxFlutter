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
      body: Row(
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
                // Hiệu ứng mờ dần và trượt nhẹ khi chuyển tab
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
              
              // Sử dụng switch case để điều hướng các màn hình rõ ràng
              child: Builder(
                key: ValueKey(_selectedIndex),
                builder: (context) {
                  switch (_selectedIndex) {
                    case 0: // Màn hình Chat chính
                      return Row(
                        children: [
                          Container(
                            width: 320,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(
                                right: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.2), 
                                  width: 1
                                ),
                              ),
                            ),
                            child: const ChatListPanel(), 
                          ),
                          const Expanded(child: MainChatArea()), 
                        ],
                      );

                    case 1: // Màn hình BẠN BÈ VÀ NHÓM
                      return const ContactsScreen();

                    case 2: // Màn hình BÀI VIẾT
                      return const TimelineScreen();

                    case 3:
                      return const NotificationsScreen();

                    case 4: // Màn hình CÀI ĐẶT
                      return const SettingsScreen();

                    default: // Các màn hình chưa phát triển (VD: Gọi điện - index 2)
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