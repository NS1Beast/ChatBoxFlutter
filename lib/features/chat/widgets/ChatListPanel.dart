// ignore_file: file_names
import 'dart:convert'; 
import 'package:flutter/material.dart';

import '../../contacts/ContactsController.dart'; 

class ChatListPanel extends StatefulWidget {
  final ContactsController controller; // 🎯 NHẬN CHUNG 1 BỘ NHỚ TỪ DASHBOARD
  final Function(Map<String, dynamic>) onChatSelected;
  final Function(Map<String, dynamic>)? onGlobalSearchFound; 
  
  const ChatListPanel({super.key, required this.controller, required this.onChatSelected, this.onGlobalSearchFound});

  @override
  State<ChatListPanel> createState() => _ChatListPanelState();
}

class _ChatListPanelState extends State<ChatListPanel> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  
  String? _selectedChatId;

  @override
  void initState() {
    super.initState();
    widget.controller.loadFriends();
    widget.controller.loadGroups(); 
    
    // Lắng nghe khi có nhóm/bạn mới tạo thì vẽ lại màn hình
    widget.controller.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    widget.controller.removeListener(_onDataChanged);
    super.dispose();
  }

  ImageProvider _getSmartAvatar(String? avatarUrl, String fallbackName) {
    if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.toLowerCase() != 'null') {
      if (avatarUrl.startsWith('data:image')) {
        final split = avatarUrl.split(',');
        if (split.length == 2) {
          try { return MemoryImage(base64Decode(split[1])); } catch (e) { debugPrint("Lỗi Base64: $e"); }
        }
      } else {
        return NetworkImage(avatarUrl);
      }
    }
    return NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(fallbackName)}&background=random');
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    var result = await widget.controller.searchUser(query.trim(), context: context);
    
    if (result != null && mounted) {
      if (widget.onGlobalSearchFound != null) {
        widget.onGlobalSearchFound!(result); 
      }
      _searchCtrl.clear();
      widget.controller.updateSearch(''); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    // ========================================================
    // 🎯 GỘP CHUNG BẠN BÈ VÀ NHÓM VÀO 1 DANH SÁCH DUY NHẤT
    // ========================================================
    final List<Map<String, dynamic>> unifiedList = [];
    
    for (var f in widget.controller.filteredFriends) {
      unifiedList.add({...f, 'isGroup': false}); // Đánh dấu là cá nhân
    }
    
    for (var g in widget.controller.filteredGroups) {
      unifiedList.add({
        'id': g['id'],
        'name': g['groupName'] ?? 'Nhóm',
        'avatarUrl': g['groupAvatarUrl'],
        'isGroup': true, // Đánh dấu là Nhóm
      });
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: widget.controller.updateSearch, // Vừa gõ vừa lọc ngay trên List
            onSubmitted: _performSearch, // Bấm Enter để tìm người lạ qua API
            decoration: InputDecoration(
              hintText: 'Tìm bạn bè hoặc nhóm...',
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
          child: widget.controller.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : unifiedList.isEmpty 
            ? Center(child: Text("Chưa có liên hệ hoặc nhóm nào.", textAlign: TextAlign.center, style: TextStyle(color: textColor.withValues(alpha: 0.5))))
            : RawScrollbar(
              controller: _scrollController,
              thumbColor: textColor.withValues(alpha: 0.15),
              radius: const Radius.circular(8), thickness: 4,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: unifiedList.length,
                itemBuilder: (context, index) {
                  final item = unifiedList[index];

                  return _HoverableChatItem(
                    name: item['name'],
                    avatarProvider: _getSmartAvatar(item['avatarUrl'], item['name']), 
                    isGroup: item['isGroup'], // 🎯 Hiển thị thêm icon nhỏ nếu là nhóm
                    isSelected: _selectedChatId == item['id'],
                    onTap: () {
                      setState(() => _selectedChatId = item['id']);
                      widget.onChatSelected(item); // Bắn nguyên cục này sang MainChat
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
  final bool isGroup;
  final VoidCallback onTap;

  const _HoverableChatItem({
    required this.name, 
    required this.avatarProvider, 
    required this.isSelected,
    this.isGroup = false, 
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
              Stack(
                children: [
                  CircleAvatar(radius: 24, backgroundImage: widget.avatarProvider),
                  if (widget.isGroup) // Đính kèm icon Group nhỏ góc dưới avatar
                    Positioned(
                      right: -2, bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle),
                        child: Icon(Icons.group_rounded, size: 14, color: primaryColor),
                      ),
                    )
                ],
              ), 
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