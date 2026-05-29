import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../profile/ProfileScreen.dart';
// Nhớ import ProfileController vào đây
import '../../profile/ProfileController.dart'; 

class ChatNavigationRail extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const ChatNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<ChatNavigationRail> createState() => _ChatNavigationRailState();
}

class _ChatNavigationRailState extends State<ChatNavigationRail> {
  // Vì đã làm Singleton ở Bước 1, nên cái controller này CHÍNH LÀ cái controller bên trang Profile
  final ProfileController _profileController = ProfileController();

  // Hàm check ảnh ưu tiên: Ảnh vừa cắt (Local) -> Ảnh Google (Network) -> Icon Mặc định
  ImageProvider _getAvatarImage() {
    if (_profileController.localAvatarBytes != null) {
      return MemoryImage(_profileController.localAvatarBytes!); 
    } else if (_profileController.avatarUrl.isNotEmpty) {
      return NetworkImage(_profileController.avatarUrl); 
    } else {
      return MemoryImage(Uint8List(0)); 
    }
  }

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
          
          // ==========================================
          // AVATAR NGƯỜI DÙNG ĐÃ ĐỒNG BỘ
          // ==========================================
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: InkWell( 
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
                // 🎯 ListenableBuilder giúp Avatar tự load lại khi bên Controller có lệnh notifyListeners()
                child: ListenableBuilder(
                  listenable: _profileController,
                  builder: (context, child) {
                    return CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white24,
                      backgroundImage: _getAvatarImage(),
                      // Fallback: Nếu không có ảnh thì hiện Icon mặc định
                      child: (_profileController.localAvatarBytes == null && _profileController.avatarUrl.isEmpty) 
                          ? const Icon(Icons.person_rounded, size: 20, color: Colors.white) 
                          : null,
                    );
                  }
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData activeIcon, IconData inactiveIcon, int index) {
    final isSelected = widget.selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: IconButton(
        icon: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? Colors.white : Colors.white54,
          size: 26,
        ),
        onPressed: () => widget.onDestinationSelected(index),
        // Thêm hiệu ứng nền mờ khi được chọn
        style: IconButton.styleFrom(
          backgroundColor: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}