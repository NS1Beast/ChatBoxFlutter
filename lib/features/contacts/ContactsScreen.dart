// ignore_file: file_names
import 'dart:convert';
import 'package:flutter/material.dart';

import 'ContactsController.dart';
import '../chat/widgets/MainChatArea.dart'; 
import '../chat/widgets/create_group_dialog.dart'; 

class ContactsScreen extends StatefulWidget {
  final Function(String userId)? onStartChat; 

  const ContactsScreen({super.key, this.onStartChat});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactsController _controller = ContactsController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.loadFriends();
    _controller.loadGroups();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  ImageProvider _getSmartAvatar(String? avatarUrl, String nameFallback) {
    if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.toLowerCase() != 'null') {
      if (avatarUrl.startsWith('data:image')) {
        final split = avatarUrl.split(',');
        if (split.length == 2) {
          try { return MemoryImage(base64Decode(split[1])); } catch (e) { debugPrint("Lỗi giải mã Base64: $e"); }
        }
      } else {
        return NetworkImage(avatarUrl);
      }
    }
    // Nếu không có ảnh thì lấy chữ cái đầu làm avatar
    return NetworkImage('https://ui-avatars.com/api/?name=$nameFallback&background=random');
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
              // CỘT TRÁI
              Container(
                width: 320,
                decoration: BoxDecoration(color: surfaceColor, border: Border(right: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Danh bạ', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
                              // 🎯 NÚT TẠO NHÓM NẰM Ở ĐÂY
                              IconButton(
                                icon: Icon(_controller.currentTab == 0 ? Icons.person_add_alt_1_rounded : Icons.group_add_rounded, color: primaryColor), 
                                tooltip: _controller.currentTab == 0 ? 'Thêm liên hệ' : 'Tạo nhóm mới',
                                onPressed: () async {
                                  if (_controller.currentTab == 1) {
                                    // 🎯 Ném cả cái controller vào, không xài danh sách validFriends nữa
                                    final result = await showDialog(
                                      context: context,
                                      builder: (_) => CreateGroupDialog(controller: _controller),
                                    );
                                    if (result == true) {
                                      _controller.loadGroups(); 
                                    }
                                  }
                                }
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                _buildTabButton('Bạn bè', 0, primaryColor, textColor),
                                _buildTabButton('Nhóm', 1, primaryColor, textColor),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _searchCtrl,
                            onChanged: _controller.updateSearch, 
                            onSubmitted: (email) => _controller.searchGlobalUser(context, email), 
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm...',
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
                    Expanded(
                      child: _controller.isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : RawScrollbar(
                        controller: _scrollController,
                        thumbColor: textColor.withValues(alpha: 0.15),
                        radius: const Radius.circular(8), thickness: 4,
                        child: _controller.currentTab == 0
                            ? _buildFriendsList(textColor, primaryColor)
                            : _buildGroupsList(textColor, primaryColor), // 🎯 GỌI HÀM RENDER LIST NHÓM
                      ),
                    ),
                  ],
                ),
              ),

              // CỘT PHẢI
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                  child: _controller.currentTab == 0
                      ? _buildFriendDetails(textColor, primaryColor, surfaceColor)
                      : _buildGroupDetails(textColor, primaryColor, surfaceColor), // 🎯 GỌI HÀM RENDER INFO NHÓM
                ),
              ),
            ],
          ),
        );
      }
    );
  }

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
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? primaryColor : textColor.withValues(alpha: 0.6))),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList(Color textColor, Color primaryColor) {
    if (_controller.filteredFriends.isEmpty) {
      return Center(child: Text("Không có liên hệ nào.\nNhập Email ở trên để tìm bạn mới!", textAlign: TextAlign.center, style: TextStyle(color: textColor.withValues(alpha: 0.5))));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _controller.filteredFriends.length,
      itemBuilder: (context, index) {
        final friend = _controller.filteredFriends[index];
        final isSelected = _controller.selectedFriend?['id'] == friend['id'];
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), 
          child: ListTile(
            selected: isSelected, selectedTileColor: primaryColor.withValues(alpha: 0.1),
            hoverColor: textColor.withValues(alpha: 0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
            leading: CircleAvatar(backgroundImage: _getSmartAvatar(friend['avatarUrl'], friend['name'] ?? 'Friend')),
            title: Text(friend['name'] ?? 'Bạn bè', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: textColor)),
            subtitle: Text(friend['bio'] ?? 'Chưa có tiểu sử', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
            onTap: () => _controller.selectFriend(friend),
          ),
        );
      },
    );
  }

  // 🎯 GIAO DIỆN DANH SÁCH NHÓM (CỘT TRÁI)
  Widget _buildGroupsList(Color textColor, Color primaryColor) {
    if (_controller.filteredGroups.isEmpty) {
      return Center(child: Text("Bạn chưa tham gia nhóm nào.\nNhấn biểu tượng ➕ phía trên để tạo nhóm!", textAlign: TextAlign.center, style: TextStyle(color: textColor.withValues(alpha: 0.5))));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _controller.filteredGroups.length,
      itemBuilder: (context, index) {
        final group = _controller.filteredGroups[index];
        final isSelected = _controller.selectedGroup?['id'] == group['id'];
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), 
          child: ListTile(
            selected: isSelected, selectedTileColor: primaryColor.withValues(alpha: 0.1),
            hoverColor: textColor.withValues(alpha: 0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
            leading: CircleAvatar(backgroundImage: _getSmartAvatar(group['groupAvatarUrl'], group['groupName'] ?? 'G')),
            title: Text(group['groupName'] ?? 'Nhóm', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: textColor)),
            subtitle: Text(group['myRole'] == 'admin' ? 'Bạn là Trưởng nhóm' : 'Thành viên', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
            onTap: () => _controller.selectGroup(group),
          ),
        );
      },
    );
  }

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

    String relationStatus = friend['relationStatus'] ?? (friend['isFriend'] == true ? 'friend' : 'none');
    bool isFriend = (relationStatus == 'friend');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(radius: 60, backgroundImage: _getSmartAvatar(friend['avatarUrl'], friend['name'] ?? 'F')),
              const SizedBox(height: 24),
              Text(friend['name'] ?? 'Người dùng', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text(friend['bio'] ?? 'Chưa có thông tin giới thiệu', style: TextStyle(color: primaryColor, fontSize: 15, fontStyle: FontStyle.italic)),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HoverableActionCard(
                    icon: Icons.chat_bubble_rounded, label: 'Nhắn tin', primaryColor: primaryColor, surfaceColor: surfaceColor, textColor: textColor, 
                    onTap: () {
                      if (widget.onStartChat != null) widget.onStartChat!(friend['id']);
                    }
                  ),
                  const SizedBox(width: 16),
                  _HoverableActionCard(
                    icon: Icons.call_rounded, label: 'Gọi thoại', primaryColor: primaryColor, surfaceColor: surfaceColor, textColor: textColor, 
                    onTap: () {
                      if (widget.onStartChat != null) widget.onStartChat!(friend['id']);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainChatArea(chatId: friend['id'], chatName: friend['name'] ?? '', chatAvatar: friend['avatarUrl'] ?? '', autoStartVoiceCall: true)));
                    }
                  ),
                  const SizedBox(width: 16),
                  _HoverableActionCard(
                    icon: Icons.videocam_rounded, label: 'Gọi video', primaryColor: primaryColor, surfaceColor: surfaceColor, textColor: textColor, 
                    onTap: () {
                      if (widget.onStartChat != null) widget.onStartChat!(friend['id']);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainChatArea(chatId: friend['id'], chatName: friend['name'] ?? '', chatAvatar: friend['avatarUrl'] ?? '', autoStartVideoCall: true)));
                    }
                  ),
                ],
              ),
              const SizedBox(height: 24), 

              SizedBox(
                width: double.infinity, height: 56, 
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: relationStatus == 'friend'
                      ? OutlinedButton.icon(
                          key: const ValueKey('unfriend'), onPressed: () async { await _controller.toggleFriendStatusFromPanel(); },
                          icon: const Icon(Icons.person_remove_rounded, size: 22), label: const FittedBox(child: Text('Hủy kết bạn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), minimumSize: const Size.fromHeight(56)),
                        )
                      : relationStatus == 'pending'
                        ? FilledButton.icon(
                            key: const ValueKey('pending'), onPressed: () async { await _controller.toggleFriendStatusFromPanel(); },
                            icon: const Icon(Icons.access_time_rounded, size: 22), label: const FittedBox(child: Text('Đã gửi yêu cầu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            style: FilledButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), minimumSize: const Size.fromHeight(56)),
                          )
                        : relationStatus == 'awaiting'
                          ? FilledButton.icon(
                              key: const ValueKey('awaiting'), onPressed: () async { await _controller.toggleFriendStatusFromPanel(); },
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 22), label: const FittedBox(child: Text('Chấp nhận lời mời', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                              style: FilledButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), minimumSize: const Size.fromHeight(56)),
                            )
                          : FilledButton.icon(
                              key: const ValueKey('add_friend'), onPressed: () async { await _controller.toggleFriendStatusFromPanel(); },
                              icon: const Icon(Icons.person_add_rounded, size: 22), label: const FittedBox(child: Text('Thêm bạn bè', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                              style: FilledButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), minimumSize: const Size.fromHeight(56)),
                            ),
                ),
              ),
              const SizedBox(height: 32),

              _buildInfoSectionHeader('Thông tin cá nhân', textColor),
              Container(
                decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                  children: [
                    _buildInfoTile(Icons.info_outline_rounded, 'Bio', friend['bio'] ?? 'Trống', textColor, primaryColor),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _buildInfoTile(Icons.email_outlined, 'Email', isFriend ? (friend['email'] ?? 'Ẩn') : 'Chỉ bạn bè mới xem được', textColor, primaryColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 GIAO DIỆN THÔNG TIN NHÓM (CỘT PHẢI)
  Widget _buildGroupDetails(Color textColor, Color primaryColor, Color surfaceColor) {
    final group = _controller.selectedGroup;
    if (group == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_rounded, size: 80, color: textColor.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('Chọn một nhóm để xem thông tin chi tiết', style: TextStyle(color: textColor.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(radius: 60, backgroundImage: _getSmartAvatar(group['groupAvatarUrl'], group['groupName'] ?? 'G')),
              const SizedBox(height: 24),
              Text(group['groupName'] ?? 'Nhóm Chat', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: group['myRole'] == 'admin' ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(group['myRole'] == 'admin' ? 'Trưởng Nhóm' : 'Thành viên', style: TextStyle(color: group['myRole'] == 'admin' ? Colors.green : textColor.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HoverableActionCard(
                    icon: Icons.chat_rounded, label: 'Vào nhóm chat', primaryColor: primaryColor, surfaceColor: surfaceColor, textColor: textColor, 
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainChatArea(
                            isGroup: true, 
                            chatId: group['id'], 
                            chatName: group['groupName'] ?? 'Nhóm',
                            chatAvatar: group['groupAvatarUrl'] ?? '',
                          ),
                        ),
                      );
                    }
                  ),
                ],
              ),
              const SizedBox(height: 24), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSectionHeader(String title, Color textColor) {
    return Padding(padding: const EdgeInsets.only(bottom: 12, left: 8), child: Align(alignment: Alignment.centerLeft, child: Text(title.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor.withValues(alpha: 0.5), letterSpacing: 1.2))));
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle, Color textColor, Color primaryColor) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: primaryColor, size: 20)),
      title: Text(title, style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.5))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}

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
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _isHovered ? widget.primaryColor.withValues(alpha: 0.1) : widget.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.03), blurRadius: _isHovered ? 15 : 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Icon(widget.icon, color: widget.primaryColor, size: 28),
                const SizedBox(height: 8),
                Text(widget.label, style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}