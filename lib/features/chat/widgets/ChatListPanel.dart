// ignore_file: file_names
import 'dart:convert'; 
import 'package:flutter/material.dart';

import '../../contacts/ContactsController.dart'; 

class ChatListPanel extends StatefulWidget {
  // 🎯 SỬA LẠI: TRUYỀN FULL OBJECT USER THAY VÌ CHỈ TRUYỀN ID STRING
  final Function(Map<String, dynamic>) onChatSelected;
  final Function(Map<String, dynamic>)? onGlobalSearchFound; 
  
  const ChatListPanel({super.key, required this.onChatSelected, this.onGlobalSearchFound});

  @override
  State<ChatListPanel> createState() => _ChatListPanelState();
}

class _ChatListPanelState extends State<ChatListPanel> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  
  final ContactsController _contactController = ContactsController();
  
  String? _selectedChatId;

  @override
  void initState() {
    super.initState();
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

  ImageProvider _getSmartAvatar(String? avatarUrl, String userId) {
    if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.toLowerCase() != 'null') {
      if (avatarUrl.startsWith('data:image')) {
        final split = avatarUrl.split(',');
        if (split.length == 2) {
          try {
            return MemoryImage(base64Decode(split[1]));
          } catch (e) {
            debugPrint("Lỗi giải mã Base64: $e");
          }
        }
      } else {
        return NetworkImage(avatarUrl);
      }
    }
    return NetworkImage('https://i.pravatar.cc/150?u=$userId');
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    var result = await _contactController.searchUser(query.trim(), context: context);
    
    if (result != null && mounted) {
      if (widget.onGlobalSearchFound != null) {
        widget.onGlobalSearchFound!(result); 
      }
      _searchCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final friends = _contactController.friendsList;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchCtrl,
            onSubmitted: _performSearch, 
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

                  ImageProvider avatarProvider = _getSmartAvatar(friend['avatarUrl'], friend['id']);

                  return _HoverableChatItem(
                    name: friend['name'] ?? 'Bạn bè',
                    avatarProvider: avatarProvider, 
                    isSelected: _selectedChatId == friend['id'],
                    onTap: () {
                      setState(() => _selectedChatId = friend['id']);
                      // 🎯 TRUYỀN TOÀN BỘ OBJECT SANG DASHBOARD ĐỂ NÓ BƠM VÀO MAIN CHAT
                      widget.onChatSelected(friend); 
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

class _HoverableChatItem extends StatefulWidget {
  final String name;
  final ImageProvider avatarProvider; 
  final bool isSelected;
  final VoidCallback onTap;

  const _HoverableChatItem({
    required this.name, 
    required this.avatarProvider, 
    required this.isSelected, 
    required this.onTap
  });

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
              CircleAvatar(radius: 24, backgroundImage: widget.avatarProvider), 
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