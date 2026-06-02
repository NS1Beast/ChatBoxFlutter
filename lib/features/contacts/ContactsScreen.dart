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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    _controller.dispose();
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
                                onPressed: () {}, // TODO: Tính năng tạo nhóm
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
                            controller: _searchCtrl,
                            onChanged: _controller.updateSearch, 
                            onSubmitted: (email) => _controller.searchGlobalUser(context, email), // Bấm Enter tìm Global
                            decoration: InputDecoration(
                              hintText: 'Nhập Email để tìm...',
                              hintStyle: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.5)),
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
                      // 🎯 SỬA LỖI Ở ĐÂY: Gọi thẳng .isLoading thay vì .apiController
                      child: _controller.isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : RawScrollbar(
                        controller: _scrollController,
                        thumbColor: textColor.withValues(alpha: 0.15),
                        radius: const Radius.circular(8),
                        thickness: 4,
                        child: _controller.currentTab == 0
                            ? _buildFriendsList(textColor, primaryColor)
                            : Center(child: Text("Tính năng Nhóm đang phát triển", style: TextStyle(color: textColor.withValues(alpha: 0.5)))),
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // CỘT PHẢI: CHI TIẾT LIÊN HỆ CẢI TIẾN
              // ==========================================
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                  child: _controller.currentTab == 0
                      ? _buildFriendDetails(textColor, primaryColor, surfaceColor)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // --- CÁC HÀM XÂY DỰNG CỘT TRÁI ---

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
    if (_controller.filteredFriends.isEmpty) {
      return Center(child: Text("Không có liên hệ nào.\nTìm bằng Email để kết bạn!", textAlign: TextAlign.center, style: TextStyle(color: textColor.withValues(alpha: 0.5))));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _controller.filteredFriends.length,
      itemBuilder: (context, index) {
        final friend = _controller.filteredFriends[index];
        final isSelected = _controller.selectedFriend?['id'] == friend['id'];
        
        String avatarUrl = (friend['avatarUrl'] == null || friend['avatarUrl'] == "") 
                         ? 'https://i.pravatar.cc/150?u=${friend['id']}' : friend['avatarUrl'];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), 
          child: ListTile(
            selected: isSelected,
            selectedTileColor: primaryColor.withValues(alpha: 0.1),
            hoverColor: textColor.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
            leading: CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
            title: Text(friend['name'] ?? 'Bạn bè', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: textColor)),
            subtitle: Text(friend['bio'] ?? 'Chưa có tiểu sử', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
            onTap: () => _controller.selectFriend(friend),
          ),
        );
      },
    );
  }

  // ==========================================
  // CÁC HÀM XÂY DỰNG CỘT PHẢI (CHI TIẾT)
  // ==========================================

  Widget _buildFriendDetails(Color textColor, Color primaryColor, Color surfaceColor) {
    final friend = _controller.selectedFriend;
    if (friend == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 80, color: textColor.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('Chọn một người bạn hoặc nhập Email để tìm kiếm', style: TextStyle(color: textColor.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    String displayAvatar = (friend['avatarUrl'] == null || friend['avatarUrl'] == "") 
                         ? 'https://i.pravatar.cc/150?u=${friend['id']}' : friend['avatarUrl'];
    bool isFriend = friend['isFriend'] ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Header (Avatar + Tên)
              CircleAvatar(radius: 60, backgroundImage: NetworkImage(displayAvatar)),
              const SizedBox(height: 24),
              Text(friend['name'] ?? 'Người dùng', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text(friend['bio'] ?? 'Chưa có thông tin giới thiệu', style: TextStyle(color: primaryColor, fontSize: 15, fontStyle: FontStyle.italic)),
              const SizedBox(height: 32),
              
              // 2. Action Buttons (Kết bạn / Nhắn tin / Gọi)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🎯 Nút KẾT BẠN (Sửa lỗi Void Callback)
                  _HoverableActionCard(
                    icon: isFriend ? Icons.person_remove_rounded : Icons.person_add_rounded, 
                    label: isFriend ? 'Hủy kết bạn' : 'Thêm bạn', 
                    primaryColor: isFriend ? Colors.redAccent : primaryColor, 
                    surfaceColor: surfaceColor, textColor: textColor, 
                    onTap: () async {
                      // Gọi hàm dành riêng cho Panel không cần truyền ID
                      await _controller.toggleFriendStatusFromPanel();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isFriend ? 'Đã hủy kết bạn' : 'Đã thêm vào danh bạ')));
                      }
                    }
                  ),
                  
                  if (isFriend) ...[
                    const SizedBox(width: 16),
                    _HoverableActionCard(icon: Icons.chat_bubble_rounded, label: 'Nhắn tin', primaryColor: primaryColor, surfaceColor: surfaceColor, textColor: textColor, onTap: (){}),
                    const SizedBox(width: 16),
                    _HoverableActionCard(icon: Icons.videocam_rounded, label: 'Gọi video', primaryColor: primaryColor, surfaceColor: surfaceColor, textColor: textColor, onTap: (){}),
                  ]
                ],
              ),
              const SizedBox(height: 40),

              // 3. Thông tin cá nhân (Card)
              _buildInfoSectionHeader('Thông tin cá nhân', textColor),
              Container(
                decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                  children: [
                    _buildInfoTile(Icons.info_outline_rounded, 'Bio', friend['bio'] ?? 'Trống', textColor, primaryColor),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _buildInfoTile(Icons.email_outlined, 'Email', friend['email'] ?? 'Ẩn', textColor, primaryColor),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 5. Vùng Nguy hiểm (Chặn)
              if (isFriend) ...[
                _buildInfoSectionHeader('Tùy chọn', textColor),
                Container(
                  decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    children: [
                      _buildActionTile(Icons.block_rounded, 'Chặn người dùng', Colors.orange),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor.withValues(alpha: 0.5), letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle, Color textColor, Color primaryColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.5))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget _buildActionTile(IconData icon, String title, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
      onTap: () {},
    );
  }
}

// ==========================================
// WIDGET CON: Thẻ nút bấm thao tác
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.03), blurRadius: _isHovered ? 15 : 10, offset: const Offset(0, 4))],
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