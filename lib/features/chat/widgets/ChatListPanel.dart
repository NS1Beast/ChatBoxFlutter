// ignore_file: file_names
import 'package:flutter/material.dart';

// 🎯 Tui đã chỉnh lại đường dẫn lùi 2 cấp (../../) để ra tới mục features, sau đó chui vào profile/contact
import '../../profile/FriendProfileScreen.dart'; 
import '../../contacts/ContactsController.dart'; // NẾU VẪN ĐỎ DÒNG NÀY, HÃY XÓA NÓ VÀ DÙNG CTRL + . NHƯ CÁCH 1

class ChatListPanel extends StatefulWidget {
  final Function(String) onChatSelected;
  const ChatListPanel({super.key, required this.onChatSelected});

  @override
  State<ChatListPanel> createState() => _ChatListPanelState();
}

class _ChatListPanelState extends State<ChatListPanel> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  
  // Nơi khai báo Controller gọi API
  final ContactsController _contactController = ContactsController();
  
  String? _selectedChatId;

  @override
  void initState() {
    super.initState();
    // Vừa mở App là chọc Database tải danh sách bạn bè
    _contactController.loadFriends();
    _contactController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    _contactController.dispose();
    super.dispose();
  }

  // HÀM TÌM KIẾM NGƯỜI DÙNG KHI BẤM ENTER
  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    var result = await _contactController.searchUser(query.trim());
    
    if (result != null && mounted) {
      // Tìm thấy -> Mở Profile
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => FriendProfileScreen(
          userId: result['id'], 
          userName: result['fullName'] ?? 'Người dùng',
          avatarUrl: result['avatarUrl'] ?? '',
          bio: result['bio'] ?? 'Chưa có thông tin',
          initialIsFriend: result['isFriend'],
          contactController: _contactController, 
        ),
      ));
      _searchCtrl.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy người dùng này!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final friends = _contactController.friendsList;

    return Column(
      children: [
        // THANH TÌM KIẾM (REAL)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchCtrl,
            onSubmitted: _performSearch, // 🎯 BẤM ENTER ĐỂ TÌM
            decoration: InputDecoration(
              hintText: 'Nhập Email để tìm kiếm...',
              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
              prefixIcon: Icon(Icons.search_rounded, color: textColor.withValues(alpha: 0.5)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        
        // DANH SÁCH BẠN BÈ / CHAT (REAL)
        Expanded(
          child: _contactController.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : friends.isEmpty 
            ? Center(child: Text("Chưa có liên hệ nào.\nHãy tìm kiếm email để kết bạn!", textAlign: TextAlign.center, style: TextStyle(color: textColor.withValues(alpha: 0.5))))
            : RawScrollbar(
              controller: _scrollController,
              thumbColor: textColor.withValues(alpha: 0.15),
              radius: const Radius.circular(8), thickness: 4,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  String avatar = (friend['avatarUrl'] == null || friend['avatarUrl'] == "") 
                                ? 'https://i.pravatar.cc/150?u=${friend['id']}' 
                                : friend['avatarUrl'];

                  return _HoverableChatItem(
                    name: friend['name'] ?? 'Bạn bè',
                    avatarUrl: avatar,
                    isSelected: _selectedChatId == friend['id'],
                    onTap: () {
                      setState(() => _selectedChatId = friend['id']);
                      widget.onChatSelected(friend['id']);
                    },
                  );
                },
              ),
            ),
        ),
      ],
    );
  }
}

// Widget Item
class _HoverableChatItem extends StatefulWidget {
  final String name;
  final String avatarUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _HoverableChatItem({required this.name, required this.avatarUrl, required this.isSelected, required this.onTap});

  @override
  State<_HoverableChatItem> createState() => _HoverableChatItemState();
}

class _HoverableChatItemState extends State<_HoverableChatItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected ? primaryColor.withValues(alpha: 0.1) : _isHovered ? textColor.withValues(alpha: 0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 24, backgroundImage: NetworkImage(widget.avatarUrl)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}