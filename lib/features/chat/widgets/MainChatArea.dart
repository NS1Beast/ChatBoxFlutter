import 'package:flutter/material.dart';

class MainChatArea extends StatelessWidget {
  const MainChatArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Màu xám nhạt để nổi bật bong bóng chat
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        children: [
          // Header (Tên người đang chat)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=20'),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Người Dùng 0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Đang hoạt động', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
                const Spacer(),
                IconButton(icon: Icon(Icons.call_outlined, color: Theme.of(context).colorScheme.primary), onPressed: () {}),
                IconButton(icon: Icon(Icons.videocam_outlined, color: Theme.of(context).colorScheme.primary), onPressed: () {}),
                IconButton(icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary), onPressed: () {}),
              ],
            ),
          ),
          
          // Khu vực tin nhắn
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildMessageBubble(context, 'Chào bạn, dạo này bán khô thế nào rồi', false),
                _buildMessageBubble(context, 'Tui bán khô 1 ngày 1 tỷ', true),
                _buildMessageBubble(context, 'Tuyệt vời! Hãy cùng nạp tiền vào liên quân mua tướng đi', false),
              ],
            ),
          ),
          
          // Thanh nhập liệu (Input Area)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.attach_file, color: Colors.grey), onPressed: () {}),
                IconButton(icon: const Icon(Icons.image_outlined, color: Colors.grey), onPressed: () {}),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 2,
                  child: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm tạo bong bóng chat
  Widget _buildMessageBubble(BuildContext context, String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
        ),
      ),
    );
  }
}