import 'package:flutter/material.dart';
import '../widgets/ChatNavigationRail.dart';
import '../widgets/ChatListPanel.dart';
import '../widgets/MainChatArea.dart';
// Import thêm file Settings bạn vừa tạo
import '../../settings/SettingsScreen.dart'; 

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
              // Logic chuyển đổi nội dung:
              // - Nếu chọn Index 3 (Cài đặt): Hiển thị toàn màn hình Settings
              // - Nếu chọn các Index khác: Hiển thị giao diện Chat (List + Area)
              child: _selectedIndex == 3
                  ? const SettingsScreen(key: ValueKey('Settings'))
                  : Row(
                      key: const ValueKey('ChatContent'),
                      children: [
                        // Danh sách Chat
                        Container(
                          width: 320,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border(
                              right: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
                            ),
                          ),
                          child: const ChatListPanel(),
                        ),
                        
                        // Khu vực Chat chính
                        const Expanded(
                          child: MainChatArea(),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}