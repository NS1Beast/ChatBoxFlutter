// ignore_file: file_names
import 'package:flutter/material.dart';

class ChatSession {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;

  ChatSession({
    required this.id, required this.name, required this.avatarUrl,
    required this.lastMessage, required this.time, this.unreadCount = 0, this.isOnline = false,
  });
}

class ChatListPanel extends StatefulWidget {
  // THÊM CALLBACK ĐỂ BÁO RA BÊN NGOÀI
  final Function(String) onChatSelected;

  const ChatListPanel({super.key, required this.onChatSelected});

  @override
  State<ChatListPanel> createState() => _ChatListPanelState();
}

class _ChatListPanelState extends State<ChatListPanel> {
  final ScrollController _scrollController = ScrollController();
  
  // Mặc định không chọn ai (null)
  String? _selectedChatId;

  final List<ChatSession> _chats = [
    ChatSession(id: '1', name: 'Trần Thị B', avatarUrl: 'https://i.pravatar.cc/150?img=20', lastMessage: 'Nhìn xịn thật sự, đúng chuẩn Mac!', time: '10:36 AM', isOnline: true),
    ChatSession(id: '2', name: 'Hội Coder Cú Đêm', avatarUrl: 'https://i.pravatar.cc/150?img=24', lastMessage: 'Ai debug hộ tui cái lỗi này với', time: '09:12 AM', unreadCount: 5),
    ChatSession(id: '3', name: 'Nguyễn Văn A', avatarUrl: 'https://i.pravatar.cc/150?img=12', lastMessage: 'Ok chốt vậy nha.', time: 'Hôm qua', isOnline: true),
    ChatSession(id: '4', name: 'Lê Hoàng C', avatarUrl: 'https://i.pravatar.cc/150?img=8', lastMessage: 'Đã gửi một tệp đính kèm.', time: 'Hôm qua'),
    ChatSession(id: '5', name: 'Dự án AI', avatarUrl: 'https://i.pravatar.cc/150?img=11', lastMessage: 'Deadline tuần sau nha mọi người', time: 'T2', unreadCount: 1),
    ChatSession(id: '6', name: 'Phạm D', avatarUrl: 'https://i.pravatar.cc/150?img=15', lastMessage: 'Cảm ơn sếp!', time: 'T7'),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        // Thanh tìm kiếm
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
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
          child: RawScrollbar(
            controller: _scrollController,
            thumbColor: textColor.withValues(alpha: 0.15),
            radius: const Radius.circular(8),
            thickness: 4,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                return _HoverableChatItem(
                  chat: _chats[index],
                  isSelected: _selectedChatId == _chats[index].id,
                  onTap: () {
                    // Cập nhật giao diện làm sáng danh sách
                    setState(() => _selectedChatId = _chats[index].id);
                    // Bắn tín hiệu ra ngoài Dashboard
                    widget.onChatSelected(_chats[index].id);
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
  final ChatSession chat;
  final bool isSelected;
  final VoidCallback onTap;

  const _HoverableChatItem({required this.chat, required this.isSelected, required this.onTap});

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
                  CircleAvatar(radius: 24, backgroundImage: NetworkImage(widget.chat.avatarUrl)),
                  if (widget.chat.isOnline)
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(widget.chat.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor))),
                        Text(widget.chat.time, style: TextStyle(fontSize: 12, color: widget.chat.unreadCount > 0 ? primaryColor : textColor.withValues(alpha: 0.5), fontWeight: widget.chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: Text(widget.chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: widget.chat.unreadCount > 0 ? textColor : textColor.withValues(alpha: 0.6), fontWeight: widget.chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal))),
                        if (widget.chat.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(10)),
                            child: Text(widget.chat.unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}