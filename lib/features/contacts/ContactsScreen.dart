// ignore_file: file_names
import 'package:flutter/material.dart';
import 'ContactsController.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactsController _controller = ContactsController();
  // Thêm Controller cho thanh cuộn Desktop
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            children: [
              // ==========================================
              // CỘT TRÁI: DANH SÁCH BẠN BÈ / NHÓM
              // ==========================================
              Container(
                width: 320,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(right: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                ),
                child: Column(
                  children: [
                    // Header & Search
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Danh bạ', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
                              IconButton(
                                icon: Icon(Icons.person_add_alt_1_rounded, color: primaryColor),
                                onPressed: () {}, // Gọi logic Thêm bạn/nhóm
                                tooltip: 'Thêm liên hệ',
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Custom Tab Bar
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _buildTabButton('Bạn bè', 0, primaryColor, textColor),
                                _buildTabButton('Nhóm', 1, primaryColor, textColor),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Search Bar
                          TextField(
                            onChanged: _controller.updateSearch,
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm...',
                              prefixIcon: Icon(Icons.search, color: textColor.withValues(alpha: 0.5)),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // List View kèm Scrollbar tàng hình
                    Expanded(
                      child: RawScrollbar(
                        controller: _scrollController,
                        thumbColor: textColor.withValues(alpha: 0.15),
                        radius: const Radius.circular(8),
                        thickness: 4,
                        child: _controller.currentTab == 0
                            ? _buildFriendsList(textColor, primaryColor)
                            : _buildGroupsList(textColor, primaryColor),
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // CỘT PHẢI: CHI TIẾT LIÊN HỆ
              // ==========================================
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                  child: Center(
                    child: _controller.currentTab == 0
                        ? _buildFriendDetails(textColor, primaryColor, surfaceColor)
                        : _buildGroupDetails(textColor, primaryColor, surfaceColor),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // --- COMPONENT HỖ TRỢ ---

  Widget _buildTabButton(String title, int index, Color primaryColor, Color textColor) {
    bool isSelected = _controller.currentTab == index;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _controller.switchTab(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
            ),
            alignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? primaryColor : textColor.withValues(alpha: 0.6)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList(Color textColor, Color primaryColor) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _controller.filteredFriends.length,
      itemBuilder: (context, index) {
        final friend = _controller.filteredFriends[index];
        final isSelected = _controller.selectedFriend?.id == friend.id;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), // Bo gọn 2 bên lề
          child: ListTile(
            selected: isSelected,
            selectedTileColor: primaryColor.withValues(alpha: 0.1),
            hoverColor: textColor.withValues(alpha: 0.05), // Đổi màu khi hover
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bo góc đẹp mắt
            leading: Stack(
              children: [
                CircleAvatar(backgroundImage: NetworkImage(friend.avatarUrl)),
                if (friend.isOnline)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(friend.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: textColor)),
            subtitle: Text(friend.isOnline ? 'Trực tuyến' : 'Ngoại tuyến', style: TextStyle(color: friend.isOnline ? Colors.green : textColor.withValues(alpha: 0.5), fontSize: 12)),
            onTap: () => _controller.selectFriend(friend),
          ),
        );
      },
    );
  }

  Widget _buildGroupsList(Color textColor, Color primaryColor) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _controller.filteredGroups.length,
      itemBuilder: (context, index) {
        final group = _controller.filteredGroups[index];
        final isSelected = _controller.selectedGroup?.id == group.id;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: ListTile(
            selected: isSelected,
            selectedTileColor: primaryColor.withValues(alpha: 0.1),
            hoverColor: textColor.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(image: NetworkImage(group.avatarUrl), fit: BoxFit.cover),
              ),
            ),
            title: Text(group.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: textColor)),
            subtitle: Text('${group.memberCount} thành viên', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
            onTap: () => _controller.selectGroup(group),
          ),
        );
      },
    );
  }

  // Giao diện bên phải khi chọn Bạn bè
  Widget _buildFriendDetails(Color textColor, Color primaryColor, Color surfaceColor) {
    final friend = _controller.selectedFriend;
    if (friend == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: textColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Chọn một người bạn để xem chi tiết', style: TextStyle(color: textColor.withValues(alpha: 0.5))),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(radius: 60, backgroundImage: NetworkImage(friend.avatarUrl)),
        const SizedBox(height: 24),
        Text(friend.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        Text(friend.phone, style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 16)),
        const SizedBox(height: 8),
        Text(friend.bio, style: TextStyle(color: primaryColor, fontSize: 15, fontStyle: FontStyle.italic)),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HoverableActionCard(icon: Icons.chat_bubble_rounded, label: 'Nhắn tin', primaryColor: primaryColor, surfaceColor: surfaceColor, textColor: textColor, onTap: (){}),
            const SizedBox(width: 16),
            _HoverableActionCard(icon: Icons.call_rounded, label: 'Gọi điện', primaryColor: primaryColor, surfaceColor: surfaceColor, textColor: textColor, onTap: (){}),
            const SizedBox(width: 16),
            _HoverableActionCard(icon: Icons.videocam_rounded, label: 'Video', primaryColor: primaryColor, surfaceColor: surfaceColor, textColor: textColor, onTap: (){}),
          ],
        )
      ],
    );
  }

  // Giao diện bên phải khi chọn Nhóm
  Widget _buildGroupDetails(Color textColor, Color primaryColor, Color surfaceColor) {
    final group = _controller.selectedGroup;
    if (group == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 80, color: textColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Chọn một nhóm để xem chi tiết', style: TextStyle(color: textColor.withValues(alpha: 0.5))),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            image: DecorationImage(image: NetworkImage(group.avatarUrl), fit: BoxFit.cover),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 24),
        Text(group.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        Text('${group.memberCount} thành viên', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 16)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(group.description, textAlign: TextAlign.center, style: TextStyle(color: primaryColor, fontSize: 15)),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HoverableActionCard(icon: Icons.forum_rounded, label: 'Vào Chat', primaryColor: primaryColor, surfaceColor: surfaceColor, textColor: textColor, onTap: (){}),
            const SizedBox(width: 16),
            _HoverableActionCard(icon: Icons.settings_rounded, label: 'Quản lý', primaryColor: primaryColor, surfaceColor: surfaceColor, textColor: textColor, onTap: (){}),
          ],
        )
      ],
    );
  }
}

// ==========================================
// WIDGET CON: Thẻ nút bấm thao tác có hiệu ứng Hover
// ==========================================
class _HoverableActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color primaryColor;
  final Color surfaceColor;
  final Color textColor;
  final VoidCallback onTap;

  const _HoverableActionCard({
    required this.icon, required this.label, 
    required this.primaryColor, required this.surfaceColor, required this.textColor, required this.onTap,
  });

  @override
  State<_HoverableActionCard> createState() => _HoverableActionCardState();
}

class _HoverableActionCardState extends State<_HoverableActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _isHovered ? widget.primaryColor.withValues(alpha: 0.1) : widget.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.03), 
                blurRadius: _isHovered ? 15 : 10, 
                offset: const Offset(0, 4)
              )
            ],
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: widget.primaryColor, size: 32),
              const SizedBox(height: 8),
              Text(widget.label, style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}