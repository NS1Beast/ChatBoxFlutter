import 'package:flutter/material.dart';
import '../../profile/ProfileScreen.dart';
class ChatNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const ChatNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72, // Độ rộng chuẩn cho sidebar gọn gàng
      color: Theme.of(context).colorScheme.primary, // Nền màu Tím #8470FF
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo App nhỏ
          const Icon(Icons.forum_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 32),
          
          // Các nút điều hướng
          _buildNavItem(Icons.chat_bubble_rounded, Icons.chat_bubble_outline, 0),
          _buildNavItem(Icons.people_alt_rounded, Icons.people_outline, 1),
          _buildNavItem(Icons.newspaper_rounded, Icons.newspaper_outlined, 2),
          _buildNavItem(Icons.inbox_rounded, Icons.inbox_outlined, 3),
          const Spacer(),
          
          // Nút Cài đặt
          _buildNavItem(Icons.settings_rounded, Icons.settings_outlined, 4),
          const SizedBox(height: 16),
          
          // Avatar của bạn (Góc dưới cùng)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: InkWell( // Bọc InkWell ở đây
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData activeIcon, IconData inactiveIcon, int index) {
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: IconButton(
        icon: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? Colors.white : Colors.white54,
          size: 26,
        ),
        onPressed: () => onDestinationSelected(index),
        // Thêm hiệu ứng nền mờ khi được chọn
        style: IconButton.styleFrom(
          backgroundColor: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}