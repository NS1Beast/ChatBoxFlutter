// ignore_file: file_names
import 'package:flutter/material.dart';
import 'NotificationsController.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsController _controller = NotificationsController();

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
          child: Column(
            children: [
              // ==========================================
              // HEADER & CÁC NÚT BỘ LỌC TẬP TRUNG
              // ==========================================
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                color: surfaceColor,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inbox_rounded, size: 28, color: textColor),
                            const SizedBox(width: 16),
                            Text('Hộp thư tin nhắn', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
                          ],
                        ),
                        // Nút Đọc tất cả giống Discord
                        if (_controller.currentFilterIndex == 0 && _controller.filteredMessages.isNotEmpty)
                          TextButton.icon(
                            onPressed: _controller.markAllAsRead,
                            icon: const Icon(Icons.done_all_rounded, size: 18),
                            label: const Text('Đánh dấu đọc tất cả', style: TextStyle(fontWeight: FontWeight.bold)),
                            // SỬA LỖI 1: Thay textColor thành foregroundColor
                            style: TextButton.styleFrom(foregroundColor: primaryColor),
                          )
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Hàng chứa nút lọc
                    Row(
                      children: [
                        _buildFilterButton('Chưa đọc', 0, primaryColor, textColor),
                        const SizedBox(width: 12),
                        _buildFilterButton('Được nhắc đến (@)', 2, primaryColor, textColor),
                        const SizedBox(width: 12),
                        _buildFilterButton('Đã đọc', 1, primaryColor, textColor),
                      ],
                    ),
                  ],
                ),
              ),

              // ==========================================
              // DANH SÁCH TIN NHẮN TỔNG HỢP
              // ==========================================
              Expanded(
                child: _controller.filteredMessages.isEmpty
                    ? _buildEmptyState(textColor)
                    : ListView.builder(
                        padding: const EdgeInsets.all(32),
                        itemCount: _controller.filteredMessages.length,
                        itemBuilder: (context, index) {
                          final msg = _controller.filteredMessages[index];
                          return _buildInboxRow(msg, surfaceColor, textColor, primaryColor);
                        },
                      ),
              ),
            ],
          ),
        );
      }
    );
  }

  // Nút chuyển bộ lọc
  Widget _buildFilterButton(String title, int index, Color primaryColor, Color textColor) {
    bool isSelected = _controller.currentFilterIndex == index;
    return ChoiceChip(
      label: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : textColor.withValues(alpha: 0.7))),
      selected: isSelected,
      selectedColor: primaryColor,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      onSelected: (val) => _controller.changeFilter(index),
      // SỬA LỖI 2: Xóa thuộc tính borderOnForeground không tồn tại
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }

  // Một dòng hiển thị tin nhắn chưa đọc
  Widget _buildInboxRow(InboxMessage msg, Color surfaceColor, Color textColor, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        // Nếu có tag tên mình thì đổi viền màu Tím nổi bật lên giống Discord
        border: msg.isMention ? Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundImage: NetworkImage(msg.avatarUrl)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(msg.senderName, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
                    if (msg.groupName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      // SỬA LỖI 3: Thay size thành fontSize
                      Text('trong', style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 13)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(msg.groupName, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                    const Spacer(),
                    Text(msg.timeStamp, style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  msg.snippet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: msg.isMention ? textColor : textColor.withValues(alpha: 0.7), fontSize: 14, fontWeight: msg.isRead ? FontWeight.normal : FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Nút hành động nhanh
          if (!msg.isRead)
            IconButton(
              icon: Icon(Icons.done_rounded, color: primaryColor),
              tooltip: 'Đánh dấu đã đọc',
              style: IconButton.styleFrom(backgroundColor: primaryColor.withValues(alpha: 0.1)),
              onPressed: () => _controller.markAsRead(msg.id),
            )
          else
            Icon(Icons.check_circle_outline_rounded, color: textColor.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  // Giao diện trống khi không có tin nhắn
  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.all_inbox_rounded, size: 72, color: textColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'Hộp thư trống rỗng!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 4),
          Text(
            'Bạn đã xử lý hết toàn bộ tin nhắn đến.',
            style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}